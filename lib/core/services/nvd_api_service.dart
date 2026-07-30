// ============================================================
// Anderson CVE — Step C: NIST NVD API v2.0 Service
// Queries https://services.nvd.nist.gov/rest/json/cves/2.0
// for each detected technology and returns CVE entries.
// Results are purely in-memory (never written to disk).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/scan_result.dart';

class NvdApiService {
  static const _baseUrl = 'https://services.nvd.nist.gov/rest/json/cves/2.0';
  static const _resultsPerPage = 20;
  static const _timeout = Duration(seconds: 30);

  // Rate-limit: NVD allows ~5 req/30s without API key.
  // With NIST_NVD_API_KEY env var it's 50 req/30s.
  final String? _apiKey;

  NvdApiService({String? apiKey}) : _apiKey = apiKey;

  /// Fetches CVEs for a given [tech] and its [version].
  /// Uses keywordSearch = "<name> <version>" when version is known,
  /// else just the name. Returns up to [_resultsPerPage] entries.
  Future<List<CveItem>> fetchCves(DetectedTech tech) async {
    final keyword = tech.version != null
        ? '${tech.name} ${tech.version}'
        : tech.name;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'keywordSearch': keyword,
      'resultsPerPage': '$_resultsPerPage',
      'keywordExactMatch': 'false',
    });

    final headers = <String, String>{
      'Accept': 'application/json',
      if (_apiKey != null) 'apiKey': _apiKey!,
    };

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else if (response.statusCode == 429) {
        // Rate limited — wait and retry once
        await Future.delayed(const Duration(seconds: 6));
        final retry = await http
            .get(uri, headers: headers)
            .timeout(_timeout);
        if (retry.statusCode == 200) {
          return _parseResponse(retry.body);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  List<CveItem> _parseResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final vulnerabilities = json['vulnerabilities'] as List<dynamic>? ?? [];
      return vulnerabilities
          .cast<Map<String, dynamic>>()
          .map(CveItem.fromNvdJson)
          .where((c) => c.cvssScore > 0)
          .toList()
        ..sort((a, b) => b.cvssScore.compareTo(a.cvssScore));
    } catch (_) {
      return [];
    }
  }

  /// Batch-fetches CVEs for all [technologies], respecting NVD rate limits.
  /// Emits progress via [onProgress] callback (0.0 → 1.0).
  Future<List<DetectedTech>> enrichWithCves(
    List<DetectedTech> technologies, {
    void Function(double progress, String techName)? onProgress,
  }) async {
    final enriched = <DetectedTech>[];

    for (var i = 0; i < technologies.length; i++) {
      final tech = technologies[i];
      onProgress?.call(i / technologies.length, tech.name);

      final cves = await fetchCves(tech);
      enriched.add(tech.copyWith(cves: cves));

      // Respect NVD rate limit between requests
      if (i < technologies.length - 1) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    onProgress?.call(1.0, '');
    return enriched;
  }
}
