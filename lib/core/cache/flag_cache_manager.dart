import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for flag images.
///
/// Configures a 7-day stale period and a maximum of 500 cached objects
/// (approximately the number of countries in the world).
class FlagCacheManager extends CacheManager {
  static const String key = 'flagCache';

  static final FlagCacheManager _instance = FlagCacheManager._();

  factory FlagCacheManager() => _instance;

  FlagCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
