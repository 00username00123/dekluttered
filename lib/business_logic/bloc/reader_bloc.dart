import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/reader_repository.dart';

part 'reader_state.dart';
part 'reader_event.dart';

class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final BookDto book;
  final ReaderRepository _readerRepository;
  int currentPage;
  ReaderBloc(this.book)
      : _readerRepository = ReaderRepository(book),
        currentPage = book.readProgress?.page ?? 1,
        super(ReaderInitial());

  int _clampPage(int page) {
    final int maxPage = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    if (page < 1) return 1;
    if (page > maxPage) return maxPage;
    return page;
  }

  @override
  Stream<ReaderState> mapEventToState(ReaderEvent event) async* {
    try {
      if (event is ReaderInitialLoad) {
        currentPage = _clampPage(book.readProgress?.page ?? 1);
        yield ReaderPageReady(
            currentPage, await _readerRepository.getPageImage(currentPage));
        await _readerRepository.updateReadPage(currentPage);
        _readerRepository.cacheAround(currentPage);
      } else if (event is ReaderGoToNextPage) {
        yield ReaderLoading(currentPage);
        if (currentPage >= book.media.pagesCount) {
          yield ReaderReachedEnd(await _readerRepository.getNextBook());
        } else {
          currentPage = _clampPage(currentPage + 1);
          final List<int> image =
              await _readerRepository.getPageImage(currentPage);
          yield ReaderPageReady(currentPage, image);
          await _readerRepository.updateReadPage(currentPage);
          _readerRepository.cacheAround(currentPage);
        }
      } else if (event is ReaderGoToPrevPage) {
        if (currentPage <= 1) {
          yield ReaderReachedStart(await _readerRepository.getPrevBook());
        } else {
          yield ReaderLoading(currentPage);
          currentPage = _clampPage(currentPage - 1);
          yield ReaderPageReady(
              currentPage, await _readerRepository.getPageImage(currentPage));
          await _readerRepository.updateReadPage(currentPage);
          _readerRepository.cacheAround(currentPage);
        }
      } else if (event is ReaderGoToPage) {
        final int targetPage = _clampPage(event.pageNumber);
        if (targetPage == currentPage && state is ReaderPageReady) return;
        yield ReaderLoading(targetPage);
        currentPage = targetPage;
        yield ReaderPageReady(
            currentPage, await _readerRepository.getPageImage(currentPage));
        await _readerRepository.updateReadPage(currentPage);
        _readerRepository.cacheAround(currentPage);
      } else if (event is ReaderGoNextbook) {
        yield ReaderLoading(currentPage);
        final BookDto nextBook = await _readerRepository.getNextBook();
        yield ReaderReachedEnd(nextBook);
      }
    } on Exception catch (_) {
      yield ReaderFailed();
    }
  }

  @override
  void onChange(change) {
    super.onChange(change);
    print(DateTime.now());
    print(change.nextState.toString());
  }
}
