import '../../data/models/izin_record.dart';

class MockIzinData {
  MockIzinData._();

  static List<IzinRecord> _records = <IzinRecord>[];

  static List<IzinRecord> get records => List.unmodifiable(_records);

  static void add(IzinRecord record) {
    _records = [..._records, record];
  }
}
