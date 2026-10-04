import '../../data/models/user.dart';

class MockUserData {
  MockUserData._();

  static User currentUser = const User(
    id: 'SUP-001',
    name: 'Andi Pratama',
    role: 'Supervisor Lapangan',
    activeProjectName: 'Riverside Tower Construction',
    password: 'mandor123',
    dateOfBirth: null,
  );
}
