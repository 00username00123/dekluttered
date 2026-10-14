import 'dart:io';

import 'package:flutter/material.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/presentation/screens/reader.dart';
import 'package:klutter/presentation/widgets/book_progress_bar.dart';
import 'package:klutter/presentation/widgets/server_drawer.dart';

class DownloadsScreen extends StatelessWidget {
  static const routeName = '/downloads';

  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final offlineLibrary = OfflineLibrary();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const ServerDrawer(),
      body: ValueListenableBuilder<int>(
        valueListenable: OfflineLibrary.revision,
        builder: (context, _, child) {
          return FutureBuilder<List<BookDto>>(
            future: offlineLibrary.getDownloadedBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE5A614)),
                  ),
                );
              }
              final books = snapshot.data ?? <BookDto>[];
              if (books.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.offline_pin,
                        color: Color(0xFF444444),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No downloaded comics',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                itemCount: books.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  mainAxisExtent: 240,
                  maxCrossAxisExtent: 140,
                ),
                itemBuilder: (context, index) =>
                    _DownloadedBookCard(book: books[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _DownloadedBookCard extends StatelessWidget {
  final BookDto book;

  const _DownloadedBookCard({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final offlineLibrary = OfflineLibrary();
    final String issueNumber = book.metadata.number.toString();
    final String displayTitle =
        book.metadata.title.isNotEmpty ? book.metadata.title : book.name;
    final bool isUnread = book.readProgress == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: SizedBox(
        width: 130,
        height: 230,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => Navigator.pushNamed(
              context,
              Reader.routeName,
              arguments: book,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 184,
                    width: 130,
                    color: const Color(0xFF141414),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<File?>(
                          future: offlineLibrary.getLocalThumbnail(book.id),
                          builder: (context, snapshot) {
                            final file = snapshot.data;
                            if (file != null) {
                              return Image.file(file, fit: BoxFit.cover);
                            }
                            return Container(
                              color: const Color(0xFF141414),
                              child: const Center(
                                child: Icon(
                                  Icons.menu_book,
                                  color: Color(0xFF333333),
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        // Unread indicator dot
                        if (isUnread)
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
                        // Issue number and download badge
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (issueNumber.isNotEmpty)
                                  Text(
                                    '#$issueNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (issueNumber.isNotEmpty)
                                  const SizedBox(width: 3),
                                const Icon(
                                  Icons.offline_pin,
                                  color: Color(0xFFE5A614),
                                  size: 11,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Progress bar fused to bottom edge
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ReadProgressBar(book: book),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
