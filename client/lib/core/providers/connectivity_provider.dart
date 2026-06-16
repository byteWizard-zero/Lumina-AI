import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

class ConnectivityState {
  final bool isOnline;
  final bool isServerAwake;
  final bool isWakingUp;

  ConnectivityState({
    required this.isOnline,
    required this.isServerAwake,
    required this.isWakingUp,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    bool? isServerAwake,
    bool? isWakingUp,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      isServerAwake: isServerAwake ?? this.isServerAwake,
      isWakingUp: isWakingUp ?? this.isWakingUp,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _service = ConnectivityService();
  StreamSubscription? _subscription;

  ConnectivityNotifier() : super(ConnectivityState(isOnline: true, isServerAwake: false, isWakingUp: false)) {
    _init();
  }

  void _init() async {
    // Check initial connectivity status
    final hasNetwork = await _service.isNetworkConnected();
    if (hasNetwork) {
      final hasInternet = await _service.checkInternetAccess();
      state = state.copyWith(isOnline: hasInternet);
      if (hasInternet) {
        wakeUpBackend();
      }
    } else {
      state = state.copyWith(isOnline: false);
    }

    // Subscribe to connection change streams
    _subscription = _service.onConnectivityChanged.listen((results) async {
      final hasConn = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (hasConn) {
        final hasInternet = await _service.checkInternetAccess();
        final wasOffline = !state.isOnline;
        state = state.copyWith(isOnline: hasInternet);
        
        // If restored from offline, or the server is not awake yet, trigger the wakeup ping
        if (hasInternet && (wasOffline || !state.isServerAwake)) {
          wakeUpBackend();
        }
      } else {
        state = state.copyWith(isOnline: false, isServerAwake: false);
      }
    });
  }

  // Pre-emptively sends `/ping` to wake the Render backend from sleep
  Future<void> wakeUpBackend() async {
    if (state.isWakingUp || state.isServerAwake) return;
    
    state = state.copyWith(isWakingUp: true);
    final success = await _service.wakeUpRenderBackend();
    
    state = state.copyWith(
      isServerAwake: success,
      isWakingUp: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});
