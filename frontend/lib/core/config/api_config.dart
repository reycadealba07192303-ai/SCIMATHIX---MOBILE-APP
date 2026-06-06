

/// Backend connection settings for the Flutter app.
///
/// Physical devices cannot use `localhost` — they need your PC's LAN IP.
/// Override at run time, e.g. Android emulator:
///   flutter run --dart-define=API_HOST=10.0.2.2
class ApiConfig {
  // Use the Render URL as the default server base URL
  static const String serverBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://scimathix-mobile-app.onrender.com',
  );

  static String get apiBaseUrl => '$serverBaseUrl/api';

  static String get uploadsBaseUrl => '$serverBaseUrl/uploads/';

  /// Cache-buster revision. Incremented after each profile image upload so
  /// [NetworkImage] re-fetches the resource instead of serving a stale copy.
  static int _imageCacheVersion = 0;

  /// Call this after a successful profile image upload to invalidate caches.
  static void bustImageCache() => _imageCacheVersion++;

  /// Resolves a stored image path to a full URL, tolerating both
  /// "/uploads/xxx.png" (new) and "xxx.png" (legacy) storage formats.
  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String url;
    if (path.startsWith('http')) {
      url = path;
    } else if (path.startsWith('/uploads/')) {
      url = '$serverBaseUrl$path';
    } else if (path.startsWith('uploads/')) {
      url = '$serverBaseUrl/$path';
    } else {
      url = '$uploadsBaseUrl$path';
    }
    // Append cache-buster to force reload after upload
    if (_imageCacheVersion > 0) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}v=$_imageCacheVersion';
    }
    return url;
  }
}
