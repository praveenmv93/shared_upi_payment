import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  static const String _groupsCollection = 'groups';
  static const String _usersCollection = 'users';
  static const String _invitesCollection = 'invites';
  static const String _transactionsCollection = 'transactions';

  // ==================== GROUP OPERATIONS ====================

  /// Create a new group and save to Firestore
  Future<Group> createGroup({
    required String userId,
    required String groupName,
    required String description,
    required String homeLocation,
    required double homeLatitude,
    required double homeLongitude,
    required int billingDay,
    required List<String> memberIds, // Includes current user
  }) async {
    try {
      final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
      final inviteCode = _generateInviteCode();

      final groupData = {
        'id': groupId,
        'name': groupName,
        'description': description,
        'homeLocationName': homeLocation,
        'homeLatitude': homeLatitude,
        'homeLongitude': homeLongitude,
        'billingDay': billingDay,
        'createdBy': userId,
        'memberIds': memberIds,
        'inviteCode': inviteCode,
        'createdAt': Timestamp.now(),
        'expenses': [], // Will be added later
      };

      await _db.collection(_groupsCollection).doc(groupId).set(groupData);

      // Add group reference to user's profile
      await _db.collection(_usersCollection).doc(userId).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });

      final members = await _fetchMembers(memberIds);

      return Group(
        id: groupId,
        name: groupName,
        description: description,
        members: members,
        expenses: [],
        billingDay: billingDay,
        inviteCode: inviteCode,
        homeLocationName: homeLocation,
        homeLatitude: homeLatitude,
        homeLongitude: homeLongitude,
      );
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }

  /// Update a group's location and save to Firestore
  Future<void> updateGroupLocation(String groupId, double latitude, double longitude, String locationName) async {
    try {
      await _db.collection(_groupsCollection).doc(groupId).update({
        'homeLatitude': latitude,
        'homeLongitude': longitude,
        'homeLocationName': locationName,
      });
    } catch (e) {
      throw Exception('Error updating group location: $e');
    }
  }

  /// Fetch all groups for a user
  Future<List<Group>> getUserGroups(String userId) async {
    try {
      final userDoc = await _db.collection(_usersCollection).doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }

      final groupIds = List<String>.from(userDoc['groupIds'] ?? []);
      
      if (groupIds.isEmpty) {
        return [];
      }

      final groups = <Group>[];
      
      for (final groupId in groupIds) {
        final groupDoc = await _db.collection(_groupsCollection).doc(groupId).get();
        
        if (groupDoc.exists) {
          final data = groupDoc.data()!;
          final group = await _documentToGroupAsync(data);
          groups.add(group);
        }
      }

      return groups;
    } catch (e) {
      throw Exception('Error fetching user groups: $e');
    }
  }

  /// Listen to real-time updates for groups
  Stream<List<Group>> streamUserGroups(String userId) {
    return _db.collection(_usersCollection).doc(userId).snapshots().asyncExpand((userDoc) {
      if (!userDoc.exists) {
        return Stream.value([]);
      }

      final groupIds = List<String>.from(userDoc['groupIds'] ?? []);
      
      if (groupIds.isEmpty) {
        return Stream.value([]);
      }

      // Stream of all groups the user is in
      return _db.collection(_groupsCollection)
          .where(FieldPath.documentId, whereIn: groupIds)
          .snapshots()
          .asyncMap((snapshot) async {
            final list = <Group>[];
            for (final doc in snapshot.docs) {
              final group = await _documentToGroupAsync(doc.data());
              list.add(group);
            }
            return list;
          });
    });
  }

  /// Join a group using invite code
  Future<Group> joinGroupByInviteCode(String userId, String inviteCode) async {
    try {
      // Find group with this invite code
      final query = await _db.collection(_groupsCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Invalid invite code');
      }

      final groupDoc = query.docs.first;
      final groupId = groupDoc.id;
      final groupData = groupDoc.data();

      // Add user to group
      await _db.collection(_groupsCollection).doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Add group to user's profile
      await _db.collection(_usersCollection).doc(userId).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });

      return await _documentToGroupAsync(groupData);
    } catch (e) {
      throw Exception('Error joining group: $e');
    }
  }

  /// Get group by ID
  Future<Group> getGroup(String groupId) async {
    try {
      final doc = await _db.collection(_groupsCollection).doc(groupId).get();
      
      if (!doc.exists) {
        throw Exception('Group not found');
      }

      return await _documentToGroupAsync(doc.data()!);
    } catch (e) {
      throw Exception('Error fetching group: $e');
    }
  }

  /// Get invite code for a group (only group members can see)
  Future<String> getGroupInviteCode(String groupId) async {
    try {
      final doc = await _db.collection(_groupsCollection).doc(groupId).get();
      
      if (!doc.exists) {
        throw Exception('Group not found');
      }

      return doc['inviteCode'] ?? 'N/A';
    } catch (e) {
      throw Exception('Error fetching invite code: $e');
    }
  }

  // ==================== EXPENSE OPERATIONS ====================

  /// Add expense to a group
  Future<void> addExpenseToGroup(String groupId, Expense expense) async {
    try {
      await _db.collection(_groupsCollection).doc(groupId).update({
        'expenses': FieldValue.arrayUnion([_expenseToMap(expense)]),
      });
    } catch (e) {
      throw Exception('Error adding expense: $e');
    }
  }

  /// Update expense in a group
  Future<void> updateExpenseInGroup(String groupId, Expense expense) async {
    try {
      final groupDoc = await _db.collection(_groupsCollection).doc(groupId).get();
      
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final expenses = List<Map<String, dynamic>>.from(groupDoc['expenses'] ?? []);
      final index = expenses.indexWhere((e) => e['id'] == expense.id);

      if (index != -1) {
        expenses[index] = _expenseToMap(expense);
        await _db.collection(_groupsCollection).doc(groupId).update({
          'expenses': expenses,
        });
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  /// Delete a single expense from a group
  Future<void> deleteExpenseFromGroup(String groupId, String expenseId) async {
    try {
      final groupDoc = await _db.collection(_groupsCollection).doc(groupId).get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final expenses = List<Map<String, dynamic>>.from(groupDoc['expenses'] ?? []);
      expenses.removeWhere((e) => e['id'] == expenseId);

      await _db.collection(_groupsCollection).doc(groupId).update({
        'expenses': expenses,
      });
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }

  /// Delete a group and remove references from members
  Future<void> deleteGroup(String groupId, List<String> memberIds) async {
    try {
      final batch = _db.batch();

      // Delete the group document
      batch.delete(_db.collection(_groupsCollection).doc(groupId));

      // Remove groupId from each member's user document if it exists
      for (final memberId in memberIds) {
        final userDoc = await _db.collection(_usersCollection).doc(memberId).get();
        if (userDoc.exists) {
          batch.update(_db.collection(_usersCollection).doc(memberId), {
            'groupIds': FieldValue.arrayRemove([groupId]),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting group: $e');
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Create user profile if it doesn't exist
  Future<void> createUserIfNotExists(String userId, String name, String email) async {
    try {
      final userDoc = await _db.collection(_usersCollection).doc(userId).get();
      
      if (!userDoc.exists) {
        await _db.collection(_usersCollection).doc(userId).set({
          'id': userId,
          'name': name,
          'email': email,
          'groupIds': [],
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return UserProfile(
        id: data['id'],
        name: data['name'],
        email: data['email'],
        upiId: data['upiId'] ?? '',
      );
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _db.collection(_transactionsCollection).doc(transaction.id).set({
        'id': transaction.id,
        'userId': transaction.userId,
        'amount': transaction.amount,
        'recipientName': transaction.recipientName,
        'recipientUpiId': transaction.recipientUpiId,
        'status': transaction.status,
        'timestamp': Timestamp.fromDate(transaction.timestamp),
        'groupId': transaction.groupId,
        'errorMessage': transaction.errorMessage,
      });
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Get transactions for a user
  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final snap = await _db.collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snap.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: data['id'],
          userId: data['userId'],
          amount: (data['amount'] as num).toDouble(),
          recipientName: data['recipientName'] ?? 'Unknown',
          recipientUpiId: data['recipientUpiId'] ?? '',
          status: data['status'] ?? 'UNKNOWN',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          groupId: data['groupId'],
          errorMessage: data['errorMessage'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  /// Generate a unique 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    for (int i = 0; i < 6; i++) {
      result += chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
    }
    return result;
  }

  Future<List<Member>> _fetchMembers(List<String> memberIds) async {
    final members = <Member>[];
    for (final id in memberIds) {
      try {
        final userDoc = await _db.collection(_usersCollection).doc(id).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          members.add(Member(
            id: id,
            name: data['name'] ?? id,
            phone: 'N/A',
            upiId: data['upiId'] ?? data['email'] ?? '$id@upi',
          ));
        } else {
          members.add(Member(
            id: id,
            name: id.startsWith('user_') ? 'Member ${id.substring(id.length - 4)}' : id,
            phone: 'N/A',
            upiId: '$id@upi',
          ));
        }
      } catch (_) {
        members.add(Member(
          id: id,
          name: id,
          phone: 'N/A',
          upiId: '$id@upi',
        ));
      }
    }
    return members;
  }

  Future<Group> _documentToGroupAsync(Map<String, dynamic> data) async {
    final memberIds = List<String>.from(data['memberIds'] ?? []);
    final members = await _fetchMembers(memberIds);
    return Group(
      id: data['id'],
      name: data['name'],
      description: data['description'] ?? '',
      members: members,
      expenses: _mapToExpenses(List<Map<String, dynamic>>.from(data['expenses'] ?? [])),
      billingDay: data['billingDay'] ?? 1,
      inviteCode: data['inviteCode'],
      createdBy: data['createdBy'],
      homeLocationName: data['homeLocationName'] ?? 'Home',
      homeLatitude: data['homeLatitude'] != null ? double.parse(data['homeLatitude'].toString()) : 12.9716,
      homeLongitude: data['homeLongitude'] != null ? double.parse(data['homeLongitude'].toString()) : 77.5946,
    );
  }

  /// Convert Firestore document to Group model
  Group _documentToGroup(Map<String, dynamic> data) {
    final memberIds = List<String>.from(data['memberIds'] ?? []);
    
    // Note: In a real app, you would fetch user profiles for these IDs
    // For now, we'll try to use a more readable name if possible
    return Group(
      id: data['id'],
      name: data['name'],
      description: data['description'] ?? '',
      members: memberIds.map((id) => Member(
        id: id,
        name: id.startsWith('user_') ? 'Member ${id.substring(id.length - 4)}' : id,
        phone: 'N/A',
        upiId: '$id@upi',
      )).toList(),
      expenses: _mapToExpenses(List<Map<String, dynamic>>.from(data['expenses'] ?? [])),
      billingDay: data['billingDay'] ?? 1,
      inviteCode: data['inviteCode'],
      createdBy: data['createdBy'],
      homeLocationName: data['homeLocationName'] ?? 'Home',
      homeLatitude: data['homeLatitude'] != null ? double.parse(data['homeLatitude'].toString()) : 12.9716,
      homeLongitude: data['homeLongitude'] != null ? double.parse(data['homeLongitude'].toString()) : 77.5946,
    );
  }

  /// Convert Expense model to Firestore map
  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'paidById': expense.paidBy.id,
      'paidByName': expense.paidBy.name,
      'paidByUpiId': expense.paidBy.upiId,
      'splits': expense.splits,
      'category': expense.category,
      'date': Timestamp.fromDate(expense.date),
      'isSettlement': expense.isSettlement,
      'isPending': expense.isPending,
    };
  }

  /// Convert expense maps to Expense models
  List<Expense> _mapToExpenses(List<Map<String, dynamic>> expensesList) {
    return expensesList.map((e) {
      final paidById = e['paidById'];
      final paidByName = e['paidByName'] ?? (paidById.startsWith('user_') ? 'Member ${paidById.substring(paidById.length - 4)}' : paidById);
      final paidByUpiId = e['paidByUpiId'] ?? '$paidById@upi';
      
      return Expense(
          id: e['id'],
          title: e['title'],
          amount: (e['amount'] as num).toDouble(),
          paidBy: Member(
            id: paidById,
            name: paidByName,
            phone: 'N/A',
            upiId: paidByUpiId,
          ),
          splits: (e['splits'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
          category: e['category'],
          date: (e['date'] as Timestamp).toDate(),
          isSettlement: e['isSettlement'] ?? false,
          isPending: e['isPending'] ?? false,
        );
    }).toList();
  }
}
