import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _name = TextEditingController(text: p.name);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    var emailPending = false;
    final ok = await runGuarded(context, () async {
      emailPending = await context.read<AppState>().updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
          );
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    Navigator.of(context).pop(emailPending
        ? 'Profil disimpan. Buka link konfirmasi di email baru untuk mengganti email.'
        : 'Profil berhasil disimpan');
  }

  @override
  Widget build(BuildContext context) {
    final initial = context.watch<AppState>().profile.initial;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah profil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.kraft,
                child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ),
            Center(
              child: TextButton(
                // TODO: pilih foto dengan paket image_picker lalu unggah ke backend.
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur ganti foto belum tersedia')),
                ),
                child: const Text('Ganti foto'),
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(label: 'Nama lengkap', controller: _name, validator: (v) => requiredField(v, 'Nama')),
            const SizedBox(height: 14),
            LabeledField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress,
                validator: emailValidator),
            const SizedBox(height: 14),
            LabeledField(label: 'Nomor HP', controller: _phone, keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done, validator: (v) => requiredField(v, 'Nomor HP')),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan perubahan')),
      ]),
    );
  }
}
