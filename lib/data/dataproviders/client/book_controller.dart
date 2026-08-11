import 'package:dio/dio.dart' hide Headers;
import 'package:klutter/data/models/bookdto.dart';
import 'package:klutter/data/models/bookmetadataupdatedto.dart';
import 'package:klutter/data/models/pagebookdto.dart';
import 'package:klutter/data/models/pagedto.dart';
import 'package:klutter/data/models/readlistdto.dart';
import 'package:klutter/data/models/readprogressupdatedto.dart';
import 'package:retrofit/retrofit.dart';

part 'book_controller.g.dart';

@RestApi()
abstract class BookController {
  factory BookController(Dio dio, {String baseUrl}) = _BookController;

  @POST("/api/v1/books/list")
  Future<PageBookDto> _listBooks(
      @Body() Map<String, dynamic> search,
      {@Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size,
      @Query("sort") List<String>? sort});

  @GET("/api/v1/books/{bookId}")
  Future<BookDto> getBook(@Path("bookId") String bookId);

  @POST("/api/v1/books/{bookId}/analyze")
  Future<HttpResponse<void>> analyzeBook(@Path("bookId") String bookId);

  //Some methods missing around downloading the book file

  @PATCH("/api/v1/books/{bookId}/metadata")
  Future<HttpResponse<void>> updateMetadata(@Path("bookId") String bookId,
      @Body() BookMetadataUpdateDto bookMetadataUpdateDto);

  @POST("/api/v1/books/{bookId}/metadata/refresh")
  Future<HttpResponse<void>> refreshMetadata(@Path("bookId") String bookId);

  @GET("/api/v1/books/{bookId}/next")
  Future<BookDto> getNextBook(@Path("bookId") String bookId);

  @GET("/api/v1/books/{bookId}/pages")
  Future<List<PageDto>> getPages(@Path("bookId") String bookId);

  @Headers(<String, String>{"accept": "*/*"})
  @GET("/api/v1/books/{bookId}/pages/{pageNumber}")
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> getPage(
      @Path("bookId") String bookId, @Path("pageNumber") int pageNumber,
      {@Query("convert") String? convert,
      @Query("zero_based") bool? zeroBased});

  @Headers(<String, String>{"accept": "image/jpeg"})
  @GET("/api/v1/books/{bookId}/pages/{pageNumber}/thumbnail")
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> getPageThumbnail(
      @Path("bookId") String bookId, @Path("pageNumber") int pageNumber);

  @GET("/api/v1/books/{bookId}/previous")
  Future<BookDto> getPreviousBook(@Path("bookId") String bookId);

  @PATCH("/api/v1/books/{bookId}/read-progress")
  Future<void> markAsRead(@Path("bookId") String bookId,
      @Body() ReadProgressUpdateDto readProgressUpdateDto);

  @DELETE("/api/v1/books/{bookId}/read-progress")
  Future<void> deleteReadProgress(@Path("bookId") String bookId);

  @GET("/api/v1/books/{bookId}/readlists")
  Future<List<ReadListDto>> getReadLists(@Path("bookID") String bookId);

  @Headers(<String, String>{"accept": "image/jpeg"})
  @GET("/api/v1/books/{bookId}/thumbnail")
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> getThumbnail(@Path("bookId") String bookId);

  //Return newly added or updated books.
  @GET("/api/v1/books/latest")
  Future<PageBookDto> getLatest(
      {@Query("unpaged") bool? unpaged,
      @Query("page") int? page,
      @Query("size") int? size});

  //Return first unread book of series with at least one book read and no books in progress.
  @GET("/api/v1/books/ondeck")
  Future<PageBookDto> getOnDeck(
      {@Query("page") int? page, @Query("size") int? size});
}

extension BookControllerCompatibility on BookController {
  Future<PageBookDto> getBooks(
      {String? search,
      List<String>? libraryId,
      List<String>? mediaStatus,
      List<String>? readStatus,
      List<String>? tag,
      bool? unpaged,
      int? page,
      int? size,
      List<String>? sort}) {
    final conditions = <Map<String, dynamic>>[];
    _addBookConditions(conditions, 'libraryId', libraryId);
    _addBookConditions(conditions, 'mediaStatus', mediaStatus);
    _addBookConditions(conditions, 'readStatus', readStatus);
    _addBookConditions(conditions, 'tag', tag);

    final body = <String, dynamic>{};
    if (search != null && search.isNotEmpty) body['fullTextSearch'] = search;
    if (conditions.length == 1) {
      body['condition'] = conditions.first;
    } else if (conditions.length > 1) {
      body['condition'] = {'allOf': conditions};
    }

    return _listBooks(
      body,
      unpaged: unpaged,
      page: page,
      size: size,
      sort: sort,
    );
  }
}

Map<String, dynamic> _bookIsCondition(String field, String value) => {
      field: {'operator': 'is', 'value': value}
    };

void _addBookConditions(List<Map<String, dynamic>> target, String field,
    List<String>? values) {
  if (values == null || values.isEmpty) return;
  if (values.length == 1) {
    target.add(_bookIsCondition(field, values.first));
  } else {
    target.add({
      'anyOf': values.map((value) => _bookIsCondition(field, value)).toList(),
    });
  }
}
