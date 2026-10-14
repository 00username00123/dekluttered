import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/presentation/screens/book_screen.dart';

class BookListTile extends StatelessWidget {
  final BookDto book;
  final ApiClient apiClient = ApiClient();

  BookListTile({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String thumburl =
        apiClient.dio.options.baseUrl + "/api/v1/books/${book.id}/thumbnail";
    final Map<String, String> header = {
      "Authorization": apiClient.dio.options.headers["Authorization"] ?? ""
    };
    final String title =
        book.metadata.title.isNotEmpty ? book.metadata.title : book.name;
    final String subtitle = book.metadata.number.isNotEmpty
        ? "#${book.metadata.number}"
        : "${book.media.pagesCount} pages";

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          width: 48,
          height: 68,
          fit: BoxFit.cover,
          imageUrl: thumburl,
          httpHeaders: header,
          placeholder: (context, url) => Container(
            width: 48,
            height: 68,
            color: const Color(0xFF1E1E1E),
            child: const Icon(
              Icons.menu_book,
              color: Color(0xFF444444),
              size: 20,
            ),
          ),
          errorWidget: (context, url, error) => Image.asset(
            "assets/images/cover.png",
            width: 48,
            height: 68,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFE5A614),
        size: 20,
      ),
      onTap: () {
        Navigator.pushNamed(context, BookScreen.routeName, arguments: book);
      },
    );
  }
}
