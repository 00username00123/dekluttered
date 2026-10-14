import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/ondeck_cubit.dart';
import 'package:klutter/business_logic/cubit/recently_added_series_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyaddedbooks_cubit.dart';
import 'package:klutter/business_logic/cubit/recentlyupdatedseries_cubit.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/data/repositories/reading_history_repository.dart';
import 'package:klutter/data/repositories/server_home_repository.dart';
import 'package:klutter/presentation/screens/book_screen.dart';
import 'package:klutter/presentation/screens/downloads_screen.dart';
import 'package:klutter/presentation/screens/library_screen.dart';
import 'package:klutter/presentation/screens/reader.dart';
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

/// Standalone Continue Reading Bar with Frosted Glass Effect and Bigger Hero Card.
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
          return const ErrorLoading('Continue Reading');
        }

        final books = snapshot.data ?? <BookDto>[];
        if (books.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ContinueReadingGlassBar(books: books);
      },
    );
  }
}

class _ContinueReadingGlassBar extends StatelessWidget {
  final List<BookDto> books;

  const _ContinueReadingGlassBar({Key? key, required this.books})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BookDto mostRecent = books.first;
    const Color amber = Color(0xFFE5A614);

    return _FadeEntry(
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF262626).withOpacity(0.72),
                    const Color(0xFF141414).withOpacity(0.42),
                    Colors.black.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  top: BorderSide(
                    color: amber.withOpacity(0.45),
                    width: 1.2,
                  ),
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.0,
                  ),
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.0,
                  ),
                  bottom: BorderSide.none,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.auto_stories,
                            color: amber,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "CONTINUE READING",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (books.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: amber.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "${books.length} in progress",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: amber,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bigger, More Accentuated Hero Card with Glass Effect
                  _HeroRecentBookCard(book: mostRecent),
                  // More in Progress Row
                  if (books.length > 1) ...[
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF262626), height: 1),
                    const SizedBox(height: 10),
                    const Text(
                      "MORE IN PROGRESS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: books.length - 1,
                        cacheExtent: 500,
                        itemBuilder: (context, index) =>
                            BookCard(books[index + 1]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroRecentBookCard extends StatelessWidget {
  final BookDto book;

  const _HeroRecentBookCard({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);
    final ApiClient apiClient = ApiClient();
    final OfflineLibrary offlineLibrary = OfflineLibrary();

    final int totalPages =
        book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    final int currentPage = (book.readProgress?.page ?? 0) + 1;
    final double progress = (currentPage / totalPages).clamp(0.0, 1.0);
    final int percent = (progress * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pushNamed(context, Reader.routeName, arguments: book)
              .then((_) => ReadingHistoryRepository.revision.value++);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF222222).withOpacity(0.75),
                    const Color(0xFF141414).withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: amber.withOpacity(0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent accentuated cover art
                  SizedBox(
                    width: 110,
                    height: 165,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<File?>(
                            future: offlineLibrary.getLocalThumbnail(book.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data != null) {
                                return Image.file(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: 110,
                                  height: 165,
                                );
                              }
                              return CachedNetworkImage(
                                imageUrl:
                                    "${apiClient.dio.options.baseUrl}/api/v1/books/${book.id}/thumbnail",
                                httpHeaders: {
                                  "Authorization": apiClient
                                          .dio.options.headers["Authorization"]
                                          ?.toString() ??
                                      ""
                                },
                                fit: BoxFit.cover,
                                width: 110,
                                height: 165,
                                memCacheWidth: 260,
                                memCacheHeight: 390,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF181818),
                                  child: const Center(
                                    child: Icon(
                                      Icons.menu_book,
                                      color: Color(0xFF333333),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFF181818),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Color(0xFF444444),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Fused bottom progress bar on thumbnail
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF333333),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(8),
                              ),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: amber,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Metadata & Actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.metadata.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: amber.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: amber.withOpacity(0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '#${book.metadata.number}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222222),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "$percent% read",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Page counts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Page $currentPage of $totalPages",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${totalPages - currentPage} left",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Resume & Details action buttons
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(amber),
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.black),
                                padding: MaterialStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                ),
                                shape:
                                    MaterialStateProperty.all<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                elevation: MaterialStateProperty.all<double>(0),
                              ),
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text(
                                "RESUME",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, Reader.routeName,
                                        arguments: book)
                                    .then((_) => ReadingHistoryRepository
                                        .revision.value++);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white70, size: 22),
                              tooltip: 'Book Details',
                              onPressed: () {
                                Navigator.pushNamed(
                                        context, BookScreen.routeName,
                                        arguments: book)
                                    .then((_) => ReadingHistoryRepository
                                        .revision.value++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
