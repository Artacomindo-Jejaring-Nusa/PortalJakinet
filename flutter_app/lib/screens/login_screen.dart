import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/technician_provider.dart';
import 'dashboard_screen.dart';
import 'technician/technician_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFFF7F5FF); // lavender-tinted white
  static const _panel = Color(0xFFE9E3FF); // hero panel
  static const _ink = Color(0xFF1D1440); // deep aubergine, used for text
  static const _violet = Color(0xFF4A2BC7); // primary action
  static const _violetSoft = Color(0xFFE6DFFF); // icon chip
  static const _muted = Color(0xFF6F6A8C); // secondary text
  static const _hint = Color(0xFFA29FBA); // placeholder
  static const _line = Color(0xFFDDD5F7); // field outline
  static const _error = Color(0xFFD6285B);

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final technicianProvider = Provider.of<TechnicianProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();

    final result = await customerProvider.loginAutoDetect(identifier);
    if (!mounted) return;

    if (result.isTechnician && result.technicianUser != null) {
      technicianProvider.setTechnicianUser(result.technicianUser!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TechnicianDashboardScreen()),
      );
    } else if (result.customerData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      final errorMsg = customerProvider.error ?? 'Data tidak ditemukan. Pastikan email atau nomor WhatsApp terdaftar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Hero: panel lengkung + cincin sinyal + gambar 3D ───────────
  Widget _buildHero(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    const contentHeight = 290.0;
    const curveDepth = 36.0;
    final totalHeight = topInset + contentHeight;

    return ClipPath(
      clipper: const _CurvedBottomClipper(depth: curveDepth),
      child: Container(
        height: totalHeight,
        color: _panel,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return CustomPaint(
              painter: _SignalRingsPainter(
                progress: t,
                centerY: topInset + (contentHeight - curveDepth) / 2,
              ),
              child: child,
            );
          },
          child: Stack(
            children: [
              Positioned(
                top: topInset,
                left: 0,
                right: 0,
                height: contentHeight - curveDepth,
                child: Center(
                  child: Image.asset(
                    'assets/images/login_3d_hero.png',
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_tethering,
                          size: 40,
                          color: _violet,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false, // hero menutupi area status bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HERO
              _buildHero(context),

              // 2. FORM
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Portal Ajnusa',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Masukkan nomor telepon atau Email untuk masuk.',
                            style: TextStyle(
                              fontSize: 14,
                              color: _muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Label
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text(
                              'Nomor WhatsApp atau Email yang terdaftar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Input Field
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.text,
                            cursorColor: _violet,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _ink,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor WhatsApp atau ID wajib diisi';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Contoh: 08123456789 atau Email...',
                              hintStyle: const TextStyle(
                                color: _hint,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: _violetSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: _violet,
                                    size: 18,
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
                              errorStyle: const TextStyle(
                                color: _error,
                                fontSize: 12,
                              ),
                              border: _fieldBorder(_line),
                              enabledBorder: _fieldBorder(_line),
                              focusedBorder: _fieldBorder(_violet, width: 1.6),
                              errorBorder: _fieldBorder(_error),
                              focusedErrorBorder: _fieldBorder(
                                _error,
                                width: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tombol Masuk
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _violet,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFB9AEEA,
                                ),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'Customer Portal v1.0.0',
                              style: TextStyle(color: _hint, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(32),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Memotong bagian bawah hero menjadi lengkung cembung yang halus.
class _CurvedBottomClipper extends CustomClipper<Path> {
  final double depth;
  const _CurvedBottomClipper({required this.depth});

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - depth)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + depth,
        size.width,
        size.height - depth,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CurvedBottomClipper oldClipper) =>
      oldClipper.depth != depth;
}

/// Cincin konsentris seperti sinyal Wi-Fi yang memancar dari gambar hero.
/// Muncul sekali saat halaman dibuka (mengembang + memudar masuk).
class _SignalRingsPainter extends CustomPainter {
  final double progress; // 0 → 1
  final double centerY;

  const _SignalRingsPainter({required this.progress, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, centerY);

    // Sorotan putih di belakang gambar
    canvas.drawCircle(
      center,
      116 * (0.6 + 0.4 * progress),
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.75 * progress),
    );

    // Cincin sinyal
    const radii = [150.0, 195.0, 245.0, 300.0, 360.0];
    for (var i = 0; i < radii.length; i++) {
      final alpha = (0.55 - i * 0.1) * progress;
      canvas.drawCircle(
        center,
        radii[i] * (0.7 + 0.3 * progress),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalRingsPainter old) =>
      old.progress != progress || old.centerY != centerY;
}
