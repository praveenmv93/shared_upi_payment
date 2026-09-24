import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

class SmsTransactionService {
  final SmsQuery _query = SmsQuery();

  /// Gets SMS transactions. Returns null if permission is denied.
  Future<List<TransactionModel>?> getSmsTransactions(String userId) async {
    final permission = await Permission.sms.status;
    if (!permission.isGranted) {
      return null;
    }

    return _queryAndParseSms(userId);
  }

  /// Requests permission and fetches if granted.
  Future<List<TransactionModel>?> requestAndGetSmsTransactions(String userId) async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      return _queryAndParseSms(userId);
    }
    return null;
  }

  Future<List<TransactionModel>> _queryAndParseSms(String userId) async {
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 1000,
    );

    List<TransactionModel> transactions = [];
    for (var msg in messages) {
      if (msg.body != null) {
        final tx = _parseMessage(msg.body!, msg.date, userId);
        if (tx != null) {
          transactions.add(tx);
        }
      }
    }
    return transactions;
  }

  TransactionModel? _parseMessage(String body, DateTime? date, String userId) {
    final lowerBody = body.toLowerCase();
    
    // Look for debit indicators usually found in bank SMS
    if ((lowerBody.contains('debited') || lowerBody.contains('sent') || lowerBody.contains('paid')) && 
        (lowerBody.contains('inr') || lowerBody.contains('rs') || lowerBody.contains('a/c'))) {
      
      // Regex to extract amount (e.g. Rs 500.00, INR 50, Rs. 100)
      final amountRegex = RegExp(r'(?:rs\.?|inr)\s*([\d,]+\.?\d*)', caseSensitive: false);
      final match = amountRegex.firstMatch(lowerBody);
      
      if (match != null && match.group(1) != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        
        if (amount != null && amount > 0) {
          // Extract recipient or merchant name
          String merchant = 'Unknown Merchant';
          
          if (lowerBody.contains('to vpa ')) {
             final vpaRegex = RegExp(r'to vpa ([^\s]+)');
             final vpaMatch = vpaRegex.firstMatch(lowerBody);
             if (vpaMatch != null) merchant = vpaMatch.group(1)!;
          } else if (lowerBody.contains('to ')) {
             // simplified extraction for "to XXXX"
             final toRegex = RegExp(r'to ([a-zA-Z0-9\s]+?)(?:\s(?:ref|on|upi|via|from)|\.)');
             final toMatch = toRegex.firstMatch(lowerBody);
             if (toMatch != null && toMatch.group(1)!.trim().isNotEmpty) {
               merchant = toMatch.group(1)!.trim();
             }
          }

          return TransactionModel(
            id: 'sms_${date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            amount: amount,
            recipientName: merchant,
            recipientUpiId: '',
            status: 'SUCCESS',
            timestamp: date ?? DateTime.now(),
            groupId: 'LOCAL_SMS', // identifier for SMS transactions
            errorMessage: 'Fetched automatically',
          );
        }
      }
    }
    return null;
  }
}
