import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'services/firestore_service.dart';
import 'models/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/geofence_service.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/qr_generate_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SplitifyApp());
}

class SplitifyApp extends StatefulWidget {
  static String? pendingJoinCode;
  const SplitifyApp({Key? key}) : super(key: key);

  @override
  State<SplitifyApp> createState() => _SplitifyAppState();
}

class _SplitifyAppState extends State<SplitifyApp> {
  UserProfile? _currentUser;
  StreamSubscription? _groupsSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize Geofence service
    GeofenceService().init();

    // Parse URL invite link parameters on app start
    try {
      final uri = Uri.base;
      String? code = uri.queryParameters['join'] ?? uri.queryParameters['code'];
      if (code == null && uri.fragment.contains('join=')) {
        final match = RegExp(r'join=([A-Za-z0-9]+)').firstMatch(uri.fragment);
        if (match != null) code = match.group(1);
      }
      if (code != null && code.trim().isNotEmpty) {
        SplitifyApp.pendingJoinCode = code.trim().toUpperCase();
      }
    } catch (_) {}
    // Listen for auth changes and fetch profile
    AuthService().authStateChanges().listen((firebaseUser) async {
      try {
        if (firebaseUser != null) {
          final profile = await AuthService().getCurrentUserProfile();
          setState(() {
            _currentUser = profile;
          });

          if (profile != null) {
            // Cancel existing subscription if any
            await _groupsSubscription?.cancel();
            
            // Listen to groups from Firestore
            _groupsSubscription = FirestoreService()
                .streamUserGroups(profile.id)
                .listen((groups) {
              setState(() {
                _groups = groups;
                // If no group is selected or selected group is gone, select the first one
                if (_selectedGroupId == null && groups.isNotEmpty) {
                  _selectedGroupId = groups.first.id;
                } else if (_selectedGroupId != null && !groups.any((g) => g.id == _selectedGroupId)) {
                  _selectedGroupId = groups.isNotEmpty ? groups.first.id : null;
                }
                
                // Update geofence tracking for the selected group
                if (_selectedGroupId != null) {
                  final groupToTrack = groups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => groups.first);
                  GeofenceService().startTracking(groupToTrack);
                } else {
                  GeofenceService().stopTracking();
                }
              });
            }, onError: (err) {
              print('Error streaming user groups: $err');
            });
        // After setting up real‑time stream, also fetch groups once to ensure we have data on first load
      FirestoreService().getUserGroups(profile.id).then((initialGroups) {
        if (initialGroups.isNotEmpty) {
          setState(() {
            _groups = initialGroups;
          });
        }
      });
          }
        } else {
          await _groupsSubscription?.cancel();
          setState(() { 
            _currentUser = null;
            _groups = [];
            _selectedGroupId = null;
          });
        }
      } catch (e) {
        print('Error during auth status update: $e');
        setState(() {
          _currentUser = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }
  List<Group> _groups = []; // Start with no groups - users create/join groups
  List<String> _notifications = [];
  bool _isAtHome = false; // Simulated location status (dev feature)
  String? _selectedGroupId; // Track currently viewed group

  void selectGroup(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      
      if (groupId != null && _groups.isNotEmpty) {
        final groupToTrack = _groups.firstWhere((g) => g.id == groupId, orElse: () => _groups.first);
        GeofenceService().startTracking(groupToTrack);
      } else {
        GeofenceService().stopTracking();
      }
    });
  }

  void addGroup(Group newGroup) {
    setState(() {
      _groups.add(newGroup);
      _selectedGroupId = newGroup.id; // Auto-select new group
    });
  }

  void addExpense(String groupId, Expense newExpense) async {
    // Optimistic update
    setState(() {
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groups[index];
        final updatedExpenses = List<Expense>.from(group.expenses)..insert(0, newExpense);
        _groups[index] = group.copyWith(expenses: updatedExpenses);
      }
    });

    // Persist to Firestore
    try {
      await FirestoreService().addExpenseToGroup(groupId, newExpense);
    } catch (e) {
      print('Error persisting expense: $e');
      // In a real app, you might want to revert the optimistic update or show an error
    }
  }

  void updateExpense(String groupId, Expense updatedExpense) async {
    // Optimistic update
    setState(() {
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groups[index];
        final updatedExpenses = group.expenses.map((e) {
          return e.id == updatedExpense.id ? updatedExpense : e;
        }).toList();
        _groups[index] = group.copyWith(expenses: updatedExpenses);
      }
    });

    // Persist to Firestore
    try {
      await FirestoreService().updateExpenseInGroup(groupId, updatedExpense);
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  void deleteExpense(String groupId, String expenseId) async {
    // Optimistic update
    setState(() {
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groups[index];
        final updatedExpenses = group.expenses.where((e) => e.id != expenseId).toList();
        _groups[index] = group.copyWith(expenses: updatedExpenses);
      }
    });

    // Persist to Firestore
    try {
      await FirestoreService().deleteExpenseFromGroup(groupId, expenseId);
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  void addNotification(String message) {
    setState(() {
      _notifications.insert(0, message);
    });
  }

  void toggleLocation() {
    // Dev-only feature: moved to settings or debug menu
    setState(() {
      _isAtHome = !_isAtHome;
      if (_selectedGroupId != null) {
        final group = _groups.firstWhere((g) => g.id == _selectedGroupId);
        if (_isAtHome) {
          final pendingCount = group.expenses.where((e) => e.isPending).length;
          if (pendingCount > 0) {
            final pendingExpense = group.expenses.firstWhere((e) => e.isPending);
            final otherMembers = group.members
                .where((m) => m.id != (pendingExpense.paidBy.id))
                .map((m) => m.name)
                .join(' & ');
            addNotification(
              "🏠 Spotted at ${group.homeLocationName}! Stop dodging and split that ${pendingExpense.category.toLowerCase()} expense of ₹${pendingExpense.amount.toStringAsFixed(0)} with $otherMembers right now! 😂",
            );
          } else {
            addNotification("🏠 You arrived at ${group.homeLocationName}. Home sweet home!");
          }
        } else {
          addNotification("🚶 You stepped out of ${group.homeLocationName}.");
        }
      }
    });
  }

  void updateCurrentUser(UserProfile updatedProfile) {
    setState(() {
      _currentUser = updatedProfile;
    });
  }

  void updateGroup(Group updatedGroup) {
    setState(() {
      final index = _groups.indexWhere((g) => g.id == updatedGroup.id);
      if (index != -1) {
        _groups[index] = updatedGroup;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      groups: _groups,
      notifications: _notifications,
      isAtHome: _isAtHome,
      currentUser: _currentUser,
      selectedGroupId: _selectedGroupId,
      addExpense: addExpense,
      updateExpense: updateExpense,
      deleteExpense: deleteExpense,
      addNotification: addNotification,
      addGroup: addGroup,
      updateGroup: updateGroup,
      selectGroup: selectGroup,
      toggleLocation: toggleLocation,
      updateCurrentUser: updateCurrentUser,
      child: MaterialApp(
        title: 'Splitify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainNavigationShell();
        }
        return const LoginScreen();
      },
    );
  }
}

// InheritedWidget to pass global state down the tree
class AppStateScope extends InheritedWidget {
  final List<Group> groups;
  final List<String> notifications;
  final UserProfile? currentUser;
  final bool isAtHome;
  final String? selectedGroupId;
  final Function(String, Expense) addExpense;
  final Function(String, Expense) updateExpense;
  final Function(String, String) deleteExpense;
  final Function(String) addNotification;
  final Function(Group) addGroup;
  final Function(Group) updateGroup;
  final Function(String?) selectGroup;
  final Function() toggleLocation;
  final Function(UserProfile) updateCurrentUser;

  const AppStateScope({
    Key? key,
    required this.groups,
    required this.notifications,
    required this.currentUser,
    required this.isAtHome,
    required this.selectedGroupId,
    required this.addExpense,
    required this.updateExpense,
    required this.deleteExpense,
    required this.addNotification,
    required this.addGroup,
    required this.updateGroup,
    required this.selectGroup,
    required this.toggleLocation,
    required this.updateCurrentUser,
    required Widget child,
  }) : super(key: key, child: child);

  static AppStateScope of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(result != null, 'No AppStateScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return groups != oldWidget.groups ||
        notifications != oldWidget.notifications ||
        isAtHome != oldWidget.isAtHome ||
        selectedGroupId != oldWidget.selectedGroupId ||
        currentUser != oldWidget.currentUser;
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _checkedPendingJoin = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoJoinCode();
    });
  }

  Future<void> _checkAutoJoinCode() async {
    if (_checkedPendingJoin) return;
    _checkedPendingJoin = true;

    final uri = Uri.base;
    String? joinCode = uri.queryParameters['join'] ?? uri.queryParameters['code'];
    if (joinCode == null && uri.fragment.contains('join=')) {
      final match = RegExp(r'join=([A-Za-z0-9]+)').firstMatch(uri.fragment);
      if (match != null) joinCode = match.group(1);
    }
    joinCode ??= SplitifyApp.pendingJoinCode;
    SplitifyApp.pendingJoinCode = null;

    if (joinCode == null || joinCode.trim().isEmpty) return;

    final code = joinCode.trim().toUpperCase();
    final state = AppStateScope.of(context);
    final user = state.currentUser;
    if (user == null) return;

    // Check if user is already in this group
    final existing = state.groups.where((g) => g.inviteCode?.toUpperCase() == code).firstOrNull;
    if (existing != null) {
      state.selectGroup(existing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${existing.name}! 🎉'),
            backgroundColor: AppTheme.surfaceElevated,
          ),
        );
      }
      return;
    }

    // Try joining via Firestore
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );

      final joinedGroup = await FirestoreService().joinGroupByInviteCode(user.id, code);
      if (mounted) Navigator.pop(context);

      state.addGroup(joinedGroup);
      state.selectGroup(joinedGroup.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${joinedGroup.name} via invite link! 🎉'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite link error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    
    if (state.groups.isEmpty) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.backgroundDark, AppTheme.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.hub_rounded, size: 80, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'No Circles Found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a sharing circle or join an existing one to start splitting expenses.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textGrey,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        'CREATE NEW CIRCLE',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JoinGroupScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_rounded),
                      label: Text(
                        'JOIN VIA CODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentGreen,
                        side: const BorderSide(color: AppTheme.accentGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    final pendingCount = state.groups
        .expand((g) => g.expenses)
        .where((e) => e.isPending)
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryLight,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.analytics_rounded),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentPink,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'AI Insights',
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScanScreen()),
            );
          },
          backgroundColor: AppTheme.primary,
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
