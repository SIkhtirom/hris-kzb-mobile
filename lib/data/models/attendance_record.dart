import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, pending }

enum ClockEventType { checkIn, checkOut }

class AttendanceRecord extends Equatable {
  final String id;
  final DateTime timestamp;
  final ClockEventType eventType;
  final String address;
  final double latitude;
  final double longitude;
  final AttendanceStatus status;
  final String? photoPath;

  const AttendanceRecord({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.photoPath,
  });

  static ClockEventType _eventFrom(String? raw) {
    switch (raw) {
      case 'check_out':
      case 'checkOut':
        return ClockEventType.checkOut;
      default:
        return ClockEventType.checkIn;
    }
  }

  static AttendanceStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'pending':
        return AttendanceStatus.pending;
      default:
        return AttendanceStatus.present;
    }
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    final rawLatitude = json['latitude'];
    final rawLongitude = json['longitude'];
    return AttendanceRecord(
      id: json['id'] as String? ?? '',
      timestamp: rawTimestamp is String
          ? DateTime.tryParse(rawTimestamp) ?? DateTime.now()
          : DateTime.now(),
      eventType: _eventFrom(json['event_type'] as String?),
      address: json['address'] as String? ?? '',
      latitude: rawLatitude is num ? rawLatitude.toDouble() : 0,
      longitude: rawLongitude is num ? rawLongitude.toDouble() : 0,
      status: _statusFrom(json['status'] as String?),
      photoPath: json['photo_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'event_type': eventType == ClockEventType.checkOut
          ? 'check_out'
          : 'check_in',
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'photo_path': photoPath,
    };
  }

  @override
  List<Object?> get props => [
    id,
    timestamp,
    eventType,
    address,
    latitude,
    longitude,
    status,
    photoPath,
  ];
}
