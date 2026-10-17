import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const bg = Color(0xFF070B17);
  static const card = Color(0xFF101733);
  static const cyan = Color(0xFF00E5FF);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFFF4D9D);
  static const green = Color(0xFF34D399);
  static const grey = Color(0xFF8A94B8);
  static const grad = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Color statusColor(String s) => switch (s) {
      'Cutting' => C.violet,
      'Stitching' => C.pink,
      'Ready' => C.cyan,
      _ => C.green,
    };

IconData statusIcon(String s) => switch (s) {
      'Cutting' => Icons.content_cut,
      'Stitching' => Icons.checkroom,
      'Ready' => Icons.check_circle,
      _ => Icons.local_shipping,
    };

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(primary: C.cyan, secondary: C.violet, surface: C.card),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      border: border(Colors.transparent),
      enabledBorder: border(C.cyan.withOpacity(.12)),
      focusedBorder: border(C.cyan),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.card,
      indicatorColor: C.violet.withOpacity(.4),
    ),
  );
}

/// Glowing aurora background
class Aurora extends StatelessWidget {
  final Widget child;
  const Aurora({super.key, required this.child});

  Widget _blob(Color c) => Container(
        width: 340,
        height: 340,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withOpacity(.25), Colors.transparent]),
        ),
      );

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned(top: -140, left: -100, child: _blob(C.violet)),
        Positioned(bottom: -160, right: -120, child: _blob(C.cyan)),
        child,
      ]);
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: C.card.withOpacity(.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.cyan.withOpacity(.18)),
          boxShadow: [BoxShadow(color: C.violet.withOpacity(.16), blurRadius: 24)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final double size;
  const GradientText(this.text, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => C.grad.createShader(r),
        child: Text(text,
            style: TextStyle(
                fontSize: size, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
      );
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF04101F);
    return Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: C.grad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: C.cyan.withOpacity(.3), blurRadius: 16)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (loading)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                else if (icon != null)
                  Icon(icon, color: fg, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: fg, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: C.grey),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: C.grey)),
        ]),
      );
}
