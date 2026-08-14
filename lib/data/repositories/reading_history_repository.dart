import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/server.dart';
import 'package:path_provider/path_provider.dart';

class ReadingHistoryRepository {
  static final ReadingHistoryRepository instance = ReadingHistoryRepository._();
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  Future<void> _writeChain = Future<void>.value();

  ReadingHistoryRepository._();

  factory ReadingHistoryRepository() => instance;

  Future<String> _serverKey() async {
    final value = await _storage.read(key: 'Current Server');
    if (value == null || value.isEmpty) return 'default';
    try {
      return Server.fromJson(jsonDecode(value)).key;
    } catch (_) {
      return 'default';
    }
  }

  Future<File> _historyFile() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/reading-history');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${await _serverKey()}.json');
  }

  Future<List<Map<String, dynamic>>> _readEntries() async {
    try {
      final file = await _historyFile();
      if (!await file.exists()) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<BookDto>> getBooks() async {
    final entries = await _readEntries();
    entries.sort((a, b) =>
        (b['lastRead'] ?? '').toString().compareTo((a['lastRead'] ?? '').toString()));

    final books = <BookDto>[];
    for (final entry in entries) {
      try {
        final bookJson = Map<String, dynamic>.from(entry['book'] as Map);
        final progress = bookJson['readProgress'];
        if (progress is Map && progress['completed'] == true) continue;
        books.add(BookDto.fromJson(bookJson));
      } catch (_) {}
    }
    return books;
  }

  Future<void> record(BookDto book, int uiPage, {required bool completed}) async {
    _writeChain = _writeChain.then((_) async {
      final entries = await _readEntries();
      entries.removeWhere((entry) => entry['bookId'] == book.id);

      if (!completed) {
        final now = DateTime.now();
        final bookJson = Map<String, dynamic>.from(book.toJson());
        bookJson['readProgress'] = <String, dynamic>{
          'page': uiPage > 0 ? uiPage - 1 : 0,
          'completed': false,
          'created': book.readProgress?.created.toIso8601String() ?? now.toIso8601String(),
          'lastModified': now.toIso8601String(),
        };
        entries.insert(0, <String, dynamic>{
          'bookId': book.id,
          'lastRead': now.toIso8601String(),
          'book': bookJson,
        });
      }

      if (entries.length > 50) entries.removeRange(50, entries.length);
      final file = await _historyFile();
      await file.writeAsString(jsonEncode(entries), flush: false);
      revision.value++;
    });
    await _writeChain;
  }
}
