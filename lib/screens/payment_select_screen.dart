import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
<<<<<<< HEAD
import 'package:shared_upi_payment/shared_upi_payment.dart';
=======
>>>>>>> origin/master
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
<<<<<<< HEAD
  final UpiPaymentService _upiService = MethodChannelUpiService();
  List<UpiApp>? _installedApps;

=======

  /// Each entry must have: name, logo emoji, package (Android package name), color
  final List<Map<String, String>> _upiApps = [
    {
      'name': 'PhonePe',
      'logo': '💜',
      'package': 'com.phonepe.app',
      'color': '0xFF5F259F',
    },
    {
      'name': 'Google Pay',
      'logo': '🟢',
      'package': 'com.google.android.apps.nbu.paisa.user',
      'color': '0xFF1A73E8',
    },
    {
      'name': 'Paytm',
      'logo': '💙',
      'package': 'net.one97.paytm',
      'color': '0xFF00B9F5',
    },
    {
      'name': 'CRED Pay',
      'logo': '🖤',
      'package': 'com.dreamplug.androidapp',
      'color': '0xFF1A1A2E',
    },
    {
      'name': 'Amazon Pay',
      'logo': '🟠',
      'package': 'com.amazon.mShop.android.shopping',
      'color': '0xFFFF9900',
    },
    {
      'name': 'BHIM UPI',
      'logo': '🇮🇳',
      'package': 'in.org.npci.upiapp',
      'color': '0xFFEC701D',
    },
  ];

>>>>>>> origin/master
  @override
  void initState() {
    super.initState();
    _amount = widget.amount;
    _amountController = TextEditingController(text: _amount.toStringAsFixed(2));
<<<<<<< HEAD
    // Load installed UPI apps
    _upiService.getInstalledApps().then((apps) {
      setState(() {
        _installedApps = apps;
      });
    });
=======
>>>>>>> origin/master
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Build a UPI URI with the current amount
  String _buildUpiLink() {
    if (widget.upiLink.isNotEmpty) {
      final uri = Uri.tryParse(widget.upiLink);
      if (uri != null && uri.scheme == 'upi') {
        final Map<String, String> params = Map<String, String>.from(uri.queryParameters);
        params['am'] = _amount.toStringAsFixed(2);
        if (!params.containsKey('tr')) {
          params['tr'] = 'splityfy-${DateTime.now().millisecondsSinceEpoch}';
        }
        params['tn'] = 'Split payment for ${widget.groupName}';
        return uri.replace(queryParameters: params).toString();
      }
    }

    // Fallback if no valid UPI link was provided
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

<<<<<<< HEAD
  /// Launch selected UPI app using shared_upi_payment plugin
  Future<void> _handlePaymentAppLaunch(UpiApp upiApp) async {
=======
  /// Launch a specific UPI app by targeting its Android package via the `psp` param.
  /// Falls back to the generic `upi://pay` URL (which shows the system UPI chooser).
  Future<void> _handlePaymentAppLaunch(String appName, String packageName) async {
>>>>>>> origin/master
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.'), backgroundColor: AppTheme.accentOrange),
      );
      return;
    }

<<<<<<< HEAD
    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final builtUri = Uri.parse(_buildUpiLink());
      final queryParams = builtUri.queryParameters;
      final request = UpiPaymentRequest(
        upiUri: builtUri.toString(),
        app: upiApp,
        amount: _amount,
        merchantName: queryParams['pn'] ?? widget.title,
        merchantUpiId: queryParams['pa'] ?? 'unknown@upi',
        note: queryParams['tn'] ?? 'Split payment for ${widget.groupName}',
        transactionRef: queryParams['tr'] ?? 'splityfy-${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await _upiService.initiatePayment(
        request: request,
        app: upiApp,
      );
      Navigator.pop(context); // dismiss loader

      final status = response.status.name.toUpperCase();
      final errorMsg = response.errorMessage ?? response.responseCode ?? 'No details';
      final isSuccess = response.status == PaymentStatus.success;
      final result = PaymentResult(
        recipientName: 'Nikitha K Gigi',
        recipientEmail: 'nikithakgigi@oksbi',
        amount: _amount,
        success: isSuccess,
        errorMessage: isSuccess ? null : errorMsg,
        timestamp: DateTime.now(),
      );
      _showResultDialog(result);
=======
    // Build a UPI URL with the `psp` parameter to target a specific app
    final baseParams = {
      'pa': 'nikithakgigi@oksbi',
      'pn': 'Nikitha K Gigi',
      'am': _amount.toStringAsFixed(2),
      'cu': 'INR',
      'tr': 'splityfy-${DateTime.now().millisecondsSinceEpoch}',
      'tn': 'Split payment for ${widget.groupName}',
    };

    // Targeted URL: add package name hint so Android resolves directly to that app
    final targetedUrl = Uri(
      scheme: 'upi',
      path: '//pay',
      queryParameters: {...baseParams, 'psp': packageName},
    );

    // Generic fallback URL (system UPI chooser)
    final genericUrl = Uri(
      scheme: 'upi',
      path: '//pay',
      queryParameters: baseParams,
    );

    try {
      bool launched = false;

      // Try launching the targeted UPI URL
      if (await canLaunchUrl(targetedUrl)) {
        await launchUrl(targetedUrl, mode: LaunchMode.externalApplication);
        launched = true;
      }

      // Fallback: try generic UPI URL (shows chooser with all installed UPI apps)
      if (!launched) {
        if (await canLaunchUrl(genericUrl)) {
          await launchUrl(genericUrl, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('No UPI app found on device');
        }
      }
>>>>>>> origin/master
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $appName. Make sure it is installed.'),
            backgroundColor: AppTheme.accentOrange,
          ),
        );
      }
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
                itemCount: _installedApps?.length ?? 0,
                itemBuilder: (context, index) {
                  final app = _installedApps![index];
                  return InkWell(
                    onTap: () => _handlePaymentAppLaunch(app),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (app.iconBytes != null)
                          Image.memory(app.iconBytes!, width: 32, height: 32)
                        else
                          const Icon(Icons.account_balance_wallet_rounded, size: 32, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(app.appName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textWhite, fontSize: 14)),
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
