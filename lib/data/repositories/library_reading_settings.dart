import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klutter/data/models/server.dart';

enum LibraryReadingDirection { leftToRight, rightToLeft }

class LibraryReadingSettings {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

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
    final value = await _storage.read(key: await _key(libraryId));
    if (value == 'rtl') return LibraryReadingDirection.rightToLeft;
    return LibraryReadingDirection.leftToRight;
  }

  Future<void> setDirection(
      String libraryId, LibraryReadingDirection direction) async {
    await _storage.write(
      key: await _key(libraryId),
      value: direction == LibraryReadingDirection.rightToLeft ? 'rtl' : 'ltr',
    );
  }
}
