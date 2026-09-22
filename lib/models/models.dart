class Member {
  final String id;
  final String name;
  final String phone;
  final String upiId;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.upiId,
  });
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final Member paidBy;
  // Splits: memberId -> amount. If isPending is true, this might be empty or incomplete.
  final Map<String, double> splits; 
  final String category;
  final DateTime date;
  final bool isSettlement;
  final bool isPending; // "Pay First, Split Later" flag

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splits,
    required this.category,
    required this.date,
    this.isSettlement = false,
    this.isPending = false,
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    Member? paidBy,
    Map<String, double>? splits,
    String? category,
    DateTime? date,
    bool? isSettlement,
    bool? isPending,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splits: splits ?? this.splits,
      category: category ?? this.category,
      date: date ?? this.date,
      isSettlement: isSettlement ?? this.isSettlement,
      isPending: isPending ?? this.isPending,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final List<Member> members;
  final List<Expense> expenses;
  final int billingDay; // e.g., 5th of every month
  final String? inviteCode;
  final String? createdBy; // Admin of the group
  final String homeLocationName; // Name of home location (e.g. "1H Apartment")
  final double homeLatitude;
  final double homeLongitude;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.expenses,
    required this.billingDay,
    this.inviteCode,
    this.createdBy,
    this.homeLocationName = "1H Apartment",
    this.homeLatitude = 12.9716, // Default Bangalore coordinates
    this.homeLongitude = 77.5946,
  });

  Group copyWith({
    String? id,
    String? name,
    String? description,
    List<Member>? members,
    List<Expense>? expenses,
    int? billingDay,
    String? inviteCode,
    String? createdBy,
    String? homeLocationName,
    double? homeLatitude,
    double? homeLongitude,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      billingDay: billingDay ?? this.billingDay,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      homeLocationName: homeLocationName ?? this.homeLocationName,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
    );
  }

  // Calculate net balances for each member in this group (excluding pending splits).
  Map<String, double> calculateBalances() {
    final Map<String, double> balances = {};
    for (var member in members) {
      balances[member.id] = 0.0;
    }

    for (var expense in expenses) {
      if (expense.isPending) continue; // Skip pending/uncompleted splits

      // The person who paid gets credit
      balances[expense.paidBy.id] = (balances[expense.paidBy.id] ?? 0.0) + expense.amount;

      // Each person in the split owes their split share
      expense.splits.forEach((memberId, share) {
        balances[memberId] = (balances[memberId] ?? 0.0) - share;
      });
    }

    return balances;
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;

  UserProfile({required this.id, required this.name, required this.email});
}
