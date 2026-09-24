import sys

def modify_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    bad_part = """  void _navigateToAddExpense(TransactionModel tx, Group group) async {
    await Navigator.push("""
    good_part = """  void _navigateToAddExpense(TransactionModel tx, Group group) async {
    final result = await Navigator.push("""
    content = content.replace(bad_part, good_part)
    
    bad_part2 = """    );
    // After returning, mark as added
    final prefs = await SharedPreferences.getInstance();"""
    good_part2 = """    );
    
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();"""
    content = content.replace(bad_part2, good_part2)
    
    bad_part3 = """      // Optionally reload to remove from list
      _loadTransactions();
    }
  }"""
    good_part3 = """      // Optionally reload to remove from list
      _loadTransactions();
    }
    }
  }"""
    content = content.replace(bad_part3, good_part3)
    
    with open(filepath, 'w') as f:
        f.write(content)

modify_file('lib/screens/transaction_history_screen.dart')
