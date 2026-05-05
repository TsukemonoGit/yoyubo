import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/data.dart';
import '../providers/data_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

/// 月詳細ページ（メモ・残高の入力）
class MonthDetailPage extends StatefulWidget {
  const MonthDetailPage({super.key, required this.yearMonth});

  final String yearMonth;

  @override
  State<MonthDetailPage> createState() => _MonthDetailPageState();
}

class _MonthDetailPageState extends State<MonthDetailPage> {
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    final record = context
        .read<AppDataProvider>()
        .data
        ?.records[widget.yearMonth];
    _balanceController = TextEditingController(
      text: record?.balance?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final record = provider.data?.records[widget.yearMonth];
    final events = record?.events ?? const <Event>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            AppDateUtils.formatYearMonthLabel(widget.yearMonth)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'その月にあったこと',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addEvent,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('まだメモはありません。'),
              ),
            )
          else
            ...events.map(
              (event) {
                final labelStyle = event.label != null
                    ? TextStyle(
                        fontSize: 11,
                        color: event.label!.color,
                        fontWeight: FontWeight.w600,
                      )
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(event.memo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (labelStyle != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: event.label!.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.label!.displayName,
                                style: labelStyle,
                              ),
                            ),
                          ),
                        event.amountHint == null
                            ? const Text('金額メモなし')
                            : Text(
                                '金額メモ: ${formatAmountWithUnit(event.amountHint)}'),
                      ],
                    ),
                    trailing: PopupMenuButton<_EventAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _EventAction.edit:
                            _editEvent(event);
                          case _EventAction.delete:
                            _deleteEvent(event);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _EventAction.edit,
                          child: Text('編集'),
                        ),
                        PopupMenuItem(
                          value: _EventAction.delete,
                          child: Text('削除'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '月末残高',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'この月の出来事が一通り終わった時点の残高です。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _balanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例: 142',
                      suffixText: '万円',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _saveBalance,
                        child: const Text('月末残高を保存'),
                      ),
                      TextButton(
                        onPressed: _clearBalance,
                        child: const Text('空欄に戻す'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBalance() async {
    final parsed = parseNullableDouble(_balanceController.text);
    if (_balanceController.text.trim().isNotEmpty && parsed == null) {
      _showSnackBar('月末残高は数値で入力してください。');
      return;
    }

    await context
        .read<AppDataProvider>()
        .updateBalance(widget.yearMonth, parsed);
    if (!mounted) return;
    _showSnackBar('月末残高を保存しました。');
  }

  Future<void> _clearBalance() async {
    _balanceController.clear();
    await context
        .read<AppDataProvider>()
        .updateBalance(widget.yearMonth, null);
    if (!mounted) return;
    _showSnackBar('月末残高を空欄にしました。');
  }

  Future<void> _addEvent() async {
    final provider = context.read<AppDataProvider>();
    final result = await showDialog<EventDraft>(
      context: context,
      builder: (context) => const EventDialog(),
    );
    if (result == null) return;

    await provider.addEvent(
        widget.yearMonth, result.memo, result.amountHint, result.label);
    if (!mounted) return;
    _showSnackBar('メモを追加しました。');
  }

  Future<void> _editEvent(Event event) async {
    final provider = context.read<AppDataProvider>();
    final result = await showDialog<EventDraft>(
      context: context,
      builder: (context) =>
          EventDialog(initialEvent: event),
    );
    if (result == null) return;

    await provider.updateEvent(
      widget.yearMonth,
      event.id,
      result.memo,
      result.amountHint,
      result.label,
    );
    if (!mounted) return;
    _showSnackBar('メモを更新しました。');
  }

  Future<void> _deleteEvent(Event event) async {
    final provider = context.read<AppDataProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: Text('「${event.memo}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await provider
        .deleteEvent(widget.yearMonth, event.id);
    if (!mounted) return;
    _showSnackBar('メモを削除しました。');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }
}

/// イベントアクション列挙
enum _EventAction { edit, delete }

