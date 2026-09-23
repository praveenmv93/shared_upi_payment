import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../main.dart';
import '../models/models.dart';
import 'payment_select_screen.dart';
import '../theme.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  final TextEditingController _upiLinkController = TextEditingController(text: '');
  String _scannerStatus = 'Align QR within the frame';
  bool _isScanned = false;
  
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    _upiLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final groupId = state.selectedGroupId ?? (state.groups.isNotEmpty ? state.groups.first.id : null);
    
    if (groupId == null || state.groups.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: Text('Scan QR Code', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          backgroundColor: AppTheme.backgroundDark,
        ),
        body: Center(
          child: Text(
            'No group selected. Please create/join a group first.',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    
    final group = state.groups.firstWhere((g) => g.id == groupId);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          if (!kIsWeb)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_isScanned) return;
                final barcode = capture.barcodes.first;
                final String? rawValue = barcode.rawValue;
                if (rawValue == null) return;
                final trimmed = rawValue.trim();
                
                if (!trimmed.toLowerCase().startsWith('upi://')) {
                  setState(() {
                    _scannerStatus = 'Not a valid UPI QR code.';
                  });
                  return;
                }
                
                setState(() {
                  _isScanned = true;
                  _upiLinkController.text = trimmed;
                  _scannerStatus = 'UPI Detected! Confirming...';
                });
                
                _scannerController.stop();
                _processUPIAndNavigate(context, group, state);
              },
            )
          else
            Container(
              color: AppTheme.backgroundDark,
              child: Center(
                child: Text(
                  'QR scanning available on mobile only.',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey),
                ),
              ),
            ),

          // 2. Custom Scanner Overlay (Darkened with clear center)
          CustomPaint(
            size: Size(size.width, size.height),
            painter: ScannerOverlayPainter(scanAreaSize: scanAreaSize),
          ),

          // 3. Animated Scan Line
          if (!_isScanned && !kIsWeb)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                final topOffset = (size.height - scanAreaSize) / 2;
                final currentY = topOffset + (_scanLineAnimation.value * scanAreaSize);
                return Positioned(
                  top: currentY,
                  left: (size.width - scanAreaSize) / 2,
                  child: Container(
                    width: scanAreaSize,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 4. Back Button & Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: AppTheme.accentOrange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Scan & Split',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Balance the row
              ],
            ),
          ),

          // 5. Glassmorphism Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.6),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _scannerStatus,
                        style: GoogleFonts.plusJakartaSans(
                          color: _isScanned ? AppTheme.accentGreen : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _upiLinkController,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Or paste UPI ID / Payload...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          prefixIcon: const Icon(Icons.link_rounded, color: Colors.white54),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 18),
                            onPressed: () {
                              if (_upiLinkController.text.isNotEmpty) {
                                _processUPIAndNavigate(context, group, state);
                              }
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
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
    );
  }

  void _processUPIAndNavigate(BuildContext context, Group group, AppStateScope state) {
    final upiUrl = _upiLinkController.text.trim();
    if (upiUrl.isEmpty) return;
    
    final uri = Uri.tryParse(upiUrl);
    if (uri == null || uri.scheme != 'upi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid UPI QR Payload URL!')),
      );
      setState(() {
        _isScanned = false;
        _scannerStatus = 'Align QR within the frame';
      });
      _scannerController.start();
      return;
    }

    final queryParams = uri.queryParameters;
    final payeeName = queryParams['pn'] ?? 'UPI Merchant';
    final amountString = queryParams['am'] ?? '0';
    final double amount = double.tryParse(amountString) ?? 0.0;

    _showGroupSelectionSheet(context, payeeName, amount, upiUrl, group, state);
  }

  void _showGroupSelectionSheet(
    BuildContext context,
    String payeeName,
    double amount,
    String upiLink,
    Group group,
    AppStateScope state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 40, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 20),
              Text(
                payeeName,
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              if (amount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.accentGreen),
                ),
              ],
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentSelectScreen(
                        upiLink: upiLink,
                        groupName: group.name,
                        title: payeeName,
                        amount: amount,
                        onPaymentComplete: () {
                          final currentUser = state.currentUser;
                          final payerMember = Member(
                            id: currentUser?.id ?? 'user_default',
                            name: currentUser?.name ?? 'User',
                            phone: 'N/A',
                            upiId: currentUser?.email ?? 'user@default.com',
                          );
                          final newExpense = Expense(
                            id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                            title: payeeName,
                            amount: amount,
                            paidBy: payerMember,
                            splits: {},
                            category: 'Groceries',
                            date: DateTime.now(),
                            isPending: true,
                          );
                          state.addExpense(group.id, newExpense);
                          state.addNotification("🛒 QR payment of ₹${amount.toStringAsFixed(0)} to $payeeName successful. Added to '${group.name}' Quick Split queue.");
                        },
                      ),
                    ),
                  ).then((_) {
                    if (mounted) Navigator.pop(context); // Close scanner screen as well
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.backgroundDark, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.group_rounded, color: AppTheme.primaryLight),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign to ${group.name}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Split with ${group.members.length} members',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted && !_isScanned) {
        _scannerController.start(); // Restart if dismissed
      }
    });
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;

  ScannerOverlayPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw darkened background with transparent hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(24))),
      ),
      backgroundPaint,
    );

    // Draw stylish corner brackets
    final bracketPaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    
    // Top Left
    canvas.drawPath(Path()
      ..moveTo(holeRect.left, holeRect.top + cornerLength)
      ..lineTo(holeRect.left, holeRect.top + 12)
      ..quadraticBezierTo(holeRect.left, holeRect.top, holeRect.left + 12, holeRect.top)
      ..lineTo(holeRect.left + cornerLength, holeRect.top), bracketPaint);

    // Top Right
    canvas.drawPath(Path()
      ..moveTo(holeRect.right - cornerLength, holeRect.top)
      ..lineTo(holeRect.right - 12, holeRect.top)
      ..quadraticBezierTo(holeRect.right, holeRect.top, holeRect.right, holeRect.top + 12)
      ..lineTo(holeRect.right, holeRect.top + cornerLength), bracketPaint);

    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(holeRect.left, holeRect.bottom - cornerLength)
      ..lineTo(holeRect.left, holeRect.bottom - 12)
      ..quadraticBezierTo(holeRect.left, holeRect.bottom, holeRect.left + 12, holeRect.bottom)
      ..lineTo(holeRect.left + cornerLength, holeRect.bottom), bracketPaint);

    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(holeRect.right - cornerLength, holeRect.bottom)
      ..lineTo(holeRect.right - 12, holeRect.bottom)
      ..quadraticBezierTo(holeRect.right, holeRect.bottom, holeRect.right, holeRect.bottom - 12)
      ..lineTo(holeRect.right, holeRect.bottom - cornerLength), bracketPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) => false;
}
