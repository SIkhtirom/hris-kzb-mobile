import 'package:equatable/equatable.dart';

class TimesheetTask extends Equatable {
  final String id;
  final String name;
  final DateTime assignedDate;
  final int hour;
  final int minute;
  final String instructions;
  final bool isCompleted;
  final String? proofPath;
  final DateTime? completedAt;

  const TimesheetTask({
    required this.id,
    required this.name,
    required this.assignedDate,
    required this.hour,
    required this.minute,
    required this.instructions,
    this.isCompleted = false,
    this.proofPath,
    this.completedAt,
  });

  factory TimesheetTask.fromJson(Map<String, dynamic> json) {
    final rawAssignedDate = json['assigned_date'];
    final rawCompletedAt = json['completed_at'];
    final rawHour = json['hour'];
    final rawMinute = json['minute'];
    return TimesheetTask(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assignedDate: rawAssignedDate is String
          ? DateTime.tryParse(rawAssignedDate) ?? DateTime.now()
          : DateTime.now(),
      hour: rawHour is int ? rawHour : 0,
      minute: rawMinute is int ? rawMinute : 0,
      instructions: json['instructions'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      proofPath: json['proof_path'] as String?,
      completedAt: rawCompletedAt is String
          ? DateTime.tryParse(rawCompletedAt)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assigned_date': assignedDate.toIso8601String(),
      'hour': hour,
      'minute': minute,
      'instructions': instructions,
      'is_completed': isCompleted,
      'proof_path': proofPath,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  TimesheetTask copyWith({
    bool? isCompleted,
    String? proofPath,
    DateTime? completedAt,
  }) {
    return TimesheetTask(
      id: id,
      name: name,
      assignedDate: assignedDate,
      hour: hour,
      minute: minute,
      instructions: instructions,
      isCompleted: isCompleted ?? this.isCompleted,
      proofPath: proofPath ?? this.proofPath,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  TimesheetTask markCompleted(String proof, DateTime at) {
    return copyWith(isCompleted: true, proofPath: proof, completedAt: at);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    assignedDate,
    hour,
    minute,
    instructions,
    isCompleted,
    proofPath,
    completedAt,
  ];
}
