import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiClient {
  late final String _baseUrl;
  late final Dio dio;

  ApiClient() {
    _baseUrl = _resolveBaseUrl();
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  String _resolveBaseUrl() {
    if (!kIsWeb) return 'http://10.0.2.2:8000';

    // Purely dynamic origin resolution for Web
    final currentOrigin = html.window.location.origin;
    
    // If the frontend is served on port 8080, assume the API is on port 8000
    if (currentOrigin.contains(':8080')) {
       return currentOrigin.replaceFirst(':8080', ':8000');
    }

    // Default to the current origin (e.g. for reverse proxy or same-port setups)
    return currentOrigin;
  }

  Future<Map<String, dynamic>> fetchStats(String shortCode) async {
    final response = await dio.get('/$shortCode/stats');
    return response.data;
  }
}
