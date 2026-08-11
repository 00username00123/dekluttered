import 'package:flutter/foundation.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/offline_library.dart';

enum DownloadTaskState { queued, downloading }

class DownloadTask {
  final BookDto book;
  final int totalPages;
  int completedPages;
  DownloadTaskState state;
  bool cancelRequested;

  DownloadTask(this.book)
      : totalPages = book.media.pagesCount < 1 ? 1 : book.media.pagesCount,
        completedPages = 0,
        state = DownloadTaskState.queued,
        cancelRequested = false;

  double get progress {
    if (totalPages <= 0) return 0.0;
    final value = completedPages / totalPages;
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager instance = DownloadManager._();

  final OfflineLibrary _offlineLibrary = OfflineLibrary();
  final ApiClient _apiClient = ApiClient();
  final List<DownloadTask> _tasks = <DownloadTask>[];
  bool _pumping = false;

  DownloadManager._();

  List<DownloadTask> get tasks => List<DownloadTask>.unmodifiable(_tasks);

  bool get hasActiveDownloads => _tasks.isNotEmpty;

  double get overallProgress {
    if (_tasks.isEmpty) return 0.0;
    double total = 0.0;
    for (final task in _tasks) total += task.progress;
    return total / _tasks.length;
  }

  Future<void> enqueueBook(BookDto book) async {
    if (await _offlineLibrary.isBookDownloaded(book.id)) {
      OfflineLibrary.revision.value++;
      return;
    }
    if (_tasks.any((task) => task.book.id == book.id)) return;
    _tasks.add(DownloadTask(book));
    notifyListeners();
    _pump();
  }

  Future<void> enqueueSeries(String seriesId) async {
    final page = await _apiClient.seriesController.getBooksFromSeries(
      seriesId,
      unpaged: true,
      sort: <String>['metadata.numberSort,asc'],
    );
    final books = page.content ?? <BookDto>[];
    for (final book in books) {
      if (!await _offlineLibrary.isBookDownloaded(book.id) &&
          !_tasks.any((task) => task.book.id == book.id)) {
        _tasks.add(DownloadTask(book));
      }
    }
    notifyListeners();
    _pump();
  }

  Future<void> cancel(String bookId) async {
    DownloadTask? found;
    for (final task in _tasks) {
      if (task.book.id == bookId) {
        found = task;
        break;
      }
    }
    if (found == null) return;
    final DownloadTask target = found;
    target.cancelRequested = true;
    if (target.state == DownloadTaskState.queued) {
      _tasks.remove(target);
      await _offlineLibrary.deleteBook(bookId);
    }
    notifyListeners();
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_tasks.isNotEmpty) {
        DownloadTask? found;
        for (final candidate in _tasks) {
          if (candidate.state == DownloadTaskState.queued) {
            found = candidate;
            break;
          }
        }
        if (found == null) break;
        final DownloadTask task = found;

        task.state = DownloadTaskState.downloading;
        notifyListeners();

        try {
          await _offlineLibrary.downloadBook(
            task.book,
            onProgress: (completed, total) {
              task.completedPages = completed;
              notifyListeners();
            },
            isCancelled: () => task.cancelRequested,
          );
        } on DownloadCancelledException catch (_) {
          await _offlineLibrary.deleteBook(task.book.id);
        } catch (error) {
          debugPrint('Download failed for ${task.book.id}: $error');
          await _offlineLibrary.deleteBook(task.book.id);
        } finally {
          _tasks.remove(task);
          notifyListeners();
        }
      }
    } finally {
      _pumping = false;
      if (_tasks.any((task) => task.state == DownloadTaskState.queued)) {
        _pump();
      }
    }
  }
}
