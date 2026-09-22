import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({Key? key}) : super(key: key);

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _joinGroup() async {
    final inviteCode = _inviteCodeController.text.trim().toUpperCase();
    
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final state = AppStateScope.of(context);
      final currentUser = state.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final firestoreService = FirestoreService();
      
      // Join group in Firebase
      final joinedGroup = await firestoreService.joinGroupByInviteCode(
        currentUser.id,
        inviteCode,
      );

      // Update local state
      state.addGroup(joinedGroup);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined group! 🎉')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining group: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Join Circle',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 64,
                  color: AppTheme.accent,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'Enter Invite Code',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textWhite,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                'Paste the invite code shared by your friend',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textGrey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Invite Code/Link Input
            Text(
              'INVITE CODE',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppTheme.textGrey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteCodeController,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. ABC123XYZ',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How to get a code?',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Ask a friend in the Splitify circle to open their group.\n2. Tap the Settings icon or Invite icon at the top.\n3. Copy the invite code and paste it here.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Join Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isJoining
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Join Circle',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
