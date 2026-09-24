import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/models.dart';
import 'payment_select_screen.dart';
import 'add_expense_screen.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../services/geofence_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';
import 'radar_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final group = state.groups.firstWhere((g) => g.id == widget.groupId);
    final balances = group.calculateBalances();
    final currentUserId = state.currentUser?.id ?? 'user_default';
    final myBalance = balances[currentUserId] ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  _tabController.animateTo(2);
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Settings',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.8),
                          AppTheme.backgroundDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppTheme.accentPink.withOpacity(0.3),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Center(
                              child: Text(
                                group.name.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            group.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildChip('${group.members.length} members',
                                  Colors.white.withOpacity(0.15)),
                              const SizedBox(width: 8),
                              _buildChip(
                                myBalance == 0
                                    ? '✓ Settled up'
                                    : myBalance > 0
                                        ? '↑ Owed ₹${myBalance.toStringAsFixed(0)}'
                                        : '↓ Owes ₹${(-myBalance).toStringAsFixed(0)}',
                                myBalance == 0
                                    ? Colors.white.withOpacity(0.15)
                                    : myBalance > 0
                                        ? AppTheme.accentGreen.withOpacity(0.2)
                                        : AppTheme.accentPink.withOpacity(0.2),
                                textColor: myBalance > 0
                                    ? AppTheme.accentGreen
                                    : myBalance < 0
                                        ? AppTheme.accentPink
                                        : Colors.white70,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: AppTheme.backgroundDark,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primaryLight,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Expenses'),
                    Tab(text: 'Settle Up'),
                    Tab(text: 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExpensesTab(context, group),
            _buildSettleUpTab(context, group, state),
            _buildSettingsTab(context, group, state),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddExpenseScreen(group: group)),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text('Add Split',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bg, {Color textColor = Colors.white70}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
            color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildExpensesTab(BuildContext context, Group group) {
    final displayExpenses = group.expenses.toList()
      ..sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return b.date.compareTo(a.date);
      });
    if (displayExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No expenses yet',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textGrey, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Add your first split!',
                style:
                    GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: displayExpenses.length,
      itemBuilder: (context, index) {
        final exp = displayExpenses[index];
        final state = AppStateScope.of(context);
        final currentUserId = state.currentUser?.id ?? 'user_default';
        final isUser = exp.paidBy.id == currentUserId;
        final color = _getCategoryColor(exp.category);
        final canEdit = !exp.isSettlement; // Don't allow editing settlements

        return Dismissible(
          key: Key(exp.id),
          direction: canEdit ? DismissDirection.endToStart : DismissDirection.none,
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Delete Expense?',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                content: Text(
                  'Remove "${exp.title}" (₹${exp.amount.toStringAsFixed(0)})?',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Delete',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            state.deleteExpense(group.id, exp.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Expense "${exp.title}" deleted',
                  style: GoogleFonts.plusJakartaSans()),
              backgroundColor: AppTheme.surfaceElevated,
              action: SnackBarAction(
                label: 'OK',
                textColor: AppTheme.primaryLight,
                onPressed: () {},
              ),
            ));
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppTheme.accentPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.accentPink.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever_rounded, color: AppTheme.accentPink, size: 26),
                const SizedBox(height: 4),
                Text('Delete',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentPink, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          child: GestureDetector(
            onTap: canEdit
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(
                          group: group,
                          existingExpense: exp,
                        ),
                      ),
                    )
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getCategoryIcon(exp.category), color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exp.title,
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text('Paid by ${isUser ? 'You' : exp.paidBy.name}',
                            style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${exp.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      if (exp.isPending)
                        Text('Needs Split',
                            style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.accentOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w700))
                      else
                        Text(isUser ? 'you lent' : 'you owe',
                            style: GoogleFonts.plusJakartaSans(
                                color: isUser ? AppTheme.accentGreen : AppTheme.accentPink,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (canEdit) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 16),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildSettleUpTab(BuildContext context, Group group, AppStateScope state) {
    final balances = group.calculateBalances();
    final settlements = _calculateSettlementTransactions(balances, group.members);

    if (settlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  size: 56, color: AppTheme.accentGreen),
            ),
            const SizedBox(height: 16),
            Text('All settled up! 🎉',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            const SizedBox(height: 6),
            Text('Everyone is even',
                style:
                    GoogleFonts.plusJakartaSans(color: AppTheme.textGrey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: settlements.length,
      itemBuilder: (context, index) {
        final tx = settlements[index];
        final Member debtor = tx['from'];
        final Member creditor = tx['to'];
        final double amount = tx['amount'];
        final currentUserId = state.currentUser?.id ?? 'user_default';
        final isUserDebtor = debtor.id == currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUserDebtor
                  ? AppTheme.accentPink.withOpacity(0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(debtor.name),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppTheme.textMuted, size: 18),
                  ),
                  _buildAvatar(creditor.name),
                  const Spacer(),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: isUserDebtor ? AppTheme.accentPink : AppTheme.accentGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey, fontSize: 13),
                  children: [
                    TextSpan(
                      text: isUserDebtor ? 'You' : debtor.name,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' owe '),
                    TextSpan(
                      text: creditor.id == currentUserId ? 'you' : creditor.name,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (isUserDebtor) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final upiLink =
                          'upi://pay?pa=${creditor.upiId}&pn=${Uri.encodeComponent(creditor.name)}&am=${amount.toStringAsFixed(2)}&cu=INR';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentSelectScreen(
                            upiLink: upiLink,
                            groupName: group.name,
                            title: 'Settle to ${creditor.name}',
                            amount: amount,
                            onPaymentComplete: () {
                              final settleExp = Expense(
                                id: 'settle_${DateTime.now().millisecondsSinceEpoch}',
                                title: 'Settle Balance to ${creditor.name}',
                                amount: amount,
                                paidBy: debtor,
                                splits: {creditor.id: amount},
                                category: 'Settlement',
                                date: DateTime.now(),
                                isSettlement: true,
                              );
                              state.addExpense(group.id, settleExp);
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Pay Now → ₹${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.accentPink]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, Group group, AppStateScope state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Circle Settings',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 20),

          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                if (group.homeLatitude != 0.0 && group.homeLongitude != 0.0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          IgnorePointer(
                            ignoring: true, // Make it view-only
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(group.homeLatitude, group.homeLongitude),
                                initialZoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.splitify.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(group.homeLatitude, group.homeLongitude),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        size: 40,
                                        color: AppTheme.accentOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _editLocation(context, group, state),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_location_alt_rounded, color: AppTheme.primaryLight, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildSettingRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Billing Cycle',
                  value: '${group.billingDay}${_getDaySuffix(group.billingDay)} of every month',
                ),
                Divider(color: AppTheme.borderColor, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSettingRow(
                        icon: Icons.home_rounded,
                        label: 'Home Location',
                        value: group.homeLocationName,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 20),
                      onPressed: () => _editLocation(context, group, state),
                    ),
                  ],
                ),
                Divider(color: AppTheme.borderColor, height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.share_rounded, color: AppTheme.primaryLight, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invite Code',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textGrey, fontSize: 12)),
                          Text(group.inviteCode ?? 'N/A',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Share on WhatsApp',
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
                          onPressed: () async {
                            final code = group.inviteCode ?? '';
                            final link = 'https://splitify-1926b.web.app/?join=$code';
                            final msg = Uri.encodeComponent(
                              '🔥 Join my circle "${group.name}" on Splitify!\n\n👉 Click link to join directly:\n$link\n\n(Or enter Invite Code: $code) 🚀'
                            );
                            final url = Uri.parse('https://wa.me/?text=$msg');
                            try {
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                await launchUrl(url);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error launching WhatsApp: $e')),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Copy Code',
                          icon: const Icon(Icons.copy_rounded, color: AppTheme.accent, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: group.inviteCode ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invite code copied to clipboard! 📋')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(color: AppTheme.borderColor, height: 24),
                GestureDetector(
                  onTap: () {
                    state.addNotification('🔔 Poke sent to ${group.name}!');
                    
                    // Trigger the native push notification
                    GeofenceService().sendNotification(
                      title: '🔔 Poke from ${group.name}',
                      body: 'Someone poked you! Settle your pending expenses.',
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Poked everyone in ${group.name}! 👋 (Push notification sent)',
                          style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: AppTheme.surfaceElevated,
                    ));
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.campaign_rounded,
                            color: AppTheme.accent, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('Poke everyone',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ],
                  ),
                ),
                Divider(color: AppTheme.borderColor, height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RadarScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radar_rounded,
                            color: Colors.cyanAccent, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('Invite via Wi-Fi Radar',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (group.createdBy == state.currentUser?.id) ...[
            const SizedBox(height: 32),
            Text('Danger Zone',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.accentPink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _confirmDeleteGroup(context, group),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.accentPink.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentPink.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        color: AppTheme.accentPink, size: 20),
                    const SizedBox(width: 14),
                    Text('Delete Circle',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.accentPink, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey, fontSize: 12)),
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  void _editLocation(BuildContext context, Group group, AppStateScope state) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: group.homeLatitude,
          initialLongitude: group.homeLongitude,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final lat = result['latitude'] as double;
      final lng = result['longitude'] as double;
      final addr = result['address'] as String;

      // Optimistic UI update
      final updatedGroup = group.copyWith(
        homeLatitude: lat,
        homeLongitude: lng,
        homeLocationName: addr,
      );
      state.updateGroup(updatedGroup);

      // Backend update
      try {
        await FirestoreService().updateGroupLocation(group.id, lat, lng, addr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Home location updated!'), backgroundColor: AppTheme.accentGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update location on server.'), backgroundColor: AppTheme.accentPink),
          );
        }
      }
    }
  }
  void _confirmDeleteGroup(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Circle?',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete "${group.name}"? All history will be lost.',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    GoogleFonts.plusJakartaSans(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accentPink)),
                );
                final memberIds = group.members.map((m) => m.id).toList();
                await FirestoreService().deleteGroup(group.id, memberIds);
                Navigator.pop(context);
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateSettlementTransactions(
      Map<String, double> balances, List<Member> members) {
    final List<Map<String, dynamic>> transactions = [];
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    balances.forEach((id, bal) {
      if (bal > 0.01) creditors.add(MapEntry(id, bal));
      else if (bal < -0.01) debtors.add(MapEntry(id, -bal));
    });

    int cIdx = 0, dIdx = 0;
    while (cIdx < creditors.length && dIdx < debtors.length) {
      final cId = creditors[cIdx].key;
      final cVal = creditors[cIdx].value;
      final dId = debtors[dIdx].key;
      final dVal = debtors[dIdx].value;
      final minVal = cVal < dVal ? cVal : dVal;

      transactions.add({
        'from': members.firstWhere((m) => m.id == dId),
        'to': members.firstWhere((m) => m.id == cId),
        'amount': minVal,
      });

      creditors[cIdx] = MapEntry(cId, cVal - minVal);
      debtors[dIdx] = MapEntry(dId, dVal - minVal);
      if (creditors[cIdx].value < 0.01) cIdx++;
      if (debtors[dIdx].value < 0.01) dIdx++;
    }
    return transactions;
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'bills': return Icons.offline_bolt_rounded;
      case 'groceries': return Icons.shopping_basket_rounded;
      case 'settlement': return Icons.handshake_rounded;
      case 'wifi': return Icons.wifi_rounded;
      case 'rent': return Icons.home_rounded;
      case 'dining': return Icons.restaurant_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'bills': return AppTheme.accentOrange;
      case 'groceries': return AppTheme.accentGreen;
      case 'settlement': return AppTheme.primaryLight;
      case 'wifi': return const Color(0xFF00B0FF);
      case 'dining': return AppTheme.accentPink;
      default: return AppTheme.accent;
    }
  }
}
