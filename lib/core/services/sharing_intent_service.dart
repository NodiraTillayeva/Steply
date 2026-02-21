import 'dart:async';
import 'package:flutter/services.dart';

/// Service to handle incoming share intents from Share Extension
/// Works with iOS Share Extension via App Groups and method channel
class SharingIntentService {
  static const platform = MethodChannel('com.example.steply/share');
  Timer? _pollingTimer;

  /// Callback when a shared URL is received while app is running
  Function(String url)? onUrlReceived;

  /// Initialize sharing intent listeners for warm start scenario
  void initialize() {
    _debugShareSetup();
    print('🔗 Sharing intent service initialized (Share Extension mode)');
    _startPolling();
  }

  Future<void> _debugShareSetup() async {
    try {
      final result = await platform.invokeMethod('debugShareSetup');
      print('🔗 App Group accessible: $result');
    } catch (e) {
      print('🔗 Debug check failed: $e');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final url = await _checkForSharedURL();
      if (url != null && url.isNotEmpty && _isValidUrl(url)) {
        print('🔗 Shared URL received (warm start): $url');
        onUrlReceived?.call(url);
      }
    });
  }

  /// Check for initial shared data when app starts (cold start)
  Future<String?> getInitialSharedURL() async {
    try {
      final url = await _checkForSharedURL();
      if (url != null && url.isNotEmpty && _isValidUrl(url)) {
        print('🔗 Initial shared URL (cold start): $url');
        return url;
      }
    } catch (e) {
      print('❌ Error getting initial shared URL: $e');
    }

    return null;
  }

  /// Check for shared URL via method channel
  Future<String?> _checkForSharedURL() async {
    try {
      final result = await platform.invokeMethod('getSharedURL');
      return result as String?;
    } on PlatformException catch (e) {
      print('❌ Platform exception: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error checking for shared URL: $e');
      return null;
    }
  }

  /// Validate if the shared text is a valid URL
  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Dispose of subscriptions
  void dispose() {
    _pollingTimer?.cancel();
  }
}
