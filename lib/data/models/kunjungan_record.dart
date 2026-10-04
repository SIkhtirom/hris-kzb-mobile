import 'package:equatable/equatable.dart';

enum KunjunganMode { start, end }

class KunjunganRecord extends Equatable {
  final String id;
  final KunjunganMode mode;
  final DateTime timestamp;
  final String timeLabel;
  final String clientName;
  final String notes;
  final String? evidencePath;
  final double? latitude;
  final double? longitude;
  final String address;

  const KunjunganRecord({
    required this.id,
    required this.mode,
    required this.timestamp,
    required this.timeLabel,
    required this.clientName,
    required this.notes,
    required this.address,
    this.evidencePath,
    this.latitude,
    this.longitude,
  });

  static KunjunganMode _modeFrom(String? raw) {
    switch (raw) {
      case 'end':
      case 'selesai':
        return KunjunganMode.end;
      default:
        return KunjunganMode.start;
    }
  }

  factory KunjunganRecord.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    final rawLatitude = json['latitude'];
    final rawLongitude = json['longitude'];
    return KunjunganRecord(
      id: json['id'] as String? ?? '',
      mode: _modeFrom(json['mode'] as String?),
      timestamp: rawTimestamp is String
          ? DateTime.tryParse(rawTimestamp) ?? DateTime.now()
          : DateTime.now(),
      timeLabel: json['time_label'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      address: json['address'] as String? ?? '',
      evidencePath: json['evidence_path'] as String?,
      latitude: rawLatitude is num ? rawLatitude.toDouble() : null,
      longitude: rawLongitude is num ? rawLongitude.toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.name,
      'timestamp': timestamp.toIso8601String(),
      'time_label': timeLabel,
      'client_name': clientName,
      'notes': notes,
      'address': address,
      'evidence_path': evidencePath,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [
    id,
    mode,
    timestamp,
    timeLabel,
    clientName,
    notes,
    evidencePath,
    latitude,
    longitude,
    address,
  ];
}
