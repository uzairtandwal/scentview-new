import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScentViewNeonSplash extends StatefulWidget {
  final VoidCallback? onFinished;
  const ScentViewNeonSplash({super.key, this.onFinished});

  @override
  State<ScentViewNeonSplash> createState() => _ScentViewNeonSplashState();
}

class _ScentViewNeonSplashState extends State<ScentViewNeonSplash> with TickerProviderStateMixin {
  late AnimationController _blueCtrl, _yellowCtrl, _redCtrl, _greenCtrl, _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _blueCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _yellowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _redCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _greenCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // ✅ FIXED: Ye block ab 4 second baad onFinished ko call karega
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.onFinished != null) {
        widget.onFinished!(); 
      }
    });
  }

  @override
  void dispose() {
    _blueCtrl.dispose(); _yellowCtrl.dispose(); _redCtrl.dispose();
    _greenCtrl.dispose(); _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D15),
      body: Center(
        child: SizedBox(
          width: 320, height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(_blueCtrl, const Color(0xFF00CFFF), 4, 140, 70, 0),
              _buildRing(_yellowCtrl, const Color(0xFFFFD84A), 4, 110, 55, math.pi / 4),
              _buildRing(_redCtrl, const Color(0xFFFF4B7A), 3, 80, 40, 0),
              _buildRing(_greenCtrl, const Color(0xFF33FFAA), 3, 60, 30, math.pi / 3),
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => _NeonText(glowOpacity: _glowAnim.value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(AnimationController ctrl, Color col, int count, double len, double rad, double offset) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Transform.rotate(
        angle: ctrl.value * 2 * math.pi,
        child: CustomPaint(
          size: const Size(320, 320),
          painter: _LineRingPainter(color: col, lineCount: count, lineLength: len, lineWidth: 3, radius: rad, startAngle: offset),
        ),
      ),
    );
  }
}

class _LineRingPainter extends CustomPainter {
  final Color color; final int lineCount; final double lineLength; final double lineWidth; final double radius; final double startAngle;
  _LineRingPainter({required this.color, required this.lineCount, required this.lineLength, required this.lineWidth, required this.radius, required this.startAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = (2 * math.pi) / lineCount;
    for (int i = 0; i < lineCount; i++) {
      final angle = startAngle + (i * angleStep);
      final dx = math.cos(angle); final dy = math.sin(angle);
      final start = Offset(center.dx + dx * (radius - lineLength / 2), center.dy + dy * (radius - lineLength / 2));
      final end = Offset(center.dx + dx * (radius + lineLength / 2), center.dy + dy * (radius + lineLength / 2));
      canvas.drawLine(start, end, Paint()..color = color.withOpacity(0.25)..strokeWidth = lineWidth * 5..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      canvas.drawLine(start, end, Paint()..color = color.withOpacity(0.5)..strokeWidth = lineWidth * 2.5..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawLine(start, end, Paint()..strokeWidth = lineWidth..strokeCap = StrokeCap.round..shader = LinearGradient(colors: [Colors.transparent, color, color, Colors.transparent], stops: const [0.0, 0.2, 0.8, 1.0]).createShader(Rect.fromPoints(start, end)));
    }
  }
  @override bool shouldRepaint(_LineRingPainter old) => false;
}

class _NeonText extends StatelessWidget {
  final double glowOpacity;
  const _NeonText({required this.glowOpacity});
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Text('SCENTVIEW', style: TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.w300, foreground: Paint()..color = const Color(0xFF00AEFF).withOpacity(glowOpacity * 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18))),
      Text('SCENTVIEW', style: TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.w300, foreground: Paint()..color = const Color(0xFF0066FF).withOpacity(glowOpacity * 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8))),
      Text('SCENTVIEW', style: TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.w300, color: Color.lerp(const Color(0xFF88CCFF), const Color(0xFFC1E6FF), glowOpacity))),
    ]);
  }
}
