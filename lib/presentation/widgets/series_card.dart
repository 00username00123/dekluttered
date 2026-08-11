import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:klutter/presentation/screens/series_screen.dart';

class SeriesCard extends StatelessWidget {
  final SeriesDto series;
  final ApiClient apiClient = ApiClient();

  SeriesCard(this.series);

  @override
  Widget build(BuildContext context) {
    final String thumburl =
        apiClient.dio.options.baseUrl + "/api/v1/series/${series.id}/thumbnail";
    final Map<String, String> header = {
      "Authorization": apiClient.dio.options.headers["Authorization"]
    };

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, SeriesScreen.routeName, arguments: series);
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: thumburl,
            httpHeaders: header,
          ),
        ),
      ),
    );
  }
}
