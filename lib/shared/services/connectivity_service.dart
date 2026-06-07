// ============================================
// FILE: connectivity_service.dart
// PATH: lib/shared/services/connectivity_service.dart
// LAYER: service
// DOMAIN: shared
// RESPONSIBLE FOR: Wraps connectivity_plus and exposes a stream of online/offline boolean status.
// RECEIVES: Nothing
// RETURNS: Stream<bool> — true = online, false = offline
// CONNECTS TO: Any provider or service that needs network awareness
// MUST NEVER: Contain Riverpod, UI imports, or business logic
// ============================================

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  // Internal broadcast controller seeded with current state
  Stream<bool>? _onlineStream;

  /// Broadcast stream of online status.
  /// Emits true = online, false = offline.
  /// Emits current state immediately on subscription.
  Stream<bool> get onlineStream {
    _onlineStream ??= _connectivity.onConnectivityChanged
        .map(_isOnline)
        .asBroadcastStream();

    return _buildSeededStream();
  }

  /// One-shot check of current connectivity state.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  // ─── private ───────────────────────────────────────────────

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Wraps the broadcast stream with an immediate seed value
  /// so new subscribers always get the current state first.
  Stream<bool> _buildSeededStream() async* {
    yield await isOnline; // immediate current state
    yield* _connectivity
        .onConnectivityChanged // then live updates
        .map(_isOnline);
  }
}
