import '../core/format.dart';

int _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '')) ?? 0;
String _s(dynamic v) => v == null ? '' : '$v';
DateTime _dt(dynamic v) {
  final p = DateTime.tryParse(_s(v));
  return p == null ? DateTime.now() : (p.isUtc ? p.toLocal() : p);
}

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    v is List ? v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList() : <T>[];

class Business {
  const Business({required this.name, this.logo = ''});
  final String name;
  final String logo;
  String get letter => name.isEmpty ? 'C' : name[0].toUpperCase();
  factory Business.fromJson(Map<String, dynamic> j) => Business(name: _s(j['name']), logo: _s(j['logo']));
  Map<String, dynamic> toJson() => {'name': name, 'logo': logo};
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.contactId = '',
    this.businessName = '',
    this.email = '',
    this.mobile = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.country = '',
    this.shippingAddress = '',
    this.balanceDue = 0,
  });
  final int id;
  final String name;
  final String contactId;
  final String businessName;
  final String email;
  final String mobile;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String shippingAddress;
  final double balanceDue;

  /// Portal shows the business name when set, otherwise the contact name.
  String get displayName => businessName.isNotEmpty ? businessName : name;
  String get letter => displayName.isEmpty ? 'C' : displayName[0].toUpperCase();
  String get initials => initialsOf(displayName);

  Customer copyWith({double? balanceDue}) => Customer(
        id: id,
        name: name,
        contactId: contactId,
        businessName: businessName,
        email: email,
        mobile: mobile,
        address1: address1,
        address2: address2,
        city: city,
        state: state,
        zip: zip,
        country: country,
        shippingAddress: shippingAddress,
        balanceDue: balanceDue ?? this.balanceDue,
      );

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: _i(j['id']),
        name: _s(j['name']),
        contactId: _s(j['contact_id']),
        businessName: _s(j['business_name']),
        email: _s(j['email']),
        mobile: _s(j['mobile']),
        address1: _s(j['address_line_1']),
        address2: _s(j['address_line_2']),
        city: _s(j['city']),
        state: _s(j['state']),
        zip: _s(j['zip_code']),
        country: _s(j['country']),
        shippingAddress: _s(j['shipping_address']),
        balanceDue: _d(j['balance_due']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact_id': contactId,
        'business_name': businessName,
        'email': email,
        'mobile': mobile,
        'address_line_1': address1,
        'address_line_2': address2,
        'city': city,
        'state': state,
        'zip_code': zip,
        'country': country,
        'shipping_address': shippingAddress,
        'balance_due': balanceDue,
      };
}

/// A store location. [label] is the state (or name) the portal shows.
class StoreLocation {
  const StoreLocation({required this.id, required this.label, this.name = '', this.city = ''});
  final int id;
  final String label;
  final String name;
  final String city;
  factory StoreLocation.fromJson(Map<String, dynamic> j) {
    final state = _s(j['state']).trim();
    final label = _s(j['label']).isNotEmpty ? _s(j['label']) : (state.isNotEmpty ? state : _s(j['name']));
    return StoreLocation(id: _i(j['id']), label: label, name: _s(j['name']), city: _s(j['city']));
  }
}

class Product {
  const Product({required this.productId, required this.variationId, required this.name, this.sku = '', required this.price, this.stock = 0, this.image = ''});
  final int productId;
  final int variationId;
  final String name;
  final String sku;
  final double price;
  final double stock;
  final String image;
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        productId: _i(j['product_id'] ?? j['id']),
        variationId: _i(j['variation_id'] ?? j['id']),
        name: _s(j['name']),
        sku: _s(j['sku']),
        price: _d(j['price']),
        stock: _d(j['stock']),
        image: _s(j['image']),
      );
}

class Category {
  const Category({required this.id, required this.name, this.subs = const []});
  final int id;
  final String name;
  final List<Category> subs;
  factory Category.fromJson(Map<String, dynamic> j) => Category(id: _i(j['id']), name: _s(j['name']), subs: _list(j['sub_categories'], Category.fromJson));
}

class HomeData {
  const HomeData({required this.balanceDue, this.location, required this.newArrivals, required this.topProducts});
  final double balanceDue;
  final StoreLocation? location;
  final List<Product> newArrivals;
  final List<Product> topProducts;
}

/// Row in My Orders: a sales order (`kind: order`) or a final invoice.
class OrderRow {
  const OrderRow({
    required this.id,
    required this.invoiceNo,
    required this.kind,
    required this.date,
    required this.total,
    this.type = 'sales_order',
    this.status = 'ordered',
    this.paymentStatus = '',
    this.shippingStatus = '',
    this.shippingMethod = '',
  });
  final int id;
  final String invoiceNo;
  final String kind;
  final String type;
  final String status;
  final DateTime date;
  final double total;
  final String paymentStatus;
  final String shippingStatus;
  final String shippingMethod;

  bool get isFinalInvoice => type == 'sell' && status == 'final';

  factory OrderRow.fromJson(Map<String, dynamic> j) => OrderRow(
        id: _i(j['id']),
        invoiceNo: _s(j['invoice_no']),
        kind: _s(j['kind']).isEmpty ? 'order' : _s(j['kind']),
        type: _s(j['type']),
        status: _s(j['status']),
        date: _dt(j['transaction_date']),
        total: _d(j['final_total']),
        paymentStatus: _s(j['payment_status']),
        shippingStatus: _s(j['shipping_status']),
        shippingMethod: _s(j['shipping_method']),
      );
}

class OrderLineView {
  const OrderLineView({
    required this.name,
    this.image = '',
    this.sku = '',
    this.size = 'N/A',
    this.upc = '',
    required this.qty,
    required this.unitBefore,
    required this.unitFinal,
    required this.lineTotal,
    this.discount = 0,
    this.hasDiscount = false,
  });
  final String name;
  final String image;
  final String sku;
  final String size;
  final String upc;
  final double qty;
  final double unitBefore;
  final double unitFinal;
  final double lineTotal;
  final double discount;
  final bool hasDiscount;

  double get offAmount => discount > 0 ? discount : ((unitBefore - unitFinal) * qty).clamp(0, double.infinity).toDouble();

  factory OrderLineView.fromJson(Map<String, dynamic> j) => OrderLineView(
        name: _s(j['name']),
        image: _s(j['image']),
        sku: _s(j['sku']),
        size: _s(j['size']).isEmpty ? 'N/A' : _s(j['size']),
        upc: _s(j['upc']),
        qty: _d(j['qty']),
        unitBefore: _d(j['unit_before']),
        unitFinal: _d(j['unit_final']),
        lineTotal: _d(j['line_total']),
        discount: _d(j['discount']),
        hasDiscount: j['has_discount'] == true,
      );
}

class OrderDetail {
  const OrderDetail({required this.order, required this.fulfillment, this.shippingAddress = '', this.note = '', required this.lines, required this.itemsTotal});
  final OrderRow order;

  /// `pickup`, `delivery` or `shipping`.
  final String fulfillment;
  final String shippingAddress;
  final String note;
  final List<OrderLineView> lines;
  final double itemsTotal;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.total,
    this.tax = 0,
    this.paid = 0,
    this.balanceDue = 0,
    this.paymentStatus = '',
  });
  final int id;
  final String invoiceNo;
  final DateTime date;
  final double total;
  final double tax;
  final double paid;
  final double balanceDue;
  final String paymentStatus;

  /// Same rule as the portal: nothing paid → UNPAID, fully paid → PAID.
  String get statusLabel => paid <= 0 ? 'UNPAID' : (paid + 0.0001 >= total ? 'PAID' : 'PARTIAL');

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: _i(j['id']),
        invoiceNo: _s(j['invoice_no']),
        date: _dt(j['transaction_date']),
        total: _d(j['final_total']),
        tax: _d(j['tax_amount']),
        paid: _d(j['total_paid']),
        balanceDue: _d(j['balance_due']),
        paymentStatus: _s(j['payment_status']),
      );
}

class DocumentsData {
  const DocumentsData({required this.invoices, required this.invoiceCount, required this.salesTotal, required this.taxTotal, required this.paidTotal});
  final List<Invoice> invoices;
  final int invoiceCount;
  final double salesTotal;
  final double taxTotal;
  final double paidTotal;

  factory DocumentsData.fromInvoices(List<Invoice> rows) => DocumentsData(
        invoices: rows,
        invoiceCount: rows.length,
        salesTotal: rows.fold(0, (t, i) => t + i.total),
        taxTotal: rows.fold(0, (t, i) => t + i.tax),
        paidTotal: rows.fold(0, (t, i) => t + i.paid),
      );
}

class OrderCreateData {
  const OrderCreateData({required this.defaultLocationId, required this.locations, this.shippingAddress = '', this.defaultFulfillment = 'Delivery'});
  final int? defaultLocationId;
  final List<StoreLocation> locations;
  final String shippingAddress;
  final String defaultFulfillment;
}

class CartLine {
  CartLine({required this.product, this.qty = 1});
  final Product product;
  int qty;
  double get total => product.price * qty;
}

class OrderInput {
  const OrderInput({required this.locationId, required this.shippingMethod, required this.lines, this.shippingAddress = '', this.note = ''});
  final int locationId;
  final String shippingMethod;
  final String shippingAddress;
  final String note;
  final List<CartLine> lines;

  double get total => lines.fold(0, (t, l) => t + l.total);

  Map<String, dynamic> toJson() => {
        'location_id': locationId,
        'shipping_method': shippingMethod,
        'shipping_details': shippingMethod,
        if (shippingAddress.isNotEmpty) 'shipping_address': shippingAddress,
        if (note.isNotEmpty) 'sale_note': note,
        'products': lines
            .map((l) => {
                  'product_id': l.product.productId,
                  'variation_id': l.product.variationId,
                  'quantity': l.qty,
                  'unit_price': l.product.price,
                })
            .toList(),
      };
}

class ProfileData {
  const ProfileData({required this.customer, required this.currentLocationId, required this.locations});
  final Customer customer;
  final int? currentLocationId;
  final List<StoreLocation> locations;
}
