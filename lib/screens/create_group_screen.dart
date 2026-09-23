import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'map_picker_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  int _billingDay = 1;
  bool _isCreating = false;
  double _latitude = 12.9716;
  double _longitude = 77.5946;

  final List<Map<String, dynamic>> _emojiOptions = [
    {'emoji': '🏠', 'label': 'Apartment'},
    {'emoji': '🛖', 'label': 'Flatmates'},
    {'emoji': '✈️', 'label': 'Trip'},
    {'emoji': '🎒', 'label': 'Roomies'},
  ];
  String _selectedEmoji = '🏠';

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    // If we don't have permission yet, just request it so the map starts roughly near user
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
          _latitude = position.latitude;
          _longitude = position.longitude;
        } catch (_) {}
      }
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationNameController.text = result['address'];
      });
    }
  }

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      final state = AppStateScope.of(context);
      final currentUser = state.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final newGroup = await FirestoreService().createGroup(
        userId: currentUser.id,
        groupName: _groupNameController.text,
        description: _descriptionController.text,
        homeLocation: _locationNameController.text.isEmpty
            ? 'Home'
            : _locationNameController.text,
        homeLatitude: _latitude,
        homeLongitude: _longitude,
        billingDay: _billingDay,
        memberIds: [currentUser.id],
      );

      state.addGroup(newGroup);
      _showSuccessDialog(newGroup);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showSuccessDialog(Group newGroup) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final code = newGroup.inviteCode ?? 'N/A';
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              '🎉 Circle Created!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invite your friends to "${newGroup.name}" using this unique code:',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryLight),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Invite code copied to clipboard! 📋')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Friends can join by tapping "JOIN VIA CODE" on their dashboard and pasting this code.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Pop create group screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5));
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        title: Text('New Circle',
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
              // Hero section
              Center(
                child: Column(
                  children: [
                    // Emoji picker
                    Wrap(
                      spacing: 12,
                      children: _emojiOptions.map((opt) {
                        final isSelected = _selectedEmoji == opt['emoji'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedEmoji = opt['emoji'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.2)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.6)
                                    : AppTheme.borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(opt['emoji'] as String,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(opt['label'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isSelected
                                          ? AppTheme.primaryLight
                                          : AppTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create a Circle',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Invite friends using a secure code',
                      style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Circle name
              _buildLabel('CIRCLE NAME'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _groupNameController,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g., 1H Apartment, B302 Crew',
                  prefixIcon: Icon(Icons.hub_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel('DESCRIPTION (OPTIONAL)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontSize: 15),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What are you splitting? Rent, WiFi, food...',
                  prefixIcon: Icon(Icons.description_rounded,
                      color: AppTheme.textMuted, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              // Home location
              _buildLabel('HOME LOCATION'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationNameController,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g., 1H Apartment',
                  prefixIcon: Icon(Icons.location_on_rounded,
                      color: AppTheme.accentPink, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_rounded, color: AppTheme.primary),
                    onPressed: _pickLocation,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Billing day
              _buildLabel('MONTHLY SETTLEMENT DAY'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _billingDay,
                    dropdownColor: AppTheme.surfaceElevated,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 15),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textGrey),
                    onChanged: (v) {
                      if (v != null) setState(() => _billingDay = v);
                    },
                    items: List.generate(28, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                  'On the $d${_getDaySuffix(d)} of every month',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white)),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: AppTheme.surfaceElevated,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text('$_selectedEmoji  Create Circle',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
