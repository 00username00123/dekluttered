import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klutter/data/models/bookdto.dart';

import 'package:klutter/data/repositories/server_home_repository.dart';

part 'keepreading_state.dart';

class KeepReadingCubit extends Cubit<KeepReadingState> {
  final ServerHomeRepository _repository;
  KeepReadingCubit(
    this._repository,
  ) : super(KeepReadingInitial());

  Future<void> getKeepReading() async {
    emit(KeepReadingLoading());
    try {
      final List<BookDto> books = await _repository.getKeepReading();
      final List<BookDto> inProgress = books
          .where((book) =>
              book.readProgress != null &&
              !book.readProgress!.completed &&
              book.readProgress!.page > 0 &&
              book.readProgress!.page < book.media.pagesCount)
          .toList();

      if (inProgress.isEmpty) {
        emit(KeepReadingEmpty());
      } else {
        emit(KeepReadingLoaded(inProgress));
      }
    } on Exception catch (_) {
      emit(KeepReadingError());
    }
  }
}
