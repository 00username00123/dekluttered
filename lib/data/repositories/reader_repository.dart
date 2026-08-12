import 'dart:math' as math;

import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/readprogressupdatedto.dart';
import 'package:klutter/data/repositories/library_reading_settings.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/data/repositories/reading_history_repository.dart';
import 'package:klutter/data/repositories/temporary_page_cache.dart';

class ReaderRepository {
  final ApiClient apiClient = ApiClient();
  final OfflineLibrary offlineLibrary = OfflineLibrary();
  final TemporaryPageCache temporaryPageCache = TemporaryPageCache();
  final LibraryReadingSettings readingSettings = LibraryReadingSettings();
  final ReadingHistoryRepository readingHistory = ReadingHistoryRepository();
  final BookDto book;
  ReaderRepository(this.book);
  Map<int, List<int>> pageMap = Map<int, List<int>>();
  int _cacheGeneration = 0;

  int _clampPage(int pageNumber) {
    final int maxPage = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    if (pageNumber < 1) return 1;
    if (pageNumber > maxPage) return maxPage;
    return pageNumber;
  }

  Future<void> cacheAround(int pageNumber) async {
    final int generation = ++_cacheGeneration;
    final int pageCount = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    final int center = _clampPage(pageNumber);
    final LibraryReadingDirection direction =
        await readingSettings.getDirection(book.libraryId);
    if (generation != _cacheGeneration) return;
    final bool isRtl = direction == LibraryReadingDirection.rightToLeft;

    final int targetCount =
        math.min(pageCount, math.max(8, (pageCount * 0.20).ceil()));
    final int surrounding = targetCount - 1;

    int forward = surrounding == 0
        ? 0
        : (surrounding * (isRtl ? 2 : 5) / 7).round();
    int back = surrounding - forward;

    int firstToKeep = center - back;
    int lastToKeep = center + forward;

    if (firstToKeep < 1) {
      lastToKeep += 1 - firstToKeep;
      firstToKeep = 1;
    }
    if (lastToKeep > pageCount) {
      firstToKeep -= lastToKeep - pageCount;
      lastToKeep = pageCount;
    }
    if (firstToKeep < 1) firstToKeep = 1;

    pageMap.removeWhere(
        (page, image) => page < firstToKeep || page > lastToKeep);

    final List<int> missing = <int>[];
    for (int i = firstToKeep; i <= lastToKeep; i++) {
      if (!pageMap.containsKey(i)) missing.add(i);
    }

    missing.sort((a, b) => (a - center).abs().compareTo((b - center).abs()));

    const int batchSize = 4;
    for (int start = 0; start < missing.length; start += batchSize) {
      if (generation != _cacheGeneration) return;
      final int end = math.min(start + batchSize, missing.length);
      await Future.wait(missing.sublist(start, end).map((page) async {
        if (generation != _cacheGeneration) return;
        try {
          pageMap[page] = await getPageImage(page);
        } on Exception catch (_) {
          // Prefetch failures should never crash or delay the active page.
        }
      }));
    }
  }

  Future<List<int>> getPageImage(int pageNumber) async {
    final int safePage = _clampPage(pageNumber);
    if (pageMap.containsKey(safePage)) {
      return pageMap[safePage]!;
    }

    final List<int>? downloaded =
        await offlineLibrary.getLocalPage(book.id, safePage);
    if (downloaded != null && downloaded.isNotEmpty) {
      pageMap[safePage] = downloaded;
      return downloaded;
    }

    final List<int>? cached =
        await temporaryPageCache.getPage(book.id, safePage);
    if (cached != null && cached.isNotEmpty) {
      pageMap[safePage] = cached;
      return cached;
    }

    final List<int> image =
        await apiClient.bookController.getPage(book.id, safePage);
    pageMap[safePage] = image;

    temporaryPageCache.putPage(book.id, safePage, image);
    return image;
  }

  Future<void> updateReadPage(int pageNumber) async {
    final int safePage = _clampPage(pageNumber);
    final int komgaPage = safePage - 1;
    final bool completed = safePage >= book.media.pagesCount;

    // Do not make page navigation wait for filesystem or network progress
    // bookkeeping. ReadingHistoryRepository serializes its own writes, so these
    // calls remain ordered even when the user flips pages quickly.
    readingHistory
        .record(book, safePage, completed: completed)
        .catchError((_) {});
    apiClient.bookController
        .markAsRead(
          book.id,
          ReadProgressUpdateDto(page: komgaPage, completed: completed),
        )
        .catchError((_) {});
  }

  Future<BookDto> getNextBook() async {
    return await apiClient.bookController.getNextBook(book.id);
  }

  Future<BookDto> getPrevBook() async {
    return await apiClient.bookController.getPreviousBook(book.id);
  }
}
