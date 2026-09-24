import sys

def modify_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Add imports
    if "import 'package:shared_preferences/shared_preferences.dart';" not in content:
        content = content.replace("import '../services/sms_transaction_service.dart';", "import '../services/sms_transaction_service.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'add_expense_screen.dart';")

    # Add state var
    if "Set<String> _addedTxIds = {};" not in content:
        content = content.replace("final SmsTransactionService _smsService = SmsTransactionService();", "final SmsTransactionService _smsService = SmsTransactionService();\n  Set<String> _addedTxIds = {};")

    # Modify load
    load_replacement = """  Future<void> _loadTransactions() async {
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
  }"""
    # Use regex or simple string replace for _loadTransactions
    import re
    content = re.sub(r'  Future<void> _loadTransactions\(\) async \{.*?\n  \}', load_replacement, content, flags=re.DOTALL)

    # Filter display list
    if "displayList = _transactions.where((t) => !_addedTxIds.contains(t.id))" not in content:
        content = content.replace("displayList = _transactions;", "displayList = _transactions.where((t) => !_addedTxIds.contains(t.id)).toList();")
        content = content.replace("displayList = _transactions.where((t) => t.status == 'SUCCESS').take(25).toList();", "displayList = _transactions.where((t) => t.status == 'SUCCESS' && !_addedTxIds.contains(t.id)).take(25).toList();")

    # Add group picker method
    picker_method = """
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          group: group,
          initialAmount: tx.amount,
          initialTitle: tx.recipientName,
        ),
      ),
    );
    // After returning, mark as added
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
"""
    if "_showGroupPickerAndAdd" not in content:
        content = content.replace("Widget _buildEmptyState() {", picker_method + "\n  Widget _buildEmptyState() {")

    # Update item UI
    item_ui_old = """          child: Row(
            children: ["""
    item_ui_new = """          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: ["""
    if "child: Column(" not in content.replace(" ", ""):
        content = content.replace(item_ui_old, item_ui_new)
        # Need to close the Row and add the divider+button
        
        row_end_old = """                ],
              ),
            ],
          ),
        );"""
        
        row_end_new = """                ],
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
        );"""
        content = content.replace(row_end_old, row_end_new)

    with open(filepath, 'w') as f:
        f.write(content)

modify_file('lib/screens/transaction_history_screen.dart')
