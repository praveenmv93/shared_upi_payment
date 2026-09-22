import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/models.dart';
import '../theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;
  final Expense? existingExpense; // If set, we are in edit mode

  const AddExpenseScreen({Key? key, required this.group, this.existingExpense}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, TextEditingController> _splitControllers = {};

  String _selectedCategory = 'Groceries';
  Map<String, double> _customSplits = {};
  Set<String> _manuallyEdited = {};
  Set<String> _selectedMemberIds = {};
  bool _isCustomSplit = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded, 'color': AppTheme.accentGreen},
    {'name': 'Rent', 'icon': Icons.home_rounded, 'color': AppTheme.primary},
    {'name': 'WiFi', 'icon': Icons.wifi_rounded, 'color': const Color(0xFF00B0FF)},
    {'name': 'Electricity', 'icon': Icons.offline_bolt_rounded, 'color': AppTheme.accent},
    {'name': 'Dining', 'icon': Icons.restaurant_rounded, 'color': AppTheme.accentPink},
    {'name': 'Others', 'icon': Icons.more_horiz_rounded, 'color': AppTheme.textGrey},
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;

    for (var member in widget.group.members) {
      _customSplits[member.id] = 0.0;
      _splitControllers[member.id] = TextEditingController(text: '0');
      _selectedMemberIds.add(member.id);
    }

    // If editing, pre-fill all fields
    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toStringAsFixed(0);
      _selectedCategory = existing.category;
      _isCustomSplit = true;

      // Pre-select only members who have a non-zero split
      _selectedMemberIds.clear();
      for (var member in widget.group.members) {
        final split = existing.splits[member.id] ?? 0.0;
        _customSplits[member.id] = split;
        _splitControllers[member.id]?.text = split.toStringAsFixed(0);
        if (split > 0) {
          _selectedMemberIds.add(member.id);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (var c in _splitControllers.values) c.dispose();
    super.dispose();
  }

  void _recalculateSplits() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (!_isCustomSplit) {
      final activeMembers = widget.group.members.where((m) => _selectedMemberIds.contains(m.id)).toList();
      final share = activeMembers.isNotEmpty ? totalAmount / activeMembers.length : 0.0;
      setState(() {
        for (var m in widget.group.members) {
          if (_selectedMemberIds.contains(m.id)) {
            _customSplits[m.id] = share;
            _splitControllers[m.id]?.text = share.toStringAsFixed(0);
          } else {
            _customSplits[m.id] = 0.0;
            _splitControllers[m.id]?.text = '0';
          }
        }
      });
    } else {
      // Custom split
      setState(() {
        for (var m in widget.group.members) {
          if (!_selectedMemberIds.contains(m.id)) {
            _customSplits[m.id] = 0.0;
            _splitControllers[m.id]?.text = '0';
          }
        }

        final manualSum = widget.group.members
            .where((m) => _selectedMemberIds.contains(m.id) && _manuallyEdited.contains(m.id))
            .fold(0.0, (sum, m) => sum + (_customSplits[m.id] ?? 0.0));
        final remaining = totalAmount - manualSum;
        final remainingMembers = widget.group.members
            .where((m) => _selectedMemberIds.contains(m.id) && !_manuallyEdited.contains(m.id))
            .toList();

        if (remainingMembers.isNotEmpty && remaining >= 0) {
          final share = remaining / remainingMembers.length;
          for (var m in remainingMembers) {
            _customSplits[m.id] = share;
            _splitControllers[m.id]?.text = share.toStringAsFixed(0);
          }
        }
      });
    }
  }

  void _onSplitChanged(String memberId, String val) {
    if (!_selectedMemberIds.contains(memberId)) return;
    final newShare = double.tryParse(val) ?? 0.0;
    setState(() {
      _customSplits[memberId] = newShare;
      _manuallyEdited.add(memberId);

      final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      final manualSum = widget.group.members
          .where((m) => _selectedMemberIds.contains(m.id) && _manuallyEdited.contains(m.id))
          .fold(0.0, (sum, m) => sum + (_customSplits[m.id] ?? 0.0));
      final remaining = totalAmount - manualSum;
      final remainingMembers = widget.group.members
          .where((m) => _selectedMemberIds.contains(m.id) && !_manuallyEdited.contains(m.id))
          .toList();

      if (remainingMembers.isNotEmpty && remaining >= 0) {
        final share = remaining / remainingMembers.length;
        for (var m in remainingMembers) {
          _customSplits[m.id] = share;
          _splitControllers[m.id]?.text = share.toStringAsFixed(0);
        }
      }
    });
  }

  void _submitExpense() {
    if (!_formKey.currentState!.validate()) return;

    final state = AppStateScope.of(context);
    final currentUser = state.currentUser;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    double sum = _customSplits.values.fold(0, (p, e) => p + e);
    if ((sum - amount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Split total (₹${sum.toStringAsFixed(2)}) must match amount (₹${amount.toStringAsFixed(2)})',
            style: GoogleFonts.plusJakartaSans()),
      ));
      return;
    }

    final existing = widget.existingExpense;
    final payerMember = existing?.paidBy ?? Member(
      id: currentUser?.id ?? 'user_default',
      name: currentUser?.name ?? 'You',
      phone: 'N/A',
      upiId: currentUser?.email ?? 'user@default.com',
    );

    final expenseTitle = _titleController.text.trim().isEmpty
        ? _selectedCategory
        : _titleController.text.trim();

    // Filter splits to only include selected members
    final filteredSplits = Map<String, double>.fromEntries(
      _customSplits.entries.where((e) => _selectedMemberIds.contains(e.key)),
    );

    if (existing != null) {
      // Edit mode — update existing expense
      final updatedExpense = existing.copyWith(
        title: expenseTitle,
        amount: amount,
        splits: filteredSplits,
        category: _selectedCategory,
      );
      state.updateExpense(widget.group.id, updatedExpense);
      state.addNotification(
          '✏️ Updated \'$expenseTitle\' (₹${amount.toStringAsFixed(0)}) in \'${widget.group.name}\'');
    } else {
      // Add mode — create new expense
      final newExpense = Expense(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        title: expenseTitle,
        amount: amount,
        paidBy: payerMember,
        splits: filteredSplits,
        category: _selectedCategory,
        date: DateTime.now(),
        isPending: false,
      );
      state.addExpense(widget.group.id, newExpense);
      state.addNotification(
          '💸 Added \'$expenseTitle\' (₹${amount.toStringAsFixed(0)}) to \'${widget.group.name}\'');
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingExpense != null;
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Text(
          isEditMode ? 'Edit Expense' : 'Add Expense',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount input — hero
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOW MUCH?',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('₹',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primaryLight,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            onChanged: (val) {
                              _manuallyEdited.clear();
                              _recalculateSplits();
                            },
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textMuted,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter amount';
                              if (double.tryParse(v) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'What\'s this for? e.g., Swiggy order',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textMuted, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: Icon(Icons.edit_rounded,
                            color: AppTheme.textMuted, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category picker
              Text('CATEGORY',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  )),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['name'];
                  final color = cat['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color.withOpacity(0.6)
                              : AppTheme.borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData,
                              color: isSelected ? color : AppTheme.textMuted,
                              size: 15),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? color : AppTheme.textGrey,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Split method
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SPLIT',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      )),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomSplit = !_isCustomSplit;
                        _manuallyEdited.clear();
                        _recalculateSplits();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: Text(
                        _isCustomSplit ? '⚖ Equal' : '✏ Custom',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.group.members.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: AppTheme.borderColor, height: 20),
                  itemBuilder: (context, index) {
                    final member = widget.group.members[index];
                    final state = AppStateScope.of(context);
                    final isUser = member.id == state.currentUser?.id;

                    final isSelected = _selectedMemberIds.contains(member.id);

                    return Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppTheme.primary,
                          checkColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedMemberIds.add(member.id);
                              } else {
                                if (_selectedMemberIds.length > 1) {
                                  _selectedMemberIds.remove(member.id);
                                  _manuallyEdited.remove(member.id);
                                }
                              }
                              _recalculateSplits();
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accentPink],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              member.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isUser ? 'You' : member.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: isSelected ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (_isCustomSplit)
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _splitControllers[member.id],
                              enabled: isSelected,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.end,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              onChanged: (v) => _onSplitChanged(member.id, v),
                              decoration: InputDecoration(
                                prefixText: '₹',
                                prefixStyle: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 13),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppTheme.borderColor)),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppTheme.primary, width: 2)),
                              ),
                            ),
                          )
                        else
                          Text(
                            '₹${_customSplits[member.id]?.toStringAsFixed(0) ?? '0'}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditMode ? 'Save Changes ✓' : 'Confirm Expense ✓',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textGrey,
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              if (isEditMode) ...[
                const SizedBox(height: 12),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final state = AppStateScope.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppTheme.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text('Delete Expense?',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                          content: Text(
                            'Remove "${widget.existingExpense!.title}"? This cannot be undone.',
                            style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textGrey),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w700)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentPink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text('Delete',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        state.deleteExpense(
                            widget.group.id, widget.existingExpense!.id);
                        navigator.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 20),
                    label: Text('Delete Expense',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentPink,
                      side: const BorderSide(color: AppTheme.accentPink, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
