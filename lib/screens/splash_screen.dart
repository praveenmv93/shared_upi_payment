import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // To access AuthWrapper
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class Particle {
  final String symbol;
  final double angleOffset;
  final double radius;
  final double size;
  final Color color;
  final double speed;
  
  Particle({
    required this.symbol,
    required this.angleOffset,
    required this.radius,
    required this.size,
    required this.color,
    required this.speed,
  });
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bgController;
  late Animation<Alignment> _bgAlignmentTop;
  late Animation<Alignment> _bgAlignmentBottom;
  
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  final List<String> _symbols = ['₹', '\$', '£', '€', '¥', '₿', '¢', '₽'];

  @override
  void initState() {
    super.initState();
    _generateParticles();

    // Background Gradient Animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _bgAlignmentTop = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _bgAlignmentBottom = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    // Main Timeline Animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _mainController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  void _generateParticles() {
    final colors = [
      AppTheme.accent, // Amber/Gold
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      AppTheme.primaryLight,
    ];
    
    for (int i = 0; i < 40; i++) {
      _particles.add(
        Particle(
          symbol: _symbols[_random.nextInt(_symbols.length)],
          angleOffset: _random.nextDouble() * 2 * math.pi,
          radius: 80 + _random.nextDouble() * 120, // Distance from center
          size: 16 + _random.nextDouble() * 24, // Size of text
          color: colors[_random.nextInt(colors.length)],
          speed: 0.5 + _random.nextDouble() * 1.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgController, _mainController]),
        builder: (context, child) {
          final double t = _mainController.value;
          
          // Timeline logic:
          // 0.0 - 0.4: Floating & swirling
          // 0.4 - 0.55: Sucked into center
          // 0.55 - 0.8: Logo explodes out
          // 0.8 - 1.0: Logo pulses slightly and text fades in

          double swarmOpacity = 1.0;
          double convergenceProgress = 0.0;
          
          if (t > 0.4 && t <= 0.55) {
            convergenceProgress = (t - 0.4) / 0.15; // 0 to 1
            swarmOpacity = 1.0 - convergenceProgress;
          } else if (t > 0.55) {
            convergenceProgress = 1.0;
            swarmOpacity = 0.0;
          }

          double logoScale = 0.0;
          double textOpacity = 0.0;
          
          if (t > 0.55 && t <= 0.8) {
            double logoT = (t - 0.55) / 0.25;
            logoScale = Curves.elasticOut.transform(logoT);
          } else if (t > 0.8) {
            double pulseT = (t - 0.8) / 0.2;
            logoScale = 1.0 + 0.05 * math.sin(pulseT * math.pi); // slight pulse
            textOpacity = Curves.easeIn.transform(pulseT);
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  AppTheme.backgroundDark,
                  Color(0xFF1E1B4B), // Deep indigo/purple
                  AppTheme.backgroundDark,
                ],
                begin: _bgAlignmentTop.value,
                end: _bgAlignmentBottom.value,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Swarm of Currency Particles
                if (swarmOpacity > 0.0)
                  ..._particles.map((p) {
                    // Calculate current position
                    double currentAngle = p.angleOffset + (t * 10 * p.speed);
                    double currentRadius = p.radius * (1.0 - (convergenceProgress * convergenceProgress));
                    
                    double dx = currentRadius * math.cos(currentAngle);
                    double dy = currentRadius * math.sin(currentAngle);
                    
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.rotate(
                        angle: currentAngle,
                        child: Opacity(
                          opacity: swarmOpacity * 0.8,
                          child: Text(
                            p.symbol,
                            style: TextStyle(
                              color: p.color,
                              fontSize: p.size * (1.0 - convergenceProgress),
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: p.color.withOpacity(0.5),
                                  blurRadius: 10,
                                )
                              ]
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                // Logo Reveal
                if (t > 0.55)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: logoScale,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3 * (1.0 - textOpacity)),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo_transparent.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Text Reveal
                      Opacity(
                        opacity: textOpacity,
                        child: Text(
                          'SPLITIFY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: AppTheme.textWhite,
                            shadows: [
                              Shadow(
                                color: AppTheme.primary.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
