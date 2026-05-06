import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';

/// 使い方ページ
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('使い方')),
      body: Column(
        children: [
          if (provider.currentFilePath != null)
            _HelpFileInfoBox(provider: provider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _HelpCard(
                  title: '1. ファイルを作る',
                  body:
                      '下の「新規作成」からファイルを作ります。'
                      ' データはテキストファイルなので、Google Driveなどのクラウド共有フォルダ内に保存すれば、複数端末で同期できます。',
                ),
                _HelpCard(
                  title: '2. その月にあったことを書く',
                  body:
                      '収支メモには、その月にあった出来事を自由に追加します。'
                      ' 支出・収入・移動・その他の4種類でラベルを付けられます。'
                      ' 金額メモは必要なときだけ万円単位で添えます。',
                ),
                _HelpCard(
                  title: '3. 月末残高を入れる',
                  body:
                      '月末残高は、その月の出来事が一通り終わった時点の残高です。'
                      ' 入力単位は万円です。',
                ),
                _HelpCard(
                  title: '4. グラフで振り返る',
                  body:
                      '右上メニューの「グラフで見る」から、入力済みの月末残高の推移を確認できます。',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _FileChangeBar(),
    );
  }
}

/// 使い方ページ内のファイル情報ボックス
class _HelpFileInfoBox extends StatelessWidget {
  const _HelpFileInfoBox({required this.provider});

  final AppDataProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.description, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '現在のファイル',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    provider.currentFilePath!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ファイル変更バー（使い方ページ下部）
class _FileChangeBar extends StatelessWidget {
  const _FileChangeBar();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _changeFile(context, create: false),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('ファイルを開く'),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () => _changeFile(context, create: true),
              icon: const Icon(Icons.create_new_folder, size: 18),
              label: const Text('新規作成'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeFile(
    BuildContext context, {
    required bool create,
  }) async {
    final provider = context.read<AppDataProvider>();
    final success = create
        ? await provider.repository.createFile()
        : await provider.repository.openFile();
    if (!success || !context.mounted) return;

    await provider.initialize();
  }
}

/// 使い方ページ内のヘルプカード
class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
