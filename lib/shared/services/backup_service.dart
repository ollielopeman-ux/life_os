import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  static const _boxNames = [
    'gym',
    'reading',
    'body',
    'schedule',
    'cardio',
    'plyo',
    'checklist',
    'settings',
    'interval_presets',
  ];

  static Future<void> export() async {
    final data = <String, dynamic>{};
    for (final name in _boxNames) {
      final box = Hive.box(name);
      data[name] = box.toMap().map(
        (k, v) => MapEntry(k.toString(), _toJsonable(v)),
      );
    }
    final payload = jsonEncode({'version': 1, 'boxes': data});
    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/life_os_backup_$date.json');
    await file.writeAsString(payload);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Life OS Backup $date',
    );
  }

  // Returns true if data was successfully restored, false if cancelled.
  static Future<bool> import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return false;
    final path = result.files.first.path;
    if (path == null) return false;

    final content = await File(path).readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final boxes = decoded['boxes'] as Map<String, dynamic>?;
    if (boxes == null) throw const FormatException('Invalid backup file');

    for (final name in _boxNames) {
      if (!boxes.containsKey(name)) continue;
      final box = Hive.box(name);
      await box.clear();
      final entries = (boxes[name] as Map<String, dynamic>).entries;
      for (final e in entries) {
        await box.put(e.key, e.value);
      }
    }
    return true;
  }

  static dynamic _toJsonable(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _toJsonable(val)));
    }
    if (v is List) return v.map(_toJsonable).toList();
    return v;
  }
}
