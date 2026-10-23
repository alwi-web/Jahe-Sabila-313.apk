import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../screens/auth/require_login.dart';
import '../screens/cart/cart_screen.dart';
import '../theme.dart';
import '../utils/errors.dart';

/// Ilustrasi kemasan kraft Sabila 313. Ganti dengan foto produk
/// (Image.asset / Image.network) kalau sudah ada.
class PackIllustration extends StatelessWidget {
  const PackIllustration({super.key, required this.width, required this.accent, this.showLabel = true});

  final double width;
  final Color accent;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.38;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.kraft,
          borderRadius: BorderRadius.circular(width * .08),
          border: Border.all(color: AppColors.kraftEdge),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Container(height: width * .14, color: AppColors.kraftTop),
          Positioned(
            left: width * .14,
            right: width * .14,
            top: h * .36,
            height: width * .66,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(width * .05)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: showLabel
                    ? [
                        Text('SABILA 313',
                            style: TextStyle(fontSize: width * .11, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1)),
                        SizedBox(height: width * .05),
                        Container(width: width * .34, height: width * .04, color: accent),
                        SizedBox(height: width * .05),
                        Text('Jahe Merah', style: TextStyle(fontSize: width * .085, color: AppColors.muted, height: 1)),
                      ]
                    : [
                        Container(width: width * .5, height: 3, color: AppColors.ink.withOpacity(.75)),
                        const SizedBox(height: 4),
                        Container(width: width * .34, height: 3, color: accent),
                      ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Foto produk kalau ada; kalau belum ada, gambar kemasan kraft.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    required this.product,
    required this.width,
    required this.height,
    required this.packWidth,
    this.showLabel = false,
    this.radius = 12,
  });

  final Product product;
  final double width;
  final double height;
  final double packWidth;
  final bool showLabel;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = PackIllustration(width: packWidth, accent: product.accent, showLabel: showLabel);
    Widget child;
    if (product.imageBytes != null) {
      child = Image.memory(product.imageBytes!, width: width, height: height, fit: BoxFit.cover);
    } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      child = Image.network(
        product.imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: 'Foto ${product.name}',
        errorBuilder: (_, __, ___) => Center(child: fallback),
        loadingBuilder: (_, w, progress) => progress == null ? w : Center(child: fallback),
      );
    } else {
      child = Center(child: fallback);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(width: width, height: height, color: AppColors.cream, child: child),
    );
  }
}

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.size, required this.product});

  final double size;
  final Product product;

  @override
  Widget build(BuildContext context) {
    return ProductPhoto(product: product, width: size, height: size * 1.2, packWidth: size * .62);
  }
}

/// Bayangan lembut untuk kartu di atas latar krem.
class AppShadow {
  static const card = [BoxShadow(color: Color(0x0F5A3A22), blurRadius: 12, offset: Offset(0, 3))];
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.borderColor});

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.line),
        boxShadow: AppShadow.card,
      ),
      child: child,
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onDecrease,
    required this.onIncrease,
    this.decreaseTooltip = 'Kurangi',
  });

  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String decreaseTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.field),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(onPressed: onDecrease, tooltip: decreaseTooltip, icon: const Icon(Icons.remove, size: 20)),
        SizedBox(
          width: 24,
          child: Text('$qty',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        IconButton(onPressed: onIncrease, tooltip: 'Tambah jumlah', icon: const Icon(Icons.add, size: 20)),
      ]),
    );
  }
}

/// Label di atas kolom isian, seperti di desain.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
        decoration: InputDecoration(hintText: hint),
      ),
    ]);
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  // Kolom password memakai controller sendiri yang menggambar titik-titik, bukan obscureText:
  // obscureText di Android menampilkan huruf terakhir sesaat (pengaturan "Tampilkan sandi" di HP),
  // sedangkan password harus langsung tersembunyi sejak diketik.
  late final _MaskedController _masked = _MaskedController(widget.controller.value);

  @override
  void initState() {
    super.initState();
    _masked.addListener(_toParent);
    widget.controller.addListener(_fromParent);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fromParent);
    _masked.dispose();
    super.dispose();
  }

  void _toParent() {
    if (widget.controller.value != _masked.value) widget.controller.value = _masked.value;
  }

  void _fromParent() {
    if (_masked.value != widget.controller.value) _masked.value = widget.controller.value;
  }

  @override
  Widget build(BuildContext context) {
    _masked.masked = _hidden;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _masked,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        keyboardType: TextInputType.visiblePassword,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        autofillHints: const [AutofillHints.password],
        // Saat tersembunyi, password tidak bisa disalin atau dipotong; tempel tetap bisa.
        contextMenuBuilder: (context, editable) => AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editable.contextMenuAnchors,
          buttonItems: _hidden
              ? editable.contextMenuButtonItems
                  .where((b) => b.type == ContextMenuButtonType.paste || b.type == ContextMenuButtonType.selectAll)
                  .toList()
              : editable.contextMenuButtonItems,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: IconButton(
            tooltip: _hidden ? 'Tampilkan password' : 'Sembunyikan password',
            icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ),
      ),
    ]);
  }
}

/// Controller yang menampilkan setiap huruf sebagai titik selama [masked] aktif.
class _MaskedController extends TextEditingController {
  _MaskedController(TextEditingValue super.value) : super.fromValue();

  bool masked = true;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!masked) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    return TextSpan(style: style, text: '\u2022' * text.length);
  }
}

/// Tombol pilihan berbentuk pil (ukuran kemasan, label alamat).
class SelectPill extends StatelessWidget {
  const SelectPill({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.brand : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.brand : AppColors.field),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label,
          style: TextStyle(color: status.foreground, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class MainBadge extends StatelessWidget {
  const MainBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF4E7E4), borderRadius: BorderRadius.circular(999)),
      child: const Text('Utama',
          style: TextStyle(color: Color(0xFF8A2E1C), fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Foto profil bulat; tanpa foto menampilkan huruf pertama nama.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.profile, this.radius = 28});

  final UserProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = profile.photoBytes != null
        ? MemoryImage(profile.photoBytes!)
        : profile.photoUrl.isNotEmpty
            ? NetworkImage(profile.photoUrl)
            : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.kraft,
      foregroundImage: image,
      onForegroundImageError: image == null ? null : (_, __) {},
      child: Text(profile.initial,
          style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w700, color: AppColors.ink)),
    );
  }
}

/// Logo Jahe Merah Sabila 313 (latar transparan, jadi ikut warna latar layar).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png', height: height, semanticLabel: 'Logo Jahe Merah Sabila 313');
  }
}

/// Area tombol di bagian bawah layar, dengan garis pemisah di atasnya.
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children, this.divider = true});

  final List<Widget> children;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: divider ? const Border(top: BorderSide(color: AppColors.line)) : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// Ikon keranjang dengan jumlah barang; membuka halaman keranjang.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppState>().cartCount;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: IconButton(
        tooltip: 'Keranjang, $count barang',
        style: IconButton.styleFrom(backgroundColor: AppColors.cream),
        onPressed: () async {
          if (!await requireLogin(context) || !context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen(pushed: true)));
        },
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: AppColors.brand,
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    );
  }
}

/// Menjalankan aksi ke server; kalau gagal, tampilkan pesan error yang ramah.
/// Mengembalikan true kalau berhasil.
Future<bool> runGuarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
    return false;
  }
}

String? requiredField(String? v, [String name = 'Kolom ini']) =>
    (v == null || v.trim().isEmpty) ? '$name wajib diisi' : null;

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Format email tidak valid';
  return null;
}

String? passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Password wajib diisi';
  if (v.length < 8) return 'Minimal 8 karakter';
  return null;
}
