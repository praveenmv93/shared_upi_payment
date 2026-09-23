import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../main.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final state = AppStateScope.of(context);
    final userId = state.currentUser?.id;
    if (userId != null) {
      final transactions = await FirestoreService().getUserTransactions(userId);
      setState(() {
        _transactions = transactions;
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Transaction History',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _transactions.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isSuccess = tx.status == 'SUCCESS';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSuccess ? AppTheme.accentGreen.withOpacity(0.15) : AppTheme.accentOrange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isSuccess ? AppTheme.accentGreen : AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.recipientName,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (!isSuccess && tx.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tx.errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${tx.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: isSuccess ? AppTheme.textWhite : AppTheme.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.status,
                    style: GoogleFonts.plusJakartaSans(
                      color: isSuccess ? AppTheme.accentGreen : AppTheme.accentOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
