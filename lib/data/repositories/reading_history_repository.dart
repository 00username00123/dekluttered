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
  final Map<String, List<Map<String, dynamic>>> _memory =
      <String, List<Map<String, dynamic>>>{};
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

  Future<File> _historyFileFor(String serverKey) async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/reading-history-v2');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$serverKey.json');
  }

  List<Map<String, dynamic>> _copyEntries(
      List<Map<String, dynamic>> entries) {
    return entries.map((entry) => Map<String, dynamic>.from(entry)).toList();
  }

  Future<List<Map<String, dynamic>>> getEntries() async {
    final serverKey = await _serverKey();
    final memoryEntries = _memory[serverKey];
    if (memoryEntries != null && memoryEntries.isNotEmpty) {
      return _copyEntries(memoryEntries);
    }

    try {
      final file = await _historyFileFor(serverKey);
      if (!await file.exists()) return <Map<String, dynamic>>[];
      final dynamic decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return <Map<String, dynamic>>[];

      final entries = decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .where((entry) => entry['bookId'] is String)
          .toList();

      entries.sort((a, b) => (b['lastRead'] ?? '')
          .toString()
          .compareTo((a['lastRead'] ?? '').toString()));
      _memory[serverKey] = _copyEntries(entries);
      return entries;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> replaceFromBooks(List<BookDto> books) async {
    final serverKey = await _serverKey();
    final entries = <Map<String, dynamic>>[];

    for (final book in books) {
      final progress = book.readProgress;
      if (progress == null || progress.completed) continue;
      entries.add(<String, dynamic>{
        'bookId': book.id,
        'page': progress.page,
        'lastRead': progress.lastModified.toIso8601String(),
      });
    }

    entries.sort((a, b) => (b['lastRead'] ?? '')
        .toString()
        .compareTo((a['lastRead'] ?? '').toString()));
    if (entries.length > 50) entries.removeRange(50, entries.length);

    _memory[serverKey] = _copyEntries(entries);
    revision.value++;

    try {
      final file = await _historyFileFor(serverKey);
      await file.writeAsString(jsonEncode(entries), flush: false);
    } catch (_) {}
  }

  Future<void> record(BookDto book, int uiPage, {required bool completed}) async {
    _writeChain = _writeChain.then((_) async {
      final serverKey = await _serverKey();
      final entries = await getEntries();
      entries.removeWhere((entry) => entry['bookId'] == book.id);

      if (!completed) {
        entries.insert(0, <String, dynamic>{
          'bookId': book.id,
          'page': uiPage > 0 ? uiPage - 1 : 0,
          'lastRead': DateTime.now().toIso8601String(),
        });
      }

      if (entries.length > 50) entries.removeRange(50, entries.length);

      // Update memory before touching disk so the UI can refresh immediately.
      _memory[serverKey] = _copyEntries(entries);
      revision.value++;

      try {
        final file = await _historyFileFor(serverKey);
        await file.writeAsString(jsonEncode(entries), flush: false);
      } catch (_) {
        // Disk persistence is best-effort; the in-memory history still works.
      }
    });
    await _writeChain;
  }
}
