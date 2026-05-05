import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _yearMonthFormat = DateFormat('yyyy-MM');

  static String getCurrentYearMonth() {
    return _yearMonthFormat.format(DateTime.now());
  }

  static String formatYearMonth(DateTime date) {
    return _yearMonthFormat.format(date);
  }

  static DateTime parseYearMonth(String yearMonth) {
    return _yearMonthFormat.parseStrict(yearMonth);
  }

  static String formatYearMonthLabel(String yearMonth) {
    final date = parseYearMonth(yearMonth);
    return '${date.year}年${date.month}月';
  }

  static List<String> generateMonthRange(
    String startYearMonth, {
    String? endYearMonth,
  }) {
    final start = parseYearMonth(startYearMonth);
    final end = parseYearMonth(endYearMonth ?? getCurrentYearMonth());
    if (start.isAfter(end)) {
      return const [];
    }

    final months = <String>[];
    var cursor = DateTime(start.year, start.month);

    while (!cursor.isAfter(end)) {
      months.add(formatYearMonth(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return months;
  }
}
