import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';

/// iPhone zoom scale used by mobile_scanner: device zoom = scale * 4 + 1.
/// 0.42 is about 2.7x on the main camera, so a product barcode fills more pixels.
const _iosPowerZoom = 0.42;
const _iosPowerZoomMax = 0.62;

/// Retail symbologies only, which keeps ML Kit / Apple Vision fast.
const _scanFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.itf2of5,
  BarcodeFormat.codabar,
  BarcodeFormat.qrCode,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.pdf417,
];

/// Opens the camera scanner and returns the first barcode read (or null).
Future<String?> scanBarcode(BuildContext context) =>
    Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ScanScreen()));

/// Full-screen "Scan barcode" overlay from the portal.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  MobileScannerController? _cam;
  late final AnimationController _laser = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  final _manual = TextEditingController();
  double _zoomAtPinchStart = 0;
  bool _done = false;
  bool _macro = false;
  bool _userZoom = false;
  Timer? _zoomBoost;

  bool get _cameraSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get _ios => _cameraSupported && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) {
      _cam = MobileScannerController(
        formats: _scanFormats,
        detectionSpeed: DetectionSpeed.unrestricted,
        cameraResolution: const Size(1920, 1080),
        // Android only. iPhone zoom is driven below.
        autoZoom: !Platform.isIOS,
        // Main lens, not the virtual triple camera that opens on ultra-wide.
        lensType: Platform.isIOS ? CameraLensType.normal : CameraLensType.any,
        initialZoom: Platform.isIOS ? _iosPowerZoom : null,
      );
      if (Platform.isIOS) _startIosZoomBoost();
    }
  }

  /// Creep zoom until a barcode fills enough of the frame to read.
  void _startIosZoomBoost() {
    var steps = 0;
    _zoomBoost = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      final cam = _cam;
      if (!mounted || _done || _userZoom || _macro || cam == null || steps >= 4) {
        timer.cancel();
        return;
      }
      if (!cam.value.isInitialized || !cam.value.isRunning) return;
      steps++;
      final next = (_iosPowerZoom + steps * 0.05).clamp(0.0, _iosPowerZoomMax);
      unawaited(cam.setZoomScale(next).catchError((Object _) => null));
    });
  }

  void _stopZoomBoost() {
    _userZoom = true;
    _zoomBoost?.cancel();
  }

  /// Ultra-wide for a label held against the phone. Main lens otherwise.
  Future<void> _toggleMacro() async {
    final cam = _cam;
    if (cam == null) return;
    _stopZoomBoost();
    final enable = !_macro;
    setState(() => _macro = enable);
    try {
      if (enable) {
        final best = await cam.getBestCloseRangeScanningLens();
        final supported = await cam.getSupportedLenses(facing: CameraFacing.back);
        if (best != null && supported.contains(best)) {
          await cam.switchCamera(SelectCamera(facingDirection: CameraFacing.back, lensType: best));
        }
        await cam.setZoomScale(0);
      } else {
        final supported = await cam.getSupportedLenses(facing: CameraFacing.back);
        final lens = supported.contains(CameraLensType.normal) ? CameraLensType.normal : CameraLensType.any;
        await cam.switchCamera(SelectCamera(facingDirection: CameraFacing.back, lensType: lens));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _zoomBoost?.cancel();
    _laser.dispose();
    _cam?.dispose();
    _manual.dispose();
    super.dispose();
  }

  /// The code nearest the frame center wins when several are visible.
  Barcode? _centerMost(BarcodeCapture cap) {
    final codes = cap.barcodes.where((b) => (b.rawValue ?? '').isNotEmpty).toList();
    if (codes.length <= 1) return codes.firstOrNull;
    final size = cap.size;
    if (size.isEmpty) return codes.first;
    final mid = Offset(size.width / 2, size.height / 2);
    double dist(Barcode b) {
      if (b.corners.isEmpty) return double.infinity;
      final c = b.corners.reduce((a, o) => a + o) / b.corners.length.toDouble();
      return (c - mid).distanceSquared;
    }

    codes.sort((a, b) => dist(a).compareTo(dist(b)));
    return codes.first;
  }

  void _finish(String code) {
    if (_done || code.trim().isEmpty) return;
    _done = true;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    Navigator.of(context).pop(code.trim());
  }

  Future<void> _scanFromPhoto() async {
    final cam = _cam;
    if (cam == null) return;
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final cap = await cam.analyzeImage(img.path, formats: _scanFormats);
    if (!mounted) return;
    final b = cap == null ? null : _centerMost(cap);
    if (b?.rawValue == null) {
      toast(context, 'No barcode found in that photo', success: false);
      return;
    }
    _finish(b!.rawValue!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xF00F172A),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Text('Scan barcode', style: display(size: 18, color: Colors.white))),
                if (_cam != null)
                  _roundBtn(Icons.photo_library_outlined, _scanFromPhoto),
                const SizedBox(width: 8),
                _roundBtn(Icons.close, () => Navigator.pop(context)),
              ]),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(children: [
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: _cam == null ? _noCamera() : _cameraView(_cam!)),
                      ),
                      if (_cam != null) _controls(_cam!),
                      const SizedBox(height: 10),
                      Text(
                        _macro ? 'Close-up is on. Hold the barcode near the camera.' : 'Fill the frame with the barcode. Pinch to zoom.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CaColors.slate300, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _manual,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        textInputAction: TextInputAction.done,
                        onSubmitted: _finish,
                        decoration: InputDecoration(
                          hintText: 'Or type barcode / SKU',
                          hintStyle: const TextStyle(color: CaColors.slate400),
                          fillColor: Colors.white.withValues(alpha: .1),
                          prefixIcon: const Icon(Icons.keyboard, color: CaColors.slate400),
                          suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.white), onPressed: () => _finish(_manual.text)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: .15))),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _roundBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white.withValues(alpha: .12),
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white))),
      );

  Widget _noCamera() => Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: const Text('Camera scanning is not available on this device.\nType the barcode below.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
      );

  Widget _cameraView(MobileScannerController cam) => LayoutBuilder(builder: (ctx, c) {
        final scanWindow = Rect.fromCenter(
          center: Offset(c.maxWidth / 2, c.maxHeight / 2),
          width: c.maxWidth * .88,
          height: c.maxHeight * .5,
        );
        return GestureDetector(
          onScaleStart: (_) {
            _stopZoomBoost();
            _zoomAtPinchStart = cam.value.zoomScale;
          },
          onScaleUpdate: (d) {
            if (d.pointerCount < 2) return;
            cam.setZoomScale((_zoomAtPinchStart + (d.scale - 1) * 0.5).clamp(0.0, 1.0));
          },
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(
              controller: cam,
              scanWindow: scanWindow,
              onDetect: (cap) {
                final code = _centerMost(cap)?.rawValue;
                if (code != null) _finish(code);
              },
              tapToFocus: true,
              errorBuilder: (ctx, err) => _cameraError(err),
              placeholderBuilder: (_) => Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
            ),
            IgnorePointer(child: _overlay(scanWindow)),
          ]),
        );
      });

  Widget _overlay(Rect window) => Stack(fit: StackFit.expand, children: [
        Positioned.fromRect(
          rect: window,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white, width: 2.5)),
            child: AnimatedBuilder(
              animation: _laser,
              builder: (_, _) => Align(
                alignment: Alignment(0, _laser.value * 2 - 1),
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: CaColors.brand, boxShadow: [BoxShadow(color: CaColors.brand.withValues(alpha: .6), blurRadius: 8)]),
                ),
              ),
            ),
          ),
        ),
      ]);

  Widget _cameraError(MobileScannerException err) {
    final denied = err.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        denied ? 'Camera permission denied or not available.' : 'Camera error: ${err.errorDetails?.message ?? err.errorCode.name}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFDA4AF), fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _controls(MobileScannerController cam) => ValueListenableBuilder<MobileScannerState>(
        valueListenable: cam,
        builder: (ctx, s, _) {
          final torchOn = s.torchState == TorchState.on;
          return Row(children: [
            IconButton(
              tooltip: 'Flashlight',
              onPressed: s.torchState == TorchState.unavailable ? null : cam.toggleTorch,
              icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off, color: torchOn ? const Color(0xFFFBBF24) : Colors.white70),
            ),
            Expanded(
              child: Slider(
                value: s.zoomScale.clamp(0.0, 1.0),
                activeColor: CaColors.brand,
                onChangeStart: (_) => _stopZoomBoost(),
                onChanged: cam.setZoomScale,
              ),
            ),
            if (_ios)
              IconButton(
                tooltip: _macro ? 'Normal scan' : 'Close-up',
                onPressed: _toggleMacro,
                icon: Icon(_macro ? Icons.center_focus_strong : Icons.center_focus_weak, color: _macro ? CaColors.brand : Colors.white70),
              )
            else
              IconButton(tooltip: 'Switch camera', onPressed: () => cam.switchCamera(), icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white70)),
          ]);
        },
      );
}
