import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const FateLensApp());
}

class FateLensApp extends StatelessWidget {
  const FateLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FateLens',
      theme: ThemeData(brightness: Brightness.dark),
      home: const FateLensWelcomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Welcome Screen
// ─────────────────────────────────────────────────────────────
class FateLensWelcomeScreen extends StatefulWidget {
  const FateLensWelcomeScreen({super.key});

  @override
  State<FateLensWelcomeScreen> createState() =>
      _FateLensWelcomeScreenState();
}

class _FateLensWelcomeScreenState extends State<FateLensWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbitCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── 1. 背景 + 星空 + 星球（全部在同一個 Painter）──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => CustomPaint(
                  painter: FateLensScenePainter(_orbitCtrl.value),
                ),
              ),
            ),

            // ── 2. 全畫面靜態噪點（只畫一次）────────────────
            Positioned.fill(
              child: CustomPaint(painter: _GrainPainter()),
            ),

            // ── 3. 前景 UI ───────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 頂部導航列
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.menu,
                            color: Colors.white, size: 26),
                        Row(
                          children: [
                            const Icon(Icons.language,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 14),
                            Icon(Icons.account_circle_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 24),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 52),

                    // 大標題
                    const Text(
                      'Welcome to\nFateLens',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Georgia',
                        letterSpacing: 0.5,
                      ),
                    ),

                    const Spacer(),

                    // 第一段
                    Text(
                      "Whether you're\nseeking direction\ntoday, or simply want\nsomeone to talk to.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 15.5,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 第二段（加粗）
                    const Text(
                      "We'll always be here with you,\nto shine a little light on your\npath.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        height: 1.65,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 52),

                    // START 按鈕
                    Center(child: _StartButton()),

                    const SizedBox(height: 44),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Scene Painter
//  背景漸層 → 隨機星星 → 後半圈文字 → 星球 → 前半圈文字
// ─────────────────────────────────────────────────────────────
class _OrbitLetter {
  final String char;
  final double x, y, z;
  _OrbitLetter(this.char, this.x, this.y, this.z);
}

class FateLensScenePainter extends CustomPainter {
  final double animationValue;
  static const String _text =
      'FateLens  Tarot  FateLens  A Join  Lens  FateLens  ';

  // 背景最深色，同時也是星球底部融合色
  static const Color kBgDark = Color(0xFF0E1A26);

  FateLensScenePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // ── 背景漸層 ──────────────────────────────────────────
    final bgRect = Offset.zero & size;
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.50, 1.0],
          colors: [
            Color(0xFF1E2E3E),
            Color(0xFF131F2C),
            Color(0xFF0E1A26),
          ],
        ).createShader(bgRect),
    );

    // ── 隨機星星 ──────────────────────────────────────────
    _drawStars(canvas, size);

    // ── 3D 場景參數 ───────────────────────────────────────
    // 星球中心偏右上，部分超出螢幕邊緣（貼近原圖）
    final planet = Offset(size.width * 0.88, size.height * 0.38);
    final planetR = size.width * 0.48;
    final orbitRx = planetR * 1.15; // 軌道水平半徑
    final orbitRy = planetR * 0.22; // 軌道垂直半徑（透視壓扁）

    // ── 計算每個字母的 3D 位置 ─────────────────────────────
    final chars = _text.characters.toList();
    final letters = <_OrbitLetter>[];
    for (int i = 0; i < chars.length; i++) {
      final theta = (i / chars.length) * 2 * math.pi +
          animationValue * 2 * math.pi;
      letters.add(_OrbitLetter(
        chars[i],
        orbitRx * math.cos(theta),
        orbitRy * math.sin(theta),
        math.sin(theta), // z: -1(後) → 1(前)
      ));
    }

    // ── 後半圈文字（藏在球後）─────────────────────────────
    for (final l in letters.where((l) => l.z < 0)) {
      _drawLetter(canvas, l, planet, isFront: false);
    }

    // ── 星球本體 ──────────────────────────────────────────
    _drawPlanet(canvas, planet, planetR, size);

    // ── 前半圈文字（疊在球前）─────────────────────────────
    for (final l in letters.where((l) => l.z >= 0)) {
      _drawLetter(canvas, l, planet, isFront: true);
    }
  }

  // ── 星球 ──────────────────────────────────────────────────
  void _drawPlanet(Canvas canvas, Offset c, double r, Size size) {
    final rect = Rect.fromCircle(center: c, radius: r);

    // 主漸層：頂部壓暗舊金 → 底部融入背景
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.32, 0.65, 0.88, 1.0],
          colors: [
            const Color(0xFF7A5C28), // 頂：暗舊金
            const Color(0xFF5C4018), // 上中：深琥珀
            const Color(0xFF321E06), // 下中：深棕
            const Color(0xFF180E02), // 接近底
            kBgDark,                  // 底：融入背景
          ],
        ).createShader(rect),
    );

    // 側面暗角
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
          stops: const [0.50, 1.0],
        ).createShader(rect),
    );

    // 左上微弱高光
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.40, -0.42),
          radius: 0.50,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // 星球表面噪點
    _drawPlanetGrain(canvas, c, r);
  }

  void _drawPlanetGrain(Canvas canvas, Offset c, double r) {
    final rng = math.Random(7);
    final p = Paint();
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    for (int i = 0; i < 2800; i++) {
      final px = c.dx + (rng.nextDouble() * 2 - 1) * r;
      final py = c.dy + (rng.nextDouble() * 2 - 1) * r;
      p.color = Colors.white.withOpacity(rng.nextDouble() * 0.055 + 0.008);
      canvas.drawCircle(Offset(px, py), rng.nextDouble() * 0.7 + 0.2, p);
    }
    canvas.restore();
  }

  // ── 星星（隨機，大小不一）────────────────────────────────
  void _drawStars(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final p = Paint();
    for (int i = 0; i < 140; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.4 + 0.2;
      p.color = Colors.white.withOpacity(rng.nextDouble() * 0.55 + 0.18);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  // ── 單個字母 ──────────────────────────────────────────────
  void _drawLetter(
    Canvas canvas,
    _OrbitLetter l,
    Offset center, {
    required bool isFront,
  }) {
    // 近大遠小
    final scale = isFront
        ? 0.88 + 0.18 * l.z       // 前：0.88 → 1.06
        : 0.72 + 0.10 * l.z.abs(); // 後：0.72 → 0.82

    // 前亮後暗
    final opacity = isFront
        ? (0.60 + 0.35 * l.z).clamp(0.60, 0.92)
        : (0.18 + 0.10 * l.z.abs()).clamp(0.18, 0.28);

    final tp = TextPainter(
      text: TextSpan(
        text: l.char,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 12.0 * scale,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(
      center.dx + l.x - tp.width / 2,
      center.dy + l.y - tp.height / 2,
    );
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(FateLensScenePainter old) =>
      old.animationValue != animationValue;
}

// ─────────────────────────────────────────────────────────────
//  Grain Overlay（靜態，shouldRepaint = false）
// ─────────────────────────────────────────────────────────────
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final p = Paint();
    for (int i = 0; i < 6000; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.75 + 0.25;
      final bright = rng.nextBool() ? Colors.white : Colors.black;
      p.color = bright.withOpacity(rng.nextDouble() * 0.052 + 0.008);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
//  START Button
// ─────────────────────────────────────────────────────────────
class _StartButton extends StatefulWidget {
  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 185,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.48),
              width: 1.2,
            ),
            color: Colors.white.withOpacity(0.06),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'START',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}