import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/collectiondto.dart';
import 'package:klutter/data/models/librarydto.dart';
import 'package:klutter/data/models/pageseriesdto.dart';
import 'package:klutter/data/repositories/libraries_repository.dart';

class SeriesRepository {
  ApiClient _apiClient = ApiClient();
  Map<String, List<int>> thumbMap = {};

  Future<PageSeriesDto> getSeries(
      int page, LibraryDto? library, CollectionDto? collection) async {
    List<String>? libraryIds;
    if (library != null) {
      libraryIds = <String>[library.id];
    } else {
      final libraries = await LibrariesRepository().getAllLibraries();
      libraryIds = libraries.map((e) => e.id).toList();
    }

    return await _apiClient.seriesController.getSeries(
        collectionId: collection == null ? null : [collection.id],
        page: page,
        libraryId: libraryIds == null || libraryIds.isEmpty ? null : libraryIds,
        size: 30);
  }

  Future<List<int>> getThumbnail(String id) async {
    if (thumbMap[id] != null) {
      return thumbMap[id]!;
    } else {
      thumbMap[id] = await _apiClient.seriesController.getThumbnail(id);
      return thumbMap[id]!;
    }
  }
}
