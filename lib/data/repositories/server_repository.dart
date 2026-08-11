import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/data/models/server.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ServerRepository {
  IOSOptions iosOptions =
      IOSOptions(accessibility: IOSAccessibility.first_unlock);
  final storage = FlutterSecureStorage();
  Uuid uuid = Uuid();

  Future<List<Server>> getAllServers() async {
    Map<String, String> allPairs = await storage.readAll();
    if (allPairs.isEmpty) {
      return List.empty();
    } else {
      if (allPairs.containsKey('Current Server')) {
        allPairs.remove('Current Server');
      }
      List<Map<String, dynamic>> serverJsons = allPairs.values
          .toList()
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
      return serverJsons.map((e) => Server.fromJson(e)).toList();
    }
  }

  Future<void> addServer(Server server) async {
    String serverString = jsonEncode(server.toJson());
    return await storage.write(
      key: server.key,
      value: serverString,
      iOptions: iosOptions,
    );
  }

  Future<void> removeServer(String key) async {
    return await storage.delete(key: key);
  }

  Future<void> setCurrentServer(Server server) async {
    String serverString = jsonEncode(server.toJson());
    await storage.delete(key: 'Current Server');
    await storage.write(key: 'Current Server', value: serverString);
    await ApiClient.init();
  }

  /// Returns null when the credentials/server are valid, otherwise a
  /// user-readable error. Use a raw authenticated request here instead of a
  /// generated DTO endpoint so Komga response-model changes cannot make a
  /// perfectly valid login look invalid.
  Future<String?> testServer(Server server) async {
    final BaseOptions options = BaseOptions(
      baseUrl: server.url,
      connectTimeout: 10000,
      receiveTimeout: 10000,
      headers: {
        'Authorization':
            genBasicAuthHeaderValue(server.username.trim(), server.password),
      },
    );
    final Dio dio = Dio(options);

    try {
      final Response response = await dio.get(
        '/api/v1/series/latest',
        queryParameters: {'size': 1},
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        return null;
      }
      return 'Komga returned HTTP $status';
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'Login rejected by Komga. Check your email/username and password.';
      }
      if (status != null) {
        return 'Komga returned HTTP $status while testing the server.';
      }
      return 'Could not reach the Komga server. Check the address and network connection.';
    } on Exception catch (_) {
      return 'Could not connect to the Komga server.';
    }
  }
}

String genBasicAuthHeaderValue(String user, String pass) {
  return 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
}
