import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/format.dart';

/// Satu baris "penjualan per produk".
class ReportRow {
  const ReportRow({required this.product, required this.qty, required this.revenue});

  final String product;
  final int qty;
  final int revenue;
}

/// Data laporan untuk satu periode.
class ReportData {
  const ReportData({
    required this.periodLabel,
    required this.revenue,
    required this.doneCount,
    required this.cancelledCount,
    required this.rows,
  });

  final String periodLabel;
  final int revenue;
  final int doneCount;
  final int cancelledCount;
  final List<ReportRow> rows;
}

String _fileStem(ReportData r) =>
    'laporan-sabila313-${r.periodLabel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';

/// Membuat PDF laporan lalu membuka lembar bagikan/simpan.
Future<void> exportPdf(ReportData r) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Laporan Penjualan Jahe Merah Sabila 313',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Periode: ${r.periodLabel} · Dibuat ${shortDate(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.Text('Pendapatan (pesanan selesai): ${rupiah(r.revenue)}'),
          pw.Text('Pesanan selesai: ${r.doneCount}'),
          pw.Text('Pesanan batal: ${r.cancelledCount}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Produk', 'Terjual', 'Pendapatan'],
            data: [for (final row in r.rows) [row.product, '${row.qty}', rupiah(row.revenue)]],
            cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
          ),
        ],
      ),
    ),
  );
  await Printing.sharePdf(bytes: await doc.save(), filename: '${_fileStem(r)}.pdf');
}

/// Membuat file Excel (.xlsx) laporan lalu membuka lembar bagikan.
Future<void> exportExcel(ReportData r) async {
  final excel = Excel.createExcel();
  final sheet = excel['Laporan'];
  excel.setDefaultSheet('Laporan');
  excel.delete('Sheet1');

  sheet.appendRow([TextCellValue('Laporan Penjualan Jahe Merah Sabila 313')]);
  sheet.appendRow([TextCellValue('Periode'), TextCellValue(r.periodLabel)]);
  sheet.appendRow([TextCellValue('Pendapatan (pesanan selesai)'), IntCellValue(r.revenue)]);
  sheet.appendRow([TextCellValue('Pesanan selesai'), IntCellValue(r.doneCount)]);
  sheet.appendRow([TextCellValue('Pesanan batal'), IntCellValue(r.cancelledCount)]);
  sheet.appendRow([]);
  sheet.appendRow([TextCellValue('Produk'), TextCellValue('Terjual'), TextCellValue('Pendapatan (Rp)')]);
  for (final row in r.rows) {
    sheet.appendRow([TextCellValue(row.product), IntCellValue(row.qty), IntCellValue(row.revenue)]);
  }

  final bytes = excel.encode();
  if (bytes == null) throw Exception('Gagal membuat file Excel');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_fileStem(r)}.xlsx');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(file.path)], text: 'Laporan penjualan ${r.periodLabel}');
}
