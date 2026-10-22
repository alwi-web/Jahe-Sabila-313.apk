import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Form tambah alamat baru dan ubah alamat (Rumah, Kantor, Lainnya).
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, required this.address, required this.isNew});

  final Address address;
  final bool isNew;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const _labels = ['Rumah', 'Kantor', 'Lainnya'];

  final _form = GlobalKey<FormState>();
  late String _label;
  late bool _makeMain;
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    final state = context.read<AppState>();
    _label = _labels.contains(a.label) ? a.label : 'Lainnya';
    _makeMain = a.isNew ? state.addresses.isEmpty : state.isMain(a);
    _recipient = TextEditingController(text: a.recipient);
    _phone = TextEditingController(text: a.phone);
    _street = TextEditingController(text: a.street);
    _city = TextEditingController(text: a.city);
    _postal = TextEditingController(text: a.postalCode);
    _note = TextEditingController(text: a.note);
  }

  @override
  void dispose() {
    for (final c in [_recipient, _phone, _street, _city, _postal, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final saved = Address(
      id: widget.address.id,
      label: _label,
      recipient: _recipient.text.trim(),
      phone: _phone.text.trim(),
      street: _street.text.trim(),
      city: _city.text.trim(),
      postalCode: _postal.text.trim(),
      note: _note.text.trim(),
    );
    setState(() => _busy = true);
    final ok = await runGuarded(context, () => context.read<AppState>().saveAddress(saved, makeMain: _makeMain));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text('Alamat "${widget.address.label}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final ok = await runGuarded(context, () => context.read<AppState>().deleteAddress(widget.address.id));
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Tambah alamat baru' : 'Ubah alamat'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'Hapus alamat',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.brand),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const Text('Label alamat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              for (final l in _labels) ...[
                Expanded(
                  child: SelectPill(label: l, selected: _label == l, onTap: () => setState(() => _label = l)),
                ),
                if (l != _labels.last) const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 16),
            LabeledField(label: 'Nama penerima', controller: _recipient, hint: 'Nama penerima',
                validator: (v) => requiredField(v, 'Nama penerima')),
            const SizedBox(height: 16),
            LabeledField(label: 'Nomor HP', controller: _phone, hint: '08xxxxxxxxxx',
                keyboardType: TextInputType.phone, validator: (v) => requiredField(v, 'Nomor HP')),
            const SizedBox(height: 16),
            LabeledField(label: 'Alamat lengkap', controller: _street, maxLines: 3,
                hint: 'Jalan, nomor rumah, RT/RW, kecamatan', validator: (v) => requiredField(v, 'Alamat')),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: LabeledField(label: 'Kota/Kabupaten', controller: _city, hint: 'Kota',
                    validator: (v) => requiredField(v, 'Kota')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(label: 'Kode pos', controller: _postal, hint: 'Kode pos',
                    keyboardType: TextInputType.number, validator: (v) => requiredField(v, 'Kode pos')),
              ),
            ]),
            const SizedBox(height: 16),
            LabeledField(label: 'Catatan untuk kurir (opsional)', controller: _note,
                hint: 'Contoh: pagar hitam', textInputAction: TextInputAction.done),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _makeMain,
              onChanged: (v) => setState(() => _makeMain = v),
              activeColor: Colors.white,
              activeTrackColor: AppColors.brand,
              title: const Text('Jadikan alamat utama', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text('Dipakai otomatis saat checkout', style: TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(widget.isNew ? 'Simpan alamat' : 'Simpan perubahan'),
        ),
      ]),
    );
  }
}
