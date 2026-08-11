import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klutter/data/models/server.dart';

enum LibraryReadingDirection { leftToRight, rightToLeft }

class LibraryReadingSettings {
  static final LibraryReadingSettings instance = LibraryReadingSettings._();
  static final Map<String, LibraryReadingDirection> _memory =
      <String, LibraryReadingDirection>{};

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  LibraryReadingSettings._();

  factory LibraryReadingSettings() => instance;

  Future<String> _key(String libraryId) async {
    final serverJson = await _storage.read(key: 'Current Server');
    if (serverJson == null || serverJson.isEmpty) {
      return 'library-reading-direction:$libraryId';
    }
    try {
      final server = Server.fromJson(jsonDecode(serverJson));
      return 'library-reading-direction:${server.key}:$libraryId';
    } catch (_) {
      return 'library-reading-direction:$libraryId';
    }
  }

  Future<LibraryReadingDirection> getDirection(String libraryId) async {
    final key = await _key(libraryId);
    final cached = _memory[key];
    if (cached != null) return cached;

    final value = await _storage.read(key: key);
    final direction = value == 'rtl'
        ? LibraryReadingDirection.rightToLeft
        : LibraryReadingDirection.leftToRight;
    _memory[key] = direction;
    return direction;
  }

  Future<void> setDirection(
      String libraryId, LibraryReadingDirection direction) async {
    final key = await _key(libraryId);
    // Update memory first so a Reader opened immediately after tapping the
    // toggle sees the new value even before secure storage finishes writing.
    _memory[key] = direction;
    await _storage.write(
      key: key,
      value: direction == LibraryReadingDirection.rightToLeft ? 'rtl' : 'ltr',
    );
  }
}
