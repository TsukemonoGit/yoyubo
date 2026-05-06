import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/data.dart';
import '../providers/data_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/balance_graph_page.dart';
import '../widgets/help_page.dart';

/// ホームメニューアクション
enum HomeMenuAction {
  addMonth,
  openOrCreateFile,
  dataInputOutput,
  graph,
  theme,
  help,
}

/// ファイル操作アクション
enum _FileAction { open, create }

/// データ入出力アクション
enum _DataInputOutputAction { export, import, restore }

/// ホームメニュー表示
Future<void> showHomeMenu(BuildContext context, AppData data) async {
  final action = await showModalBottomSheet<HomeMenuAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => _HomeMenuList(data: data),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case HomeMenuAction.addMonth:
      await _showAddMonthPicker(context);
    case HomeMenuAction.openOrCreateFile:
      await _showOpenOrCreateDialog(context);
    case HomeMenuAction.dataInputOutput:
      await _showDataInputOutputMenu(context);
    case HomeMenuAction.graph:
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BalanceGraphPage(data: data)),
      );
    case HomeMenuAction.theme:
      _showNotImplemented(context, 'テーマ');
    case HomeMenuAction.help:
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const HelpPage()));
  }
}

/// ホームメニューリスト
class _HomeMenuList extends StatelessWidget {
  const _HomeMenuList({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 46),
      children: [
        if (provider.currentFileName != null) ...[
          _buildFileInfoSection(context, provider),
          const Divider(height: 1),
        ],
        _buildAddSection(context),
        const Divider(height: 1),
        _homeMenuItem(context, Icons.bar_chart, 'グラフで見る', HomeMenuAction.graph),
        _homeMenuItem(
          context,
          Icons.folder_open,
          'ファイル操作',
          HomeMenuAction.openOrCreateFile,
        ),
        _homeMenuItem(
          context,
          Icons.upload,
          'データの入出力',
          HomeMenuAction.dataInputOutput,
        ),
        _homeMenuItem(context, Icons.color_lens, 'テーマ', HomeMenuAction.theme),
        _homeMenuItem(context, Icons.help, '使い方', HomeMenuAction.help),
      ],
    );
  }

  Widget _buildFileInfoSection(BuildContext context, AppDataProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '現在のファイル',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.currentFileName!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // ファイル名のみ表示
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSection(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(HomeMenuAction.addMonth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.add_circle,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '追加',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'メモ・残高・月を追加',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _homeMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    HomeMenuAction action,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}

/// 月選択ダイアログ
class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.maxYear,
    required this.maxMonth,
  });

  final int initialYear;
  final int initialMonth;
  final int maxYear;
  final int maxMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  int get _maxMonthForYear {
    if (_year == widget.maxYear) {
      return widget.maxMonth % 12 == 0 ? 12 : widget.maxMonth % 12;
    }
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('月を選択'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(
                    labelText: '年',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    widget.maxYear - 2000 + 1,
                    (i) => DropdownMenuItem<int>(
                      value: 2000 + i,
                      child: Text('${2000 + i}年'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _year = value;
                        if (_month > _maxMonthForYear) {
                          _month = _maxMonthForYear;
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: const InputDecoration(
                    labelText: '月',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    _maxMonthForYear,
                    (i) => DropdownMenuItem<int>(
                      value: i + 1,
                      child: Text('${i + 1}月'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _month = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            final yearMonth = AppDateUtils.formatYearMonth(
              DateTime(_year, _month),
            );
            final provider = context.read<AppDataProvider>();
            if (provider.data != null) {
              provider.addMonth(yearMonth);
            }
            Navigator.of(context).pop();
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}

/// ホームメニューの各アクション対応関数

Future<void> _showAddMonthPicker(BuildContext context) async {
  final now = DateTime.now();
  final maxYear = now.year + 1;
  final maxMonth = now.month + (now.year == maxYear - 1 ? 11 : 12);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _MonthPickerDialog(
      initialYear: now.year,
      initialMonth: now.month,
      maxYear: maxYear,
      maxMonth: maxMonth,
    ),
  );
}

Future<void> _showOpenOrCreateDialog(BuildContext context) async {
  final result = await showDialog<_FileAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('ファイル操作'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('ファイルを開く'),
            subtitle: const Text('既存のファイルを選択して読み込み'),
            onTap: () => Navigator.of(dialogContext).pop(_FileAction.open),
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('新規作成'),
            subtitle: const Text('新しいファイルを作成'),
            onTap: () => Navigator.of(dialogContext).pop(_FileAction.create),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;

  final provider = context.read<AppDataProvider>();
  final success = result == _FileAction.create
      ? await provider.repository.createFile()
      : await provider.repository.openFile();
  if (!success) return;

  await provider.initialize();
}

Future<void> _showDataInputOutputMenu(BuildContext context) async {
  final result = await showDialog<_DataInputOutputAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('データの入出力'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('エクスポート'),
            subtitle: const Text('データを外部ファイルに書き出し'),
            onTap: () =>
                Navigator.of(dialogContext).pop(_DataInputOutputAction.export),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('インポート'),
            subtitle: const Text('外部ファイルからデータを読み込み'),
            onTap: () =>
                Navigator.of(dialogContext).pop(_DataInputOutputAction.import),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('バックアップから復元'),
            subtitle: const Text('内部バックアップから復元'),
            onTap: () =>
                Navigator.of(dialogContext).pop(_DataInputOutputAction.restore),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;

  switch (result) {
    case _DataInputOutputAction.export:
      await _exportData(context);
    case _DataInputOutputAction.import:
      await _importData(context);
    case _DataInputOutputAction.restore:
      await _restoreBackup(context);
  }
}

Future<void> _importData(BuildContext context) async {
  final provider = context.read<AppDataProvider>();
  final success = await provider.importData();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(success ? 'データをインポートしました。' : 'インポートに失敗しました。')),
  );
}

Future<void> _restoreBackup(BuildContext context) async {
  final provider = context.read<AppDataProvider>();
  final restored = await provider.restoreFromInternalBackup();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(restored ? 'バックアップから復元しました。' : '復元できるバックアップがありません。'),
    ),
  );
}

Future<void> _exportData(BuildContext context) async {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('エクスポート機能は現在準備中です。')));
}

void _showNotImplemented(BuildContext context, String label) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$label はこれから実装します。')));
}
