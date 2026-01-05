import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.parse(url);

  var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  return launched;
}
