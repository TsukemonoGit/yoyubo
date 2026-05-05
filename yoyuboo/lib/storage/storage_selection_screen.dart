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
              const SizedBox(height: 8),
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
}
