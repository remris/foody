import 'package:flutter/material.dart';

extension DateTimeExtension on DateTime {
  bool get isExpiringSoon {
    final now = DateTime.now();
    final diff = difference(now).inDays;
    return diff >= 0 && diff <= 3;
  }

  bool get isExpired {
    return isBefore(DateTime.now());
  }

  String get formattedDate {
    return '$day.$month.$year';
  }
}

extension StringExtension on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

Color expiryColor(DateTime? expiryDate) {
  if (expiryDate == null) return Colors.grey;
  if (expiryDate.isExpired) return Colors.red;
  if (expiryDate.isExpiringSoon) return Colors.orange;
  return Colors.green;
}

