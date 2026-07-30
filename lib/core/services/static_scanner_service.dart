// ============================================================
// Anderson CVE — Step A: Static / Passive Scanner
// Reads HTTP headers, HTML meta tags, and DOM asset URLs
// to fingerprint technologies without executing JavaScript.
// ============================================================

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/scan_result.dart';

class StaticScannerService {
  static const _timeout = Duration(seconds: 20);

  /// Fetches [url] and extracts all technologies it can identify
  /// from response headers and the static HTML document.
  Future<List<DetectedTech>> scan(String url) async {
    final List<DetectedTech> found = [];

    late http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Anderson-CVE/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9',
        },
      ).timeout(_timeout);
    } catch (e) {
      throw ScanException('Network error fetching $url: $e');
    }

    // ─── A1 : HTTP Response Headers ────────────────────────────
    found.addAll(_parseHeaders(response.headers));

    // ─── A2 : HTML Meta Tags ───────────────────────────────────
    final document = html_parser.parse(response.body);
    found.addAll(_parseMetaTags(document));

    // ─── A3 : DOM Assets (script/link src with version params) ─
    found.addAll(_parseDomAssets(document));

    return _deduplicateByName(found);
  }

  // ─── A1 Header Fingerprints ──────────────────────────────────

  List<DetectedTech> _parseHeaders(Map<String, String> headers) {
    final List<DetectedTech> techs = [];

    // Server header  (e.g. "nginx/1.24.0" or "Apache/2.4.57")
    final server = headers['server'];
    if (server != null) {
      final m = RegExp(r'^([\w\-]+)(?:/([\d.]+))?').firstMatch(server);
      if (m != null) {
        techs.add(DetectedTech(
          name: _normalise(m.group(1)!),
          version: m.group(2),
          category: TechCategory.server,
          detectionSource: 'header:server',
        ));
      }
    }

    // X-Powered-By  (e.g. "PHP/8.2.1" or "Express")
    final xpb = headers['x-powered-by'];
    if (xpb != null) {
      final m = RegExp(r'^([\w\-\.]+)(?:/([\d.]+))?').firstMatch(xpb);
      if (m != null) {
        techs.add(DetectedTech(
          name: _normalise(m.group(1)!),
          version: m.group(2),
          category: _guessCategory(m.group(1)!),
          detectionSource: 'header:x-powered-by',
        ));
      }
    }

    // CMS-specific headers
    final headerSigs = <String, String>{
      'x-drupal-cache': 'Drupal',
      'x-drupal-dynamic-cache': 'Drupal',
      'x-wp-nonce': 'WordPress',
      'x-shopify-stage': 'Shopify',
      'x-ghost-cache-status': 'Ghost',
      'x-joomla-build': 'Joomla',
    };
    for (final entry in headerSigs.entries) {
      if (headers.containsKey(entry.key)) {
        techs.add(DetectedTech(
          name: entry.value,
          category: TechCategory.cms,
          detectionSource: 'header:${entry.key}',
        ));
      }
    }

    // ASP.NET via X-AspNet-Version
    final aspNet = headers['x-aspnet-version'];
    if (aspNet != null) {
      techs.add(DetectedTech(
        name: 'ASP.NET',
        version: aspNet,
        category: TechCategory.framework,
        detectionSource: 'header:x-aspnet-version',
      ));
    }

    return techs;
  }

  // ─── A2 Meta Tag Fingerprints ────────────────────────────────

  List<DetectedTech> _parseMetaTags(dynamic document) {
    final List<DetectedTech> techs = [];

    for (final meta in document.querySelectorAll('meta[name="generator"]')) {
      final content = meta.attributes['content'];
      if (content == null || content.isEmpty) continue;

      // Common generators: "WordPress 6.4.2", "Drupal 10", "Joomla! 4.3.4"
      final m = RegExp(
        r'^([\w\s\!\-]+?)[\s\/]+([\d]+(?:\.[\d]+)*)',
        caseSensitive: false,
      ).firstMatch(content);

      if (m != null) {
        techs.add(DetectedTech(
          name: _normalise(m.group(1)!),
          version: m.group(2),
          category: TechCategory.cms,
          detectionSource: 'meta:generator',
        ));
      } else if (content.trim().isNotEmpty) {
        techs.add(DetectedTech(
          name: _normalise(content.trim()),
          category: TechCategory.cms,
          detectionSource: 'meta:generator',
        ));
      }
    }

    return techs;
  }

  // ─── A3 DOM Asset URL Fingerprints ───────────────────────────

  List<DetectedTech> _parseDomAssets(dynamic document) {
    final List<DetectedTech> techs = [];

    // Map: regex pattern → (name, category)
    final assetPatterns = <RegExp, _AssetSig>{
      // WordPress version in query param
      RegExp(r'\?ver=([\d.]+)', caseSensitive: false):
          _AssetSig('WordPress', TechCategory.cms),

      // jQuery: jquery-3.6.0.min.js or jquery/3.6.0
      RegExp(r'jquery[/-]([\d]+\.[\d]+\.[\d]+)', caseSensitive: false):
          _AssetSig('jQuery', TechCategory.jsLibrary),

      // Bootstrap
      RegExp(r'bootstrap[/-]([\d]+\.[\d]+\.[\d]+)', caseSensitive: false):
          _AssetSig('Bootstrap', TechCategory.cssFramework),

      // React (react.production.min.js)
      RegExp(r'react(?:\.production)?\.min\.js\b', caseSensitive: false):
          _AssetSig('React', TechCategory.jsLibrary),

      // Vue
      RegExp(r'vue(?:\.min)?\.js\b', caseSensitive: false):
          _AssetSig('Vue.js', TechCategory.jsLibrary),

      // Angular
      RegExp(r'@angular/core@([\d.]+)', caseSensitive: false):
          _AssetSig('Angular', TechCategory.jsLibrary),

      // Lodash
      RegExp(r'lodash[.-]([\d]+\.[\d]+\.[\d]+)', caseSensitive: false):
          _AssetSig('Lodash', TechCategory.jsLibrary),

      // Moment.js
      RegExp(r'moment[.-]([\d]+\.[\d]+\.[\d]+)', caseSensitive: false):
          _AssetSig('Moment.js', TechCategory.jsLibrary),
    };

    final selectors = [
      ...document.querySelectorAll('script[src]'),
      ...document.querySelectorAll('link[href]'),
    ];

    for (final el in selectors) {
      final src = (el.attributes['src'] ?? el.attributes['href'] ?? '');
      if (src.isEmpty) continue;

      for (final entry in assetPatterns.entries) {
        final match = entry.key.firstMatch(src);
        if (match != null) {
          techs.add(DetectedTech(
            name: entry.value.name,
            version: match.groupCount > 0 ? match.group(1) : null,
            category: entry.value.category,
            detectionSource: 'dom:asset',
          ));
          break; // one match per asset element is enough
        }
      }
    }

    return techs;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _normalise(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll('!', '');

  TechCategory _guessCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('php') || n.contains('ruby') || n.contains('python')) {
      return TechCategory.language;
    }
    if (n.contains('express') || n.contains('rails') || n.contains('laravel')) {
      return TechCategory.framework;
    }
    return TechCategory.unknown;
  }

  List<DetectedTech> _deduplicateByName(List<DetectedTech> techs) {
    final Map<String, DetectedTech> map = {};
    for (final t in techs) {
      final key = t.name.toLowerCase();
      if (!map.containsKey(key) ||
          (t.version != null && map[key]!.version == null)) {
        map[key] = t;
      }
    }
    return map.values.toList();
  }
}

class _AssetSig {
  final String name;
  final TechCategory category;
  const _AssetSig(this.name, this.category);
}

class ScanException implements Exception {
  final String message;
  const ScanException(this.message);
  @override
  String toString() => 'ScanException: $message';
}
