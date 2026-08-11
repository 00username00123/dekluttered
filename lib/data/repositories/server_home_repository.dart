import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/pagebookdto.dart';
import 'package:klutter/data/models/pageseriesdto.dart';
import 'package:klutter/data/models/seriesdto.dart';

class ServerHomeRepository {
  ApiClient apiClient = ApiClient();

  Future<List<BookDto>> getKeepReading() async {
    final PageBookDto page = await apiClient.bookController.getBooks(
      unpaged: true,
    );
    final books = (page.content ?? <BookDto>[])
        .where((book) =>
            book.readProgress != null &&
            !book.readProgress!.completed &&
            book.readProgress!.page > 0 &&
            book.readProgress!.page < book.media.pagesCount)
        .toList();

    books.sort((a, b) =>
        b.readProgress!.lastModified.compareTo(a.readProgress!.lastModified));
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
