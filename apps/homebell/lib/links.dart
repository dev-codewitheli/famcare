import 'package:url_launcher/url_launcher.dart';

/// Public pages about HomeBell, hosted on the developer's GitHub Pages site.
class Links {
  Links._();

  static final privacyPolicy = Uri.parse('https://dev-codewitheli.github.io/homebell/privacy.html');
  static final sourceCode = Uri.parse('https://github.com/dev-codewitheli/famcare');

  static Future<void> open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
