import 'dart:io';

import 'package:flutter/material.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/presentation/screens/reader.dart';
import 'package:klutter/presentation/widgets/server_drawer.dart';

class DownloadsScreen extends StatelessWidget {
  static const routeName = '/downloads';

  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final offlineLibrary = OfflineLibrary();
    return Scaffold(
      appBar: AppBar(title: Text('Downloads')),
      drawer: ServerDrawer(),
      body: ValueListenableBuilder<int>(
        valueListenable: OfflineLibrary.revision,
        builder: (context, _, child) {
          return FutureBuilder<List<BookDto>>(
            future: offlineLibrary.getDownloadedBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final books = snapshot.data ?? <BookDto>[];
              if (books.isEmpty) {
                return Center(child: Text('No downloaded comics'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: books.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  mainAxisExtent: 200,
                  maxCrossAxisExtent: 150,
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
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Reader.routeName,
        arguments: book,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
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
                    color: Colors.black12,
                    child: Icon(Icons.menu_book),
                  );
                },
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.metadata.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.offline_pin,
                          color: Colors.white, size: 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
