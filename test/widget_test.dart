import 'package:flutter_test/flutter_test.dart';
import 'package:splitify/models/models.dart';

void main() {
  test('UserProfile model test', () {
    final user = UserProfile(
      id: '123',
      name: 'Test User',
      email: 'test@example.com',
      upiId: 'test@upi',
    );
    expect(user.id, '123');
    expect(user.name, 'Test User');
    expect(user.email, 'test@example.com');
  });
}
