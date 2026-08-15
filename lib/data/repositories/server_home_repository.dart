import 'package:dio/dio.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/pagebookdto.dart';
import 'package:klutter/data/models/pageseriesdto.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/data/repositories/reading_history_repository.dart';

class ServerHomeRepository {
  ApiClient apiClient = ApiClient();
  final ReadingHistoryRepository readingHistory = ReadingHistoryRepository();

  Future<List<BookDto>> getKeepReading() async {
    // Keep Reading v2: history contains only stable book IDs/page/timestamp.
    // Resolve the current BookDto from Komga so old serialized DTO snapshots can
    // never make the section silently empty after an API/model change.
    final entries = await readingHistory.getEntries();
    if (entries.isNotEmpty) {
      final recent = entries.take(20).toList();
      final resolved = await Future.wait(recent.map((entry) async {
        try {
          return await apiClient.bookController
              .getBook(entry['bookId'].toString());
        } catch (_) {
          return null;
        }
      }));

      final books = <BookDto>[];
      for (final book in resolved) {
        if (book != null) books.add(book);
      }
      if (books.isNotEmpty) return books;
    }

    // Migration/bootstrap path for installs that have Komga progress but no v2
    // local history yet. Fetch normal book objects and inspect readProgress
    // locally instead of trusting readStatus search behavior.
    List<BookDto> books = <BookDto>[];
    try {
      final Response response = await apiClient.dio.post(
        '/api/v1/books/list',
        data: {
          'condition': {
            'deleted': {'operator': 'isFalse'}
          }
        },
        queryParameters: {'unpaged': true},
      );
      final PageBookDto page =
          PageBookDto.fromJson(Map<String, dynamic>.from(response.data));
      books = page.content ?? <BookDto>[];
    } catch (_) {
      try {
        final Response response = await apiClient.dio.get(
          '/api/v1/books',
          queryParameters: {'unpaged': true},
        );
        final PageBookDto page =
            PageBookDto.fromJson(Map<String, dynamic>.from(response.data));
        books = page.content ?? <BookDto>[];
      } catch (_) {
        return <BookDto>[];
      }
    }

    final inProgress = books
        .where((book) =>
            book.readProgress != null && !book.readProgress!.completed)
        .toList();
    inProgress.sort((a, b) =>
        b.readProgress!.lastModified.compareTo(a.readProgress!.lastModified));

    final result = inProgress.take(20).toList();
    if (result.isNotEmpty) {
      await readingHistory.replaceFromBooks(result);
    }
    return result;
  }

  Future<List<BookDto>> getOndeck() async {
    final PageBookDto ondeckPage =
        await apiClient.bookController.getOnDeck(page: 0, size: 20);
    return ondeckPage.content ?? <BookDto>[];
  }

  Future<List<SeriesDto>> getRecentlyaddedSeries() async {
    final PageSeriesDto recentlyaddedSeries =
        await apiClient.seriesController.getNew(page: 0, size: 20);
    return recentlyaddedSeries.content ?? <SeriesDto>[];
  }

  Future<List<SeriesDto>> getRecentlyupdatedSeries() async {
    final PageSeriesDto recentlyupdatedSeries =
        await apiClient.seriesController.getUpdated(page: 0, size: 20);
    return recentlyupdatedSeries.content ?? <SeriesDto>[];
  }

  Future<List<BookDto>> getRecentlyaddedBooks() async {
    final PageBookDto recentlyaddedBooks =
        await apiClient.bookController.getLatest(page: 0, size: 20);
    return recentlyaddedBooks.content ?? <BookDto>[];
  }
}
