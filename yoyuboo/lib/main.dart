import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/data_provider.dart';
import 'screens/home_screen.dart';
import 'storage/storage_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDataProvider = AppDataProvider();
  await appDataProvider.loadSettingsAndInitialize();

  runApp(
    ChangeNotifierProvider.value(
        value: appDataProvider, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yoyuboo',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
      ],
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: const Color(0xFFB85C38)),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();

    if (!provider.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (provider.hasError) {
      return StorageSelectionScreen(
        title: '読み込みエラー',
        message: provider.errorMessage ?? 'データの読み込みに失敗しました。',
      );
    }

    if (!provider.isStorageSelected && !kIsWeb) {
      return const StorageSelectionScreen(
        title: '保存先を選択',
        message:
            'yoyuboo.json を保存するファイルを選びます。\n'
            'Google Drive や Dropbox も利用できます。',
      );
    }

    return const HomePage();
  }
}
