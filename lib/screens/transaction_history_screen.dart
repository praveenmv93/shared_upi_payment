import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../main.dart';
import '../services/sms_transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_expense_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _showAll = false;
  List<TransactionModel> _transactions = [];
  final SmsTransactionService _smsService = SmsTransactionService();
  Set<String> _addedTxIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final addedList = prefs.getStringList('added_tx_ids') ?? [];
    _addedTxIds = addedList.toSet();

    final state = AppStateScope.of(context);
    final userId = state.currentUser?.id;
    if (userId != null) {
      final transactions = await FirestoreService().getUserTransactions(userId);
      // Attempt to load SMS transactions without prompting for permission
      final smsTransactions = await _smsService.getSmsTransactions(userId);
      if (smsTransactions != null) {
        transactions.addAll(smsTransactions);
      }
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _transactions = transactions;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _syncSmsTransactions() async {
    setState(() => _isSyncing = true);
    final state = AppStateScope.of(context);
    final userId = state.currentUser?.id;
    if (userId != null) {
      final smsTransactions = await _smsService.requestAndGetSmsTransactions(userId);
      if (smsTransactions != null) {
        // Reload all
        final transactions = await FirestoreService().getUserTransactions(userId);
        transactions.addAll(smsTransactions);
        transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        setState(() {
          _transactions = transactions;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced ${smsTransactions.length} recent transactions'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction access permission denied'),
              backgroundColor: AppTheme.accentOrange,
            ),
          );
        }
      }
    }
    setState(() => _isSyncing = false);
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
        actions: [
          _isSyncing 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)
                  )
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded, color: AppTheme.primary),
                  tooltip: 'Sync Recent Transactions',
                  onPressed: _syncSmsTransactions,
                ),
        ],
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

  
  void _showGroupPickerAndAdd(TransactionModel tx) {
    final state = AppStateScope.of(context);
    final groups = state.groups;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No circles available. Please create one first.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add to Circle',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a circle to split this expense.',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...groups.map((g) => ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddExpense(tx, g);
                },
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: const Icon(Icons.group_rounded, color: AppTheme.primary, size: 20),
                ),
                title: Text(g.name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text('${g.members.length} members', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12)),
              )).toList(),
            ],
          ),
        );
      }
    );
  }

  void _navigateToAddExpense(TransactionModel tx, Group group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          group: group,
          initialAmount: tx.amount,
          initialTitle: tx.recipientName,
        ),
      ),
    );
    
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
    final addedList = prefs.getStringList('added_tx_ids') ?? [];
    if (!addedList.contains(tx.id)) {
      addedList.add(tx.id);
      await prefs.setStringList('added_tx_ids', addedList);
      setState(() {
        _addedTxIds.add(tx.id);
      });
      // Optionally reload to remove from list
      _loadTransactions();
    }
    }
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
    List<TransactionModel> displayList;
    if (_showAll) {
      displayList = _transactions.where((t) => !_addedTxIds.contains(t.id)).toList();
    } else {
      displayList = _transactions.where((t) => t.status == 'SUCCESS' && !_addedTxIds.contains(t.id)).take(25).toList();
    }
    
    bool canShowMore = !_showAll && _transactions.length > displayList.length;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayList.length + (canShowMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (canShowMore && index == displayList.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAll = true;
                  });
                },
                icon: const Icon(Icons.expand_more_rounded, color: AppTheme.primary),
                label: Text(
                  'Show More',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          );
        }

        final tx = displayList[index];
        final isSuccess = tx.status == 'SUCCESS';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      tx.groupId == 'LOCAL_SMS' 
                        ? '${DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp)} • Auto-tracked'
                        : DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp),
                      style: GoogleFonts.plusJakartaSans(
                        color: tx.groupId == 'LOCAL_SMS' ? AppTheme.primary.withOpacity(0.8) : AppTheme.textMuted,
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
          if (tx.groupId == 'LOCAL_SMS' && isSuccess) ...[
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderColor, height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showGroupPickerAndAdd(tx),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: Text(
                      'Add to Circle & Split',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      foregroundColor: AppTheme.primaryLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
