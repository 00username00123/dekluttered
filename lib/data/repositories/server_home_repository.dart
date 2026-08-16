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
    // Keep Reading is intentionally local-history driven. Do not scan the
    // complete Komga catalog here: that can monopolize the connection and make
    // every other Home section appear to hang on large libraries.
    final entries = (await readingHistory.getEntries()).take(20).toList();
    if (entries.isEmpty) return <BookDto>[];

    // Resolve the small local history set in parallel so the section uses fresh
    // BookDto objects without serializing whole books into the history store.
    final resolved = await Future.wait(entries.map((entry) async {
      try {
        final String id = entry['bookId'].toString();
        if (id.isEmpty) return null;
        return await apiClient.bookController.getBook(id);
      } catch (_) {
        return null;
      }
    }));

    final books = <BookDto>[];
    for (final book in resolved) {
      if (book != null) books.add(book);
    }
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
