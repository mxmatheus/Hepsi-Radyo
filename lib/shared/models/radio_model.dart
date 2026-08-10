import '../../core/network/image_url_helper.dart';

class RadioModel {
  final String id;
  final String name;
  final String streamUrl;
  final String? faviconUrl;
  final List<String> tags;
  final String country;
  final String? city;
  final int bitrate;
  final String codec;
  final bool isActive;
  final bool isMetadataSupported;
  final String source;
  final String? radioBrowserUuid;
  final int sortOrder;

  RadioModel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.faviconUrl,
    this.tags = const [],
    this.country = 'Turkey',
    this.city,
    this.bitrate = 128,
    this.codec = 'MP3',
    this.isActive = true,
    this.isMetadataSupported = true,
    this.source = 'radio-browser',
    this.radioBrowserUuid,
    this.sortOrder = 0,
  });

  String? get corsSafeFavicon {
    if (faviconUrl == null || faviconUrl!.isEmpty) return null;
    return ImageUrlHelper.getCorsSafeUrl(faviconUrl);
  }

  /// Automatically repairs and upgrades stream URLs (StreamTheWorld, Karnaval, Kral, Slow Turk)
  static String fixStreamUrl(String rawUrl, String name) {
    if (rawUrl.isEmpty) return rawUrl;
    var url = rawUrl.trim();

    final nameLower = name.toLowerCase();

    // 1. Karnaval & StreamTheWorld official live redirect resolution
    if (url.contains('streamtheworld.com') || nameLower.contains('virgin') || nameLower.contains('metro') || nameLower.contains('joy')) {
      if (nameLower.contains('virgin')) {
        return 'https://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC';
      } else if (nameLower.contains('metro')) {
        return 'https://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC';
      } else if (nameLower.contains('süper fm') || nameLower.contains('super fm')) {
        return 'https://playerservices.streamtheworld.com/api/livestream-redirect/SUPER_FM_SC';
      } else if (nameLower.contains('joy türk') || nameLower.contains('joy turk')) {
        return 'https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_TURK_SC';
      } else if (nameLower.contains('joy fm') || nameLower.contains('joyfm')) {
        return 'https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_FM_SC';
      }

      final regExp = RegExp(r'/([A-Za-z0-9_]+_SC)', caseSensitive: false);
      final match = regExp.firstMatch(url);
      if (match != null) {
        final stationId = match.group(1)!.toUpperCase();
        return 'https://playerservices.streamtheworld.com/api/livestream-redirect/$stationId';
      }
    }

    // 2. High quality verified streams
    if (nameLower == 'kral fm') {
      return 'https://dygedge2.radyotvonline.net/kralfm/playlist.m3u8';
    } else if (nameLower == 'slow türk' || nameLower == 'slow turk') {
      return 'https://radyo.duhnet.tv/slowturk';
    } else if (nameLower == 'power fm') {
      return 'https://listen.powerapp.com.tr/powerfm/mpeg/icecast.audio';
    }

    return url;
  }

  factory RadioModel.fromJson(Map<String, dynamic> json) {
    List<String> tagsList = [];
    if (json['tags'] is List) {
      tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      tagsList = (json['tags'] as String).split(',').map((e) => e.trim()).toList();
    }

    final rawFavicon = (json['favicon_url'] != null && json['favicon_url'].toString().startsWith('http'))
        ? json['favicon_url']
        : ((json['favicon'] != null && json['favicon'].toString().startsWith('http')) ? json['favicon'] : null);

    final rawName = json['name'] ?? 'Bilinmeyen Radyo';
    final rawStream = json['stream_url'] ?? json['url'] ?? '';
    final sanitizedStream = fixStreamUrl(rawStream, rawName);

    return RadioModel(
      id: json['id']?.toString() ?? json['radio_browser_uuid']?.toString() ?? rawName,
      name: rawName,
      streamUrl: sanitizedStream,
      faviconUrl: rawFavicon,
      tags: tagsList,
      country: json['country'] ?? 'Turkey',
      city: json['city'] ?? json['state'] ?? 'Genel',
      bitrate: json['bitrate'] is int ? json['bitrate'] : (int.tryParse(json['bitrate']?.toString() ?? '128') ?? 128),
      codec: json['codec'] ?? 'MP3',
      isActive: json['is_active'] ?? true,
      isMetadataSupported: json['is_metadata_supported'] ?? true,
      source: json['source'] ?? 'radio-browser',
      radioBrowserUuid: json['radio_browser_uuid'] ?? json['stationuuid'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'favicon_url': faviconUrl,
      'tags': tags,
      'country': country,
      'city': city,
      'bitrate': bitrate,
      'codec': codec,
      'is_active': isActive,
      'is_metadata_supported': isMetadataSupported,
      'source': source,
      'radio_browser_uuid': radioBrowserUuid,
      'sort_order': sortOrder,
    };
  }
}
