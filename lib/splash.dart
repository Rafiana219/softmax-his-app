import 'package:flutter/material.dart';

import 'config.dart';

/// Branded opening screen: logo in a gold-ringed circle, institute name,
/// loading dots. Fades and scales in on first frame.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key});

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _dots.dispose();
    super.dispose();
  }

  Animation<double> _step(double from, double to) => CurvedAnimation(
    parent: _intro,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logo = (size.shortestSide * 0.52).clamp(150.0, 260.0);
    final logoIn = _step(0, 0.6);
    final textIn = _step(0.3, 0.9);
    final footIn = _step(0.6, 1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BrandColors.goldLight, Colors.white, BrandColors.blueLight],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: [
          // Soft decorative circles in the logo colours.
          Positioned(
            top: -size.width * 0.35,
            right: -size.width * 0.25,
            child: _blob(size.width * 0.9, BrandColors.gold.withAlpha(28)),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0.3,
            child: _blob(size.width, BrandColors.blue.withAlpha(22)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: logoIn,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.82, end: 1.0).animate(logoIn),
                      child: _logoBadge(logo),
                    ),
                  ),
                  SizedBox(height: logo * 0.16),
                  FadeTransition(
                    opacity: textIn,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(textIn),
                      child: _names(),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeTransition(opacity: footIn, child: _loadingDots()),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: FadeTransition(
              opacity: footIn,
              child: Text(
                AppConfig.poweredBy,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: BrandColors.navy.withAlpha(120),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double d, Color c) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
  );

  Widget _logoBadge(double d) {
    return Container(
      width: d,
      height: d,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            BrandColors.gold,
            Color(0xFFFFE08A),
            BrandColors.gold,
            Color(0xFFB98100),
            BrandColors.gold,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.gold.withAlpha(70),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: BrandColors.navy.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: EdgeInsets.all(d * 0.025),
        child: ClipOval(
          child: Image.asset(
            AppConfig.logoAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _names() {
    return Column(
      children: [
        const Text(
          AppConfig.orgNameTh,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: BrandColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppConfig.orgNameEn,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 0.3,
            color: BrandColors.navy.withAlpha(160),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: BrandColors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                AppConfig.systemLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
            ),
            _line(),
          ],
        ),
      ],
    );
  }

  Widget _line() =>
      Container(width: 42, height: 1.5, color: BrandColors.gold.withAlpha(160));

  Widget _loadingDots() {
    return AnimatedBuilder(
      animation: _dots,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_dots.value - i * 0.18) % 1.0);
            final lift = t < 0.5 ? Curves.easeOut.transform(t * 2) : 0.0;
            final up = lift < 1 ? lift : 2 - lift;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              transform: Matrix4.translationValues(0, -8 * up, 0),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 1 ? BrandColors.gold : BrandColors.blue,
              ),
            );
          }),
        );
      },
    );
  }
}
