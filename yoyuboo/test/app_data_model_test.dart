import 'package:flutter_test/flutter_test.dart';
import 'package:yoyuboo/models/data.dart';

void main() {
  group('AppData model', () {
    test('toJson/fromJson roundtrip', () {
      final data = AppData(
        startYearMonth: '2024-04',
        records: {
          '2024-04': MonthRecord(
            balance: 42.5,
            events: [Event(memo: 'memo', amountHint: 100.0)],
          ),
        },
      );

      final json = data.toJson();
      final restored = AppData.fromJson(json);

      expect(restored.startYearMonth, '2024-04');
      expect(restored.records, contains('2024-04'));
      expect(restored.records['2024-04']!.balance, 42.5);
      expect(restored.records['2024-04']!.events, hasLength(1));
      expect(restored.records['2024-04']!.events.first.memo, 'memo');
      expect(restored.records['2024-04']!.events.first.amountHint, 100.0);
    });
  });
}
