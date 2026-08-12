import 'package:flutter/material.dart';
import 'package:klutter/business_logic/cubit/keepreading_cubit.dart';
import 'package:klutter/business_logic/cubit/ondeck_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/recently_added_series_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyaddedbooks_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyupdatedseries_cubit.dart';
import 'package:klutter/data/repositories/server_home_repository.dart';
import 'package:klutter/presentation/widgets/search.dart';
import 'package:klutter/presentation/widgets/server_drawer.dart';
import 'package:klutter/presentation/widgets/book_card.dart';
import 'package:klutter/presentation/widgets/series_card.dart';

class ServerHome extends StatelessWidget {
  static const routeName = '/serverHome';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: RepositoryProvider<ServerHomeRepository>(
        create: (_) => ServerHomeRepository(),
        child: Builder(
          builder: (context) {
            final repository = context.read<ServerHomeRepository>();
            return MultiBlocProvider(
              providers: [
                BlocProvider<KeepReadingCubit>(
                  create: (_) => KeepReadingCubit(repository)..getKeepReading(),
                ),
                BlocProvider<OndeckCubit>(
                  create: (_) => OndeckCubit(repository)..getOndeck(),
                ),
                BlocProvider<RecentlyAddedSeriesCubit>(
                  create: (_) => RecentlyAddedSeriesCubit(repository)
                    ..getRecentlyAddedSeries(),
                ),
                BlocProvider<RecentlyUpdatedSeriesCubit>(
                  create: (_) => RecentlyUpdatedSeriesCubit(repository)
                    ..getRecentlyUpdatedSeries(),
                ),
                BlocProvider<RecentlyaddedbooksCubit>(
                  create: (_) => RecentlyaddedbooksCubit(repository)
                    ..getRecentlyaddedBooks(),
                ),
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
            );
          },
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
        } else if (state is RecentlyUpdatedSeriesLoaded) {
          return _SeriesRail(
            title: 'Recently Updated Series',
            series: state.series,
          );
        }
        return ErrorLoading();
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
        } else if (state is KeepReadingLoaded) {
          return _BookRail(title: 'Keep Reading', books: state.books);
        }
        return ErrorLoading();
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
        } else if (state is RecentlyAddedSeriesLoaded) {
          return _SeriesRail(
            title: 'Recently Added Series',
            series: state.series,
          );
        }
        return ErrorLoading();
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
        } else if (state is RecentlyaddedbooksLoaded) {
          return _BookRail(
            title: 'Recently Added Books',
            books: state.books,
          );
        }
        return ErrorLoading();
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
        } else if (state is OndeckLoaded) {
          return _BookRail(title: 'On Deck', books: state.books);
        }
        return ErrorLoading();
      },
    );
  }
}

class _BookRail extends StatelessWidget {
  final String title;
  final List books;

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
  final List series;

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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.error, color: Colors.red),
        Text('Error loading'),
      ],
    );
  }
}
