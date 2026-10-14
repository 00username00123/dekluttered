import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/pagedto.dart';
import 'package:klutter/data/repositories/offline_library.dart';

class PageThumbnail extends StatelessWidget {
  final ApiClient apiClient = ApiClient();
  final OfflineLibrary offlineLibrary = OfflineLibrary();
  final BookDto book;
  final PageDto page;

  PageThumbnail({Key? key, required this.book, required this.page})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>?>(
      future: offlineLibrary.getLocalPage(book.id, page.number),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              Uint8List.fromList(snapshot.data!),
              fit: BoxFit.cover,
            ),
          );
        }

        final String thumburl = apiClient.dio.options.baseUrl +
            "/api/v1/books/${book.id}/pages/${page.number}/thumbnail";
        final Map<String, String> header = {
          "Authorization":
              apiClient.dio.options.headers["Authorization"]?.toString() ?? ""
        };

        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: thumburl,
            httpHeaders: header,
            cacheKey: 'thumb_${book.id}_${page.number}',
            memCacheWidth: 200,
            memCacheHeight: 300,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFF141414),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A614)),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF141414),
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Color(0xFF444444),
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
