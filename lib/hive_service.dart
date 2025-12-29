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

  static Future<void> addReminder(String task) async {
    final box = getRemindersBox();

    await box.add({
      "task": task,
      "createdAt": DateTime.now().toIso8601String(),
    });
  }
}
