import 'package:flutter/material.dart';


enum PaymentStatus {
  initiated,
  processing,
  success,
  failed,
  cancelled,
  pending,
  unknown;

  String get label {
    switch (this) {
      case PaymentStatus.initiated:
        return 'Initiated';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.success:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.unknown:
        return 'Status Uncertain';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.initiated:
      case PaymentStatus.unknown:
        return Colors.orangeAccent;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PaymentStatus.success:
        return Colors.green.shade100;
      case PaymentStatus.failed:
        return Colors.red.shade100;
      case PaymentStatus.cancelled:
        return Colors.grey.shade200;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Colors.orange.shade100;
      case PaymentStatus.initiated:
      case PaymentStatus.unknown:
        return Colors.orangeAccent.shade100;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.success:
        return Icons.check_circle_rounded;
      case PaymentStatus.failed:
        return Icons.error_rounded;
      case PaymentStatus.cancelled:
        return Icons.cancel_rounded;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Icons.hourglass_top_rounded;
      case PaymentStatus.initiated:
      case PaymentStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}
