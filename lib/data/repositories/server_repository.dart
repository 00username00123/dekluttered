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
    final Map<String, String> allPairs = await storage.readAll();
    if (allPairs.isEmpty) return <Server>[];

    final List<Server> servers = <Server>[];

    for (final entry in allPairs.entries) {
      // These are app settings/state, not saved Komga server records.
      if (entry.key == 'Current Server' ||
          entry.key.startsWith('library-reading-direction:')) {
        continue;
      }

      try {
        final dynamic decoded = jsonDecode(entry.value);
        if (decoded is! Map) continue;

        final Map<String, dynamic> json =
            Map<String, dynamic>.from(decoded as Map);

        // Only accept values that actually look like a saved Server. This also
        // makes the picker resilient to future secure-storage settings.
        if (json['name'] is! String ||
            json['url'] is! String ||
            json['username'] is! String ||
            json['password'] is! String ||
            json['key'] is! String) {
          continue;
        }

        servers.add(Server.fromJson(json));
      } catch (_) {
        // Ignore unrelated/corrupt secure-storage entries instead of making
        // the entire server picker fail to load.
      }
    }

    return servers;
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
