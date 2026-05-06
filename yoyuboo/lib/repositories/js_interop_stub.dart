// Android / iOS / Desktop では kIsWeb=false のため実際には呼ばれない。
// 条件付きimportの型解決のためだけに存在する。

Future<String> callLoadMainFile() => throw UnsupportedError('Web only');

Future<String> callSaveMainFile(String content) =>
    throw UnsupportedError('Web only');

Future<bool> callHasStoredHandle() => throw UnsupportedError('Web only');

Future<String> callGetFileHandleName() => throw UnsupportedError('Web only');

Future<String> callOpenFile() => throw UnsupportedError('Web only');

Future<String> callCreateFile() => throw UnsupportedError('Web only');

Future<String> callRestoreFile() => throw UnsupportedError('Web only');
