import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/readprogressupdatedto.dart';
import 'package:klutter/data/repositories/offline_library.dart';

class ReaderRepository {
  final ApiClient apiClient = ApiClient();
  final OfflineLibrary offlineLibrary = OfflineLibrary();
  final BookDto book;
  ReaderRepository(this.book);
  Map<int, List<int>> pageMap = Map<int, List<int>>();

  int _clampPage(int pageNumber) {
    final int maxPage = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    if (pageNumber < 1) return 1;
    if (pageNumber > maxPage) return maxPage;
    return pageNumber;
  }

  Future<void> cacheAround(int pageNumber) async {
    final int center = _clampPage(pageNumber);
    for (int i = center - 2; i <= center + 2; i++) {
      if (i >= 1 && i <= book.media.pagesCount) {
        if (!pageMap.containsKey(i)) {
          try {
            pageMap[i] = await getPageImage(i);
          } on Exception catch (_) {
            // Prefetch failures should never crash the active reader page.
          }
        }
      }
    }
  }

  Future<List<int>> getPageImage(int pageNumber) async {
    final int safePage = _clampPage(pageNumber);
    if (pageMap.containsKey(safePage)) {
      return pageMap[safePage]!;
    }

    final List<int>? local =
        await offlineLibrary.getLocalPage(book.id, safePage);
    if (local != null && local.isNotEmpty) {
      pageMap[safePage] = local;
      return local;
    }

    final List<int> image =
        await apiClient.bookController.getPage(book.id, safePage);
    pageMap[safePage] = image;
    return image;
  }

  Future<void> updateReadPage(int pageNumber) async {
    final int safePage = _clampPage(pageNumber);
    try {
      await apiClient.bookController
          .markAsRead(book.id, ReadProgressUpdateDto(page: safePage));
    } on Exception catch (_) {
      // Reading downloaded pages must remain usable when the server is offline.
      // A later sync queue can reconcile progress without blocking the reader.
    }
  }

  Future<BookDto> getNextBook() async {
    return await apiClient.bookController.getNextBook(book.id);
  }

  Future<BookDto> getPrevBook() async {
    return await apiClient.bookController.getPreviousBook(book.id);
  }
}
