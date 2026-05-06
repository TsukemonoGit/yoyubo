/*
「外部のメインパス」と「内部のバックアップパス」の2つを持つ構成

メイン（普段使い）: ユーザーが指定したフォルダ（Googleドライブ等）のファイルを直接読み書きする。

バックアップ: メインのファイルがある場所ではなく、「アプリしか見ることができない内部領域」へ、保存のたびにこっそりコピーを隠しておく。

設定画面に「アプリ内のバックアップから復元」というボタンを用意して、バックアップから復元できるようにする
*/

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'js_interop_stub.dart'
    if (dart.library.js_interop) 'js_interop_web.dart';
import '../models/data.dart';

// --- 報告書の定義 ---
enum LoadResultStatus { success, firstTime, failure }

class LoadResult {
  final LoadResultStatus status;
  final AppData? data;
  final String? errorMessage;

  LoadResult({required this.status, this.data, this.errorMessage});
}

// --- MethodChannel ---
const _channel = MethodChannel('com.example.yoyuboo/file');

// --- 実務担当（Repository） ---
class DataRepository {
  bool get _canUseNativeFileChannel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // ファイルを選択させてURIを取得する
  // 戻り値: true=選択完了, false=キャンセル or 失敗
  Future<bool> openFile() async {
    if (kIsWeb) {
      final result = await callOpenFile();
      return result == 'success';
    }
    if (!_canUseNativeFileChannel) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openFile');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> createFile() async {
    if (kIsWeb) {
      final result = await callCreateFile();
      return result == 'success';
    }
    if (!_canUseNativeFileChannel) return false;
    try {
      final result = await _channel.invokeMethod<bool>('createFile');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // 前回開いたファイルを開く
  Future<bool> restoreFile() async {
    if (kIsWeb) {
      final result = await callRestoreFile();
      return result == 'success';
    }
    // Webのみ対応（Androidは未対応）
    return false;
  }

  // 前回のファイルURIが保存されているか確認する
  Future<bool> hasStoredFile() async {
    if (kIsWeb) {
      // Web: File System Access APIのHandleがIndexedDBに保存済みか確認
      final result = await callHasStoredHandle();
      return result;
    }
    if (!_canUseNativeFileChannel) return false;
    try {
      final result = await _channel.invokeMethod<bool>('hasStoredUri');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // 1. データの読み込み
  Future<LoadResult> loadData() async {
    if (kIsWeb) {
      final result = await callLoadMainFile();
      if (result.startsWith('error:') || result.trim().isEmpty) {
        return LoadResult(status: LoadResultStatus.firstTime);
      }
      try {
        return LoadResult(
          status: LoadResultStatus.success,
          data: AppData.fromJson(jsonDecode(result)),
        );
      } catch (e) {
        return LoadResult(
          status: LoadResultStatus.failure,
          errorMessage: e.toString(),
        );
      }
    }

    if (!_canUseNativeFileChannel) {
      return LoadResult(status: LoadResultStatus.firstTime);
    }

    // Android
    try {
      final jsonString = await _channel.invokeMethod<String>('readFile');
      if (jsonString == null) {
        return LoadResult(status: LoadResultStatus.firstTime);
      }
      return LoadResult(
        status: LoadResultStatus.success,
        data: AppData.fromJson(jsonDecode(jsonString)),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NO_URI') {
        return LoadResult(status: LoadResultStatus.firstTime);
      }
      return LoadResult(
        status: LoadResultStatus.failure,
        errorMessage: e.message,
      );
    } on MissingPluginException {
      return LoadResult(status: LoadResultStatus.firstTime);
    } catch (e) {
      return LoadResult(
        status: LoadResultStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  // 2. データの保存
  Future<void> saveData(AppData data) async {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(data.toJson());

    developer.log(
      'DataRepository.saveData: kIsWeb=$kIsWeb, jsonLength=${jsonString.length}',
      name: 'DataRepository',
    );
    developer.log(
      'DataRepository.saveData: json=${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...',
      name: 'DataRepository',
    );

    if (kIsWeb) {
      final result = await callSaveMainFile(jsonString);
      developer.log(
        'DataRepository.saveData: web result=$result',
        name: 'DataRepository',
      );
      if (result != 'success') {
        throw Exception('Failed to save file: $result');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup', jsonString);
      return;
    }

    if (!_canUseNativeFileChannel) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup', jsonString);
      return;
    }

    // Android
    try {
      developer.log(
        'DataRepository.saveData: calling writeFile via MethodChannel',
        name: 'DataRepository',
      );
      await _channel.invokeMethod('writeFile', {'content': jsonString});
      developer.log(
        'DataRepository.saveData: writeFile success',
        name: 'DataRepository',
      );
    } on PlatformException catch (e) {
      developer.log(
        'DataRepository.saveData: writeFile failed: ${e.code} - ${e.message}',
        name: 'DataRepository',
      );
      throw Exception('Failed to save file: ${e.message}');
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup', jsonString);
    }
  }

  // ファイル名を取得する
  Future<String?> getFileName() async {
    if (kIsWeb) {
      final result = await callGetFileHandleName();
      if (result.startsWith('error:')) {
        return null;
      }
      return result;
    }
    // Web以外では未対応
    return null;
  }

  // 内部バックアップから読み込む（設定画面の「バックアップから復元」）
  Future<LoadResult> loadDataFromBackup() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString('backup');
      if (backupJson == null) {
        return LoadResult(status: LoadResultStatus.failure);
      }
      try {
        return LoadResult(
          status: LoadResultStatus.success,
          data: AppData.fromJson(jsonDecode(backupJson)),
        );
      } catch (e) {
        return LoadResult(
          status: LoadResultStatus.failure,
          errorMessage: e.toString(),
        );
      }
    }

    // Mobile/Desktop: 内部ストレージのSharedPreferencesから読み込む
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('backup');
      if (jsonString == null) {
        return LoadResult(status: LoadResultStatus.failure);
      }
      return LoadResult(
        status: LoadResultStatus.success,
        data: AppData.fromJson(jsonDecode(jsonString)),
      );
    } on Exception catch (e) {
      return LoadResult(
        status: LoadResultStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }
}
