import 'package:flutter_test/flutter_test.dart';

import 'package:field_supervisor_app/core/constants/app_strings.dart';

void main() {
  test('home greeting follows device time rules with user first name', () {
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 0, 0)),
      'Selamat Pagi Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 11, 59)),
      'Selamat Pagi Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 12, 0)),
      'Selamat Siang Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 14, 59)),
      'Selamat Siang Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 15, 0)),
      'Selamat Sore Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 18, 29)),
      'Selamat Sore Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 18, 30)),
      'Selamat Malam Andi',
    );
    expect(
      AppStrings.homeGreeting('Andi Pratama', DateTime(2026, 9, 22, 23, 59)),
      'Selamat Malam Andi',
    );
    expect(
      AppStrings.homeGreeting('', DateTime(2026, 9, 22, 9, 0)),
      'Selamat Pagi',
    );
  });
}
