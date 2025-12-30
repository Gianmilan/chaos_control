import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _boxName = "remindersBox";
  static const String _keyName = "encriptionKey";

  static Future<void> init() async {
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    String? base64Key = await secureStorage.read(key: _keyName);

    if (base64Key == null) {
      final key = Hive.generateSecureKey();

      await secureStorage.write(key: _keyName, value: base64.encode(key));
      base64Key = base64.encode(key);
    }

    final encryptionKey = base64.decode(base64Key);

    await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  static Box getRemindersBox() {
    return Hive.box(_boxName);
  }

  static Map<String, dynamic> getAllReminders() {
    final box = getRemindersBox();

    return Map<String, dynamic>.from(box.toMap());
  }

  static Future<void> addAllReminders(Map<String, dynamic> incomingData) async {
    final box = getRemindersBox();

    for (var dateKey in incomingData.keys) {
      final List<dynamic> localData = box.get(dateKey) ?? [];
      final List<dynamic> remoteData = incomingData[dateKey] ?? [];

      final combined = [...localData, ...remoteData];

      final seen = <String>{};
      final uniqueReminders = combined.where((reminder) {
        final fingerprint =
            "${reminder['title']}-${reminder['hour']}-${reminder['minute']}";
        return seen.add(fingerprint);
      }).toList();

      await box.put(dateKey, uniqueReminders);
    }
  }

  static Future<void> addReminder(String task) async {
    final box = getRemindersBox();

    await box.add({
      "task": task,
      "createdAt": DateTime.now().toIso8601String(),
    });
  }
}
