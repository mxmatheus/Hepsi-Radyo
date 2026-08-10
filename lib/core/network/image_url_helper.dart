import 'package:flutter/foundation.dart';

class ImageUrlHelper {
  /// Converts image URLs on Flutter Web to use a CORS-safe image proxy (wsrv.nl),
  /// cleans dirty markdown image URLs, filters broken domains, and keeps native Android/iOS requests direct.
  static String getCorsSafeUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.trim().isEmpty) return '';
    var url = originalUrl.trim();

    // Clean malformed markdown URLs like "http://site.com/logo.png](http://site.com/logo.png"
    if (url.contains('](')) {
      url = url.split('](').first.trim();
    }
    if (url.endsWith(']')) {
      url = url.substring(0, url.length - 1).trim();
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) return url;

    // Filter out known broken/dead favicon domains to prevent browser console 404s
    final brokenDomains = [
      'radyonida.com.tr',
      'imbatfm.com',
      'radyocan.net',
      'tarsusfm.com.tr',
      'radyo9.com',
      'radio5.com.tr',
      'turkuradyo.info'
    ];

    if (brokenDomains.any((domain) => url.contains(domain))) {
      return ''; // Cleanly triggers fallback logo badge
    }

    if (kIsWeb) {
      // wsrv.nl is a free, high-performance image CDN proxy with CORS headers enabled
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
    }

    return url;
  }
}
