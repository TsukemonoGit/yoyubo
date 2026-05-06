import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/home_menu_actions.dart';
import 'month_detail_screen.dart';

/// ホームページ
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final data = provider.data;

    if (data == null) {
      return const Scaffold(body: Center(child: Text('データを表示できません。')));
    }

    final monthList = data.records.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yoyuboo'),
            if (provider.currentFileName != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.description,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  provider.currentFileName!,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: monthList.isEmpty
            ? const Center(child: Text('まだデータがありません。\n右上メニューから追加してください。'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: monthList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final yearMonth = monthList[index];
                  final record = data.records[yearMonth];
                  return MonthCard(
                    yearMonth: yearMonth,
                    record: record,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => MonthDetailPage(yearMonth: yearMonth)),
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHomeMenu(context, data),
        icon: const Icon(Icons.menu),
        label: const Text('メニュー'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
