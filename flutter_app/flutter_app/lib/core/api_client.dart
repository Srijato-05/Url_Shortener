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

    final currentOrigin = html.window.location.origin;
    
    // If running on dev port 8080, assume backend is on 8000
    if (currentOrigin.contains(':8080')) {
       return currentOrigin.replaceFirst(':8080', ':8000');
    }

    // Check if the origin has a port specified (e.g. http://localhost:1234)
    // We check for a colon that is NOT part of the protocol (http:// or https://)
    final hasPort = RegExp(r':\d+$').hasMatch(currentOrigin);

    if (!hasPort) {
       // Gateway mode (Port 80/443): Use /api prefix for all backend calls
       return '$currentOrigin/api';
    }

    return currentOrigin;
  }

  Future<Map<String, dynamic>> fetchStats(String shortCode) async {
    final response = await dio.get('/$shortCode/stats');
    return response.data;
  }
}
