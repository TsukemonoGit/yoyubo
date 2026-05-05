import 'package:flutter_test/flutter_test.dart';
import 'package:yoyuboo/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('getCurrentYearMonth returns yyyy-MM', () {
      final result = AppDateUtils.getCurrentYearMonth();
      expect(result, matches(r'^\d{4}-\d{2}$'));
    });

    test('formatYearMonth formats DateTime correctly', () {
      final date = DateTime(2024, 4, 15);
      expect(AppDateUtils.formatYearMonth(date), '2024-04');
    });

    test('parseYearMonth returns first day of month', () {
      final date = AppDateUtils.parseYearMonth('2024-04');
      expect(date.year, 2024);
      expect(date.month, 4);
      expect(date.day, 1);
    });

    test('formatYearMonthLabel builds Japanese label', () {
      expect(AppDateUtils.formatYearMonthLabel('2024-04'), '2024年4月');
    });

    test('generateMonthRange returns descending inclusive range', () {
      final months = AppDateUtils.generateMonthRange(
        '2024-02',
        endYearMonth: '2024-05',
      );

      expect(months, ['2024-05', '2024-04', '2024-03', '2024-02']);
    });

    test('generateMonthRange returns empty when start is after end', () {
      final months = AppDateUtils.generateMonthRange(
        '2024-06',
        endYearMonth: '2024-05',
      );

      expect(months, isEmpty);
    });
  });
}
