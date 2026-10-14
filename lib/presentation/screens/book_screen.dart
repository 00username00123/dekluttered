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
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            Container(
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFF101010),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF222222),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const TabBar(
                                indicatorColor: amber,
                                indicatorWeight: 2.5,
                                labelColor: amber,
                                unselectedLabelColor: Color(0xFF888888),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                tabs: [
                                  Tab(text: "Overview"),
                                  Tab(text: "Details"),
                                  Tab(text: "Credits"),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _OverviewTab(book: currentbook),
                                  _DetailsTab(book: currentbook),
                                  _CreditsTab(book: currentbook),
                                ],
                              ),
                            ),
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
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Color(0xFFE5A614)),
                  SizedBox(width: 8),
                  Text("Failed to mark as read"),
                ],
              ),
            ),
          );
        } else if (state is BookScreenMoreMenuMarkReadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
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
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Color(0xFFE5A614)),
                  SizedBox(width: 8),
                  Text("Failed to mark as unread"),
                ],
              ),
            ),
          );
        } else if (state is BookScreenMoreMenuMarkUnreadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
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

class _OverviewTab extends StatelessWidget {
  final BookDto book;
  const _OverviewTab({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);
    final int totalPages =
        book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    final int currentPage = (book.readProgress?.page ?? 0) + 1;
    final bool isCompleted = book.readProgress?.completed ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF242424), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.bookmark,
                      color: isCompleted ? const Color(0xFF4CAF50) : amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCompleted
                          ? "Completed"
                          : (book.readProgress == null
                              ? "Unread"
                              : "Page $currentPage of $totalPages"),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  "$totalPages pages",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          if (book.metadata.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  color: amber,
                  margin: const EdgeInsets.only(right: 6),
                ),
                const Text(
                  "TAGS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: book.metadata.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    tag,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ],
          if (book.metadata.summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  color: amber,
                  margin: const EdgeInsets.only(right: 6),
                ),
                const Text(
                  "SUMMARY",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              book.metadata.summary,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB0B0B0),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditsTab extends StatelessWidget {
  final BookDto book;
  const _CreditsTab({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);
    final authors = book.metadata.authors;

    if (authors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.person_outline, color: Color(0xFF444444), size: 36),
              SizedBox(height: 8),
              Text(
                "No creator credits available",
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<String>> roleMap = <String, List<String>>{};
    for (final a in authors) {
      final role = a.role.trim().isEmpty ? 'Creator' : a.role.trim();
      roleMap.putIfAbsent(role, () => <String>[]).add(a.name.trim());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: roleMap.entries.map((entry) {
          final roleTitle =
              entry.key[0].toUpperCase() + entry.key.substring(1);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF242424), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: amber.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        roleTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.value.join(", "),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final BookDto book;
  const _DetailsTab({Key? key, required this.book}) : super(key: key);

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    final double mb = bytes / (1024 * 1024);
    if (mb >= 1000) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(1)} MB";
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    const Color amber = Color(0xFFE5A614);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF242424), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF222222), height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Widget? customValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: customValue ??
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);
    final DateFormat formatter = DateFormat('yMMMMd');
    final DateFormat timeFormatter = DateFormat('yMMMMd, h:mm a');
    final OfflineLibrary offlineLibrary = OfflineLibrary();

    final int totalPages =
        book.media.pagesCount < 1 ? 1 : book.media.pagesCount;
    final int currentPage = (book.readProgress?.page ?? 0) + 1;
    final bool isCompleted = book.readProgress?.completed ?? false;
    final double progress = (currentPage / totalPages).clamp(0.0, 1.0);
    final int percent = (progress * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Reading Progress & Status Card
          _buildCard(
            icon: Icons.auto_stories,
            title: "Reading Progress",
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF4CAF50).withOpacity(0.18)
                    : (book.readProgress == null
                        ? const Color(0xFF333333)
                        : amber.withOpacity(0.18)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF4CAF50).withOpacity(0.4)
                      : (book.readProgress == null
                          ? const Color(0xFF444444)
                          : amber.withOpacity(0.4)),
                  width: 0.8,
                ),
              ),
              child: Text(
                isCompleted
                    ? "COMPLETED"
                    : (book.readProgress == null
                        ? "UNREAD"
                        : "$percent% IN PROGRESS"),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : (book.readProgress == null
                          ? const Color(0xFFAAAAAA)
                          : amber),
                ),
              ),
            ),
            children: [
              _buildRow("Current Position", "Page $currentPage of $totalPages"),
              _buildRow("Remaining", "${totalPages - currentPage} pages left"),
              if (book.readProgress != null)
                _buildRow(
                  "Last Read",
                  timeFormatter.format(book.readProgress!.lastModified),
                ),
              const SizedBox(height: 6),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF222222),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? const Color(0xFF4CAF50) : amber,
                  ),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
              // Toggle Read / Unread quick action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        isCompleted ? Colors.white70 : amber,
                      ),
                    ),
                    icon: Icon(
                      isCompleted ? Icons.undo : Icons.done_all,
                      size: 16,
                    ),
                    label: Text(
                      isCompleted ? "Mark Unread" : "Mark as Read",
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      if (isCompleted) {
                        context
                            .read<BookScreenMoreMenuCubit>()
                            .markAsUnread();
                      } else {
                        context
                            .read<BookScreenMoreMenuCubit>()
                            .markAsRead();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          // 2. Publication & Series Information Card
          _buildCard(
            icon: Icons.collections_bookmark,
            title: "Publication & Series",
            children: [
              _buildRow("Issue Number", "#${book.metadata.number}"),
              _buildRow("Sort Order", "${book.metadata.numberSort}"),
              if (book.metadata.releaseDate != null)
                _buildRow("Release Date",
                    formatter.format(book.metadata.releaseDate!)),
              _buildRow("File Name", book.name),
            ],
          ),

          // 3. Technical Specifications & File Info Card
          _buildCard(
            icon: Icons.description,
            title: "File & Technical Specs",
            children: [
              _buildRow(
                "Format",
                book.media.mediaType,
                customValue: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: amber.withOpacity(0.4), width: 0.8),
                      ),
                      child: Text(
                        book.media.mediaType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRow("File Size", _formatBytes(book.sizeBytes)),
              _buildRow("Total Pages", "${book.media.pagesCount}"),
              _buildRow("Status", book.media.status),
              if (book.media.comment.isNotEmpty)
                _buildRow("Comment", book.media.comment),
              // Download Status Row
              FutureBuilder<bool>(
                future: offlineLibrary.isBookDownloaded(book.id),
                builder: (context, snapshot) {
                  final bool isDownloaded = snapshot.data == true;
                  return _buildRow(
                    "Offline Storage",
                    isDownloaded ? "Downloaded" : "Online Only",
                    customValue: Row(
                      children: [
                        Icon(
                          isDownloaded
                              ? Icons.offline_pin
                              : Icons.cloud_outlined,
                          color: isDownloaded
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF888888),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDownloaded ? "Downloaded" : "Online Only",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDownloaded
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // 4. Server Timestamps & Identifiers Card
          _buildCard(
            icon: Icons.info_outline,
            title: "Server & Timestamps",
            children: [
              _buildRow("Added to Library", formatter.format(book.created)),
              _buildRow(
                  "File Last Modified", formatter.format(book.fileLastModified)),
              _buildRow(
                  "Metadata Updated", formatter.format(book.lastModified)),
              _buildRow("Book ID", book.id),
            ],
          ),
        ],
      ),
    );
  }
}
