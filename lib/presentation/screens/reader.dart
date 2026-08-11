import 'dart:typed_data';

import 'package:klutter/business_logic/bloc/reader_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/page_thumbnail_cubit.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/library_reading_settings.dart';
import 'package:klutter/presentation/screens/book_screen.dart';
import 'package:klutter/presentation/widgets/page_thumbnail.dart';
import 'package:photo_view/photo_view.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:sizer/sizer.dart';

class Reader extends StatefulWidget {
  static const routeName = '/reader';

  @override
  _ReaderState createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  bool menuVisible = false;
  int currentSliderValue = 1;
  bool sliderDragging = false;
  PageThumbnailCubit? pageThumbnailCubit;
  late PhotoViewScaleStateController scaleController;
  DismissDirection dismissDirection = DismissDirection.horizontal;
  final LibraryReadingSettings _readingSettings = LibraryReadingSettings();
  LibraryReadingDirection _readingDirection =
      LibraryReadingDirection.leftToRight;
  bool _directionLoadStarted = false;

  bool get _isRtl =>
      _readingDirection == LibraryReadingDirection.rightToLeft;

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    scaleController = PhotoViewScaleStateController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_directionLoadStarted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookDto) {
      _directionLoadStarted = true;
      _loadReadingDirection(args.libraryId);
    }
  }

  Future<void> _loadReadingDirection(String libraryId) async {
    final direction = await _readingSettings.getDirection(libraryId);
    if (!mounted) return;
    setState(() => _readingDirection = direction);
  }

  Future<void> _toggleReadingDirection(BookDto book) async {
    final next = _isRtl
        ? LibraryReadingDirection.leftToRight
        : LibraryReadingDirection.rightToLeft;
    setState(() => _readingDirection = next);
    await _readingSettings.setDirection(book.libraryId, next);
  }

  int _safePage(BookDto book, int page) {
    final int maxPage = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    if (page < 1) return 1;
    if (page > maxPage) return maxPage;
    return page;
  }

  void _goVisualLeft(BuildContext context) {
    if (_isRtl) {
      context.read<ReaderBloc>().add(ReaderGoToNextPage());
    } else {
      context.read<ReaderBloc>().add(ReaderGoToPrevPage());
    }
  }

  void _goVisualRight(BuildContext context) {
    if (_isRtl) {
      context.read<ReaderBloc>().add(ReaderGoToPrevPage());
    } else {
      context.read<ReaderBloc>().add(ReaderGoToNextPage());
    }
  }

  void _handleSwipe(BuildContext context, DismissDirection direction) {
    final bool swipedRight = direction == DismissDirection.startToEnd;
    if (_isRtl) {
      context.read<ReaderBloc>().add(
          swipedRight ? ReaderGoToNextPage() : ReaderGoToPrevPage());
    } else {
      context.read<ReaderBloc>().add(
          swipedRight ? ReaderGoToPrevPage() : ReaderGoToNextPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookDto currentbook =
        ModalRoute.of(context)?.settings.arguments as BookDto;
    pageThumbnailCubit ??= PageThumbnailCubit(currentbook);
    final int maxPage = currentbook.media.pagesCount < 1
        ? 1
        : currentbook.media.pagesCount;
    currentSliderValue = _safePage(currentbook, currentSliderValue);

    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ReaderBloc>(
              lazy: false,
              create: (context) =>
                  ReaderBloc(currentbook)..add(ReaderInitialLoad())),
        ],
        child: Scaffold(
          appBar: null,
          body: Builder(builder: (context) {
            return SizedBox.expand(
              child: Stack(
                children: [
                  Container(
                    color: Colors.black,
                    child: BlocConsumer<ReaderBloc, ReaderState>(
                      listener: (context, state) {
                        if (state is ReaderReachedEnd) {
                          Navigator.of(context).popAndPushNamed(
                              BookScreen.routeName,
                              arguments: state.nextBook);
                        } else if (state is ReaderReachedStart) {
                          Navigator.of(context).popAndPushNamed(
                              BookScreen.routeName,
                              arguments: state.prevBook);
                        } else if (state is ReaderPageReady && !sliderDragging) {
                          setState(() {
                            currentSliderValue =
                                _safePage(currentbook, state.pageNumber);
                          });
                        }
                      },
                      builder: (context, state) {
                        if (state is ReaderInitial || state is ReaderLoading) {
                          return Center(child: CircularProgressIndicator());
                        } else if (state is ReaderFailed) {
                          return Center(
                              child: Icon(Icons.error, color: Colors.red));
                        } else if (state is ReaderPageReady) {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: Dismissible(
                              behavior: HitTestBehavior.translucent,
                              key: ValueKey<int>(state.pageNumber),
                              direction: dismissDirection,
                              onDismissed: (direction) =>
                                  _handleSwipe(context, direction),
                              resizeDuration: null,
                              child: PhotoView(
                                scaleStateChangedCallback: (scaleState) {
                                  setState(() {
                                    dismissDirection = scaleState !=
                                            PhotoViewScaleState.initial
                                        ? DismissDirection.none
                                        : DismissDirection.horizontal;
                                  });
                                },
                                scaleStateController: scaleController,
                                filterQuality: FilterQuality.high,
                                initialScale: PhotoViewComputedScale.contained,
                                minScale: PhotoViewComputedScale.contained,
                                gaplessPlayback: true,
                                enableRotation: false,
                                imageProvider: MemoryImage(
                                  Uint8List.fromList(state.pageImage),
                                ),
                              ),
                            ),
                          );
                        }
                        return Center(child: Icon(Icons.error, color: Colors.red));
                      },
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      flex: 20,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _goVisualLeft(context),
                      ),
                    ),
                    Expanded(
                      flex: 60,
                      child: Column(
                        children: [
                          Expanded(child: Container()),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => setState(() {
                                menuVisible = !menuVisible;
                              }),
                            ),
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _goVisualRight(context),
                      ),
                    ),
                  ]),
                  IgnorePointer(
                    ignoring: !menuVisible,
                    child: AnimatedOpacity(
                      opacity: menuVisible ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 10,
                            child: Container(
                              color: Theme.of(context).canvasColor,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.of(context)
                                        .popAndPushNamed(BookScreen.routeName,
                                            arguments: currentbook),
                                  ),
                                  Expanded(
                                    child: Text(
                                      currentbook.metadata.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _toggleReadingDirection(currentbook),
                                    child: Text(_isRtl ? 'RTL' : 'LTR'),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.grid_view),
                                    onPressed: () async {
                                      final int? value = await showDialog<int>(
                                        context: context,
                                        builder: (context) {
                                          return BlocProvider.value(
                                            value: pageThumbnailCubit!
                                              ..getPageThumbnails(),
                                            child: PageThumbnailGridDialog(
                                                book: currentbook),
                                          );
                                        },
                                      );
                                      if (value != null && mounted) {
                                        context.read<ReaderBloc>().add(
                                            ReaderGoToPage(
                                                _safePage(currentbook, value)));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(flex: 70, child: Container()),
                          Expanded(
                            flex: 10,
                            child: SizedBox.expand(
                              child: Container(
                                color: Theme.of(context).canvasColor,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.skip_previous),
                                      onPressed: () => context
                                          .read<ReaderBloc>()
                                          .add(ReaderGoPreviousBook()),
                                    ),
                                    Expanded(
                                      child: Directionality(
                                        textDirection: _isRtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                        child: Slider(
                                          value: currentSliderValue
                                              .clamp(1, maxPage)
                                              .toDouble(),
                                          min: 1,
                                          max: maxPage.toDouble(),
                                          divisions:
                                              maxPage > 1 ? maxPage - 1 : null,
                                          label: currentSliderValue.toString(),
                                          onChangeStart: maxPage > 1
                                              ? (_) => setState(() {
                                                    sliderDragging = true;
                                                  })
                                              : null,
                                          onChanged: maxPage > 1
                                              ? (newvalue) => setState(() {
                                                    currentSliderValue =
                                                        _safePage(currentbook,
                                                            newvalue.round());
                                                  })
                                              : null,
                                          onChangeEnd: maxPage > 1
                                              ? (newvalue) {
                                                  final int page = _safePage(
                                                      currentbook,
                                                      newvalue.round());
                                                  setState(() {
                                                    sliderDragging = false;
                                                    currentSliderValue = page;
                                                  });
                                                  context
                                                      .read<ReaderBloc>()
                                                      .add(ReaderGoToPage(page));
                                                }
                                              : null,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.skip_next),
                                      onPressed: () => context
                                          .read<ReaderBloc>()
                                          .add(ReaderGoNextbook()),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _exitFullscreen();
    scaleController.dispose();
    super.dispose();
  }

  _enterFullscreen() async {
    await FullScreen.enterFullScreen(FullScreenMode.EMERSIVE);
  }

  _exitFullscreen() async {
    await FullScreen.exitFullScreen();
  }
}

class PageThumbnailGridDialog extends StatelessWidget {
  final BookDto book;
  const PageThumbnailGridDialog({required this.book, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: BlocBuilder<PageThumbnailCubit, PageThumbnailState>(
        builder: (context, state) {
          if (state is PageThumbnailLoaded) {
            return GridView.builder(
              padding: EdgeInsets.all(8),
              itemCount: state.pages.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170),
              itemBuilder: (context, index) {
                return GridTile(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 9,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(
                                context, state.pages[index].number),
                            child: PageThumbnail(
                              book: book,
                              page: state.pages[index],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(state.pages[index].number.toString()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}
