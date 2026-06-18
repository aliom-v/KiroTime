import 'package:isar/isar.dart';

import 'string_id_hash.dart';

part 'app_setting_record.g.dart';

@collection
class AppSettingRecord {
  @Index(unique: true, replace: true)
  late String key;

  Id get isarId => stableStringIdHash(key);

  late String value;

  AppSettingRecord();

  factory AppSettingRecord.create({
    required String key,
    required String value,
  }) {
    return AppSettingRecord()
      ..key = key
      ..value = value;
  }
}
