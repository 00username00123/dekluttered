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
    // New implementation: paint local reading history first. This is updated
    // on every page turn and does not depend on Komga being fast or reachable.
    final local = await readingHistory.getBooks();
    if (local.isNotEmpty) return local.take(20).toList();

    // First-run/server-migration fallback: seed the section from Komga if local
    // history does not exist yet. Once the user reads in Dekluttered, the local
    // history path above becomes authoritative and instant.
    List<BookDto> books = <BookDto>[];
    try {
      final Response response = await apiClient.dio.post(
        '/api/v1/books/list',
        data: {
          'condition': {
            'readStatus': {'operator': 'is', 'value': 'IN_PROGRESS'}
          }
        },
        queryParameters: {'page': 0, 'size': 20},
      );
      final PageBookDto page =
          PageBookDto.fromJson(Map<String, dynamic>.from(response.data));
      books = page.content ?? <BookDto>[];
    } catch (_) {
      try {
        final Response response = await apiClient.dio.get(
          '/api/v1/books',
          queryParameters: {
            'read_status': 'IN_PROGRESS',
            'page': 0,
            'size': 20,
          },
        );
        final PageBookDto page =
            PageBookDto.fromJson(Map<String, dynamic>.from(response.data));
        books = page.content ?? <BookDto>[];
      } catch (_) {
        return <BookDto>[];
      }
    }

    books.removeWhere(
        (book) => book.readProgress == null || book.readProgress!.completed);
    books.sort((a, b) =>
        b.readProgress!.lastModified.compareTo(a.readProgress!.lastModified));
    return books;
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
