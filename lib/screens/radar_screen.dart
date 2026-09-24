import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Real list of discovered users
  final List<DiscoveredUser> _discoveredUsers = [];

  BonsoirBroadcast? _broadcast;
  final List<BonsoirDiscovery> _discoveries = [];

  @override
  void initState() {
    super.initState();
    // The radar completes one sweep every 4 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startBonsoir();
    _startNetworkSweepFallback();
  }

  Future<void> _startNetworkSweepFallback() async {
    try {
      final String? wifiIP = await NetworkInfo().getWifiIP();
      if (wifiIP != null && wifiIP.contains('.')) {
        final String subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));
        print("Radar: Starting fallback sweep on subnet $subnet.x");
        for (int i = 1; i < 255; i++) {
          final String ip = '$subnet.$i';
          if (ip == wifiIP) continue; 

          // Quick ping sweep on port 53 (Router/DNS) or 8009 (Chromecast)
          Socket.connect(ip, 53, timeout: const Duration(milliseconds: 350)).then((socket) {
            _addGenericDeviceFallback(ip);
            socket.destroy();
          }).catchError((error) {
             Socket.connect(ip, 8009, timeout: const Duration(milliseconds: 350)).then((socket) {
               _addGenericDeviceFallback(ip);
               socket.destroy();
             }).catchError((error) {});
          });
        }
      }
    } catch (e) {
      print("Radar Network Sweep Error: $e");
    }
  }

  void _addGenericDeviceFallback(String ip) {
    if (!mounted) return;
    setState(() {
      if (!_discoveredUsers.any((u) => u.name == ip)) {
        _discoveredUsers.add(DiscoveredUser(
          name: ip,
          angle: Random().nextDouble() * 2 * pi,
          distance: 0.5 + (Random().nextDouble() * 0.4),
          isGeneric: true,
        ));
      }
    });
  }

  Future<void> _startBonsoir() async {
    // 1. Start Broadcasting our presence
    BonsoirService service = BonsoirService(
      name: 'User_${Random().nextInt(1000)}', // Replace with the actual logged-in user's name
      type: '_splitify._tcp',
      port: 3000, 
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.start();
    
    // 2. Discover our app users
    _startDiscovery('_splitify._tcp', isSplitifyUser: true);

    // 3. Discover generic smart devices to populate radar with friendly names
    final List<String> commonTypes = [
      '_googlecast._tcp',
      '_airplay._tcp',
      '_raop._tcp',
      '_spotify-connect._tcp',
      '_http._tcp',
      '_smb._tcp',
      '_ipp._tcp', // Printers
      '_companion-link._tcp', // Apple devices
    ];

    for (var type in commonTypes) {
      _startDiscovery(type, isSplitifyUser: false);
    }
  }

  void _startDiscovery(String type, {required bool isSplitifyUser}) async {
    BonsoirDiscovery discovery = BonsoirDiscovery(type: type);
    _discoveries.add(discovery);
    await discovery.start();

    discovery.eventStream!.listen((event) {
      print("Radar mDNS Event: ${event.runtimeType}");
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        print("Radar: Found mDNS service, resolving...");
        event.service.resolve(discovery.serviceResolver); 
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        print("Radar: Resolved mDNS service -> ${event.service.name}");
        if (event.service.name != _broadcast?.service.name) {
          setState(() {
            if (!_discoveredUsers.any((u) => u.name == event.service.name)) {
              _discoveredUsers.add(DiscoveredUser(
                name: event.service.name,
                angle: Random().nextDouble() * 2 * pi,
                distance: 0.3 + (Random().nextDouble() * 0.6),
                isGeneric: !isSplitifyUser,
              ));
            }
          });
        }
      } else if (event is BonsoirDiscoveryServiceLostEvent) {
         setState(() {
            _discoveredUsers.removeWhere((u) => u.name == event.service.name);
         });
      }
    });
  }

  @override
  void dispose() {
    _broadcast?.stop();
    for (var d in _discoveries) {
       d.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark radar-like background
      appBar: AppBar(
        title: const Text('Discover Nearby', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Searching for friends on the same Wi-Fi...",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. The Radar Background and Sweep
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(320, 320),
                        painter: RadarPainter(
                          sweepAngle: _controller.value * 2 * pi,
                        ),
                      );
                    },
                  ),
                  
                  // 2. The Discovered Users (Ships)
                  ..._discoveredUsers.map((user) => _buildUserDot(user)),
                  
                  // 3. Center User (You)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              onPressed: () {
                // Show QR code for users without the app
              },
              icon: const Icon(Icons.qr_code),
              label: const Text("Invite via QR Code"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B263B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUserDot(DiscoveredUser user) {
    final double radius = 160.0; // Half of 320 (Radar size)
    final double maxDistance = radius - 20; // Keep dots inside the radar
    
    final double x = maxDistance * user.distance * cos(user.angle);
    final double y = maxDistance * user.distance * sin(user.angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTap: () {
          // Send Invite action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invite sent to ${user.name}!')),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: user.isGeneric ? Colors.blueGrey : Colors.cyanAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: user.isGeneric ? Colors.blueGrey.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double sweepAngle;

  RadarPainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw concentric circles
    final Paint circlePaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.66, circlePaint);
    canvas.drawCircle(center, radius * 0.33, circlePaint);

    // Draw crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), circlePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), circlePaint);

    // Draw the radar sweep
    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: pi / 2, // The width of the sweep tail
        colors: [
          Colors.transparent,
          Colors.greenAccent.withOpacity(0.5),
        ],
        stops: const [0.0, 1.0],
        transform: GradientRotation(sweepAngle - pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - pi / 2,
      pi / 2,
      true,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}

class DiscoveredUser {
  final String name;
  final double angle;
  final double distance;
  final bool isGeneric;

  DiscoveredUser({required this.name, required this.angle, required this.distance, this.isGeneric = false});
}
