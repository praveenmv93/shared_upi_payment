import '../models/models.dart';

class MockDataService {
  static final Member currentUser = Member(
    id: 'user_georg',
    name: 'Georg',
    phone: '+91 98765 43210',
    upiId: 'georg@okaxis',
  );

  static final Member memberRahul = Member(
    id: 'user_rahul',
    name: 'Rahul',
    phone: '+91 98765 43211',
    upiId: 'rahul@okicici',
  );

  static final Member memberSneha = Member(
    id: 'user_sneha',
    name: 'Sneha',
    phone: '+91 98765 43212',
    upiId: 'sneha@okhdfc',
  );

  static final List<Member> allMembers = [currentUser, memberRahul, memberSneha];

  // Simulated notification list
  static List<String> notifications = [
    "Welcome to Splitify! Scan a QR code to try 'Pay First, Split Later'. 🚀",
  ];

  static Group activeGroup = Group(
    id: 'group_1h',
    name: '1H Apartment 🏠',
    description: 'Shared flat expenses for 1H, Bangalore',
    billingDay: 5,
    members: allMembers,
    homeLocationName: '1H Apartment, HSR Layout',
    homeLatitude: 12.9141,
    homeLongitude: 77.6413,
    expenses: [
      Expense(
        id: 'exp_1',
        title: 'Electricity Bill',
        amount: 3000.0,
        paidBy: currentUser,
        splits: {
          'user_georg': 1000.0,
          'user_rahul': 1000.0,
          'user_sneha': 1000.0,
        },
        category: 'Bills',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Expense(
        id: 'exp_2',
        title: 'Groceries (D-Mart)',
        amount: 1500.0,
        paidBy: memberSneha,
        splits: {
          'user_georg': 500.0,
          'user_rahul': 500.0,
          'user_sneha': 500.0,
        },
        category: 'Groceries',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      // A pending split that the user made but hasn't configured yet
      Expense(
        id: 'exp_pending_1',
        title: 'Star Supermarket scan',
        amount: 450.0,
        paidBy: currentUser,
        splits: {},
        category: 'Groceries',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        isPending: true,
      ),
    ],
  );

  static List<Group> groups = [activeGroup];
}
