import sys

def modify_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # We need to find the "if (tx.groupId == 'LOCAL_SMS' && isSuccess)"
    # and make sure there is a "],)," before it to close the Row.
    
    # Let's find exactly what's there
    bad_part = """                ],
              ),
              if (tx.groupId == 'LOCAL_SMS' && isSuccess) ...["""
    
    good_part = """                ],
              ),
            ],
          ),
          if (tx.groupId == 'LOCAL_SMS' && isSuccess) ...["""

    content = content.replace(bad_part, good_part)
    
    with open(filepath, 'w') as f:
        f.write(content)

modify_file('lib/screens/transaction_history_screen.dart')
