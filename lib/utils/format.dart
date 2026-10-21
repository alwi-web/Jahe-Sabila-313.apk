/// Format angka ke rupiah, misalnya 105000 menjadi "Rp 105.000".
String rupiah(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}Rp $buf';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Format tanggal pendek, misalnya "21 Okt 2026".
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Format tanggal dan jam, misalnya "21 Okt 2026, 14.05".
String dateTime(DateTime d) =>
    '${shortDate(d)}, ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
