import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/repositories/offline_library.dart';
import 'package:klutter/presentation/screens/book_screen.dart';

class BookCard extends StatelessWidget {
  final BookDto book;
  final ApiClient apiClient = ApiClient();
  final OfflineLibrary offlineLibrary = OfflineLibrary();

  BookCard(this.book);

  @override
  Widget build(BuildContext context) {
    final String thumburl =
        apiClient.dio.options.baseUrl + "/api/v1/books/${book.id}/thumbnail";
    final Map<String, String> header = {
      "Authorization": apiClient.dio.options.headers["Authorization"]
    };
    final String issueNumber = book.metadata.number.toString();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, BookScreen.routeName, arguments: book);
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: thumburl,
                httpHeaders: header,
                imageBuilder: (context, provider) => Image(
                  image: provider,
                  fit: BoxFit.cover,
                ),
                errorWidget: (context, url, error) => FutureBuilder(
                  future: offlineLibrary.getLocalThumbnail(book.id),
                  builder: (context, snapshot) {
                    final file = snapshot.data;
                    if (file != null) {
                      return Image.file(file, fit: BoxFit.cover);
                    }
                    return Container(color: Colors.black12);
                  },
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: ValueListenableBuilder<int>(
                  valueListenable: OfflineLibrary.revision,
                  builder: (context, _, child) {
                    return FutureBuilder<bool>(
                      future: offlineLibrary.isBookDownloaded(book.id),
                      builder: (context, snapshot) {
                        final downloaded = snapshot.data == true;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                issueNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (downloaded) ...[
                                const SizedBox(width: 5),
                                const Icon(Icons.download_done,
                                    color: Colors.white, size: 15),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
