import 'package:equatable/equatable.dart';

enum ClaimStatus { pending, approved, rejected }

enum ExpenseCategory { material, transport, meals, other }

class ReimbursementClaim extends Equatable {
  final String id;
  final double amount;
  final String activityName;
  final ExpenseCategory category;
  final DateTime? expenseDate;
  final String currency;
  final String sellerName;
  final String notes;
  final DateTime submittedAt;
  final ClaimStatus status;
  final String? receiptFileName;

  const ReimbursementClaim({
    required this.id,
    required this.amount,
    required this.category,
    required this.notes,
    required this.submittedAt,
    required this.status,
    this.activityName = '',
    this.expenseDate,
    this.currency = 'IDR',
    this.sellerName = '',
    this.receiptFileName,
  });

  static ClaimStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      default:
        return ClaimStatus.pending;
    }
  }

  static ExpenseCategory _categoryFrom(String? raw) {
    switch (raw) {
      case 'transport':
        return ExpenseCategory.transport;
      case 'meals':
        return ExpenseCategory.meals;
      case 'other':
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.material;
    }
  }

  factory ReimbursementClaim.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final rawExpenseDate = json['expense_date'];
    final rawSubmittedAt = json['submitted_at'];
    return ReimbursementClaim(
      id: json['id'] as String? ?? '',
      amount: rawAmount is num ? rawAmount.toDouble() : 0,
      activityName: json['activity_name'] as String? ?? '',
      category: _categoryFrom(json['category'] as String?),
      expenseDate: rawExpenseDate is String
          ? DateTime.tryParse(rawExpenseDate)
          : null,
      currency: json['currency'] as String? ?? 'IDR',
      sellerName: json['seller_name'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      submittedAt: rawSubmittedAt is String
          ? DateTime.tryParse(rawSubmittedAt) ?? DateTime.now()
          : DateTime.now(),
      status: _statusFrom(json['status'] as String?),
      receiptFileName: json['receipt_file_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'activity_name': activityName,
      'category': category.name,
      'expense_date': expenseDate?.toIso8601String(),
      'currency': currency,
      'seller_name': sellerName,
      'notes': notes,
      'submitted_at': submittedAt.toIso8601String(),
      'status': status.name,
      'receipt_file_name': receiptFileName,
    };
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    activityName,
    category,
    expenseDate,
    currency,
    sellerName,
    notes,
    submittedAt,
    status,
    receiptFileName,
  ];
}
