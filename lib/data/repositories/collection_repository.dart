import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/librarydto.dart';
import 'package:klutter/data/models/pagecollectiondto.dart';
import 'package:klutter/data/repositories/libraries_repository.dart';

class CollectionsRepository {
  Map<String, List<int>> thumbMap = {};
  final ApiClient _apiClient = ApiClient();

  Future<PageCollectionDto> getCollections(
      int page, LibraryDto? library) async {
    List<String>? libraryIds;
    if (library != null) {
      libraryIds = <String>[library.id];
    } else {
      final libraries = await LibrariesRepository().getAllLibraries();
      libraryIds = libraries.map((e) => e.id).toList();
    }

    return await _apiClient.collectionController.getCollections(
        libraryId: libraryIds == null || libraryIds.isEmpty ? null : libraryIds,
        page: page,
        size: 100);
  }

  Future<List<int>> getThumbnail(String id) async {
    if (thumbMap[id] != null) {
      return thumbMap[id]!;
    } else {
      thumbMap[id] = await _apiClient.collectionController.getThumbnail(id);
      return thumbMap[id]!;
    }
  }
}
