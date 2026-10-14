import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/ondeck_cubit.dart';
import 'package:klutter/business_logic/cubit/recently_added_series_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyaddedbooks_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyupdatedseries_cubit.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/data/repositories/reading_history_repository.dart';
import 'package:klutter/data/repositories/server_home_repository.dart';
import 'package:klutter/presentation/screens/downloads_screen.dart';
import 'package:klutter/presentation/screens/library_screen.dart';
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
  late OndeckCubit _ondeckCubit;
  late RecentlyAddedSeriesCubit _recentlyAddedSeriesCubit;
  late RecentlyUpdatedSeriesCubit _recentlyUpdatedSeriesCubit;
  late RecentlyaddedbooksCubit _recentlyAddedBooksCubit;

  @override
  void initState() {
    super.initState();

    _ondeckCubit = OndeckCubit(_repository)..getOndeck();
    _recentlyAddedSeriesCubit = RecentlyAddedSeriesCubit(_repository)
      ..getRecentlyAddedSeries();
    _recentlyUpdatedSeriesCubit = RecentlyUpdatedSeriesCubit(_repository)
      ..getRecentlyUpdatedSeries();
    _recentlyAddedBooksCubit = RecentlyaddedbooksCubit(_repository)
      ..getRecentlyaddedBooks();
  }

  @override
  void dispose() {
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
          BlocProvider<OndeckCubit>.value(value: _ondeckCubit),
          BlocProvider<RecentlyAddedSeriesCubit>.value(
              value: _recentlyAddedSeriesCubit),
          BlocProvider<RecentlyUpdatedSeriesCubit>.value(
              value: _recentlyUpdatedSeriesCubit),
          BlocProvider<RecentlyaddedbooksCubit>.value(
              value: _recentlyAddedBooksCubit),
        ],
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Dekluttered',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: const [KlutterSearchButton()],
          ),
          drawer: const ServerDrawer(),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView(
              children: const [
                KeepReading(),
                OnDeck(),
                RecentlyaddedSeries(),
                RecentlyupdatedSeries(),
                RecentlyaddedBooks(),
                SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFFE5A614),
            unselectedItemColor: const Color(0xFF666666),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              if (index == 1) {
                Navigator.pushNamed(context, LibraryScreen.routeName);
              } else if (index == 2) {
                Navigator.pushNamed(context, DownloadsScreen.routeName);
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'Libraries',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.offline_pin),
                label: 'Downloads',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeEntry extends StatelessWidget {
  final Widget child;
  const _FadeEntry({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Container(
    margin: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
    padding: const EdgeInsets.only(left: 8),
    decoration: const BoxDecoration(
      border: Border(
        left: BorderSide(
          color: Color(0xFFE5A614),
          width: 4,
        ),
      ),
    ),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.white,
      ),
    ),
  );
}

/// Standalone Keep Reading implementation.
class KeepReading extends StatefulWidget {
  const KeepReading({Key? key}) : super(key: key);

  @override
  _KeepReadingState createState() => _KeepReadingState();
}

class _KeepReadingState extends State<KeepReading> {
  final ServerHomeRepository _repository = ServerHomeRepository();
  late Future<List<BookDto>> _books;

  @override
  void initState() {
    super.initState();
    _books = _load();
    ReadingHistoryRepository.revision.addListener(_refresh);
  }

  Future<List<BookDto>> _load() async {
    final books = await _repository.getKeepReading();
    return books.take(20).toList();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _books = _load();
    });
  }

  @override
  void dispose() {
    ReadingHistoryRepository.revision.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookDto>>(
      future: _books,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const ErrorLoading('Keep Reading');
        }

        final books = snapshot.data ?? <BookDto>[];
        if (books.isEmpty) {
          return const SizedBox.shrink();
        }

        return _BookRail(title: 'Keep Reading', books: books);
      },
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
          return const SizedBox.shrink();
        }
        if (state is RecentlyUpdatedSeriesLoaded) {
          return _SeriesRail(
            title: 'Recently Updated Series',
            series: state.series,
          );
        }
        return const ErrorLoading('Recently Updated Series');
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
          return const SizedBox.shrink();
        }
        if (state is RecentlyAddedSeriesLoaded) {
          return _SeriesRail(
            title: 'Recently Added Series',
            series: state.series,
          );
        }
        return const ErrorLoading('Recently Added Series');
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
          return const SizedBox.shrink();
        }
        if (state is RecentlyaddedbooksLoaded) {
          return _BookRail(
            title: 'Recently Added Books',
            books: state.books,
          );
        }
        return const ErrorLoading('Recently Added Books');
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
          return const SizedBox.shrink();
        }
        if (state is OndeckLoaded) {
          return _BookRail(title: 'On Deck', books: state.books);
        }
        return const ErrorLoading('On Deck');
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
    return _FadeEntry(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              cacheExtent: 500,
              itemBuilder: (context, index) => BookCard(books[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesRail extends StatelessWidget {
  final String title;
  final List<SeriesDto> series;

  const _SeriesRail({required this.title, required this.series});

  @override
  Widget build(BuildContext context) {
    return _FadeEntry(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: series.length,
              cacheExtent: 500,
              itemBuilder: (context, index) => SeriesCard(series[index]),
            ),
          ),
        ],
      ),
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
          const Icon(Icons.error_outline, color: Color(0xFFE5A614), size: 18),
          const SizedBox(width: 6),
          Text(
            '$section failed to load',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
