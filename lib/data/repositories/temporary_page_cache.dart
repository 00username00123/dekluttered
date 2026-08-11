import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klutter/data/models/server.dart';
import 'package:path_provider/path_provider.dart';

class TemporaryPageCache {
  static const Duration maxAge = Duration(days: 7);
  static const int maxBytes = 750 * 1024 * 1024;

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _cleanupStarted = false;

  Future<Server> _currentServer() async {
    final value = await _storage.read(key: 'Current Server');
    if (value == null || value.isEmpty) {
      throw StateError('No current server is selected');
    }
    return Server.fromJson(jsonDecode(value));
  }

  Future<Directory> _serverRoot() async {
    final temp = await getTemporaryDirectory();
    final server = await _currentServer();
    return Directory('${temp.path}/dekluttered-page-cache/${server.key}');
  }

  Future<File> _pageFile(String bookId, int pageNumber) async {
    final root = await _serverRoot();
    return File('${root.path}/$bookId/$pageNumber.page');
  }

  Future<List<int>?> getPage(String bookId, int pageNumber) async {
    _scheduleCleanup();
    try {
      final file = await _pageFile(bookId, pageNumber);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) > maxAge) {
        await file.delete();
        return null;
      }

      // Touch the file so recently-read pages survive LRU cleanup.
      await file.setLastModified(DateTime.now());
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> putPage(
      String bookId, int pageNumber, List<int> bytes) async {
    if (bytes.isEmpty) return;
    _scheduleCleanup();
    try {
      final file = await _pageFile(bookId, pageNumber);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: false);
    } catch (_) {
      // Cache writes are best-effort and must never interrupt reading.
    }
  }

  void _scheduleCleanup() {
    if (_cleanupStarted) return;
    _cleanupStarted = true;
    Future<void>(() async {
      try {
        await cleanup();
      } finally {
        _cleanupStarted = false;
      }
    });
  }

  Future<void> cleanup() async {
    Directory root;
    try {
      root = await _serverRoot();
    } catch (_) {
      return;
    }
    if (!await root.exists()) return;

    final now = DateTime.now();
    final files = <FileSystemEntity>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) files.add(entity);
    }

    int totalBytes = 0;
    final liveFiles = <File>[];
    for (final entity in files) {
      final file = entity as File;
      try {
        final stat = await file.stat();
        if (now.difference(stat.modified) > maxAge) {
          await file.delete();
          continue;
        }
        totalBytes += stat.size;
        liveFiles.add(file);
      } catch (_) {}
    }

    if (totalBytes <= maxBytes) return;

    liveFiles.sort((a, b) {
      try {
        return a.lastModifiedSync().compareTo(b.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });

    for (final file in liveFiles) {
      if (totalBytes <= maxBytes) break;
      try {
        final size = await file.length();
        await file.delete();
        totalBytes -= size;
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    try {
      final root = await _serverRoot();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
  }
}
