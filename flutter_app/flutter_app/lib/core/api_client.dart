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
    const buildTimeUrl = String.fromEnvironment('API_BASE_URL');
    
    if (!kIsWeb) return buildTimeUrl.isNotEmpty ? buildTimeUrl : 'http://10.0.2.2:8000';

    // In Web environments, prioritize the current origin to avoid 'localhost' mismatches
    final currentOrigin = html.window.location.origin;
    if (currentOrigin.contains('localhost')) {
      return buildTimeUrl.isNotEmpty ? buildTimeUrl : 'http://localhost:8000';
    }

    // If served from a real IP/Domain, assume API is on port 8000 of the same host
    // or use the browser's origin if it's the same port (reverse proxy setup)
    return currentOrigin.replaceFirst(':8080', ':8000');
  }

  Future<Map<String, dynamic>> fetchStats(String shortCode) async {
    final response = await dio.get('/$shortCode/stats');
    return response.data;
  }
}
