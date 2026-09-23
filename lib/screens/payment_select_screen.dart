import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:upi_india/upi_india.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

/// Model representing the result of a payment transaction
class PaymentResult {
  final String recipientName;
  final String recipientEmail;
  final double amount;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;
  const PaymentResult({
    required this.recipientName,
    required this.recipientEmail,
    required this.amount,
    required this.success,
    this.errorMessage,
    required this.timestamp,
  });
}

class PaymentSelectScreen extends StatefulWidget {
  final String upiLink;
  final String groupName;
  final String title;
  final double amount;
  final VoidCallback onPaymentComplete;

  const PaymentSelectScreen({
    Key? key,
    required this.upiLink,
    required this.groupName,
    required this.title,
    required this.amount,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentSelectScreen> createState() => _PaymentSelectScreenState();
}

class _PaymentSelectScreenState extends State<PaymentSelectScreen> {
  late double _amount;
  late TextEditingController _amountController;
  bool _isOfflineMode = false;
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? _installedApps;

  final List<Map<String, String>> _upiApps = [
    {'name': 'PhonePe', 'logo': '💜', 'scheme': 'phonepe://pay', 'color': '0xFF5F259F'},
    {'name': 'Google Pay', 'logo': '⚡', 'scheme': 'gpay://upi/pay', 'color': '0xFF1A73E8'},
    {'name': 'Paytm', 'logo': '💙', 'scheme': 'paytmmp://cash_wallet', 'color': '0xFF00B9F5'},
    {'name': 'CRED Pay', 'logo': '🖤', 'scheme': 'cred://pay', 'color': '0xFF0F0F0F'},
    {'name': 'BHIM UPI', 'logo': '🇮🇳', 'scheme': 'upi://pay', 'color': '0xFFEC701D'},
  ];

  @override
  void initState() {
    super.initState();
    _amount = widget.amount;
    _amountController = TextEditingController(text: _amount.toStringAsFixed(2));
    // Load installed UPI apps
    _upiIndia.getAllUpiApps().then((apps) {
      setState(() {
        _installedApps = apps;
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Build a UPI URI with the current amount (fallback if needed)
  String _buildUpiLink() {
    final uri = Uri(
      scheme: 'upi',
      path: '//pay',
      queryParameters: {
        'pa': 'nikithakgigi@oksbi',
        'pn': 'Nikitha K Gigi',
        'am': _amount.toStringAsFixed(2),
        'cu': 'INR',
        'tr': 'splityfy-${DateTime.now().millisecondsSinceEpoch}',
        'tn': 'Split payment for ${widget.groupName}',
      },
    );
    return uri.toString();
  }

  /// Launch selected UPI app using upi_india plugin
  Future<void> _handlePaymentAppLaunch(String appName, String scheme) async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter a valid amount.'), backgroundColor: AppTheme.accentOrange),
      );
      return;
    }

      // Find the installed UPI app that matches the selected name
      UpiApp? upiApp;
      if (_installedApps != null) {
        try {
          upiApp = _installedApps!.firstWhere(
            (app) => app.name.toLowerCase() == appName.toLowerCase(),
          );
        } catch (_) {
          upiApp = _installedApps!.isNotEmpty ? _installedApps!.first : null;
        }
      }

      if (upiApp == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('No UPI app available.'), backgroundColor: AppTheme.accentOrange),
        );
        return;
      }

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final response = await _upiIndia.startTransaction(
        app: upiApp,
        receiverUpiId: 'nikithakgigi@oksbi',
        receiverName: 'Nikitha K Gigi',
        transactionRefId: 'splityfy-${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: 'Split payment for ${widget.groupName}',
        amount: _amount,
      );
      Navigator.pop(context); // dismiss loader

      final status = response.status?.toUpperCase() ?? 'UNKNOWN';
      final errorMsg = response.responseCode ?? 'No details';
      final result = PaymentResult(
        recipientName: 'Nikitha K Gigi',
        recipientEmail: 'nikithakgigi@oksbi',
        amount: _amount,
        success: status == 'SUCCESS',
        errorMessage: status == 'SUCCESS' ? null : errorMsg,
        timestamp: DateTime.now(),
      );
      _showResultDialog(result);
    } catch (e) {
      Navigator.pop(context);
      final result = PaymentResult(
        recipientName: 'Nikitha K Gigi',
        recipientEmail: 'nikithakgigi@oksbi',
        amount: _amount,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
      _showResultDialog(result);
    }
  }

  void _showResultDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.success ? 'Payment Successful' : 'Payment Failed',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: result.success ? AppTheme.accentGreen : AppTheme.accentOrange,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Recipient', '${result.recipientName} (${result.recipientEmail})'),
              _detailRow('Amount', '₹${result.amount.toStringAsFixed(2)}'),
              if (!result.success && result.errorMessage != null) _detailRow('Reason', result.errorMessage!),
              if (!result.success) _detailRow('Refund Info', 'If money was debited, the refund will be processed within the next 24 hours.'),
              _detailRow('Timestamp', DateFormat('d MMM yyyy, h:mm a').format(result.timestamp)),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: Text('$label:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
            Expanded(flex: 6, child: Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: AppTheme.textWhite))),
          ],
        ),
      );

  Widget _buildUSSDStep(String stepNumber, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(stepNumber, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryLight)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: GoogleFonts.plusJakartaSans(color: AppTheme.textWhite, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('Checkout Gateway', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textWhite)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textWhite), onPressed: () => Navigator.pop(context)),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.borderColor, width: 1.5), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)]),
              child: Column(
                children: [
                  Text(widget.title.toUpperCase(), style: GoogleFonts.plusJakartaSans(letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppTheme.textGrey, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 38, fontWeight: FontWeight.w800, color: AppTheme.textWhite, letterSpacing: -1),
                    decoration: const InputDecoration(prefixText: '₹', border: InputBorder.none, isDense: true),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) setState(() => _amount = parsed);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('Assigning split to: ${widget.groupName}', style: GoogleFonts.plusJakartaSans(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Low Bandwidth Toggle
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderColor, width: 1.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Low Network Bandwidth?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textWhite)),
                        const SizedBox(height: 4),
                        Text('Switch to offline USSD UPI (*99#)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Switch(value: _isOfflineMode, onChanged: (v) => setState(() => _isOfflineMode = v), activeColor: AppTheme.accent),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!_isOfflineMode) ...[
              Text('SELECT UPI APP', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.6),
                itemCount: _upiApps.length,
                itemBuilder: (context, index) {
                  final app = _upiApps[index];
                  final colorVal = int.parse(app['color']!);
                  final isDefault = app['name'] == 'Google Pay';
                  return InkWell(
                    onTap: () => _handlePaymentAppLaunch(app['name']!, app['scheme']!),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDefault ? Color(colorVal).withOpacity(0.25) : Color(colorVal).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(colorVal).withOpacity(0.4), width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(app['logo']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(app['name']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textWhite, fontSize: 14)),
                      ]),
                    ),
                  );
                },
              ),
            ] else ...[
              // Offline USSD Pane
              Container(
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.borderColor, width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.wifi_off_rounded, color: AppTheme.accentOrange, size: 24),
                        const SizedBox(width: 12),
                        Text('Offline Payment via *99#', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textWhite, fontSize: 16)),
                      ]),
                      const SizedBox(height: 16),
                      Text('Follow these steps in your dialer:', style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildUSSDStep('1', 'Dial *99#'),
                      _buildUSSDStep('2', 'Select Send Money'),
                      _buildUSSDStep('3', 'Select UPI ID option'),
                      _buildUSSDStep('4', 'Enter UPI ID'),
                      _buildUSSDStep('5', 'Enter amount: ₹${_amount.toStringAsFixed(0)}'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('tel:*99*1*3%23')),
                          icon: const Icon(Icons.phone_android_rounded, size: 18),
                          label: Text('Dial *99*1*3#', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSimulationPrompt(String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Launching $appName', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textWhite)),
        content: Text('UPI deep-links require a physical device with $appName installed.\n\nSimulate transaction authorization for ₹${_amount.toStringAsFixed(2)}?', style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w700))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateSuccessfulPayment();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: Text('Authorize', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _simulateSuccessfulPayment() {
    widget.onPaymentComplete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(children: [const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen), const SizedBox(width: 8), Text('Payment Successful! Split registered.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))]), backgroundColor: AppTheme.surfaceElevated),
    );
    Navigator.pop(context);
  }
}
