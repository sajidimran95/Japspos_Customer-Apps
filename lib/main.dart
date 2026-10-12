import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/storage.dart';
import 'state/app_state.dart';
import 'state/cart_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  final store = await LocalStore.open();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppState(store)),
      ChangeNotifierProvider(create: (_) => CartState()),
    ],
    child: const CustomerApp(),
  ));
}
