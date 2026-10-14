import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:klutter/business_logic/bloc/reader_bloc.dart';
import 'package:klutter/business_logic/cubit/page_thumbnail_cubit.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/library_reading_settings.dart';
import 'package:klutter/data/repositories/reader_repository.dart';
import 'package:klutter/presentation/screens/book_screen.dart';
import 'package:klutter/presentation/widgets/page_thumbnail.dart';
import 'package:photo_view/photo_view.dart';
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
  ReaderMode _readerMode = ReaderMode.paged;
  bool _settingsLoadStarted = false;
  ReaderRepository? _readerRepository;
  ScrollController? _webtoonScrollController;

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
    if (_settingsLoadStarted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookDto) {
      _settingsLoadStarted = true;
      _readerRepository = ReaderRepository(args);
      _loadSettings(args.libraryId);
      currentSliderValue = (args.readProgress?.page ?? 0) + 1;
    }
  }

  Future<void> _loadSettings(String libraryId) async {
    final direction = await _readingSettings.getDirection(libraryId);
    final mode = await _readingSettings.getReaderMode(libraryId);
    if (!mounted) return;
    setState(() {
      _readingDirection = direction;
      _readerMode = mode;
    });
  }

  Future<void> _toggleReadingDirection(BookDto book) async {
    final next = _isRtl
        ? LibraryReadingDirection.leftToRight
        : LibraryReadingDirection.rightToLeft;
    setState(() => _readingDirection = next);
    await _readingSettings.setDirection(book.libraryId, next);
  }

  Future<void> _setReaderMode(BookDto book, ReaderMode mode) async {
    setState(() => _readerMode = mode);
    await _readingSettings.setReaderMode(book.libraryId, mode);
    if (mode == ReaderMode.verticalScroll && currentSliderValue > 1) {
      final int maxPage =
          book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _scrollToWebtoonPage(currentSliderValue, maxPage);
      });
    }
  }

  void _scrollToWebtoonPage(int page, int maxPage) {
    if (_webtoonScrollController != null &&
        _webtoonScrollController!.hasClients &&
        maxPage > 1) {
      final double maxExtent =
          _webtoonScrollController!.position.maxScrollExtent;
      final double target =
          (maxExtent * (page - 1) / (maxPage - 1)).clamp(0.0, maxExtent);
      _webtoonScrollController!.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _safePage(BookDto book, int page) {
    final int maxPage = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    if (page < 1) return 1;
    if (page > maxPage) return maxPage;
    return page;
  }

  void _goVisualLeft(BuildContext context, BookDto book) {
    if (_readerMode == ReaderMode.dualPage) {
      if (_isRtl) {
        _advanceDualPage(context, book, 1);
      } else {
        _advanceDualPage(context, book, -1);
      }
      return;
    }

    if (_isRtl) {
      context.read<ReaderBloc>().add(ReaderGoToNextPage());
    } else {
      context.read<ReaderBloc>().add(ReaderGoToPrevPage());
    }
  }

  void _goVisualRight(BuildContext context, BookDto book) {
    if (_readerMode == ReaderMode.dualPage) {
      if (_isRtl) {
        _advanceDualPage(context, book, -1);
      } else {
        _advanceDualPage(context, book, 1);
      }
      return;
    }

    if (_isRtl) {
      context.read<ReaderBloc>().add(ReaderGoToPrevPage());
    } else {
      context.read<ReaderBloc>().add(ReaderGoToNextPage());
    }
  }

  void _advanceDualPage(BuildContext context, BookDto book, int direction) {
    final int maxPage = book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    int target;
    if (direction > 0) {
      if (currentSliderValue == 1) {
        target = 2;
      } else {
        target = currentSliderValue + 2;
      }
    } else {
      if (currentSliderValue <= 2) {
        target = 1;
      } else {
        target = currentSliderValue - 2;
      }
    }
    target = target.clamp(1, maxPage);
    if (target != currentSliderValue) {
      context.read<ReaderBloc>().add(ReaderGoToPage(target));
      setState(() => currentSliderValue = target);
    }
  }

  void _handleSwipe(BuildContext context, DismissDirection direction, BookDto book) {
    final bool swipedRight = direction == DismissDirection.startToEnd;
    if (_readerMode == ReaderMode.dualPage) {
      final int step = swipedRight ? -1 : 1;
      _advanceDualPage(context, book, _isRtl ? -step : step);
      return;
    }

    if (_isRtl) {
      context.read<ReaderBloc>().add(
          swipedRight ? ReaderGoToNextPage() : ReaderGoToPrevPage());
    } else {
      context.read<ReaderBloc>().add(
          swipedRight ? ReaderGoToPrevPage() : ReaderGoToNextPage());
    }
  }

  void _showModePicker(BuildContext context, BookDto book) {
    const Color amber = Color(0xFFE5A614);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    "READING MODE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.view_carousel,
                    color: _readerMode == ReaderMode.paged ? amber : Colors.white70,
                  ),
                  title: Text(
                    "Single Page (Paged)",
                    style: TextStyle(
                      color: _readerMode == ReaderMode.paged ? amber : Colors.white,
                      fontWeight: _readerMode == ReaderMode.paged
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _readerMode == ReaderMode.paged
                      ? const Icon(Icons.check, color: amber)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _setReaderMode(book, ReaderMode.paged);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.auto_stories,
                    color: _readerMode == ReaderMode.dualPage ? amber : Colors.white70,
                  ),
                  title: Text(
                    "Dual Page Spread (Side-by-Side)",
                    style: TextStyle(
                      color: _readerMode == ReaderMode.dualPage ? amber : Colors.white,
                      fontWeight: _readerMode == ReaderMode.dualPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _readerMode == ReaderMode.dualPage
                      ? const Icon(Icons.check, color: amber)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _setReaderMode(book, ReaderMode.dualPage);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.view_day,
                    color: _readerMode == ReaderMode.verticalScroll ? amber : Colors.white70,
                  ),
                  title: Text(
                    "Continuous Scroll (Webtoon)",
                    style: TextStyle(
                      color: _readerMode == ReaderMode.verticalScroll ? amber : Colors.white,
                      fontWeight: _readerMode == ReaderMode.verticalScroll
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _readerMode == ReaderMode.verticalScroll
                      ? const Icon(Icons.check, color: amber)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _setReaderMode(book, ReaderMode.verticalScroll);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    const Color amber = Color(0xFFE5A614);

    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ReaderBloc>(
            lazy: false,
            create: (context) =>
                ReaderBloc(currentbook)..add(ReaderInitialLoad()),
          ),
        ],
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: null,
          body: Builder(builder: (context) {
            return SizedBox.expand(
              child: Stack(
                children: [
                  // Main Reader Viewport
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
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(amber),
                            ),
                          );
                        } else if (state is ReaderFailed) {
                          return const Center(
                            child: Icon(Icons.error_outline,
                                color: amber, size: 36),
                          );
                        } else if (state is ReaderPageReady) {
                          if (_readerMode == ReaderMode.verticalScroll) {
                            return _buildWebtoonView(context, currentbook, maxPage);
                          } else if (_readerMode == ReaderMode.dualPage) {
                            return _buildDualPageView(
                                context, currentbook, state.pageNumber, state.pageImage);
                          }
                          return _buildSinglePageView(
                              context, currentbook, state.pageNumber, state.pageImage);
                        }
                        return const Center(
                          child: Icon(Icons.error_outline,
                              color: amber, size: 36),
                        );
                      },
                    ),
                  ),

                  // Tap Regions for Page Turning & Menu Toggle (Paged & Dual modes)
                  if (_readerMode != ReaderMode.verticalScroll)
                    Row(
                      children: [
                        Expanded(
                          flex: 22,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _goVisualLeft(context, currentbook),
                          ),
                        ),
                        Expanded(
                          flex: 56,
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
                          flex: 22,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _goVisualRight(context, currentbook),
                          ),
                        ),
                      ],
                    ),

                  // Reader HUD Overlay
                  IgnorePointer(
                    ignoring: !menuVisible,
                    child: AnimatedOpacity(
                      opacity: menuVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          // Top App Bar
                          Container(
                            color: Colors.black.withOpacity(0.85),
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 4,
                              bottom: 4,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () => Navigator.of(context)
                                      .popAndPushNamed(BookScreen.routeName,
                                          arguments: currentbook),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentbook.metadata.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Page $currentSliderValue of $maxPage",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Mode selector button
                                IconButton(
                                  icon: Icon(
                                    _readerMode == ReaderMode.dualPage
                                        ? Icons.auto_stories
                                        : (_readerMode == ReaderMode.verticalScroll
                                            ? Icons.view_day
                                            : Icons.view_carousel),
                                    color: amber,
                                  ),
                                  tooltip: 'Reading Mode',
                                  onPressed: () =>
                                      _showModePicker(context, currentbook),
                                ),
                                // Reading Direction toggle (LTR / RTL)
                                if (_readerMode != ReaderMode.verticalScroll)
                                  TextButton(
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(amber),
                                    ),
                                    onPressed: () =>
                                        _toggleReadingDirection(currentbook),
                                    child: Text(
                                      _isRtl ? 'RTL' : 'LTR',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                // Optimized Page Grid Button
                                IconButton(
                                  icon: const Icon(Icons.grid_view,
                                      color: Colors.white),
                                  tooltip: 'Page Gallery',
                                  onPressed: () async {
                                    final int? value =
                                        await showDialog<int>(
                                      context: context,
                                      builder: (dialogCtx) {
                                        return BlocProvider.value(
                                          value: pageThumbnailCubit!
                                            ..getPageThumbnails(),
                                          child: PageThumbnailGridDialog(
                                            book: currentbook,
                                            currentPage: currentSliderValue,
                                          ),
                                        );
                                      },
                                    );
                                    if (value != null && mounted) {
                                      final targetPage =
                                          _safePage(currentbook, value);
                                      context.read<ReaderBloc>().add(
                                          ReaderGoToPage(targetPage));
                                      setState(() {
                                        currentSliderValue = targetPage;
                                      });
                                      if (_readerMode ==
                                          ReaderMode.verticalScroll) {
                                        _scrollToWebtoonPage(
                                            targetPage, maxPage);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Bottom Controls Bar
                          Container(
                            color: Colors.black.withOpacity(0.85),
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom + 6,
                              top: 6,
                              left: 8,
                              right: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous,
                                      color: Colors.white),
                                  tooltip: 'Previous Issue',
                                  onPressed: () => context
                                      .read<ReaderBloc>()
                                      .add(ReaderGoPreviousBook()),
                                ),
                                Expanded(
                                  child: Directionality(
                                    textDirection: _isRtl &&
                                            _readerMode != ReaderMode.verticalScroll
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    child: Slider(
                                      activeColor: amber,
                                      inactiveColor: const Color(0xFF333333),
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
                                                currentSliderValue = _safePage(
                                                    currentbook,
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
                                              if (_readerMode ==
                                                  ReaderMode.verticalScroll) {
                                                _scrollToWebtoonPage(
                                                    page, maxPage);
                                              }
                                              context
                                                  .read<ReaderBloc>()
                                                  .add(ReaderGoToPage(page));
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next,
                                      color: Colors.white),
                                  tooltip: 'Next Issue',
                                  onPressed: () => context
                                      .read<ReaderBloc>()
                                      .add(ReaderGoNextbook()),
                                ),
                              ],
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

  Widget _buildSinglePageView(BuildContext context, BookDto currentbook,
      int pageNumber, List<int> pageImage) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Dismissible(
        behavior: HitTestBehavior.translucent,
        key: ValueKey<int>(pageNumber),
        direction: dismissDirection,
        onDismissed: (direction) =>
            _handleSwipe(context, direction, currentbook),
        resizeDuration: null,
        child: PhotoView(
          scaleStateChangedCallback: (scaleState) {
            setState(() {
              dismissDirection = scaleState != PhotoViewScaleState.initial
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
            Uint8List.fromList(pageImage),
          ),
        ),
      ),
    );
  }

  Widget _buildDualPageView(BuildContext context, BookDto currentbook,
      int pageNumber, List<int> pageImage) {
    final int maxPage = currentbook.media.pagesCount < 1
        ? 1
        : currentbook.media.pagesCount;

    // Page 1 is solo cover in standard comics
    if (pageNumber == 1) {
      return _buildSinglePageView(context, currentbook, pageNumber, pageImage);
    }

    final int firstInPair = pageNumber.isEven ? pageNumber : pageNumber - 1;
    final int secondInPair = firstInPair + 1;
    final bool hasSecond = secondInPair <= maxPage;

    return FutureBuilder<List<int>>(
      future: hasSecond
          ? (_readerRepository ?? ReaderRepository(currentbook))
              .getPageImage(secondInPair)
          : Future.value(<int>[]),
      builder: (context, snapshot) {
        final List<int>? secondImage = snapshot.data;

        final Widget firstWidget = Expanded(
          child: Image.memory(
            Uint8List.fromList(pageImage),
            fit: BoxFit.contain,
          ),
        );

        final Widget secondWidget = Expanded(
          child: secondImage != null && secondImage.isNotEmpty
              ? Image.memory(
                  Uint8List.fromList(secondImage),
                  fit: BoxFit.contain,
                )
              : const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFE5A614)),
                    ),
                  ),
                ),
        );

        // In LTR: Left is earlier, Right is later
        // In RTL: Right is earlier, Left is later
        final List<Widget> dualChildren = _isRtl
            ? [secondWidget, const SizedBox(width: 4), firstWidget]
            : [firstWidget, const SizedBox(width: 4), secondWidget];

        return Dismissible(
          key: ValueKey<int>(firstInPair),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) =>
              _handleSwipe(context, direction, currentbook),
          resizeDuration: null,
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: dualChildren,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebtoonView(
      BuildContext context, BookDto currentbook, int maxPage) {
    if (_webtoonScrollController == null) {
      _webtoonScrollController = ScrollController();
      if (currentSliderValue > 1) {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          _scrollToWebtoonPage(currentSliderValue, maxPage);
        });
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          menuVisible = !menuVisible;
        });
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
              notification.metrics.maxScrollExtent > 0) {
            final double fraction =
                (notification.metrics.pixels / notification.metrics.maxScrollExtent)
                    .clamp(0.0, 1.0);
            final int approxPage = ((fraction * (maxPage - 1)).round() + 1)
                .clamp(1, maxPage);
            if (approxPage != currentSliderValue && !sliderDragging) {
              setState(() {
                currentSliderValue = approxPage;
              });
              _readerRepository?.updateReadPage(approxPage);
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: _webtoonScrollController,
          itemCount: maxPage,
          cacheExtent: 600,
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            return _WebtoonPageItem(
              book: currentbook,
              pageNumber: index + 1,
              repository: _readerRepository ?? ReaderRepository(currentbook),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _exitFullscreen();
    scaleController.dispose();
    _webtoonScrollController?.dispose();
    super.dispose();
  }

  _enterFullscreen() async {
    await FullScreen.enterFullScreen(FullScreenMode.EMERSIVE);
  }

  _exitFullscreen() async {
    await FullScreen.exitFullScreen();
  }
}

class _WebtoonPageItem extends StatelessWidget {
  final BookDto book;
  final int pageNumber;
  final ReaderRepository repository;

  const _WebtoonPageItem({
    Key? key,
    required this.book,
    required this.pageNumber,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: repository.getPageImage(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            fit: BoxFit.fitWidth,
            width: double.infinity,
          );
        }
        if (snapshot.hasError) {
          return Container(
            height: 250,
            color: const Color(0xFF111111),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image,
                      color: Color(0xFFE5A614), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Page $pageNumber failed to load",
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          height: 380,
          color: const Color(0xFF0A0A0A),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE5A614)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Page $pageNumber",
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PageThumbnailGridDialog extends StatefulWidget {
  final BookDto book;
  final int currentPage;

  const PageThumbnailGridDialog({
    required this.book,
    this.currentPage = 1,
    Key? key,
  }) : super(key: key);

  @override
  _PageThumbnailGridDialogState createState() =>
      _PageThumbnailGridDialogState();
}

class _PageThumbnailGridDialogState extends State<PageThumbnailGridDialog> {
  late TextEditingController _jumpController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _jumpController =
        TextEditingController(text: widget.currentPage.toString());
    // Auto-scroll to row containing current page
    final int initialRow = ((widget.currentPage - 1) / 3).floor();
    final double initialOffset = (initialRow * 175.0).clamp(0.0, 50000.0);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildQuickJumpChip(
      BuildContext context, String label, int targetPage) {
    const Color amber = Color(0xFFE5A614);
    final bool isCurrent = targetPage == widget.currentPage;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, targetPage),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? amber : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? amber : const Color(0xFF333333),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);
    final int maxPage =
        widget.book.media.pagesCount < 1 ? 1 : widget.book.media.pagesCount;

    return Dialog(
      backgroundColor: const Color(0xFF141414),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF282828), width: 1),
      ),
      child: Column(
        children: [
          // Header with Quick Jump
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF222222), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_view, color: amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Pages ($maxPage)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Quick Jump Input
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _jumpController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (text) {
                      final int? p = int.tryParse(text.trim());
                      if (p != null) {
                        Navigator.pop(context, p.clamp(1, maxPage));
                      }
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: const Color(0xFF222222),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(amber),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    elevation: MaterialStateProperty.all<double>(0),
                  ),
                  onPressed: () {
                    final int? p = int.tryParse(_jumpController.text.trim());
                    if (p != null) {
                      Navigator.pop(context, p.clamp(1, maxPage));
                    }
                  },
                  child: const Text(
                    "GO",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Quick Milestone Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFF101010),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickJumpChip(context, "Cover (1)", 1),
                  if (maxPage >= 4) ...[
                    _buildQuickJumpChip(
                        context, "25%", (maxPage * 0.25).round().clamp(1, maxPage)),
                    _buildQuickJumpChip(
                        context, "50%", (maxPage * 0.50).round().clamp(1, maxPage)),
                    _buildQuickJumpChip(
                        context, "75%", (maxPage * 0.75).round().clamp(1, maxPage)),
                  ],
                  _buildQuickJumpChip(context, "End ($maxPage)", maxPage),
                ],
              ),
            ),
          ),
          // Thumbnails Grid (Lightweight, low cacheExtent, memoized)
          Expanded(
            child: BlocBuilder<PageThumbnailCubit, PageThumbnailState>(
              builder: (context, state) {
                if (state is PageThumbnailLoaded) {
                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: state.pages.length,
                    cacheExtent: 150,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 130,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final page = state.pages[index];
                      final bool isCurrent = page.number == widget.currentPage;

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, page.number),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCurrent ? amber : const Color(0xFF262626),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: PageThumbnail(
                                  book: widget.book,
                                  page: page,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(5),
                                    ),
                                  ),
                                  child: Text(
                                    "${page.number}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isCurrent ? amber : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "NOW",
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(amber),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
