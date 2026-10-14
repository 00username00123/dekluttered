import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:klutter/business_logic/cubit/book_screen_more_menu_cubit.dart';
import 'package:klutter/business_logic/cubit/bookscreen_info_cubit.dart';
import 'package:klutter/business_logic/cubit/bookscreen_navbar_cubit.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/book_screen_repository.dart';
import 'package:klutter/data/repositories/download_manager.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/presentation/screens/reader.dart';
import 'package:klutter/presentation/screens/series_screen.dart';
import 'package:klutter/presentation/widgets/book_progress_bar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

class BookScreen extends StatefulWidget {
  static const routeName = '/bookScreen';

  @override
  _BookScreenState createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  @override
  Widget build(BuildContext context) {
    final BookDto currentbook =
        ModalRoute.of(context)!.settings.arguments as BookDto;
    const Color amber = Color(0xFFE5A614);

    return RepositoryProvider(
      create: (context) => BookScreenRepository(currentbook),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            lazy: false,
            create: (context) =>
                BookscreenInfoCubit(context.read<BookScreenRepository>())
                  ..getInfo(),
          ),
          BlocProvider(
            create: (context) =>
                BookscreenNavbarCubit(context.read<BookScreenRepository>()),
          ),
          BlocProvider(
            create: (context) => BookScreenMoreMenuCubit(
                context.read<BookScreenRepository>()),
          ),
        ],
        child: BlocListener<BookscreenNavbarCubit, BookscreenNavbarState>(
          listener: (context, state) {
            if (state is BookscreenNoNextBook) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You are at the last book")),
              );
            } else if (state is BookscreenNoPrevBook) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You are at the first book")),
              );
            } else if (state is BookscreenGoNextBook) {
              Navigator.popAndPushNamed(
                context,
                BookScreen.routeName,
                arguments: state.nextbook,
              );
            } else if (state is BookscreenGoPrevBook) {
              Navigator.popAndPushNamed(
                context,
                BookScreen.routeName,
                arguments: state.prevbook,
              );
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: Text(
                currentbook.metadata.title.isNotEmpty
                    ? currentbook.metadata.title
                    : currentbook.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        context.read<BookscreenNavbarCubit>().tryGoPrev();
                      },
                    );
                  },
                ),
                Builder(builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      context.read<BookscreenNavbarCubit>().tryGoNext();
                    },
                  );
                }),
                MoreMenu(book: currentbook)
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.all(2.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 4,
                              child: BlocBuilder<BookscreenInfoCubit,
                                  BookscreenInfoState>(
                                builder: (context, state) {
                                  if (state is BookscreenInfoInitial) {
                                    return BookScreenImage(
                                        currentbook: currentbook);
                                  } else if (state is BookscreenInfoReady) {
                                    return BookScreenImage(
                                      currentbook: state.currentbook,
                                      image: state.thumb,
                                    );
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: EdgeInsets.all(2.w),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    BlocBuilder<BookscreenInfoCubit,
                                        BookscreenInfoState>(
                                      builder: (context, state) {
                                        if (state is BookscreenInfoReady) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextButton(
                                                style: ButtonStyle(
                                                  foregroundColor:
                                                      MaterialStateProperty.all<
                                                          Color>(amber),
                                                  padding:
                                                      MaterialStateProperty.all<
                                                              EdgeInsetsGeometry>(
                                                          EdgeInsets.zero),
                                                ),
                                                child: Text(
                                                  state.series.name,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    SeriesScreen.routeName,
                                                    arguments: state.series,
                                                  ).then((value) => context
                                                      .read<
                                                          BookscreenInfoCubit>()
                                                      .getInfo());
                                                },
                                              ),
                                              const Divider(
                                                color: Color(0xFF222222),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    ),
                                    Text(
                                      currentbook.metadata.title,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '#' + currentbook.metadata.number,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    currentbook.metadata.releaseDate == null
                                        ? const SizedBox.shrink()
                                        : Text(
                                            (DateFormat('yMMMMd').format(
                                                currentbook.metadata
                                                    .releaseDate!)),
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              color: const Color(0xFF888888),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentbook.metadata.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: <Widget>[
                                      const Text(
                                        "TAGS",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: amber,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ...currentbook.metadata.tags.map(
                                        (e) => Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF141414),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFF2A2A2A)),
                                          ),
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (currentbook.metadata.summary.isNotEmpty) ...[
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 8, bottom: 8),
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
                              Text(
                                currentbook.metadata.summary,
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: const Color(0xFFB0B0B0),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: amber,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.menu_book),
              label: const Text(
                "Read",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.popAndPushNamed(
                  context,
                  Reader.routeName,
                  arguments: currentbook,
                ).then((value) =>
                    context.read<BookscreenInfoCubit>().getInfo());
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BookScreenImage extends StatelessWidget {
  final List<int>? image;
  const BookScreenImage({
    Key? key,
    required this.currentbook,
    this.image,
  }) : super(key: key);

  final BookDto currentbook;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image.memory(
                    Uint8List.fromList(image!),
                    fit: BoxFit.contain,
                  )
                else
                  Container(
                    color: const Color(0xFF141414),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book,
                        color: Color(0xFF333333),
                        size: 32,
                      ),
                    ),
                  ),
                if (currentbook.readProgress == null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5A614),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        ReadProgressBar(book: currentbook),
      ],
    );
  }
}

class MoreMenu extends StatelessWidget {
  final BookDto book;
  const MoreMenu({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookScreenMoreMenuCubit, BookScreenMoreMenuState>(
      listener: (context, state) {
        if (state is BookScreenMoreMenuMarkReadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFE5A614)),
                  SizedBox(width: 8),
                  Text("Failed to mark as read"),
                ],
              ),
            ),
          );
        } else if (state is BookScreenMoreMenuMarkReadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text("Successfully marked as read"),
                ],
              ),
            ),
          );
          context.read<BookscreenInfoCubit>().getInfo();
        } else if (state is BookScreenMoreMenuMarkUnreadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFE5A614)),
                  SizedBox(width: 8),
                  Text("Failed to mark as unread"),
                ],
              ),
            ),
          );
        } else if (state is BookScreenMoreMenuMarkUnreadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text("Successfully marked as unread"),
                ],
              ),
            ),
          );
          context.read<BookscreenInfoCubit>().getInfo();
        }
      },
      child: PopupMenuButton<MoreMenuChoice>(
        icon: const Icon(Icons.more_vert),
        color: const Color(0xFF1E1E1E),
        onSelected: (MoreMenuChoice choice) async {
          if (choice == MoreMenuChoice.analyse) {
            context.read<BookScreenMoreMenuCubit>().analyseMetadata();
          } else if (choice == MoreMenuChoice.refresh) {
            context.read<BookScreenMoreMenuCubit>().refreshMetadata();
          } else if (choice == MoreMenuChoice.markRead) {
            context.read<BookScreenMoreMenuCubit>().markAsRead();
          } else if (choice == MoreMenuChoice.markUnread) {
            context.read<BookScreenMoreMenuCubit>().markAsUnread();
          } else if (choice == MoreMenuChoice.download) {
            await DownloadManager.instance.enqueueBook(book);
          } else if (choice == MoreMenuChoice.deleteDownload) {
            await DownloadManager.instance.cancel(book.id);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await OfflineLibrary().deleteBook(book.id);
              messenger.showSnackBar(
                const SnackBar(content: Text('Downloaded issue removed')),
              );
            } catch (_) {
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Could not remove downloaded issue')),
              );
            }
          }
        },
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<MoreMenuChoice>>[
          const PopupMenuItem<MoreMenuChoice>(
            value: MoreMenuChoice.download,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.file_download, color: Color(0xFFE5A614)),
              title: Text(
                "Download for offline reading",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          const PopupMenuItem<MoreMenuChoice>(
            value: MoreMenuChoice.deleteDownload,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(
                "Delete downloaded copy",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem<MoreMenuChoice>(
            value: MoreMenuChoice.analyse,
            child: Text("Analyse", style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem<MoreMenuChoice>(
            value: MoreMenuChoice.refresh,
            child: Text("Refresh metadata",
                style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem<MoreMenuChoice>(
            value: MoreMenuChoice.markRead,
            child: Text("Mark as read", style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem<MoreMenuChoice>(
            value: MoreMenuChoice.markUnread,
            child: Text("Mark as unread",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}

enum MoreMenuChoice {
  download,
  deleteDownload,
  analyse,
  refresh,
  markRead,
  markUnread
}
