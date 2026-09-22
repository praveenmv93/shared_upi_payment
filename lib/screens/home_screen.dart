import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/models.dart';
import 'group_detail_screen.dart';
import '../theme.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';

import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final groupId = state.selectedGroupId ??
        (state.groups.isNotEmpty ? state.groups.first.id : null);
    if (groupId == null || state.groups.isEmpty) {
      return _buildEmptyState(context);
    }

    final group = state.groups.firstWhere((g) => g.id == groupId);
    final balances = group.calculateBalances();
    final currentUserId = state.currentUser?.id ?? 'user_default';
    final userBalance = balances[currentUserId] ?? 0.0;
    final pendingExpenses = group.expenses.where((e) => e.isPending).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Purple blob
                Positioned(
                  top: -40,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.primary.withOpacity(0.3),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hey ${state.currentUser?.name?.split(' ').first ?? "there"} 👋',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textGrey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'splitify',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Group selector pill
                                GestureDetector(
                                  onTap: () => _showGroupPicker(context, state),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceElevated,
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.hub_rounded,
                                            size: 14, color: AppTheme.primaryLight),
                                        const SizedBox(width: 6),
                                        Text(
                                          group.name.length > 10
                                              ? '${group.name.substring(0, 10)}…'
                                              : group.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.keyboard_arrow_down_rounded,
                                            size: 16, color: AppTheme.textGrey),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Notification bell
                                GestureDetector(
                                  onTap: () => _showNotificationsDialog(
                                      context, state.notifications),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceElevated,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(Icons.notifications_none_rounded,
                                            size: 20, color: Colors.white),
                                        if (state.notifications.isNotEmpty)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentPink,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: AppTheme.surfaceElevated,
                                                    width: 1.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Profile Avatar
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                    );
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Text(
                                      state.currentUser != null && state.currentUser!.name.isNotEmpty
                                          ? state.currentUser!.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                          : 'U',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.primaryLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Balance card
                        _buildBalanceCard(context, userBalance, group),
                        const SizedBox(height: 24),

                        // Quick action chips
                        Row(
                          children: [
                            _buildQuickAction(
                              icon: Icons.add_rounded,
                              label: 'Add Split',
                              color: AppTheme.primary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => GroupDetailScreen(groupId: group.id)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                              icon: Icons.handshake_rounded,
                              label: 'Settle Up',
                              color: AppTheme.accentGreen,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => GroupDetailScreen(groupId: group.id)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                              icon: Icons.group_add_rounded,
                              label: 'Invite',
                              color: AppTheme.accentOrange,
                              onTap: () => _showInviteCode(context, group),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pending splits section
          if (pendingExpenses.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: AppTheme.accentPink.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${pendingExpenses.length} pending',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.accentPink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exp = pendingExpenses[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: _buildPendingCard(context, exp, group, state),
                  );
                },
                childCount: pendingExpenses.length,
              ),
            ),
          ],

          // Your Circles section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Circles',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
                    child: Text(
                      '+ New',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final g = state.groups[index];
                final gBalances = g.calculateBalances();
                final myBal = gBalances[currentUserId] ?? 0.0;
                final isSelected = g.id == groupId;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: GestureDetector(
                    onTap: () {
                      state.selectGroup(g.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(groupId: g.id)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.12)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.5)
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.accentPink,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                g.name.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${g.members.length} members · ${g.expenses.length} expenses',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                myBal == 0
                                    ? 'Settled'
                                    : myBal > 0
                                        ? '+₹${myBal.toStringAsFixed(0)}'
                                        : '-₹${(-myBal).toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: myBal == 0
                                      ? AppTheme.textGrey
                                      : myBal > 0
                                          ? AppTheme.accentGreen
                                          : AppTheme.accentPink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.textMuted, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: state.groups.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance, Group group) {
    final isOwed = balance > 0;
    final isSettled = balance == 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSettled
              ? [AppTheme.surface, AppTheme.surfaceElevated]
              : isOwed
                  ? [
                      const Color(0xFF0D2B1F),
                      AppTheme.surface,
                    ]
                  : [
                      const Color(0xFF2B0D1A),
                      AppTheme.surface,
                    ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSettled
              ? AppTheme.borderColor
              : isOwed
                  ? AppTheme.accentGreen.withOpacity(0.3)
                  : AppTheme.accentPink.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR BALANCE',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSettled
                      ? AppTheme.textMuted.withOpacity(0.2)
                      : isOwed
                          ? AppTheme.accentGreen.withOpacity(0.15)
                          : AppTheme.accentPink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  isSettled ? '✓ Settled' : isOwed ? '↑ Owed' : '↓ Owes',
                  style: GoogleFonts.plusJakartaSans(
                    color: isSettled
                        ? AppTheme.textGrey
                        : isOwed
                            ? AppTheme.accentGreen
                            : AppTheme.accentPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isSettled
                ? 'All square! 🎉'
                : isOwed
                    ? '₹${balance.toStringAsFixed(0)}'
                    : '₹${(-balance).toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              color: isSettled
                  ? Colors.white
                  : isOwed
                      ? AppTheme.accentGreen
                      : AppTheme.accentPink,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSettled
                ? 'No pending dues in ${group.name}'
                : isOwed
                    ? 'People owe you in ${group.name}'
                    : 'You owe people in ${group.name}',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard(
      BuildContext context, Expense exp, Group group, AppStateScope state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded,
                color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '₹${exp.amount.toStringAsFixed(0)} · Pending split',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showSplitEditor(context, exp, group, state),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 12),
            ),
            child: const Text('Split'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withOpacity(0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accentPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.hub_rounded,
                        size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No circles yet',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create a sharing circle or join your\nflatmates to start splitting expenses.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateGroupScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Create a Circle',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const JoinGroupScreen())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryLight,
                        side: BorderSide(color: AppTheme.borderColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Join via Code',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker(BuildContext context, AppStateScope state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Circle',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 20),
            ...state.groups.map((g) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accentPink]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(g.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  title: Text(g.name,
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('${g.members.length} members',
                      style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textGrey, fontSize: 12)),
                  trailing: state.selectedGroupId == g.id
                      ? Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary)
                      : null,
                  onTap: () {
                    state.selectGroup(g.id);
                    Navigator.pop(context);
                  },
                )),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Icon(Icons.add_rounded, color: AppTheme.primaryLight),
              ),
              title: Text('Create new circle',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primaryLight, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteCode(BuildContext context, Group group) {
    final code = group.inviteCode ?? 'N/A';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share_rounded, color: AppTheme.primary, size: 40),
            const SizedBox(height: 16),
            Text('Invite to ${group.name}',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            const SizedBox(height: 10),
            Text('Share this code with your crew',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textGrey, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
              ),
              child: Text(
                code,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, List<String> notifications) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_rounded, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Text('Alerts & Pokes',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Text('No notifications yet ✨',
                            style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textGrey)),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: AppTheme.borderColor, height: 20),
                        itemBuilder: (_, index) => Text(
                          notifications[index],
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontSize: 14, height: 1.5),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSplitEditor(
      BuildContext context, Expense expense, Group group, AppStateScope state) {
    double equalShare = expense.amount / group.members.length;
    Map<String, double> tempSplits = {
      for (var m in group.members) m.id: equalShare
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Configure Split',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded,
                        color: AppTheme.textGrey, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${expense.title} · ₹${expense.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 24),
              ...group.members.map((member) {
                final currentUserId =
                    state.currentUser?.id ?? 'user_default';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            child: Text(
                              member.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            member.id == currentUserId ? 'You' : member.name,
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue:
                              tempSplits[member.id]?.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setModalState(
                                  () => tempSplits[member.id] = parsed);
                            }
                          },
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
                                    BorderSide(color: AppTheme.primary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final completedExpense = expense.copyWith(
                      splits: tempSplits,
                      isPending: false,
                    );
                    state.updateExpense(group.id, completedExpense);
                    state.addNotification(
                        '🎉 ${expense.title} of ₹${expense.amount.toStringAsFixed(0)} split!');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Confirm Split',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
