import 'package:equatable/equatable.dart';

enum IzinReason { sick, family, other }

enum IzinStatus { pending, approved, rejected }

class IzinRecord extends Equatable {
  final String id;
  final DateTime date;
  final IzinReason reason;
  final String notes;
  final IzinStatus status;
  final String? photoPath;
  final DateTime createdAt;

  const IzinRecord({
    required this.id,
    required this.date,
    required this.reason,
    required this.notes,
    required this.status,
    this.photoPath,
    required this.createdAt,
  });

  static IzinReason _reasonFrom(String? raw) {
    switch (raw) {
      case 'family':
        return IzinReason.family;
      case 'other':
        return IzinReason.other;
      default:
        return IzinReason.sick;
    }
  }

  static IzinStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'approved':
        return IzinStatus.approved;
      case 'rejected':
        return IzinStatus.rejected;
      default:
        return IzinStatus.pending;
    }
  }

  factory IzinRecord.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final rawCreatedAt = json['created_at'];
    return IzinRecord(
      id: json['id'] as String? ?? '',
      date: rawDate is String
          ? DateTime.tryParse(rawDate) ?? DateTime.now()
          : DateTime.now(),
      reason: _reasonFrom(json['reason'] as String?),
      notes: json['notes'] as String? ?? '',
      status: _statusFrom(json['status'] as String?),
      photoPath: json['photo_path'] as String?,
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'reason': reason.name,
      'notes': notes,
      'status': status.name,
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    date,
    reason,
    notes,
    status,
    photoPath,
    createdAt,
  ];
}
