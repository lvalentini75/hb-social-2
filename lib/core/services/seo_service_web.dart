import 'package:web/web.dart' as web;

class SeoService {
  static void setLanguage(String languageCode) => web.document.documentElement?.setAttribute('lang', languageCode);

  static void update({required String title, required String description, required String path, String? imageUrl}) {
    web.document.title = title;
    _meta('name', 'description', description);
    _meta('property', 'og:title', title);
    _meta('property', 'og:description', description);
    _meta('property', 'og:url', Uri.base.resolve(path).toString());
    _meta('property', 'og:image', imageUrl ?? Uri.base.resolve('/icons/Icon-512.png').toString());
  }

  static void _meta(String attribute, String value, String content) {
    var element = web.document.head?.querySelector('meta[$attribute="$value"]') as web.HTMLMetaElement?;
    if (element == null) {
      element = web.document.createElement('meta') as web.HTMLMetaElement;
      element.setAttribute(attribute, value);
      web.document.head?.append(element);
    }
    element.content = content;
  }
}