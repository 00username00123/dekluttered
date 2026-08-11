import 'package:dio/dio.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/pagebookdto.dart';
import 'package:klutter/data/models/pageseriesdto.dart';
import 'package:klutter/data/models/seriesdto.dart';

class ServerHomeRepository {
  ApiClient apiClient = ApiClient();

  Future<List<BookDto>> getKeepReading() async {
    List<BookDto> books = <BookDto>[];

    try {
      final Response response = await apiClient.dio.post(
        '/api/v1/books/list',
        data: {
          'condition': {
            'readStatus': {'operator': 'is', 'value': 'IN_PROGRESS'}
          }
        },
        queryParameters: {'unpaged': true},
      );
      final PageBookDto page =
          PageBookDto.fromJson(Map<String, dynamic>.from(response.data));
      books = page.content ?? <BookDto>[];
    } catch (_) {
      // Fall through to a broad query below. This keeps Keep Reading working
      // on Komga builds with slightly different search-condition handling.
    }

    if (books.isEmpty) {
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
        return <BookDto>[];
      }
    }

    final List<BookDto> inProgress = books
        .where((book) =>
            book.readProgress != null &&
            !book.readProgress!.completed &&
            book.readProgress!.page >= 0 &&
            book.readProgress!.page < book.media.pagesCount)
        .toList();

    inProgress.sort((a, b) =>
        b.readProgress!.lastModified.compareTo(a.readProgress!.lastModified));
    return inProgress;
  }

  Future<List<BookDto>> getOndeck() async {
    final PageBookDto ondeckPage = await apiClient.bookController.getOnDeck();
    return ondeckPage.content ?? <BookDto>[];
  }

  Future<List<SeriesDto>> getRecentlyaddedSeries() async {
    final PageSeriesDto recentlyaddedSeries =
        await apiClient.seriesController.getNew();
    return recentlyaddedSeries.content ?? <SeriesDto>[];
  }

  Future<List<SeriesDto>> getRecentlyupdatedSeries() async {
    final PageSeriesDto recentlyupdatedSeries =
        await apiClient.seriesController.getUpdated();
    return recentlyupdatedSeries.content ?? <SeriesDto>[];
  }

  Future<List<BookDto>> getRecentlyaddedBooks() async {
    final PageBookDto recentlyaddedBooks =
        await apiClient.bookController.getBooks(sort: ["createdDate,desc"]);
    return recentlyaddedBooks.content ?? <BookDto>[];
  }
}
