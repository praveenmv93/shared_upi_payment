import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final groupId = state.selectedGroupId ??
        (state.groups.isNotEmpty ? state.groups.first.id : null);

    if (groupId == null || state.groups.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Text('No circle selected',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textGrey)),
        ),
      );
    }

    final group = state.groups.firstWhere((g) => g.id == groupId);
    final totalSpend = group.expenses
        .where((e) => !e.isPending && !e.isSettlement)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.accent.withOpacity(0.15),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Insights ✨',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  group.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      color: AppTheme.accent, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Total spend card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primary.withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL SPEND',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white60,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${totalSpend.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This month in ${group.name}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.trending_up_rounded,
                                    color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Spend Distribution
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spend Breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        // Stacked bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 16,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 50,
                                    child: Container(color: AppTheme.accentGreen)),
                                Expanded(
                                    flex: 35,
                                    child: Container(color: AppTheme.accentOrange)),
                                Expanded(
                                    flex: 15,
                                    child: Container(color: AppTheme.primary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegend('Groceries', '50%', AppTheme.accentGreen),
                            _buildLegend('Bills', '35%', AppTheme.accentOrange),
                            _buildLegend('Others', '15%', AppTheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Category cards row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.shopping_basket_rounded,
                          label: 'Groceries',
                          value: '₹${(totalSpend * 0.5).toStringAsFixed(0)}',
                          color: AppTheme.accentGreen,
                          change: '+18%',
                          isUp: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.offline_bolt_rounded,
                          label: 'Bills',
                          value: '₹${(totalSpend * 0.35).toStringAsFixed(0)}',
                          color: AppTheme.accentOrange,
                          change: '-5%',
                          isUp: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // AI Insights Section
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI Insights',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._buildInsightCards(group.name),
                  const SizedBox(height: 28),

                  // Fun pokes section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPink.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('😂', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Friendly Pokes',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reminders with Indian household references to keep things chill',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String pct, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $pct',
          style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textGrey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String change,
    required bool isUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUp
                      ? AppTheme.accentPink.withOpacity(0.15)
                      : AppTheme.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.plusJakartaSans(
                    color: isUp ? AppTheme.accentPink : AppTheme.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInsightCards(String groupName) {
    final insights = [
      {
        'emoji': '🙋',
        'text':
            'Sneha has paid for 65% of expenses this month. Settle your dues soon to maintain flat harmony!',
        'tag': 'Balance alert',
        'color': AppTheme.accentOrange,
      },
      {
        'emoji': '📈',
        'text':
            'Groceries spending increased by 18% vs last month. D-Mart bulk buys might save you ₹500!',
        'tag': 'Spend trend',
        'color': AppTheme.accentGreen,
      },
      {
        'emoji': '💡',
        'text':
            'Setting the settlement reminder on the 5th aligns perfectly with salary credits for everyone in $groupName!',
        'tag': 'Smart tip',
        'color': AppTheme.primary,
      },
    ];

    return insights.map((item) {
      final color = item['color'] as Color;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['emoji'] as String, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      item['tag'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['text'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
