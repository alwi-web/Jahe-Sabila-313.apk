import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Tambah atau ubah produk beserta harga dan stok tiap ukuran.
class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, required this.draft});

  final ProductDraft draft;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.draft.name);
  late final _desc = TextEditingController(text: widget.draft.description);
  late final _composition = TextEditingController(text: widget.draft.composition);
  late final _serving = TextEditingController(text: widget.draft.servingSuggestion);
  late final _storage = TextEditingController(text: widget.draft.storageSuggestion);
  late final Map<PackSize, TextEditingController> _price = {
    for (final s in PackSize.values) s: TextEditingController(text: widget.draft.prices[s]?.toString() ?? ''),
  };
  late final Map<PackSize, TextEditingController> _stock = {
    for (final s in PackSize.values) s: TextEditingController(text: widget.draft.stocks[s]?.toString() ?? ''),
  };
  bool _busy = false;

  bool get _editing => widget.draft.id != null;
  ProductDraft get d => widget.draft;

  bool get _hasPhoto =>
      d.newImageBytes != null ||
      (!d.removeImage && (d.currentImageBytes != null || (d.imageUrl != null && d.imageUrl!.isNotEmpty)));

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran foto maksimal 5 MB')));
        }
        return;
      }
      setState(() {
        d.newImageBytes = bytes;
        d.newImageExt = x.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        d.removeImage = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto tidak bisa dibuka. Periksa izin galeri atau kamera.')),
        );
      }
    }
  }

  void _removePhoto() => setState(() {
        d.newImageBytes = null;
        d.removeImage = true;
      });

  Widget _photoPreview() {
    Widget? img;
    if (d.newImageBytes != null) {
      img = Image.memory(d.newImageBytes!, fit: BoxFit.cover);
    } else if (!d.removeImage && d.currentImageBytes != null) {
      img = Image.memory(d.currentImageBytes!, fit: BoxFit.cover);
    } else if (!d.removeImage && d.imageUrl != null && d.imageUrl!.isNotEmpty) {
      img = Image.network(d.imageUrl!, fit: BoxFit.cover);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        width: double.infinity,
        color: AppColors.paper,
        child: img ??
            const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.brown),
              SizedBox(height: 8),
              Text('Belum ada foto', style: TextStyle(color: AppColors.muted)),
              Text('Tanpa foto, katalog memakai gambar kemasan', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _composition.dispose();
    _serving.dispose();
    _storage.dispose();
    for (final c in [..._price.values, ..._stock.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final draft = ProductDraft(
      id: d.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      composition: _composition.text.trim(),
      servingSuggestion: _serving.text.trim(),
      storageSuggestion: _storage.text.trim(),
      imageUrl: d.imageUrl,
      currentImageBytes: d.currentImageBytes,
      prices: {for (final s in PackSize.values) s: int.parse(_price[s]!.text.trim())},
      stocks: {
        for (final s in PackSize.values) s: _stock[s]!.text.trim().isEmpty ? null : int.parse(_stock[s]!.text.trim()),
      },
    )
      ..newImageBytes = d.newImageBytes
      ..newImageExt = d.newImageExt
      ..removeImage = d.removeImage;
    setState(() => _busy = true);
    // Mengunggah foto bisa butuh beberapa detik.
    final ok = await runGuarded(context, () => context.read<AppState>().saveProduct(draft));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(_editing ? 'Produk diperbarui' : 'Produk ditambahkan');
  }

  Future<void> _deactivate() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${widget.draft.name}?'),
        content: const Text('Produk tidak tampil lagi di aplikasi pembeli. Riwayat pesanan lama tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, hapus')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () => context.read<AppState>().deactivateProduct(widget.draft.id!));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop('Produk dihapus');
  }

  String? _priceValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return 'Isi harga';
    return null;
  }

  String? _stockValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 0) return 'Tidak valid';
    return null;
  }

  Widget _numberField(String label, TextEditingController c, String? Function(String?) validator) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 4),
      TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: validator,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Ubah produk' : 'Tambah produk')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text('Foto produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _photoPreview(),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(_hasPhoto ? 'Ganti foto' : 'Pilih dari galeri', style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Ambil foto', style: TextStyle(fontSize: 14)),
                ),
              ),
            ]),
            if (_hasPhoto)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _busy ? null : _removePhoto, child: const Text('Hapus foto')),
              ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Nama produk',
              controller: _name,
              hint: 'Contoh: Jahe Merah dengan Madu',
              validator: (v) => requiredField(v, 'Nama produk'),
            ),
            const SizedBox(height: 14),
            LabeledField(label: 'Deskripsi', controller: _desc, hint: 'Deskripsi singkat produk', maxLines: 3),
            const SizedBox(height: 20),
            const Text('Informasi produk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Opsional. Yang diisi tampil di halaman detail produk pembeli.',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 10),
            LabeledField(
                label: 'Komposisi', controller: _composition, hint: 'Contoh: jahe merah, gula aren', maxLines: 3),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Saran penyajian',
                controller: _serving,
                hint: 'Contoh: seduh 1 sendok makan dengan 200 ml air panas',
                maxLines: 3),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Saran penyimpanan',
                controller: _storage,
                hint: 'Contoh: simpan di tempat kering dan tertutup rapat',
                maxLines: 3),
            const SizedBox(height: 20),
            const Text('Harga dan stok per ukuran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Kosongkan stok kalau tidak ingin dihitung.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 10),
            for (final s in PackSize.values) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 56,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(s.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
                Expanded(child: _numberField('Harga (Rp)', _price[s]!, _priceValidator)),
                const SizedBox(width: 8),
                Expanded(child: _numberField('Stok', _stock[s]!, _stockValidator)),
              ]),
              const SizedBox(height: 10),
            ],
            if (_editing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: Color(0xFFE3B8AE)),
                ),
                onPressed: _busy ? null : _deactivate,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus produk'),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Simpan produk'),
        ),
      ]),
    );
  }
}
