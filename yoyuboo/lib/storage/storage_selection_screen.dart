import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';

/// 保存先選択画面（ファイル選択・新規作成）
class StorageSelectionScreen extends StatelessWidget {
  const StorageSelectionScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _pickFile(context, create: false),
                child: const Text('既存ファイルを開く'),
              ),
              if (kIsWeb)
                FutureBuilder<bool>(
                  future: context.read<AppDataProvider>().repository.hasStoredFile(),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _restoreFile(context),
                          child: const Text('前回開いたファイルを開く'),
                        ),
                      ],
                    );
                  },
                ),
              if (kIsWeb) const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _pickFile(context, create: true),
                child: const Text('新規ファイルを作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(
      BuildContext context, {required bool create}) async {
    await context.read<AppDataProvider>().pickFileAndInitialize(
        create: create);
  }

  Future<void> _restoreFile(BuildContext context) async {
    final provider = context.read<AppDataProvider>();
    final success = await provider.repository.restoreFile();
    if (!success || !context.mounted) return;
    await provider.initialize();
  }
}
