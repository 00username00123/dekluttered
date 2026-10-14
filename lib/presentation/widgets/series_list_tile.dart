import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/presentation/screens/series_screen.dart';

class SeriesListTile extends StatelessWidget {
  final SeriesDto series;
  final ApiClient apiClient = ApiClient();

  SeriesListTile({
    Key? key,
    required this.series,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String thumburl =
        apiClient.dio.options.baseUrl + "/api/v1/series/${series.id}/thumbnail";
    final Map<String, String> header = {
      "Authorization": apiClient.dio.options.headers["Authorization"] ?? ""
    };
    final String subtitle =
        series.booksCount == 1 ? "1 book" : "${series.booksCount} books";

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
              Icons.collections_bookmark,
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
        series.name,
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
        Navigator.pushNamed(context, SeriesScreen.routeName, arguments: series);
      },
    );
  }
}
