import '../../data/models/reimbursement_claim.dart';

class MockReimbursementData {
  MockReimbursementData._();

  static List<ReimbursementClaim> _claims = <ReimbursementClaim>[];

  static List<ReimbursementClaim> get claims => List.unmodifiable(_claims);

  static void add(ReimbursementClaim claim) {
    _claims = [..._claims, claim];
  }
}
