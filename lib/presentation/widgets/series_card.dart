import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/presentation/screens/series_screen.dart';

class SeriesCard extends StatelessWidget {
  final SeriesDto series;
  final ApiClient apiClient = ApiClient();

  SeriesCard(this.series, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String thumburl =
        apiClient.dio.options.baseUrl + "/api/v1/series/${series.id}/thumbnail";
    final Map<String, String> header = {
      "Authorization": apiClient.dio.options.headers["Authorization"] ?? ""
    };
    final String booksText =
        series.booksCount == 1 ? "1 book" : "${series.booksCount} books";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: SizedBox(
        width: 130,
        height: 230,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              Navigator.pushNamed(
                context,
                SeriesScreen.routeName,
                arguments: series,
              );
            },
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
                        CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: thumburl,
                          httpHeaders: header,
                          imageBuilder: (context, provider) => Image(
                            image: provider,
                            fit: BoxFit.cover,
                          ),
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF141414),
                            child: const Center(
                              child: Icon(
                                Icons.collections_bookmark,
                                color: Color(0xFF333333),
                                size: 28,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF141414),
                            child: const Center(
                              child: Icon(
                                Icons.collections_bookmark,
                                color: Color(0xFF333333),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        // Unread count badge if there are unread books
                        if (series.booksUnreadCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A614),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${series.booksUnreadCount}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    series.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    booksText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
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
