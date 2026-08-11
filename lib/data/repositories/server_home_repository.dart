import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/pagebookdto.dart';
import 'package:klutter/data/models/pageseriesdto.dart';
import 'package:klutter/data/models/seriesdto.dart';

class ServerHomeRepository {
  ApiClient apiClient = ApiClient();

  Future<List<BookDto>> getKeepReading() async {
    final PageBookDto keepReadingBooks = await apiClient.bookController.getBooks(
      readStatus: ["IN_PROGRESS"],
      size: 100,
    );
    final books = keepReadingBooks.content ?? <BookDto>[];
    books.sort((a, b) {
      final aDate = a.readProgress?.lastModified;
      final bDate = b.readProgress?.lastModified;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return books;
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
