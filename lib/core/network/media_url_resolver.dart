import '../constants/api_config.dart';

class MediaUrlResolver {
  MediaUrlResolver._();

  static String? resolve(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return rawUrl;
    }

    final mediaUri = Uri.tryParse(rawUrl);
    final apiUri = Uri.tryParse(ApiConfig.baseUrl);
    if (mediaUri == null || apiUri == null) {
      return rawUrl;
    }

    final host = mediaUri.host.toLowerCase();
    if (host != 'localhost' && host != '127.0.0.1' && host != '::1') {
      return rawUrl;
    }

    return mediaUri
        .replace(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.hasPort ? apiUri.port : null,
        )
        .toString();
  }
}
