import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _photoBusy = false;

  /// Galeri / Kamera / Hapus foto, lalu langsung disimpan.
  Future<void> _changePhoto() async {
    final state = context.read<AppState>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil foto'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          if (state.profile.hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.brand),
              title: const Text('Hapus foto', style: TextStyle(color: AppColors.brand)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'remove') {
      setState(() => _photoBusy = true);
      final ok = await runGuarded(context, state.removeProfilePhoto);
      if (!mounted) return;
      setState(() => _photoBusy = false);
      if (ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil dihapus')));
      return;
    }

    final XFile? x;
    try {
      x = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto tidak bisa dibuka. Periksa izin galeri atau kamera.')),
        );
      }
      return;
    }
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran foto maksimal 5 MB')));
      return;
    }
    final ext = x.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    setState(() => _photoBusy = true);
    final ok = await runGuarded(context, () => state.changeProfilePhoto(bytes, ext));
    if (!mounted) return;
    setState(() => _photoBusy = false);
    if (ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
  }

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
    final profile = context.watch<AppState>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah profil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Center(
              child: Stack(alignment: Alignment.center, children: [
                UserAvatar(profile: profile, radius: 40),
                if (_photoBusy) const CircularProgressIndicator(),
              ]),
            ),
            Center(
              child: TextButton(
                onPressed: _photoBusy ? null : _changePhoto,
                child: Text(profile.hasPhoto ? 'Ganti foto' : 'Tambah foto'),
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
