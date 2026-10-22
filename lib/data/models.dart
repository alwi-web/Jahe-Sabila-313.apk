import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Ukuran kemasan. Teks [label] sama dengan kolom varian_produk.ukuran.
enum PackSize {
  g250('250 g'),
  g500('500 g'),
  kg1('1 kg');

  const PackSize(this.label);
  final String label;

  static PackSize fromLabel(String text) =>
      values.firstWhere((s) => s.label == text.trim(), orElse: () => throw FormatException('Ukuran tidak dikenal: $text'));
}

class Variant {
  const Variant({required this.id, required this.size, required this.price, this.stock});

  final String id;
  final PackSize size;
  final int price;

  /// null berarti stok tidak dihitung.
  final int? stock;

  bool get soldOut => stock != null && stock! <= 0;
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.accent,
    required List<Variant> variants,
    this.imageUrl,
    this.imageBytes,
  }) : variants = [...variants]..sort((a, b) => a.size.index.compareTo(b.size.index));

  final String id;
  final String name;
  final String description;

  /// Warna garis label pada kemasan, pembeda antar varian.
  final Color accent;
  final String? imageUrl;

  /// Hanya dipakai mode demo (foto disimpan di memori, bukan di server).
  final Uint8List? imageBytes;

  bool get hasPhoto => imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);

  /// Varian diurutkan 250 g, 500 g, 1 kg.
  final List<Variant> variants;

  Variant? variantOf(PackSize size) {
    for (final v in variants) {
      if (v.size == size) return v;
    }
    return null;
  }

  int get startingPrice => variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
}

class CartItem {
  CartItem({required this.product, required this.variant, required this.qty});

  final Product product;
  final Variant variant;
  int qty;

  /// Satu baris keranjang per varian.
  String get key => variant.id;
  PackSize get size => variant.size;
  int get lineTotal => variant.price * qty;
}

enum OrderStatus {
  waitingPayment('menunggu', 'Menunggu bayar', Color(0xFFFFF4D6), Color(0xFF7A5200)),
  processing('diproses', 'Diproses', Color(0xFFE3EEF9), Color(0xFF1D4F86)),
  done('selesai', 'Selesai', Color(0xFFE1F2E8), Color(0xFF1F6440)),
  cancelled('batal', 'Dibatalkan', Color(0xFFF4E7E4), Color(0xFF8A2E1C));

  const OrderStatus(this.code, this.label, this.background, this.foreground);

  /// Nilai kolom pesanan.status di database.
  final String code;
  final String label;
  final Color background;
  final Color foreground;

  static OrderStatus fromCode(String code) =>
      values.firstWhere((s) => s.code == code, orElse: () => OrderStatus.waitingPayment);
}

/// Baris pesanan menyimpan nama dan harga saat pesanan dibuat,
/// supaya riwayat tidak berubah kalau produk atau harganya diubah nanti.
class OrderLine {
  const OrderLine({
    required this.productName,
    required this.productId,
    required this.size,
    required this.qty,
    required this.unitPrice,
  });

  final String productName;

  /// Bisa null kalau produknya sudah dihapus.
  final String? productId;
  final PackSize size;
  final int qty;
  final int unitPrice;

  int get total => unitPrice * qty;
}

class Order {
  Order({
    required this.id,
    required this.date,
    required this.lines,
    required this.addressText,
    required this.total,
    this.status = OrderStatus.waitingPayment,
    this.buyerName = '',
    this.buyerPhone = '',
    this.courier = '',
    this.trackingNumber = '',
    this.updatedAt,
    this.readAt,
  });

  /// Batas waktu bayar; lewat dari ini pesanan Menunggu bayar dibatalkan otomatis.
  static const paymentWindow = Duration(hours: 3);

  /// Diisi untuk tampilan admin.
  final String buyerName;
  final String buyerPhone;

  final String id;
  final DateTime date;
  final List<OrderLine> lines;

  /// Salinan alamat saat checkout (pesanan.alamat_kirim).
  final String addressText;
  final int total;
  OrderStatus status;

  /// Kurir pengiriman (JNE / J&T) dan nomor resinya, diisi admin.
  String courier;
  String trackingNumber;
  bool get hasTracking => trackingNumber.isNotEmpty;

  /// Kapan status/resi terakhir diubah, dan kapan pembeli terakhir membuka riwayat pesanan.
  DateTime? updatedAt;
  DateTime? readAt;
  bool get hasUnreadUpdate => updatedAt != null && (readAt == null || updatedAt!.isAfter(readAt!));

  DateTime get payBefore => date.add(paymentWindow);

  String get number => id.padLeft(3, '0');
  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);
}

class Address {
  Address({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.street,
    required this.city,
    required this.postalCode,
    this.note = '',
    this.isMain = false,
  });

  /// Kosong ('') untuk alamat baru yang belum disimpan.
  final String id;
  String label;
  String recipient;
  String phone;
  String street;
  String city;
  String postalCode;
  String note;
  bool isMain;

  bool get isNew => id.isEmpty;

  String get fullText {
    final buf = StringBuffer('$recipient ($phone)\n$street, $city $postalCode');
    if (note.trim().isNotEmpty) buf.write('\nCatatan: $note');
    return buf.toString();
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    this.photoBytes,
  });

  final String id;
  String name;
  String email;
  String phone;

  /// Foto profil: URL di Supabase Storage (bucket avatar), atau byte di mode demo.
  String photoUrl;
  Uint8List? photoBytes;
  bool get hasPhoto => photoBytes != null || photoUrl.isNotEmpty;

  static UserProfile get empty => UserProfile(id: '', name: '', email: '', phone: '');

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

/// Isi form tambah/ubah produk di sisi admin.
class ProductDraft {
  ProductDraft({
    this.id,
    this.name = '',
    this.description = '',
    this.imageUrl,
    this.currentImageBytes,
    Map<PackSize, int>? prices,
    Map<PackSize, int?>? stocks,
  })  : prices = prices ?? {},
        stocks = stocks ?? {};

  /// null untuk produk baru.
  final String? id;
  String name;
  String description;

  /// Foto yang sudah tersimpan (URL di Supabase Storage).
  String? imageUrl;

  /// Foto yang sudah tersimpan di mode demo.
  Uint8List? currentImageBytes;

  /// Foto baru yang dipilih admin dan belum diunggah.
  Uint8List? newImageBytes;
  String newImageExt = 'jpg';

  /// true kalau admin menghapus foto (kembali ke gambar kemasan).
  bool removeImage = false;
  final Map<PackSize, int> prices;
  final Map<PackSize, int?> stocks;

  factory ProductDraft.fromProduct(Product p) => ProductDraft(
        id: p.id,
        name: p.name,
        description: p.description,
        imageUrl: p.imageUrl,
        currentImageBytes: p.imageBytes,
        prices: {for (final v in p.variants) v.size: v.price},
        stocks: {for (final v in p.variants) v.size: v.stock},
      );
}

/// Mengubah teks warna "#B8412C" dari database menjadi Color.
Color colorFromHex(String? hex, {Color fallback = const Color(0xFFA8321F)}) {
  if (hex == null) return fallback;
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? fallback : Color(v);
}
