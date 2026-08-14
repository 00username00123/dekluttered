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
    // Prefer Dekluttered's own history. It is written on every page turn and
    // makes this section instant and resilient once a book has been opened in
    // a build containing the local-history implementation.
    final local = await readingHistory.getBooks();
    if (local.isNotEmpty) return local.take(20).toList();

    // Do NOT rely on Komga's readStatus search here. Some Komga versions return
    // an empty result for that condition even though normal BookDto responses
    // contain valid readProgress objects. Fetch the catalog and determine
    // in-progress state from readProgress ourselves.
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
      // Older Komga compatibility fallback.
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

    final List<BookDto> inProgress = books
        .where((book) =>
            book.readProgress != null && !book.readProgress!.completed)
        .toList();

    inProgress.sort((a, b) =>
        b.readProgress!.lastModified.compareTo(a.readProgress!.lastModified));

    return inProgress.take(20).toList();
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
