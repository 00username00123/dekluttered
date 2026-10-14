import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/collections_list_cubit.dart';
import 'package:klutter/business_logic/cubit/series_list_cubit.dart';
import 'package:klutter/data/models/librarydto.dart';
import 'package:klutter/data/repositories/collection_repository.dart';
import 'package:klutter/data/repositories/libraries_repository.dart';
import 'package:klutter/data/repositories/library_reading_settings.dart';
import 'package:klutter/data/repositories/series_repository.dart';
import 'package:klutter/presentation/screens/collection_screen.dart';
import 'package:klutter/presentation/widgets/collection_card.dart';
import 'package:klutter/presentation/widgets/search.dart';
import 'package:klutter/presentation/widgets/series_grid_view.dart';
import 'package:klutter/presentation/widgets/server_drawer.dart';

class LibraryScreen extends StatefulWidget {
  static const String routeName = '/libraryScreen';
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibrariesRepository _librariesRepository = LibrariesRepository();
  Future<List<LibraryDto>>? _librariesFuture;

  @override
  void initState() {
    super.initState();
    _librariesFuture = _librariesRepository.getAllLibraries();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryDto? initiallySelected =
        ModalRoute.of(context)?.settings.arguments as LibraryDto?;
    const Color amber = Color(0xFFE5A614);

    return WillPopScope(
      onWillPop: () async => false,
      child: FutureBuilder<List<LibraryDto>>(
        future: _librariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.black,
              drawer: const ServerDrawer(),
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                title: Text(initiallySelected?.name ?? 'Libraries'),
              ),
              body: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(amber),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.black,
              drawer: const ServerDrawer(),
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                title: Text(initiallySelected?.name ?? 'Libraries'),
              ),
              body: const Center(
                child: Icon(Icons.error_outline, color: amber, size: 32),
              ),
            );
          }

          final libraries = snapshot.data ?? <LibraryDto>[];
          int initialIndex = 0;
          if (initiallySelected != null) {
            final found =
                libraries.indexWhere((l) => l.id == initiallySelected.id);
            if (found >= 0) initialIndex = found + 1;
          }

          return DefaultTabController(
            length: libraries.length + 1,
            initialIndex: initialIndex,
            child: Scaffold(
              backgroundColor: Colors.black,
              drawer: const ServerDrawer(),
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                title: Text(initiallySelected?.name ?? 'Libraries'),
                actions: const [KlutterSearchButton()],
                bottom: TabBar(
                  isScrollable: true,
                  indicatorColor: amber,
                  indicatorWeight: 3,
                  labelColor: amber,
                  unselectedLabelColor: Colors.white60,
                  tabs: <Widget>[
                    const Tab(text: 'All'),
                    ...libraries.map((library) => Tab(text: library.name)),
                  ],
                ),
              ),
              body: TabBarView(
                children: <Widget>[
                  const _LibraryPane(library: null),
                  ...libraries.map((library) => _LibraryPane(library: library)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryPane extends StatelessWidget {
  final LibraryDto? library;

  const _LibraryPane({Key? key, required this.library}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SeriesListCubit>(
          create: (context) => SeriesListCubit(
            repository: SeriesRepository(),
            library: library,
          )..getSeriesPage(0),
        ),
        BlocProvider<CollectionsListCubit>(
          create: (context) => CollectionsListCubit(
            repository: CollectionsRepository(),
            library: library,
          )..getCollectionPage(0),
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            if (library != null) _LibraryDirectionToggle(library: library!),
            Material(
              color: const Color(0xFF0D0D0D),
              child: const TabBar(
                indicatorColor: amber,
                labelColor: amber,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Browse'),
                  Tab(text: 'Collections'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: BlocBuilder<SeriesListCubit, SeriesListState>(
                      builder: (context, state) {
                        if (state is SeriesListInitial) {
                          return const SizedBox.shrink();
                        } else if (state is SeriesListEmpty) {
                          return const Center(
                            child: Text(
                              'No series found',
                              style: TextStyle(color: Color(0xFF888888)),
                            ),
                          );
                        } else if (state is SeriesListLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(amber),
                            ),
                          );
                        } else if (state is SeriesListReady) {
                          return SeriesGridView(state);
                        }
                        return const Center(
                          child:
                              Icon(Icons.error_outline, color: amber, size: 32),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: CollectionGrid(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryDirectionToggle extends StatefulWidget {
  final LibraryDto library;

  const _LibraryDirectionToggle({Key? key, required this.library})
      : super(key: key);

  @override
  _LibraryDirectionToggleState createState() => _LibraryDirectionToggleState();
}

class _LibraryDirectionToggleState extends State<_LibraryDirectionToggle> {
  final LibraryReadingSettings _settings = LibraryReadingSettings();
  LibraryReadingDirection _direction = LibraryReadingDirection.leftToRight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _settings.getDirection(widget.library.id);
    if (!mounted) return;
    setState(() {
      _direction = value;
      _loading = false;
    });
  }

  Future<void> _setDirection(LibraryReadingDirection direction) async {
    if (_direction == direction) return;
    setState(() => _direction = direction);
    await _settings.setDirection(widget.library.id, direction);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.library.name}: ${direction == LibraryReadingDirection.rightToLeft ? 'RTL' : 'LTR'}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Reading direction',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(amber),
              ),
            )
          else
            ToggleButtons(
              constraints: const BoxConstraints(minHeight: 30, minWidth: 50),
              borderRadius: BorderRadius.circular(6),
              borderColor: const Color(0xFF333333),
              selectedBorderColor: amber,
              color: Colors.white70,
              selectedColor: Colors.black,
              fillColor: amber,
              isSelected: [
                _direction == LibraryReadingDirection.leftToRight,
                _direction == LibraryReadingDirection.rightToLeft,
              ],
              onPressed: (index) {
                _setDirection(
                  index == 0
                      ? LibraryReadingDirection.leftToRight
                      : LibraryReadingDirection.rightToLeft,
                );
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('LTR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('RTL',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class CollectionGrid extends StatelessWidget {
  const CollectionGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);

    return BlocBuilder<CollectionsListCubit, CollectionsListState>(
      builder: (context, state) {
        if (state is CollectionsListEmpty) {
          return const Center(
            child: Text(
              'No collections found',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          );
        } else if (state is CollectionsListReady) {
          final int totalPages = state.collectionsPage.totalPages ?? 1;
          final int currentPage = state.collectionsPage.number ?? 0;

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
                        color: state.collectionsPage.first == true
                            ? Colors.white24
                            : amber,
                        onPressed: state.collectionsPage.first == true
                            ? null
                            : () => context
                                .read<CollectionsListCubit>()
                                .getCollectionPage(currentPage - 1),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Page ${currentPage + 1} of $totalPages',
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
                                if (value != null) {
                                  context
                                      .read<CollectionsListCubit>()
                                      .getCollectionPage(value);
                                }
                              },
                              items: Iterable<int>.generate(totalPages)
                                  .map<DropdownMenuItem<int>>(
                                    (e) => DropdownMenuItem<int>(
                                      value: e,
                                      child: Text(
                                        (e + 1).toString(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: state.collectionsPage.last == true
                            ? Colors.white24
                            : amber,
                        onPressed: state.collectionsPage.last == true
                            ? null
                            : () => context
                                .read<CollectionsListCubit>()
                                .getCollectionPage(currentPage + 1),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisExtent: 240,
                    maxCrossAxisExtent: 140,
                  ),
                  itemCount: state.collectionsPage.content!.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      CollectionScreen.routeName,
                      arguments:
                          state.collectionsPage.content!.elementAt(index),
                    ),
                    child: CollectionCard(
                      state.collectionsPage.content!.elementAt(index),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else if (state is CollectionsListLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(amber),
            ),
          );
        }
        return const Center(
          child: Icon(Icons.error_outline, color: amber, size: 32),
        );
      },
    );
  }
}
