import 'dart:js_interop';

@JS('loadMainFile')
external JSPromise<JSString> _loadMainFile();

@JS('saveMainFile')
external JSPromise<JSString> _saveMainFile(String content);

@JS('getFileHandleName')
external JSPromise<JSString> _getFileHandleName();

@JS('hasStoredHandle')
external JSPromise<JSBoolean> _hasStoredHandle();

@JS('openFile')
external JSPromise<JSString> _openFile();

@JS('createFile')
external JSPromise<JSString> _createFile();

Future<String> callLoadMainFile() async {
  final JSString result = await _loadMainFile().toDart;
  return result.toDart;
}

Future<String> callSaveMainFile(String content) async {
  final JSString result = await _saveMainFile(content).toDart;
  return result.toDart;
}

Future<bool> callHasStoredHandle() async {
  final JSBoolean result = await _hasStoredHandle().toDart;
  return result.toDart;
}

Future<String> callGetFileHandleName() async {
  final JSString result = await _getFileHandleName().toDart;
  return result.toDart;
}

Future<String> callOpenFile() async {
  final JSString result = await _openFile().toDart;
  return result.toDart;
}

Future<String> callCreateFile() async {
  final JSString result = await _createFile().toDart;
  return result.toDart;
}
