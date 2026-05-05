import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/data.dart';
import '../utils/date_utils.dart';

// グラフ関連のimportはcommon_widgetsからformatAmountWithUnitを使用

// --- 補助関数 ---

/// 破線を描画するペインター（グラフの凡例で使用）
class _DashLinePainter extends CustomPainter {
  final Color color;

  const _DashLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const space = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// グラフのY軸間隔を計算
double _horizontalInterval(List<FlSpot> points) {
  if (points.isEmpty) return 1;

  final values = points.map((p) => p.y).toList();
  final min = values.reduce((a, b) => a < b ? a : b);
  final max = values.reduce((a, b) => a > b ? a : b);
  final range = (max - min).abs();

  if (range <= 5) return 1;
  if (range <= 20) return 5;
  if (range <= 50) return 10;
  return 20;
}

/// 月末残高推移グラフ用データ計算
ChartData _calculateBalanceChartData(AppData data) {
  final records = data.records;
  final sortedKeys = records.keys.toList()..sort();

  if (sortedKeys.isEmpty) {
    return const ChartData(
      totalMonths: 0,
      realPoints: [],
      interpolatedPoints: [],
      labels: [],
      balanceByIndex: {},
      hasInterpolation: false,
      allSpots: [],
      dateKeys: [],
      dateByIndex: {},
    );
  }

  // 全月のインデックス範囲を計算
  final firstKey = sortedKeys.first;
  final lastKey = sortedKeys.last;
  final firstDate = AppDateUtils.parseYearMonth(firstKey);
  final lastDate = AppDateUtils.parseYearMonth(lastKey);
  final totalMonths = (lastDate.year - firstDate.year) * 12 +
      lastDate.month -
      firstDate.month +
      1;

  // 各月のインデックスと残高をマッピング
  final balanceByIndex = <int, double>{};
  final dateByIndex = <int, String>{};
  for (final key in sortedKeys) {
    final date = AppDateUtils.parseYearMonth(key);
    // 最初の月からの相対インデックス（月ごとの連続番号）
    final relativeIndex =
        (date.year - firstDate.year) * 12 + date.month - firstDate.month;
    final record = records[key];
    if (record?.balance != null) {
      balanceByIndex[relativeIndex] = record!.balance!;
      dateByIndex[relativeIndex] = key;
    }
  }

  // 実データポイント
  final realPoints = <FlSpot>[];
  for (final entry in balanceByIndex.entries) {
    realPoints.add(FlSpot(entry.key.toDouble(), entry.value));
  }

  // 補間用ポイント（前後の値を直線補間）
  final interpolatedPoints = <FlSpot>[];
  final sortedIndices = balanceByIndex.keys.toList()..sort();

  for (var i = 0; i < sortedIndices.length - 1; i++) {
    final currentIdx = sortedIndices[i];
    final nextIdx = sortedIndices[i + 1];

    if (nextIdx - currentIdx > 1) {
      final currentVal = balanceByIndex[currentIdx]!;
      final nextVal = balanceByIndex[nextIdx]!;

      // 補間に使う中間点
      for (var j = currentIdx + 1; j < nextIdx; j++) {
        final t = (j - currentIdx).toDouble() / (nextIdx - currentIdx);
        final interpolated = currentVal + (nextVal - currentVal) * t;
        interpolatedPoints.add(FlSpot(j.toDouble(), interpolated));
      }
    }
  }

  // ラベル生成（X軸インデックス用のラベル）
  final labels = <String>[];
  for (var i = 0; i < totalMonths; i++) {
    final dateKey = dateByIndex[i];
    if (dateKey != null) {
      final date = AppDateUtils.parseYearMonth(dateKey);
      labels.add('${date.year}/${date.month.toString().padLeft(2, '0')}');
    } else {
      labels.add('');
    }
  }

  // 全ポイント（実データ + 補間）
  final allSpots = [...realPoints, ...interpolatedPoints]
    ..sort((a, b) => a.x.compareTo(b.x));

  final hasInterpolation = interpolatedPoints.isNotEmpty;

  return ChartData(
    totalMonths: totalMonths,
    realPoints: realPoints,
    interpolatedPoints: interpolatedPoints,
    labels: labels,
    balanceByIndex: balanceByIndex,
    hasInterpolation: hasInterpolation,
    allSpots: allSpots,
    dateKeys: sortedKeys,
    dateByIndex: dateByIndex,
  );
}

// --- ウィジェット ---

/// 月末残高推移グラフページ
class BalanceGraphPage extends StatefulWidget {
  const BalanceGraphPage({super.key, required this.data});

  final AppData data;

  @override
  State<BalanceGraphPage> createState() => _BalanceGraphPageState();
}

class _BalanceGraphPageState extends State<BalanceGraphPage> {
  int? _selectedIndex;
  String? _selectedDateKey;

  @override
  Widget build(BuildContext context) {
    final chartData = _calculateBalanceChartData(widget.data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('月末残高の推移'),
      ),
      body: chartData.allSpots.isEmpty
          ? const Center(child: Text('残高データがありません。'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 凡例
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          const Text('実データ'),
                        ],
                      ),
                      if (chartData.hasInterpolation) ...[
                        const SizedBox(width: 16),
                        CustomPaint(
                          size: const Size(24, 2),
                          painter: _DashLinePainter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('補間'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // グラフ
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval:
                              _horizontalInterval(chartData.allSpots),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: (chartData.totalMonths <= 12
                                      ? 1
                                      : chartData.totalMonths <= 36
                                          ? 3
                                          : 6)
                                  .toDouble(),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= chartData.labels.length) {
                                  return const SizedBox.shrink();
                                }
                                final label = chartData.labels[index];
                                if (label.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        lineBarsData: [
                          // 補間線（下層）
                          LineChartBarData(
                            isCurved: false,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                            spots: chartData.interpolatedPoints,
                          ),
                          // 実データ線（上層）
                          LineChartBarData(
                            isCurved: false,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final isInterpolated =
                                    chartData.interpolatedPoints
                                        .any((p) =>
                                            p.x == spot.x && p.y == spot.y);
                                final isSelected =
                                    !isInterpolated &&
                                    spot.x.toInt() == _selectedIndex;
                                return FlDotCirclePainter(
                                  radius: isSelected ? 8 : isInterpolated ? 3 : 5,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : isInterpolated
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.5)
                                          : Theme.of(context).colorScheme.primary,
                                  strokeWidth: isSelected ? 3 : 2,
                                  strokeColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(show: false),
                            spots: chartData.allSpots,
                          ),
                        ],
                        minX: chartData.allSpots.isEmpty
                            ? 0
                            : chartData.allSpots.first.x,
                        maxX: chartData.allSpots.isEmpty
                            ? 0
                            : chartData.allSpots.last.x,
                        minY: chartData.allSpots.isEmpty
                            ? 0
                            : chartData.allSpots
                                .map((p) => p.y)
                                .reduce((a, b) => a < b ? a : b) -
                                5,
                        maxY: chartData.allSpots.isEmpty
                            ? 0
                            : chartData.allSpots
                                .map((p) => p.y)
                                .reduce((a, b) => a > b ? a : b) +
                                5,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return List.generate(touchedSpots.length, (i) {
                                final spot = touchedSpots[i];
                                final index = spot.x.toInt();
                                final dateKey = chartData.dateByIndex[index];
                                String label;
                                if (dateKey != null) {
                                  final date =
                                      AppDateUtils.parseYearMonth(dateKey);
                                  label =
                                      '${date.year}/${date.month.toString().padLeft(2, '0')}';
                                } else {
                                  label = '';
                                }
                                return LineTooltipItem(
                                  label.isNotEmpty
                                      ? '$label\n${spot.y.toStringAsFixed(1)}万円'
                                      : '${spot.y.toStringAsFixed(1)}万円',
                                  TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              });
                            },
                          ),
                          handleBuiltInTouches: true,
                          touchCallback: (event, response) {
                            if (response != null &&
                                response.lineBarSpots != null &&
                                event is PointerDownEvent) {
                              final touchedSpot = response.lineBarSpots!.first;
                              final xIndex = touchedSpot.x.toInt();
                              final isRealPoint = chartData.realPoints.any((p) => p.x == touchedSpot.x && p.y == touchedSpot.y);
                              if (isRealPoint) {
                                final dateKey = chartData.dateByIndex[xIndex];
                                setState(() {
                                  _selectedIndex = xIndex;
                                  _selectedDateKey = dateKey;
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedDateKey != null) ...[
                    Text(
                      '選択した月の詳細',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SelectedMonthEventCard(
                      dateKey: _selectedDateKey,
                      appData: widget.data,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// 選択した月の詳細を表示するカード
class _SelectedMonthEventCard extends StatelessWidget {
  const _SelectedMonthEventCard({
    required this.dateKey,
    required this.appData,
  });

  final String? dateKey;
  final AppData appData;

  @override
  Widget build(BuildContext context) {
    if (dateKey == null) return const SizedBox.shrink();

    final record = appData.records[dateKey!];
    final date = AppDateUtils.parseYearMonth(dateKey!);
    final events = record?.events ?? const <Event>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.year}年${date.month}月',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatAmountWithUnit(record?.balance),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (events.isNotEmpty) const SizedBox(height: 8),
            if (events.isNotEmpty)
              ...events.map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      if (event.label != null)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: event.label!.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (event.label != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.memo,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (event.amountHint != null)
                        Text(
                          '${event.amountHint!.toStringAsFixed(1)}万円',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            if (events.isEmpty)
              Text(
                'メモはありません',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 金額を単位付きでフォーマット（balance_graph_page用コピー）
String _formatAmountWithUnit(double? value) {
  if (value == null) return '---';
  return '${value.toStringAsFixed(1)} 万円';
}

/// グラフチャート用計算結果（public版）
class ChartData {
  const ChartData({
    required this.totalMonths,
    required this.realPoints,
    required this.interpolatedPoints,
    required this.labels,
    required this.balanceByIndex,
    required this.hasInterpolation,
    required this.allSpots,
    required this.dateKeys,
    required this.dateByIndex,
  });

  final int totalMonths;
  final List<FlSpot> realPoints;
  final List<FlSpot> interpolatedPoints;
  final List<String> labels;
  final Map<int, double> balanceByIndex;
  final bool hasInterpolation;
  final List<FlSpot> allSpots;
  final List<String> dateKeys;
  final Map<int, String> dateByIndex;
}
