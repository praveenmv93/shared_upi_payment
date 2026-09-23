import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import 'payment_select_screen.dart';
import '../main.dart';

class QRGenerateScreen extends StatefulWidget {
  const QRGenerateScreen({Key? key}) : super(key: key);

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen> {
  late final TextEditingController _paController;
  late final TextEditingController _pnController;
  final TextEditingController _tnController = TextEditingController(text: 'Payment');
  final TextEditingController _amController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppStateScope.of(context);
      setState(() {
        _paController = TextEditingController(text: state.currentUser?.upiId ?? '');
        _pnController = TextEditingController(text: state.currentUser?.name ?? '');
      });
    });
  }

  @override
  void dispose() {
    _paController.dispose();
    _pnController.dispose();
    _tnController.dispose();
    _amController.dispose();
    super.dispose();
  }

  String get _upiLink {
    if (!mounted) return '';
    try {
      final pa = _paController.text.trim();
      final pn = _pnController.text.trim();
      final tn = _tnController.text.trim().isEmpty ? 'Payment' : _tnController.text.trim();
      final am = _amController.text.trim().isEmpty ? '0' : _amController.text.trim();

      if (pa.isEmpty || pn.isEmpty) return '';
      return 'upi://pay?pa=$pa&pn=$pn&tn=$tn&am=$am';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Generate UPI QR Code',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Display
            if (_upiLink.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _upiLink,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                ),
              )
            else
              Container(
                height: 290,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'Fill in details to generate QR',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Input Fields
            Text(
              'UPI DETAILS',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppTheme.textGrey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            _buildInputField('UPI ID (pa)', _paController, 'nikithakgigi@oksbi'),
            const SizedBox(height: 14),

            _buildInputField('Payee Name (pn)', _pnController, 'Nikki'),
            const SizedBox(height: 14),

            _buildInputField('Transaction Note (tn)', _tnController, 'Payment'),
            const SizedBox(height: 14),

            _buildInputField('Amount (am)', _amController, '0', keyboardType: TextInputType.number),
            const SizedBox(height: 32),

            if (_upiLink.isNotEmpty) ...[
              // Display full link
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor, width: 1.5),
                ),
                child: SelectableText(
                  _upiLink,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Test button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_amController.text.trim()) ?? 0.0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentSelectScreen(
                          upiLink: _upiLink,
                          groupName: 'Test Group',
                          title: _pnController.text.trim(),
                          amount: amount,
                          onPaymentComplete: () {},
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Test Payment',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppTheme.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
