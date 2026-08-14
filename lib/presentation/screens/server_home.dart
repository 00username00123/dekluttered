import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/keepreading_cubit.dart';
import 'package:klutter/business_logic/cubit/ondeck_cubit.dart';
import 'package:klutter/business_logic/cubit/recently_added_series_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyaddedbooks_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyupdatedseries_cubit.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/data/repositories/reading_history_repository.dart';
import 'package:klutter/data/repositories/server_home_repository.dart';
import 'package:klutter/presentation/widgets/book_card.dart';
import 'package:klutter/presentation/widgets/search.dart';
import 'package:klutter/presentation/widgets/series_card.dart';
import 'package:klutter/presentation/widgets/server_drawer.dart';

class ServerHome extends StatefulWidget {
  static const routeName = '/serverHome';

  @override
  _ServerHomeState createState() => _ServerHomeState();
}

class _ServerHomeState extends State<ServerHome> {
  final ServerHomeRepository _repository = ServerHomeRepository();
  late KeepReadingCubit _keepReadingCubit;
  late OndeckCubit _ondeckCubit;
  late RecentlyAddedSeriesCubit _recentlyAddedSeriesCubit;
  late RecentlyUpdatedSeriesCubit _recentlyUpdatedSeriesCubit;
  late RecentlyaddedbooksCubit _recentlyAddedBooksCubit;

  @override
  void initState() {
    super.initState();

    _keepReadingCubit = KeepReadingCubit(_repository)..getKeepReading();
    _ondeckCubit = OndeckCubit(_repository)..getOndeck();
    _recentlyAddedSeriesCubit = RecentlyAddedSeriesCubit(_repository)
      ..getRecentlyAddedSeries();
    _recentlyUpdatedSeriesCubit = RecentlyUpdatedSeriesCubit(_repository)
      ..getRecentlyUpdatedSeries();
    _recentlyAddedBooksCubit = RecentlyaddedbooksCubit(_repository)
      ..getRecentlyaddedBooks();

    ReadingHistoryRepository.revision.addListener(_refreshKeepReading);
  }

  void _refreshKeepReading() {
    _keepReadingCubit.getKeepReading();
  }

  @override
  void dispose() {
    ReadingHistoryRepository.revision.removeListener(_refreshKeepReading);
    _keepReadingCubit.close();
    _ondeckCubit.close();
    _recentlyAddedSeriesCubit.close();
    _recentlyUpdatedSeriesCubit.close();
    _recentlyAddedBooksCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<KeepReadingCubit>.value(value: _keepReadingCubit),
          BlocProvider<OndeckCubit>.value(value: _ondeckCubit),
          BlocProvider<RecentlyAddedSeriesCubit>.value(
              value: _recentlyAddedSeriesCubit),
          BlocProvider<RecentlyUpdatedSeriesCubit>.value(
              value: _recentlyUpdatedSeriesCubit),
          BlocProvider<RecentlyaddedbooksCubit>.value(
              value: _recentlyAddedBooksCubit),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text('Server Home'),
            actions: [KlutterSearchButton()],
          ),
          drawer: ServerDrawer(),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView(
              children: [
                KeepReading(),
                OnDeck(),
                RecentlyaddedSeries(),
                RecentlyupdatedSeries(),
                RecentlyaddedBooks(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentlyupdatedSeries extends StatelessWidget {
  const RecentlyupdatedSeries({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyUpdatedSeriesCubit, RecentlyUpdatedSeriesState>(
      builder: (context, state) {
        if (state is RecentlyUpdatedSeriesInitial ||
            state is RecentlyUpdatedSeriesLoading ||
            state is RecentlyUpdatedSeriesEmpty) {
          return SizedBox.shrink();
        }
        if (state is RecentlyUpdatedSeriesLoaded) {
          return _SeriesRail(
            title: 'Recently Updated Series',
            series: state.series,
          );
        }
        return ErrorLoading('Recently Updated Series');
      },
    );
  }
}

class KeepReading extends StatelessWidget {
  const KeepReading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeepReadingCubit, KeepReadingState>(
      builder: (context, state) {
        if (state is KeepReadingInitial ||
            state is KeepReadingLoading ||
            state is KeepReadingEmpty) {
          return SizedBox.shrink();
        }
        if (state is KeepReadingLoaded) {
          return _BookRail(title: 'Keep Reading', books: state.books);
        }
        return ErrorLoading('Keep Reading');
      },
    );
  }
}

class RecentlyaddedSeries extends StatelessWidget {
  const RecentlyaddedSeries({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyAddedSeriesCubit, RecentlyAddedSeriesState>(
      builder: (context, state) {
        if (state is RecentlyAddedSeriesInitial ||
            state is RecentlyAddedSeriesLoading ||
            state is RecentlyAddedSeriesEmpty) {
          return SizedBox.shrink();
        }
        if (state is RecentlyAddedSeriesLoaded) {
          return _SeriesRail(
            title: 'Recently Added Series',
            series: state.series,
          );
        }
        return ErrorLoading('Recently Added Series');
      },
    );
  }
}

class RecentlyaddedBooks extends StatelessWidget {
  const RecentlyaddedBooks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyaddedbooksCubit, RecentlyaddedbooksState>(
      builder: (context, state) {
        if (state is RecentlyaddedbooksInitial ||
            state is RecentlyaddedbooksLoading ||
            state is RecentlyaddedbooksEmpty) {
          return SizedBox.shrink();
        }
        if (state is RecentlyaddedbooksLoaded) {
          return _BookRail(
            title: 'Recently Added Books',
            books: state.books,
          );
        }
        return ErrorLoading('Recently Added Books');
      },
    );
  }
}

class OnDeck extends StatelessWidget {
  const OnDeck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OndeckCubit, OndeckState>(
      builder: (context, state) {
        if (state is OndeckInitial ||
            state is OndeckLoading ||
            state is OnDeckEmpty) {
          return SizedBox.shrink();
        }
        if (state is OndeckLoaded) {
          return _BookRail(title: 'On Deck', books: state.books);
        }
        return ErrorLoading('On Deck');
      },
    );
  }
}

class _BookRail extends StatelessWidget {
  final String title;
  final List<BookDto> books;

  const _BookRail({required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: Theme.of(context).textTheme.headline6),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            cacheExtent: 500,
            itemBuilder: (context, index) => BookCard(books[index]),
          ),
        ),
      ],
    );
  }
}

class _SeriesRail extends StatelessWidget {
  final String title;
  final List<SeriesDto> series;

  const _SeriesRail({required this.title, required this.series});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: Theme.of(context).textTheme.headline6),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: series.length,
            cacheExtent: 500,
            itemBuilder: (context, index) => SeriesCard(series[index]),
          ),
        ),
      ],
    );
  }
}

class ErrorLoading extends StatelessWidget {
  final String section;

  const ErrorLoading(this.section, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 18),
          SizedBox(width: 6),
          Text('$section failed to load'),
        ],
      ),
    );
  }
}
