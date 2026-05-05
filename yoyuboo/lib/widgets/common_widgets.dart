import 'package:flutter/material.dart';

import '../models/data.dart';
import '../utils/date_utils.dart';

// --- 補助関数 ---

/// 数値文字列を数値パースする（null許容）
double? parseNullableDouble(String s) {
  if (s.trim().isEmpty) return null;
  try {
    return double.parse(s);
  } catch (_) {
    return null;
  }
}

/// 金額をコンパクトに表示
String compactAmountLabel(double value) {
  final abs = value.abs();
  if (abs >= 10000) {
    return '${(value / 10000).toStringAsFixed(1)}万';
  }
  return value.toStringAsFixed(0);
}

/// 金額を単位付きでフォーマット
String formatAmountWithUnit(double? value) {
  if (value == null) return '---';
  return '${value.toStringAsFixed(1)} 万円';
}

// --- 共通ウィジェット ---

/// 情報ピルウィジェット
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: muted
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: muted
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// 月のカードウィジェット
class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.yearMonth,
    required this.record,
    required this.onTap,
  });

  final String yearMonth;
  final MonthRecord? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final events = record?.events ?? const <Event>[];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppDateUtils.formatYearMonthLabel(yearMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              if (events.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: events.map((event) {
                    final memo = event.memo.trim();
                    if (memo.isEmpty) return const SizedBox.shrink();
                    final bgColor = event.label?.color
                        .withValues(alpha: 0.15)
                        ?? Theme.of(context).colorScheme.primaryContainer;
                    final fgColor = event.label != null
                        ? event.label!.color
                        : Theme.of(context).colorScheme.onPrimaryContainer;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        memo,
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (record?.balance != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    formatAmountWithUnit(record!.balance),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (events.isEmpty && record?.balance == null)
                Text(
                  '---',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// メモ追加/編集ダイアログ
class EventDialog extends StatefulWidget {
  const EventDialog({super.key, this.initialEvent});

  final Event? initialEvent;

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late final TextEditingController _memoController;
  late final TextEditingController _amountController;
  late final EventLabel? _initialLabel;

  EventLabel? _selectedLabel;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(
      text: widget.initialEvent?.memo ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialEvent?.amountHint?.toString() ?? '',
    );
    _initialLabel = widget.initialEvent?.label;
    _selectedLabel = _initialLabel;
  }

  @override
  void dispose() {
    _memoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialEvent == null
          ? '収支メモを追加'
          : '収支メモを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _memoController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
                hintText: '例: バイク駐輪',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: '金額メモ（万円）',
                border: OutlineInputBorder(),
                hintText: '例: -0.3',
                suffixText: '万円',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ラベル',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventLabel.values.map((label) {
                final isSelected = _selectedLabel == label;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedLabel = label;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? label.color
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? label.color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      label.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initialEvent == null ? '追加' : '保存',
          ),
        ),
      ],
    );
  }

  void _submit() {
    final memo = _memoController.text.trim();
    final amountHint = parseNullableDouble(_amountController.text);

    if (memo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
        content: Text('メモを入力してください。'),
      ));
      return;
    }

    if (_amountController.text.trim().isNotEmpty &&
        amountHint == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
        content: Text('金額メモは数値で入力してください。'),
      ));
      return;
    }

    Navigator.of(context)
        .pop(EventDraft(memo: memo, amountHint: amountHint, label: _selectedLabel));
  }
}

/// メモ追加ダイアログから戻るデータの型
class EventDraft {
  const EventDraft({required this.memo, required this.amountHint, this.label});

  final String memo;
  final double? amountHint;
  final EventLabel? label;
}
