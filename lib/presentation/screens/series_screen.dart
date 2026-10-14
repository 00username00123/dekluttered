import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/bloc/series_books_bloc.dart';
import 'package:klutter/business_logic/cubit/series_info_cubit.dart';
import 'package:klutter/business_logic/cubit/series_thumbnail_cubit.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/data/repositories/download_manager.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/presentation/widgets/book_card.dart';
import 'package:klutter/presentation/widgets/search.dart';

class SeriesScreen extends StatefulWidget {
  static const routeName = '/seriesScreen';
  const SeriesScreen({Key? key}) : super(key: key);

  @override
  _SeriesScreenState createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  @override
  Widget build(BuildContext context) {
    final SeriesDto series =
        ModalRoute.of(context)!.settings.arguments as SeriesDto;
    const Color amber = Color(0xFFE5A614);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SeriesThumbnailCubit>(
          create: (context) => SeriesThumbnailCubit(series)..getThumbnail(),
        ),
        BlocProvider<SeriesInfoCubit>(
          lazy: false,
          create: (context) => SeriesInfoCubit(series)..getSeriesInfo(),
        ),
        BlocProvider(
          create: (context) =>
              SeriesBooksBloc(series)..add(SeriesBooksGetPage(0)),
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text(
              series.metadata.title.isNotEmpty
                  ? series.metadata.title
                  : series.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              const KlutterSearchButton(),
              SeriesOfflineMenu(series: series),
            ],
            bottom: const TabBar(
              indicatorColor: amber,
              indicatorWeight: 3,
              labelColor: amber,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: "Info"),
                Tab(text: "Books"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              InfoTab(series: series),
              const BooksTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class SeriesOfflineMenu extends StatelessWidget {
  final SeriesDto series;
  const SeriesOfflineMenu({Key? key, required this.series}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SeriesOfflineChoice>(
      icon: const Icon(Icons.more_vert),
      color: const Color(0xFF1E1E1E),
      onSelected: (choice) async {
        final messenger = ScaffoldMessenger.of(context);
        if (choice == SeriesOfflineChoice.download) {
          try {
            await DownloadManager.instance.enqueueSeries(series.id);
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not queue series download')),
            );
          }
        } else if (choice == SeriesOfflineChoice.deleteDownloads) {
          try {
            final active = DownloadManager.instance.tasks
                .where((task) => task.book.seriesId == series.id)
                .toList();
            for (final task in active) {
              await DownloadManager.instance.cancel(task.book.id);
            }
            await OfflineLibrary().deleteSeries(series.id);
            messenger.showSnackBar(
              const SnackBar(content: Text('Series downloads removed')),
            );
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not remove series downloads')),
            );
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<SeriesOfflineChoice>(
          value: SeriesOfflineChoice.download,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.file_download, color: Color(0xFFE5A614)),
            title: Text(
              'Download series for offline reading',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
        PopupMenuItem<SeriesOfflineChoice>(
          value: SeriesOfflineChoice.deleteDownloads,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: Colors.redAccent),
            title: Text(
              'Delete series downloads',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

enum SeriesOfflineChoice { download, deleteDownloads }

class InfoTab extends StatelessWidget {
  const InfoTab({
    Key? key,
    required this.series,
  }) : super(key: key);

  final SeriesDto series;

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);
    final String bookCountStr =
        series.booksCount == 1 ? "1 book" : "${series.booksCount} books";

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section: Cover left, title & key metadata right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 120,
                    height: 170,
                    color: const Color(0xFF141414),
                    child: BlocBuilder<SeriesThumbnailCubit,
                        SeriesThumbnailState>(
                      builder: (context, state) {
                        if (state is SeriesThumbnailReady) {
                          return Image.memory(
                            Uint8List.fromList(state.thumbnail),
                            fit: BoxFit.cover,
                          );
                        }
                        return const Center(
                          child: Icon(
                            Icons.collections_bookmark,
                            color: Color(0xFF333333),
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.metadata.title.isNotEmpty
                            ? series.metadata.title
                            : series.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (series.booksMetadata.releaseDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            series.booksMetadata.releaseDate!.year.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                      if (series.metadata.publisher.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            series.metadata.publisher,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: Text(
                          bookCountStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tags
            if (series.metadata.tags.isNotEmpty) ...[
              const Text(
                "TAGS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: amber,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: series.metadata.tags
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Text(
                          e,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Genres
            if (series.metadata.genres.isNotEmpty) ...[
              const Text(
                "GENRES",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: amber,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: series.metadata.genres
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Text(
                          e,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Summary
            if (series.booksMetadata.summary.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: amber,
                      width: 4,
                    ),
                  ),
                ),
                child: const Text(
                  'SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              if (series.booksMetadata.summaryNumber.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "From book ${series.booksMetadata.summaryNumber}:",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              Text(
                series.booksMetadata.summary,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB0B0B0),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class BooksTab extends StatelessWidget {
  const BooksTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);

    return BlocBuilder<SeriesBooksBloc, SeriesBooksState>(
      builder: (context, state) {
        if (state is SeriesBooksInitial) {
          return const SizedBox.shrink();
        } else if (state is SeriesBooksLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(amber),
            ),
          );
        } else if (state is SeriesBooksReady) {
          final int totalPages = state.page.totalPages ?? 1;
          final int currentPage = state.page.number ?? 0;

          return Column(
            children: [
              if (totalPages > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0D0D),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1E1E1E)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: state.page.first == true ? Colors.white24 : amber,
                        onPressed: state.page.first == true
                            ? null
                            : () => context.read<SeriesBooksBloc>().add(
                                  SeriesBooksGetPage(currentPage - 1),
                                ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Page ${currentPage + 1} of $totalPages",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: const Color(0xFF161616),
                            ),
                            child: DropdownButton<int>(
                              isDense: true,
                              underline: const SizedBox.shrink(),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: amber),
                              value: currentPage,
                              onChanged: (value) {
                                if (value != null && value != currentPage) {
                                  context
                                      .read<SeriesBooksBloc>()
                                      .add(SeriesBooksGetPage(value));
                                }
                              },
                              items: Iterable<int>.generate(totalPages)
                                  .map<DropdownMenuItem<int>>((e) =>
                                      DropdownMenuItem<int>(
                                        value: e,
                                        child: Text(
                                          (e + 1).toString(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: state.page.last == true ? Colors.white24 : amber,
                        onPressed: state.page.last == true
                            ? null
                            : () => context.read<SeriesBooksBloc>().add(
                                  SeriesBooksGetPage(currentPage + 1),
                                ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  itemCount: state.page.numberOfElements,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisExtent: 240,
                    maxCrossAxisExtent: 140,
                  ),
                  itemBuilder: (context, index) {
                    return BookCard(state.page.content!.elementAt(index));
                  },
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: Icon(Icons.error_outline, color: amber, size: 32),
          );
        }
      },
    );
  }
}
