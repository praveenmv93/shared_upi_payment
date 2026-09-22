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

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  final TextEditingController _upiLinkController = TextEditingController(text: '');
  String _scannerStatus = 'Ready to scan UPI QR code';

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppTheme.textWhite,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Simulator QR Code Frame
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    if (!kIsWeb)
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final barcode = capture.barcodes.first;
                          final String? rawValue = barcode.rawValue;
                          if (rawValue == null) return;
                          final trimmed = rawValue.trim();
                          if (!trimmed.toLowerCase().startsWith('upi://')) {
                            setState(() {
                              _scannerStatus = 'Scanned QR does not look like a UPI payload.';
                            });
                            return;
                          }
                          setState(() {
                            _upiLinkController.text = trimmed;
                            _scannerStatus = 'UPI QR detected. Tap confirm to continue.';
                          });
                          _scannerController.stop();
                        },
                      )
                    else
                      Center(
                        child: Text(
                          'QR scanning is available on mobile devices only.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Positioned(
                      top: 40,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGreen.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _scannerStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (!kIsWeb) {
                                  _scannerController.start();
                                }
                                setState(() {
                                  _scannerStatus = 'Ready to scan UPI QR code';
                                });
                              },
                              child: Text(
                                'Restart',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'PASTE UPI PAYLOAD',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppTheme.textGrey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiLinkController,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'upi://pay?pa=...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _processUPIAndNavigate(context, group, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm & Select Group',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processUPIAndNavigate(BuildContext context, Group group, AppStateScope state) {
    final upiUrl = _upiLinkController.text.trim();
    final uri = Uri.tryParse(upiUrl);
    if (uri == null || uri.scheme != 'upi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid UPI QR Payload URL!')),
      );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign to Split Circle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 20),
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
                    Navigator.pop(context); // Close scanner screen as well
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.group_rounded, color: AppTheme.primaryLight),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textWhite,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${group.members.length} active members',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
