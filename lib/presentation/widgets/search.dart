import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/bloc/search_bloc.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/data/repositories/thumbnail_repository.dart';
import 'package:klutter/presentation/widgets/book_list_tile.dart';
import 'package:klutter/presentation/widgets/series_list_tile.dart';

class KlutterSearchButton extends StatelessWidget {
  const KlutterSearchButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(),
      child: Builder(
        builder: (context) => IconButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: KlutterSearchDelegate(
                BlocProvider.of<SearchBloc>(context),
              ),
            );
          },
          icon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

class KlutterSearchDelegate extends SearchDelegate {
  final SearchBloc searchBloc;
  KlutterSearchDelegate(this.searchBloc);

  @override
  TextStyle get searchFieldStyle =>
      const TextStyle(color: Colors.white, fontSize: 18);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.black,
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    const Color amber = Color(0xFFE5A614);

    if (query.length > 3) {
      searchBloc.add(SearchQuery(query));
      return RepositoryProvider(
        create: (context) => ThumbnailRepository(),
        child: BlocBuilder<SearchBloc, SearchState>(
          bloc: searchBloc,
          builder: (context, state) {
            if (state is SearchReady) {
              final List<BookDto> bookResults = state.searchResults.bookResults;
              final List<SeriesDto> seriesResults =
                  state.searchResults.seriesResults;
              return DefaultTabController(
                length: 2,
                child: Scaffold(
                  backgroundColor: Colors.black,
                  appBar: const TabBar(
                    indicatorColor: amber,
                    indicatorWeight: 3,
                    labelColor: amber,
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: "Series"),
                      Tab(text: "Books"),
                    ],
                  ),
                  body: TabBarView(children: [
                    SeriesResultsPane(seriesResults: seriesResults),
                    BookResultsPane(bookResults: bookResults),
                  ]),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(amber),
                ),
              );
            }
          },
        ),
      );
    } else {
      return const Center(
        child: Text(
          "Minimum query length is 4 characters",
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: Colors.black,
    );
  }
}

class SeriesResultsPane extends StatelessWidget {
  final List<SeriesDto> seriesResults;

  const SeriesResultsPane({
    Key? key,
    required this.seriesResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (seriesResults.isEmpty) {
      return const Center(
        child: Text(
          "No series found",
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color(0xFFE5A614),
                  width: 4,
                ),
              ),
            ),
            child: const Text(
              'SERIES RESULTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: seriesResults.length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0xFF1E1E1E),
                height: 1,
              ),
              itemBuilder: (context, index) {
                return SeriesListTile(series: seriesResults.elementAt(index));
              },
            ),
          ),
        ],
      );
    }
  }
}

class BookResultsPane extends StatelessWidget {
  final List<BookDto> bookResults;

  const BookResultsPane({
    Key? key,
    required this.bookResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bookResults.isEmpty) {
      return const Center(
        child: Text(
          "No books found",
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color(0xFFE5A614),
                  width: 4,
                ),
              ),
            ),
            child: const Text(
              'BOOK RESULTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: bookResults.length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0xFF1E1E1E),
                height: 1,
              ),
              itemBuilder: (context, index) {
                return BookListTile(book: bookResults.elementAt(index));
              },
            ),
          ),
        ],
      );
    }
  }
}
