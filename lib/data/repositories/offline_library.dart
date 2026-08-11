import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/server.dart';
import 'package:path_provider/path_provider.dart';

class OfflineLibrary {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Server> _currentServer() async {
    final value = await _storage.read(key: 'Current Server');
    if (value == null || value.isEmpty) {
      throw StateError('No current server is selected');
    }
    return Server.fromJson(jsonDecode(value));
  }

  Future<Directory> _serverRoot() async {
    final support = await getApplicationSupportDirectory();
    final server = await _currentServer();
    return Directory('${support.path}/offline/${server.key}');
  }

  Future<Directory> _bookRoot(String bookId) async {
    final root = await _serverRoot();
    return Directory('${root.path}/$bookId');
  }

  Future<File> _pageFile(String bookId, int pageNumber) async {
    final root = await _bookRoot(bookId);
    return File('${root.path}/pages/$pageNumber.page');
  }

  Future<bool> isBookDownloaded(String bookId) async {
    final root = await _bookRoot(bookId);
    return File('${root.path}/complete').exists();
  }

  Future<List<int>?> getLocalPage(String bookId, int pageNumber) async {
    if (!await isBookDownloaded(bookId)) return null;
    final page = await _pageFile(bookId, pageNumber);
    if (!await page.exists()) return null;
    return page.readAsBytes();
  }

  Future<File?> getLocalThumbnail(String bookId) async {
    if (!await isBookDownloaded(bookId)) return null;
    final root = await _bookRoot(bookId);
    final file = File('${root.path}/thumbnail.jpg');
    return await file.exists() ? file : null;
  }

  Future<void> downloadBook(BookDto book) async {
    final root = await _bookRoot(book.id);
    final pages = Directory('${root.path}/pages');
    await pages.create(recursive: true);

    final complete = File('${root.path}/complete');
    if (await complete.exists()) await complete.delete();

    await File('${root.path}/book.json')
        .writeAsString(jsonEncode(book.toJson()), flush: true);

    try {
      final thumbnail = await _apiClient.bookController.getThumbnail(book.id);
      await File('${root.path}/thumbnail.jpg')
          .writeAsBytes(thumbnail, flush: true);
    } catch (_) {}

    for (int pageNumber = 1;
        pageNumber <= book.media.pagesCount;
        pageNumber++) {
      final target = File('${pages.path}/$pageNumber.page');
      if (await target.exists() && await target.length() > 0) continue;
      final bytes = await _apiClient.bookController.getPage(book.id, pageNumber);
      await target.writeAsBytes(bytes, flush: true);
    }

    await complete.writeAsString('ok', flush: true);
    revision.value++;
  }

  Future<void> deleteBook(String bookId) async {
    final root = await _bookRoot(bookId);
    if (await root.exists()) await root.delete(recursive: true);
    revision.value++;
  }

  Future<List<BookDto>> _downloadedBooks() async {
    final root = await _serverRoot();
    if (!await root.exists()) return <BookDto>[];
    final result = <BookDto>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final complete = File('${entity.path}/complete');
      final metadata = File('${entity.path}/book.json');
      if (!await complete.exists() || !await metadata.exists()) continue;
      try {
        final data = jsonDecode(await metadata.readAsString());
        result.add(BookDto.fromJson(data as Map<String, dynamic>));
      } catch (_) {}
    }
    return result;
  }

  Future<List<BookDto>> getDownloadedBooks() async {
    final books = await _downloadedBooks();
    books.sort((a, b) {
      final seriesCompare = a.seriesId.compareTo(b.seriesId);
      if (seriesCompare != 0) return seriesCompare;
      return a.metadata.numberSort.compareTo(b.metadata.numberSort);
    });
    return books;
  }

  Future<bool> isSeriesDownloaded(String seriesId) async {
    final books = await _downloadedBooks();
    return books.any((book) => book.seriesId == seriesId);
  }

  Future<void> downloadSeries(String seriesId) async {
    final page = await _apiClient.seriesController.getBooksFromSeries(
      seriesId,
      unpaged: true,
      sort: <String>['metadata.numberSort,asc'],
    );
    final books = page.content ?? <BookDto>[];
    for (final book in books) {
      await downloadBook(book);
    }
  }

  Future<void> deleteSeries(String seriesId) async {
    final books = await _downloadedBooks();
    for (final book in books.where((book) => book.seriesId == seriesId)) {
      final root = await _bookRoot(book.id);
      if (await root.exists()) await root.delete(recursive: true);
    }
    revision.value++;
  }
}
