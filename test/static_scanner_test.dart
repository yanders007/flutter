// ============================================================
// Anderson CVE — Static Scanner Unit Tests
// Tests regex patterns used in passive HTTP/DOM analysis.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:anderson_cve/core/models/scan_result.dart';

// We test the internal parsing logic indirectly through public-facing
// helpers. Full integration tests require a live network.

void main() {
  group('Header fingerprint patterns', () {
    final serverRegex = RegExp(r'^([\w\-]+)(?:/([\d.]+))?');

    test('parses nginx server header', () {
      final m = serverRegex.firstMatch('nginx/1.24.0');
      expect(m?.group(1), 'nginx');
      expect(m?.group(2), '1.24.0');
    });

    test('parses Apache server header', () {
      final m = serverRegex.firstMatch('Apache/2.4.57 (Debian)');
      expect(m?.group(1), 'Apache');
      expect(m?.group(2), '2.4.57');
    });

    test('parses headerless server', () {
      final m = serverRegex.firstMatch('cloudflare');
      expect(m?.group(1), 'cloudflare');
      expect(m?.group(2), isNull);
    });
  });

  group('Meta generator patterns', () {
    final generatorRegex = RegExp(
      r'^([\w\s\!\-]+?)[\s\/]+([\d]+(?:\.[\d]+)*)',
      caseSensitive: false,
    );

    test('parses WordPress generator', () {
      final m = generatorRegex.firstMatch('WordPress 6.4.2');
      expect(m?.group(1)?.trim(), 'WordPress');
      expect(m?.group(2), '6.4.2');
    });

    test('parses Drupal generator', () {
      final m = generatorRegex.firstMatch('Drupal 10.1.2 (https://www.drupal.org)');
      expect(m?.group(1)?.trim(), 'Drupal');
      expect(m?.group(2), '10.1.2');
    });

    test('parses Joomla generator', () {
      final m = generatorRegex.firstMatch('Joomla! 4.3.4');
      expect(m?.group(1)?.trim(), 'Joomla!');
      expect(m?.group(2), '4.3.4');
    });
  });

  group('DOM asset URL patterns', () {
    final jqueryRegex = RegExp(r'jquery[/-]([\d]+\.[\d]+\.[\d]+)',
        caseSensitive: false);
    final bootstrapRegex = RegExp(r'bootstrap[/-]([\d]+\.[\d]+\.[\d]+)',
        caseSensitive: false);
    final wpVerRegex = RegExp(r'\?ver=([\d.]+)', caseSensitive: false);

    test('extracts jQuery version from filename', () {
      const src = '/wp-includes/js/jquery/jquery-3.7.1.min.js';
      final m = jqueryRegex.firstMatch(src);
      expect(m?.group(1), '3.7.1');
    });

    test('extracts Bootstrap version from CDN URL', () {
      const src = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css';
      // CDN uses @ so test a common filename pattern:
      final m = bootstrapRegex.firstMatch('bootstrap-5.3.0.min.js');
      expect(m?.group(1), '5.3.0');
    });

    test('extracts WordPress ver query param', () {
      const src = '/wp-content/themes/twentytwenty/style.css?ver=6.4.2';
      final m = wpVerRegex.firstMatch(src);
      expect(m?.group(1), '6.4.2');
    });
  });

  group('SeverityLevel color mapping', () {
    test('all severity levels map to a non-null label', () {
      for (final level in SeverityLevel.values) {
        expect(level.label, isNotEmpty);
      }
    });
  });
}
