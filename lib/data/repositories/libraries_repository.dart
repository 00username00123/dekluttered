import 'package:dio/dio.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/librarydto.dart';

class LibrariesRepository {
  final ApiClient apiClient = ApiClient();

  Future<List<LibraryDto>> getAllLibraries() async {
    // Do not deserialize the whole response through the legacy LibraryDto
    // generator. Modern Komga has changed library configuration fields over
    // time, while Dekluttered only needs id/name for browsing and settings.
    final Response response = await apiClient.dio.get('/api/v1/libraries');
    final dynamic data = response.data;
    if (data is! List) return <LibraryDto>[];

    final List<LibraryDto> libraries = <LibraryDto>[];
    for (final dynamic item in data) {
      if (item is! Map) continue;
      final Map<String, dynamic> json = Map<String, dynamic>.from(item);
      final dynamic id = json['id'];
      final dynamic name = json['name'];
      if (id is! String || name is! String) continue;

      libraries.add(LibraryDto(
        id: id,
        name: name,
        root: json['root'] is String ? json['root'] as String : '',
        importComicInfoBook: json['importComicInfoBook'] == true,
        importComicInfoSeries: json['importComicInfoSeries'] == true,
        importComicInfoCollection: json['importComicInfoCollection'] == true,
        importComicInfoReadList: json['importComicInfoReadList'] == true,
        importEpubBook: json['importEpubBook'] == true,
        importEpubSeries: json['importEpubSeries'] == true,
        importLocalArtwork: json['importLocalArtwork'] == true,
        scanForceModifiedTime: json['scanForceModifiedTime'] == true,
        scanDeep: json['scanDeep'] == true,
      ));
    }

    return libraries;
  }
}
