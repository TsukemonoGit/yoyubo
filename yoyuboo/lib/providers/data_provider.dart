/*
次のステップ：データの「司令塔」を作る（ChangeNotifier）
レポジトリという「保存の仕組み」が完成したので、次はアプリを動かしている間の**「状態（State）」**を管理するクラスを作ります。

このクラスは、以下のような役割を担います。

1. データの保持: 現在の AppData オブジェクトをメモリ上に持っておく。
2. 操作の仲介: 画面から「メモ追加」や「残高入力」の指示を受け取り、AppData を書き換える。
3. 画面への通知: データが書き換わったら、画面に対して「新しくなったから再描画して！」と合図を送る（notifyListeners()）。
4. 自動保存: データを書き換えるたびに、先ほどの DataRepository を使ってファイルに保存する。
 */
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/data.dart';
import '../repositories/data_repository.dart';
import '../utils/date_utils.dart';

class AppDataProvider extends ChangeNotifier {
  // DataRepositoryは引数なしで生成できる（URI管理はKotlin側 / Web側に委譲）
  final repository = DataRepository();

  AppData? _data;
  bool _isInitialized = false;
  bool _isStorageSelected = false;
  String? _errorMessage;
  LoadResultStatus? _lastStatus;
  String? _currentFileName;
  String? _currentFilePath;

  // --- ゲッター ---
  AppData? get data => _data;
  bool get isInitialized => _isInitialized;
  bool get hasError => _lastStatus == LoadResultStatus.failure;
  String? get errorMessage => _errorMessage;
  bool get isStorageSelected => _isStorageSelected;
  String? get currentFileName => _currentFileName;
  String? get currentFilePath => _currentFilePath;

  // --- 1. アプリ起動時の入り口 ---
  Future<void> loadSettingsAndInitialize() async {
    final hasFile = await repository.hasStoredFile();

    if (hasFile) {
      _isStorageSelected = true;
      await initialize();
    } else {
      // 保存先未設定 → 画面にファイル選択を促す
      _isInitialized = true;
      notifyListeners();
    }
  }

  // --- 2. ファイルの新規選択（設定画面 or 初回起動時） ---
  Future<bool> pickFileAndInitialize({required bool create}) async {
    final picked = create
        ? await repository.createFile()
        : await repository.openFile();
    if (!picked) return false;

    _isStorageSelected = true;
    await initialize();
    return true;
  }

  // --- 3. データの読み込み実行 ---
  Future<void> initialize() async {
    developer.log('initialize: starting', name: 'DataProvider');
    final result = await repository.loadData();
    developer.log('initialize: loadData status=${result.status}, dataKeys=${result.data?.records.keys.toList()}', name: 'DataProvider');
    _lastStatus = result.status;

    if (result.status == LoadResultStatus.firstTime) {
      _data = AppData(
        startYearMonth: AppDateUtils.getCurrentYearMonth(),
        records: {},
      );
      developer.log('initialize: created new data', name: 'DataProvider');
      await repository.saveData(_data!);
    } else if (result.status == LoadResultStatus.success) {
      _data = result.data;
      developer.log('initialize: loaded existing data, records=${_data!.records.keys.toList()}', name: 'DataProvider');
    } else {
      _errorMessage = result.errorMessage;
      developer.log('initialize: load failed, error=$_errorMessage', name: 'DataProvider');
    }

    // ファイル名を取得
    _currentFileName = await repository.getFileName();
    developer.log('initialize: fileName=$_currentFileName', name: 'DataProvider');

    _isInitialized = true;
    notifyListeners();
  }

  // --- 4. バックアップから復元する ---
  Future<bool> restoreFromInternalBackup() async {
    final result = await repository.loadDataFromBackup();

    if (result.status == LoadResultStatus.success) {
      _data = result.data;
      await repository.saveData(_data!);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- データ更新ロジック ---
  Future<void> updateBalance(String yearMonth, double? balance) async {
    _ensureMonthRecord(yearMonth);
    _data?.records[yearMonth]?.balance = balance;
    developer.log('updateBalance: $yearMonth = $balance', name: 'DataProvider');
    await _saveAndNotify();
  }

  Future<void> addEvent(
    String yearMonth,
    String memo,
    double? amountHint,
    EventLabel? label,
  ) async {
    _ensureMonthRecord(yearMonth);
    _data?.records[yearMonth]?.events.add(
      Event(memo: memo, amountHint: amountHint, label: label),
    );
    developer.log('addEvent: $yearMonth memo=$memo label=$label', name: 'DataProvider');
    await _saveAndNotify();
  }

  Future<void> updateEvent(
    String yearMonth,
    String eventId,
    String memo,
    double? amountHint,
    EventLabel? label,
  ) async {
    _ensureMonthRecord(yearMonth);
    final events = _data?.records[yearMonth]?.events;
    if (events == null) {
      return;
    }

    final index = events.indexWhere((event) => event.id == eventId);
    if (index == -1) {
      return;
    }

    events[index] = Event(id: eventId, memo: memo, amountHint: amountHint, label: label);
    await _saveAndNotify();
  }

  Future<void> deleteEvent(String yearMonth, String eventId) async {
    _ensureMonthRecord(yearMonth);
    _data?.records[yearMonth]?.events.removeWhere(
      (event) => event.id == eventId,
    );
    await _saveAndNotify();
  }

  Future<void> updateStartYearMonth(String yearMonth) async {
    if (_data == null) {
      return;
    }
    _data!.startYearMonth = yearMonth;
    await _saveAndNotify();
  }

  // 内部処理
  void _ensureMonthRecord(String yearMonth) {
    _data?.records.putIfAbsent(yearMonth, () => MonthRecord(events: []));
  }

  Future<void> _saveAndNotify() async {
    if (_data == null) {
      _errorMessage = 'データが初期化されていません。';
      notifyListeners();
      return;
    }

    developer.log('_saveAndNotify: records=${_data!.records.keys.toList()}, startYearMonth=${_data!.startYearMonth}', name: 'DataProvider');

    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(_data!.toJson());
      developer.log('_saveAndNotify: JSON length=${jsonStr.length}', name: 'DataProvider');
      await repository.saveData(_data!);
      developer.log('_saveAndNotify: saveData success', name: 'DataProvider');
      _errorMessage = null;
      notifyListeners();
    } catch (e, stack) {
      developer.log('_saveAndNotify: saveData failed: $e', name: 'DataProvider', error: e, stackTrace: stack);
      _errorMessage = 'データの保存に失敗しました: ${e.toString()}';
      notifyListeners();
    }
  }

  // --- インポート機能 ---
  Future<bool> importData() async {
    try {
      final success = await repository.openFile();
      if (!success) {
        return false;
      }

      final result = await repository.loadData();
      if (result.status == LoadResultStatus.success) {
        _data = result.data;
        _isStorageSelected = true;
        _isInitialized = true;
        _lastStatus = LoadResultStatus.success;
        _errorMessage = null;
        _currentFileName = await repository.getFileName();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
