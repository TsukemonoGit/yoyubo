/* 1. 
家計簿アプリにとって、画面のデザインよりも重要なのは「データがどういう形で存在し、どう保存されるか」です。
ここがブレると、後で画面を作るときにすべて作り直しになってしまいます。
「アプリの骨組み」を確定させるために、最初にclassを作ります。

JSON⇔オブジェクト型

起動時: ファイルからJSONを読み込む → AppData.fromJson を通して、アプリ内で扱える形にする。

入力時: 新しい Event を作って、特定の月の MonthRecord の events リストに追加する。

保存時: AppData.toJson を実行してJSON文字列に戻す → ファイルに上書き保存する。

まとめ
このコードを書くことで、**「Yoyubooというアプリが扱う世界のルール」**が定義されました。

「月」をキーにしてデータを探せる。

「残高」は空でもいい。

「メモ」には自動でIDがつく。

次は、この「ルール」に基づいて、実際にスマホの画面にデータを表示したり、ファイルとして保存したりする処理（ControllerやServiceと呼ばれる部分）に進む準備が整いました。

次のステップ：データの「読み書き」と「管理」
骨組み（Model）ができたので、次は以下の2つを実装することになります。

Repository（レポジトリ）: JSONファイルを実際にスマホのストレージに保存したり、読み込んだりする「倉庫番」の役割。

State Management（状態管理）: アプリを動かしている間、この AppData をメモリ上に保持し、画面からの入力（メモ追加など）に応じて中身を書き換える「司令塔」の役割。

まずは「レポジトリ」から手をつけるのが、データの永続化（アプリを閉じても消えない状態）を保証できるためスムーズです。

*/

import 'dart:ui';

import 'package:uuid/uuid.dart';

class AppData {
  String startYearMonth; //いつからこのアプリを使い始めたか
  Map<String, MonthRecord> records; //月ごとのデータをMap（辞書型）で持っています。
  //key: "2024-04" という文字列
  //value: その月の詳細データ（MonthRecord）

  AppData({required this.startYearMonth, required this.records});

  // JSONから生成
  factory AppData.fromJson(Map<String, dynamic> json) {
    final recordsMap = (json['records'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, MonthRecord.fromJson(value)),
    );
    return AppData(startYearMonth: json['startYearMonth'], records: recordsMap);
  }

  // JSONへ変換
  Map<String, dynamic> toJson() => {
    'startYearMonth': startYearMonth,
    'records': records.map((key, value) => MapEntry(key, value.toJson())),
  };
}

// 月の詳細
class MonthRecord {
  double? balance; // 月末の残高 万円単位（小数/null許容）
  List<Event> events; //その月に登録した「出来事メモ」のリスト

  MonthRecord({this.balance, required this.events});

  factory MonthRecord.fromJson(Map<String, dynamic> json) {
    return MonthRecord(
      balance: (json['balance'] as num?)
          ?.toDouble(), //JSONでは、100（整数）と 100.5（小数）が混ざることがあります。Dartでは int と double は厳格に区別されるため、どちらが来ても大丈夫なように一度 num（数値全般）として受け取り、強制的に double（小数対応）に変換しています。
      events: (json['events'] as List).map((e) => Event.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'events': events.map((e) => e.toJson()).toList(),
  };
}

// 最小単位のメモ
class Event {
  String
  id; //UUIDという「世界で重複しないID」を自動で振ります。これにより、メモを編集したり削除したりするときに「どのメモか」を確実に特定できます。
  String memo;
  double?
  amountHint; //amountHint: 「-30万」などの数値。メモから数字を抜き出してここに入れておけば、後で計算の助けになります。
  EventLabel? label;

  Event({String? id, required this.memo, this.amountHint, this.label})
    : id = id ?? _uuidGenerator.v4(); // IDがなければ自動生成

  static final _uuidGenerator = const Uuid();

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      memo: json['memo'],
      amountHint: (json['amountHint'] as num?)?.toDouble(),
      label: json['label'] != null
          ? EventLabel.values.byName(json['label'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memo': memo,
    'amountHint': amountHint,
    if (label != null) 'label': label!.name,
  };
}

/// メモのラベル種類
enum EventLabel {
  expense('支出', Color(0xFFFF5252)),
  income('収入', Color(0xFF4CAF50)),
  transfer('移動', Color(0xFFFFC107)),
  other('その他', Color(0xFF9E9E9E));

  const EventLabel(this.displayName, this.color);
  final String displayName;
  final Color color;
}
