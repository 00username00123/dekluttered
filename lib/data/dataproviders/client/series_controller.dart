import 'package:dio/dio.dart' hide Headers;
import 'package:klutter/data/models/collectiondto.dart';
import 'package:klutter/data/models/pagebookdto.dart';
import 'package:klutter/data/models/seriesdto.dart';
import 'package:retrofit/retrofit.dart';
import 'package:klutter/data/models/pageseriesdto.dart';
import 'package:klutter/data/models/status.dart';

part 'series_controller.g.dart';

@RestApi()
abstract class SeriesController {
  factory SeriesController(Dio dio, {String baseUrl}) = _SeriesController;

  @POST("/api/v1/series/list")
  Future<PageSeriesDto> _listSeries(
      @Body() Map<String, dynamic> search,
      {@Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size,
      @Query("sort") List<String>? sort});

  @GET("/api/v1/series/{seriesId}")
  Future<SeriesDto> getSeriesById(@Path("seriesId") String seriesId);

  @POST("/api/v1/series/{seriesId}/analyze")
  Future<void> analyzeSeries(@Path("seriesId") String seriesId);

  @POST("/api/v1/books/list")
  Future<PageBookDto> _listBooks(
      @Body() Map<String, dynamic> search,
      {@Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size,
      @Query("sort") List<String>? sort});

  @GET("/api/v1/series/{seriesId}/collections")
  Future<List<CollectionDto>> getCollectionsContainingSeries(
      @Path("seriesId") String seriesId);

  //PATCH /api/v1/series/{seriesId}/metadata update series metadata

  @POST("/api/v1/series/{seriesId}/metadata/refresh")
  Future<void> refreshMetadata(@Path("seriesId") String seriesId);

  @POST("/api/v1/series/{seriesId}/read-progress")
  Future<void> markAsRead(@Path("seriesId") String seriesId);

  @DELETE("/api/v1/series/{seriesId}/read-progress")
  Future<void> deleteReadProgress(@Path("seriesId") String seriesId);

  @Headers(<String, String>{"accept": "image/jpeg"})
  @GET("/api/v1/series/{seriesId}/thumbnail")
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> getThumbnail(@Path("seriesId") String seriesId);

  @GET("/api/v1/series/latest")
  Future<PageSeriesDto> getLatest(
      {@Query("library_id") List<String>? libraryId,
      @Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size});

  @GET("/api/v1/series/new")
  Future<PageSeriesDto> getNew(
      {@Query("library_id") List<String>? libraryId,
      @Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size});

  @GET("/api/v1/series/updated")
  Future<PageSeriesDto> getUpdated(
      {@Query("library_id") List<String>? libraryId,
      @Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size});
}

extension SeriesControllerCompatibility on SeriesController {
  Future<PageSeriesDto> getSeries(
      {String? search,
      List<String>? libraryId,
      List<String>? collectionId,
      List<Status>? status,
      List<String>? readStatus,
      List<String>? publisher,
      List<String>? language,
      List<String>? genre,
      List<String>? tag,
      List<String>? ageRating,
      List<String>? releaseYear,
      bool? unpaged,
      int? page,
      int? size,
      List<String>? sort,
      List<String>? author}) {
    final conditions = <Map<String, dynamic>>[];
    _addStringConditions(conditions, 'libraryId', libraryId);
    _addStringConditions(conditions, 'collectionId', collectionId);
    _addStringConditions(conditions, 'readStatus', readStatus);
    _addStringConditions(conditions, 'publisher', publisher);
    _addStringConditions(conditions, 'language', language);
    _addStringConditions(conditions, 'genre', genre);
    _addStringConditions(conditions, 'tag', tag);
    _addStringConditions(conditions, 'author', author);
    if (status != null && status.isNotEmpty) {
      final values = status.map(_statusValue).toList();
      _addStringConditions(conditions, 'seriesStatus', values);
    }

    return _listSeries(
      _searchBody(search, conditions),
      unpaged: unpaged,
      page: page,
      size: size,
      sort: sort,
    );
  }

  Future<PageBookDto> getBooksFromSeries(String seriesId,
      {List<String>? mediaStatus,
      List<String>? readStatus,
      List<String>? tag,
      bool? unpaged,
      int? page,
      int? size,
      List<String>? sort,
      List<String>? author}) {
    final conditions = <Map<String, dynamic>>[
      _isCondition('seriesId', seriesId),
    ];
    _addStringConditions(conditions, 'mediaStatus', mediaStatus);
    _addStringConditions(conditions, 'readStatus', readStatus);
    _addStringConditions(conditions, 'tag', tag);
    _addStringConditions(conditions, 'author', author);

    return _listBooks(
      _searchBody(null, conditions),
      unpaged: unpaged,
      page: page,
      size: size,
      sort: sort,
    );
  }
}

Map<String, dynamic> _searchBody(
    String? fullTextSearch, List<Map<String, dynamic>> conditions) {
  final body = <String, dynamic>{};
  if (fullTextSearch != null && fullTextSearch.isNotEmpty) {
    body['fullTextSearch'] = fullTextSearch;
  }
  if (conditions.length == 1) {
    body['condition'] = conditions.first;
  } else if (conditions.length > 1) {
    body['condition'] = {'allOf': conditions};
  }
  return body;
}

Map<String, dynamic> _isCondition(String field, dynamic value) => {
      field: {'operator': 'is', 'value': value}
    };

void _addStringConditions(List<Map<String, dynamic>> target, String field,
    List<String>? values) {
  if (values == null || values.isEmpty) return;
  if (values.length == 1) {
    target.add(_isCondition(field, values.first));
  } else {
    target.add({
      'anyOf': values.map((value) => _isCondition(field, value)).toList(),
    });
  }
}

String _statusValue(Status status) {
  switch (status) {
    case Status.ended:
      return 'ENDED';
    case Status.ongoing:
      return 'ONGOING';
    case Status.abandoned:
      return 'ABANDONED';
    case Status.hiatus:
      return 'HIATUS';
  }
}
