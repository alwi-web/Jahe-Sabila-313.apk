import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/models.dart';
import 'format.dart';

/// Menyusun pesan otomatis berisi daftar barang, total, nama, no. HP, dan alamat.
String buildOrderMessage(Order order, UserProfile buyer) {
  final b = StringBuffer()..writeln('Halo Jahe Merah Sabila 313, saya ingin memesan:');
  _writeOrderDetails(b, order, buyer.name, buyer.phone);
  b
    ..writeln()
    ..write('Mohon info nomor rekening untuk pembayaran. Terima kasih.');
  return b.toString();
}

/// Pesan admin ke pembeli: isi sama dengan pesan pembeli, ditambah status pesanan.
String buildAdminOrderMessage(Order order) {
  final b = StringBuffer()
    ..writeln('Halo ${order.buyerName.isEmpty ? 'Kak' : order.buyerName}, berikut pesanan Anda di Jahe Merah Sabila 313:');
  _writeOrderDetails(b, order, order.buyerName, order.buyerPhone);
  b
    ..writeln()
    ..write('Status pesanan: ${order.status.label}');
  return b.toString();
}

void _writeOrderDetails(StringBuffer b, Order order, String name, String phone) {
  b
    ..writeln('No. pesanan: #${order.number}')
    ..writeln();
  for (var i = 0; i < order.lines.length; i++) {
    final l = order.lines[i];
    b.writeln('${i + 1}. ${l.productName} ${l.size.label} x${l.qty} = ${rupiah(l.total)}');
  }
  b
    ..writeln()
    ..writeln('Total: ${rupiah(order.total)} (${order.itemCount} barang)')
    ..writeln()
    ..writeln('Nama: $name');
  if (phone.isNotEmpty) b.writeln('No. HP: $phone');
  b
    ..writeln('Alamat kirim:')
    ..writeln(order.addressText);
}

/// Membuka WhatsApp ke nomor penjual dengan pesan yang sudah terisi.
/// Mengembalikan false kalau WhatsApp atau browser tidak bisa dibuka.
Future<bool> openWhatsApp(String message) async {
  final uri = Uri.https('wa.me', '/$sellerWhatsApp', {'text': message});
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

