// ============================================================
// Anderson CVE — Step B: Dynamic JS Scanner (Headless WebView)
// Uses flutter_inappwebview in incognito/headless mode to
// evaluate window.* global objects after full JS execution.
// Zero-Trace: no cache, no cookies persisted, disposed after use.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/scan_result.dart';

class DynamicScannerService {
  static const _pageLoadTimeout = Duration(seconds: 25);

  /// JS probes to evaluate against window.*
  /// Each entry: { jsExpr, name, category }
  static const _probes = [
    _JsProbe(
      expr: "window.jQuery ? window.jQuery.fn.jquery : null",
      name: 'jQuery',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.React ? window.React.version : null",
      name: 'React',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.Vue ? (window.Vue.version || (window.Vue.default && window.Vue.default.version) || 'detected') : null",
      name: 'Vue.js',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.angular ? (window.angular.version ? window.angular.version.full : 'detected') : null",
      name: 'AngularJS',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.ng ? 'detected' : null",
      name: 'Angular',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.Backbone ? window.Backbone.VERSION : null",
      name: 'Backbone.js',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.Ember ? window.Ember.VERSION : null",
      name: 'Ember.js',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window._ ? (window._.VERSION || null) : null",
      name: 'Lodash/Underscore',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.moment ? window.moment.version : null",
      name: 'Moment.js',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.Svelte ? window.Svelte.VERSION : (document.querySelector('[class*=\"svelte-\"]') ? 'detected' : null)",
      name: 'Svelte',
      category: TechCategory.jsLibrary,
    ),
    _JsProbe(
      expr: "window.wp ? (window.wp.blocks ? 'detected' : null) : null",
      name: 'WordPress (Gutenberg)',
      category: TechCategory.cms,
    ),
    _JsProbe(
      expr: "window.Shopify ? (window.Shopify.version || 'detected') : null",
      name: 'Shopify',
      category: TechCategory.cms,
    ),
    _JsProbe(
      expr: "window.Drupal ? (window.Drupal.version || 'detected') : null",
      name: 'Drupal',
      category: TechCategory.cms,
    ),
    _JsProbe(
      expr: "window.ga ? 'detected' : (window.gtag ? 'detected' : null)",
      name: 'Google Analytics',
      category: TechCategory.analytics,
    ),
    _JsProbe(
      expr: "window.dataLayer ? 'detected' : null",
      name: 'Google Tag Manager',
      category: TechCategory.analytics,
    ),
    _JsProbe(
      expr: "window.bootstrap ? (window.bootstrap.Tooltip ? window.bootstrap.Tooltip.VERSION : null) : null",
      name: 'Bootstrap',
      category: TechCategory.cssFramework,
    ),
    _JsProbe(
      expr: "window.next ? (window.next.version || 'detected') : null",
      name: 'Next.js',
      category: TechCategory.framework,
    ),
    _JsProbe(
      expr: "window.nuxt ? 'detected' : null",
      name: 'Nuxt.js',
      category: TechCategory.framework,
    ),
  ];

  /// Runs a headless incognito WebView, loads [url], waits for page load,
  /// evaluates all JS probes, destroys the WebView and returns results.
  ///
  /// Must be called from a widget context (requires an overlay entry).
  Future<List<DetectedTech>> scan(String url, BuildContext context) async {
    final completer = Completer<List<DetectedTech>>();
    HeadlessInAppWebView? headlessWebView;

    // InAppWebView settings: incognito, no cache, no cookies
    final settings = InAppWebViewSettings(
      incognito: true,
      cacheEnabled: false,
      clearCache: true,
      clearSessionCache: true,
      javaScriptEnabled: true,
      userAgent:
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Anderson-CVE/1.0',
      // Prevent any data from being stored
      domStorageEnabled: false,
      databaseEnabled: false,
      geolocationEnabled: false,
      mediaPlaybackRequiresUserGesture: true,
      allowsInlineMediaPlayback: false,
    );

    // Timeout guard
    final timer = Timer(_pageLoadTimeout, () {
      if (!completer.isCompleted) {
        _destroyWebView(headlessWebView);
        completer.complete([]);
      }
    });

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: settings,
      onLoadStop: (controller, uri) async {
        if (completer.isCompleted) return;
        timer.cancel();

        try {
          final results = await _evaluateProbes(controller);
          completer.complete(results);
        } catch (_) {
          completer.complete([]);
        } finally {
          await _destroyWebView(headlessWebView);
        }
      },
      onReceivedError: (controller, request, error) {
        if (!completer.isCompleted) {
          timer.cancel();
          _destroyWebView(headlessWebView);
          completer.complete([]);
        }
      },
    );

    await headlessWebView.run();

    return completer.future;
  }

  Future<List<DetectedTech>> _evaluateProbes(
      InAppWebViewController controller) async {
    final List<DetectedTech> found = [];

    for (final probe in _probes) {
      try {
        final result = await controller.evaluateJavascript(source: probe.expr);
        if (result == null || result == 'null') continue;

        final version = (result is String && result != 'detected')
            ? result
            : null;

        found.add(DetectedTech(
          name: probe.name,
          version: version,
          category: probe.category,
          detectionSource: 'js_global',
        ));
      } catch (_) {
        // Probe failed — not a detection failure, just skip
        continue;
      }
    }

    return found;
  }

  Future<void> _destroyWebView(HeadlessInAppWebView? webView) async {
    if (webView == null) return;
    try {
      final ctrl = await webView.webViewController;
      await ctrl?.clearCache();
      await webView.dispose();
    } catch (_) {}
  }
}

class _JsProbe {
  final String expr;
  final String name;
  final TechCategory category;

  const _JsProbe({
    required this.expr,
    required this.name,
    required this.category,
  });
}
