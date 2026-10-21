import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/models.dart';
import 'format.dart';

/// Menyusun pesan otomatis berisi daftar barang, total, nama, no. HP, dan alamat.
String buildOrderMessage(Order order, UserProfile buyer) {
  final b = StringBuffer()
    ..writeln('Halo Jahe Merah Sabila 313, saya ingin memesan:')
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
    ..writeln('Nama: ${buyer.name}');
  if (buyer.phone.isNotEmpty) b.writeln('No. HP: ${buyer.phone}');
  b
    ..writeln('Alamat kirim:')
    ..writeln(order.addressText)
    ..writeln()
    ..write('Mohon info nomor rekening untuk pembayaran. Terima kasih.');
  return b.toString();
}

/// Membuka WhatsApp ke nomor penjual dengan pesan yang sudah terisi.
/// Mengembalikan false kalau WhatsApp atau browser tidak bisa dibuka.
Future<bool> openWhatsApp(String message) async {
  final uri = Uri.https('wa.me', '/$sellerWhatsApp', {'text': message});
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

