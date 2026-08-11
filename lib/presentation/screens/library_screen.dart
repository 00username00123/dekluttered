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

    return WillPopScope(
      onWillPop: () async => false,
      child: FutureBuilder<List<LibraryDto>>(
        future: _librariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              drawer: ServerDrawer(),
              appBar: AppBar(title: Text('Libraries')),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              drawer: ServerDrawer(),
              appBar: AppBar(title: Text('Libraries')),
              body: Center(child: Icon(Icons.error, color: Colors.red)),
            );
          }

          final libraries = snapshot.data ?? <LibraryDto>[];
          int initialIndex = 0;
          if (initiallySelected != null) {
            final found = libraries.indexWhere((l) => l.id == initiallySelected.id);
            if (found >= 0) initialIndex = found + 1;
          }

          return DefaultTabController(
            length: libraries.length + 1,
            initialIndex: initialIndex,
            child: Scaffold(
              drawer: ServerDrawer(),
              appBar: AppBar(
                title: Text('Libraries'),
                actions: [KlutterSearchButton()],
                bottom: TabBar(
                  isScrollable: true,
                  tabs: <Widget>[
                    Tab(text: 'All'),
                    ...libraries.map((library) => Tab(text: library.name)),
                  ],
                ),
              ),
              body: TabBarView(
                children: <Widget>[
                  _LibraryPane(library: null),
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
            if (library != null)
              _LibraryDirectionToggle(library: library!),
            Material(
              color: Theme.of(context).canvasColor,
              child: TabBar(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: BlocBuilder<SeriesListCubit, SeriesListState>(
                      builder: (context, state) {
                        if (state is SeriesListInitial) {
                          return SizedBox.shrink();
                        } else if (state is SeriesListEmpty) {
                          return Center(child: Text('No series found'));
                        } else if (state is SeriesListLoading) {
                          return Center(child: CircularProgressIndicator());
                        } else if (state is SeriesListReady) {
                          return SeriesGridView(state);
                        }
                        return Center(
                          child: Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Reading direction',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          if (_loading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ToggleButtons(
              constraints: BoxConstraints(minHeight: 36, minWidth: 58),
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
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('LTR'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('RTL'),
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
    return BlocBuilder<CollectionsListCubit, CollectionsListState>(
      builder: (context, state) {
        if (state is CollectionsListEmpty) {
          return Center(child: Text('No collections found'));
        } else if (state is CollectionsListReady) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              state.collectionsPage.totalPages == 1
                  ? SizedBox.shrink()
                  : Expanded(
                      flex: 15,
                      child: ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: state.collectionsPage.first!
                                ? null
                                : () => context
                                    .read<CollectionsListCubit>()
                                    .getCollectionPage(
                                        state.collectionsPage.number! - 1),
                            child: Icon(Icons.chevron_left),
                          ),
                          Row(
                            children: [
                              Text('Page '),
                              DropdownButton<int>(
                                isDense: true,
                                onChanged: (value) {
                                  if (value != null) {
                                    context
                                        .read<CollectionsListCubit>()
                                        .getCollectionPage(value);
                                  }
                                },
                                value: state.collectionsPage.number,
                                items: Iterable<int>.generate(
                                  state.collectionsPage.totalPages!,
                                )
                                    .map<DropdownMenuItem<int>>(
                                      (e) => DropdownMenuItem<int>(
                                        value: e,
                                        child: Text((e + 1).toString()),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          OutlinedButton(
                            onPressed: state.collectionsPage.last!
                                ? null
                                : () => context
                                    .read<CollectionsListCubit>()
                                    .getCollectionPage(
                                        state.collectionsPage.number! + 1),
                            child: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
              Expanded(
                flex: 85,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisExtent: 200,
                    maxCrossAxisExtent: 150,
                  ),
                  itemCount: state.collectionsPage.content!.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      CollectionScreen.routeName,
                      arguments: state.collectionsPage.content!.elementAt(index),
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
          return Center(child: CircularProgressIndicator());
        }
        return Center(child: Icon(Icons.error, color: Colors.red));
      },
    );
  }
}
