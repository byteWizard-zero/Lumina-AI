import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio();
  
  // Stream of network changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  // Performs a quick check to see if the device is connected to a network adapter
  Future<bool> isNetworkConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty && !result.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint("Check connectivity exception: $e");
      return false;
    }
  }

  // Verifies if there is actual internet access by executing a quick socket/DNS lookup
  Future<bool> checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      debugPrint("Internet address lookup failed: $e");
      return false;
    }
  }

  // Sends a pre-emptive ping request to trigger a cold boot on the Render backend
  Future<bool> wakeUpRenderBackend() async {
    try {
      final baseUrl = dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000';
      final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final pingUrl = '$cleanUrl/ping';

      debugPrint("Pre-emptive wakeup: sending ping to $pingUrl");
      
      // Use long timeouts (60s) to allow Render free tier to complete cold boot without throwing timeout error
      final response = await _dio.get(
        pingUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          connectTimeout: const Duration(seconds: 60),
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint("Render backend is awake: ${response.data}");
        return true;
      }
    } catch (e) {
      debugPrint("Render backend wakeup ping failed (server is likely still spinning up): $e");
    }
    return false;
  }
}
