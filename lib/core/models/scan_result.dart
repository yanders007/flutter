// ============================================================
// Anderson CVE — Core Models (100% In-Memory, Zero Persistence)
// All instances live exclusively in RAM and are GC'd on dispose.
// ============================================================

enum SeverityLevel { critical, high, medium, low, none }

extension SeverityLevelExtension on SeverityLevel {
  String get label => switch (this) {
        SeverityLevel.critical => 'CRITICAL',
        SeverityLevel.high => 'HIGH',
        SeverityLevel.medium => 'MEDIUM',
        SeverityLevel.low => 'LOW',
        SeverityLevel.none => 'NONE',
      };

  static SeverityLevel fromCvss(double score) {
    if (score >= 9.0) return SeverityLevel.critical;
    if (score >= 7.0) return SeverityLevel.high;
    if (score >= 4.0) return SeverityLevel.medium;
    if (score > 0.0) return SeverityLevel.low;
    return SeverityLevel.none;
  }
}

/// A single CVE entry fetched from NIST NVD API v2.0.
class CveItem {
  final String id;
  final String description;
  final double cvssScore;
  final SeverityLevel severity;
  final String? cvssVector;
  final DateTime? publishedDate;

  const CveItem({
    required this.id,
    required this.description,
    required this.cvssScore,
    required this.severity,
    this.cvssVector,
    this.publishedDate,
  });

  factory CveItem.fromNvdJson(Map<String, dynamic> json) {
    final cve = json['cve'] as Map<String, dynamic>;
    final id = cve['id'] as String? ?? 'UNKNOWN';

    // Extract English description
    final descriptions = cve['descriptions'] as List<dynamic>? ?? [];
    final englishDesc = descriptions
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (d) => d['lang'] == 'en',
          orElse: () => {'value': 'No description available.'},
        )['value'] as String;

    // Extract CVSS v3.1 metrics
    double cvssScore = 0.0;
    String? cvssVector;
    final metrics = cve['metrics'] as Map<String, dynamic>?;
    if (metrics != null) {
      final v31 = (metrics['cvssMetricV31'] as List<dynamic>?)?.firstOrNull;
      if (v31 != null) {
        final cvssData = (v31 as Map<String, dynamic>)['cvssData']
            as Map<String, dynamic>?;
        cvssScore = (cvssData?['baseScore'] as num?)?.toDouble() ?? 0.0;
        cvssVector = cvssData?['vectorString'] as String?;
      } else {
        // Fallback to v30
        final v30 = (metrics['cvssMetricV30'] as List<dynamic>?)?.firstOrNull;
        if (v30 != null) {
          final cvssData = (v30 as Map<String, dynamic>)['cvssData']
              as Map<String, dynamic>?;
          cvssScore = (cvssData?['baseScore'] as num?)?.toDouble() ?? 0.0;
          cvssVector = cvssData?['vectorString'] as String?;
        }
      }
    }

    DateTime? publishedDate;
    final pubString = cve['published'] as String?;
    if (pubString != null) {
      publishedDate = DateTime.tryParse(pubString);
    }

    return CveItem(
      id: id,
      description: englishDesc,
      cvssScore: cvssScore,
      severity: SeverityLevelExtension.fromCvss(cvssScore),
      cvssVector: cvssVector,
      publishedDate: publishedDate,
    );
  }
}

/// A technology detected on the target URL.
class DetectedTech {
  final String name;
  final String? version;
  final TechCategory category;
  final String detectionSource; // 'header', 'meta', 'dom', 'js_global'
  final List<CveItem> cves;

  const DetectedTech({
    required this.name,
    this.version,
    required this.category,
    required this.detectionSource,
    this.cves = const [],
  });

  DetectedTech copyWith({List<CveItem>? cves}) {
    return DetectedTech(
      name: name,
      version: version,
      category: category,
      detectionSource: detectionSource,
      cves: cves ?? this.cves,
    );
  }

  int get criticalCount =>
      cves.where((c) => c.severity == SeverityLevel.critical).length;
  int get highCount =>
      cves.where((c) => c.severity == SeverityLevel.high).length;

  SeverityLevel get worstSeverity {
    if (cves.isEmpty) return SeverityLevel.none;
    return cves
        .map((c) => c.severity)
        .reduce((a, b) => a.index < b.index ? a : b);
  }
}

enum TechCategory {
  cms,
  framework,
  server,
  language,
  jsLibrary,
  cssFramework,
  analytics,
  cdn,
  unknown,
}

extension TechCategoryExtension on TechCategory {
  String get label => switch (this) {
        TechCategory.cms => 'CMS',
        TechCategory.framework => 'Framework',
        TechCategory.server => 'Server',
        TechCategory.language => 'Language',
        TechCategory.jsLibrary => 'JS Library',
        TechCategory.cssFramework => 'CSS Framework',
        TechCategory.analytics => 'Analytics',
        TechCategory.cdn => 'CDN',
        TechCategory.unknown => 'Unknown',
      };
}

/// Represents the complete in-memory scan session.
/// Lifetime: from scan start → Widget dispose() → GC.
class ScanResult {
  final String targetUrl;
  final DateTime scanStartedAt;
  final DateTime? scanCompletedAt;
  final ScanStatus status;
  final List<DetectedTech> technologies;
  final String? errorMessage;

  const ScanResult({
    required this.targetUrl,
    required this.scanStartedAt,
    this.scanCompletedAt,
    this.status = ScanStatus.idle,
    this.technologies = const [],
    this.errorMessage,
  });

  ScanResult copyWith({
    DateTime? scanCompletedAt,
    ScanStatus? status,
    List<DetectedTech>? technologies,
    String? errorMessage,
  }) {
    return ScanResult(
      targetUrl: targetUrl,
      scanStartedAt: scanStartedAt,
      scanCompletedAt: scanCompletedAt ?? this.scanCompletedAt,
      status: status ?? this.status,
      technologies: technologies ?? this.technologies,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  int get totalCveCount =>
      technologies.fold(0, (sum, t) => sum + t.cves.length);

  int get criticalCount =>
      technologies.fold(0, (sum, t) => sum + t.criticalCount);

  Duration? get scanDuration => scanCompletedAt != null
      ? scanCompletedAt!.difference(scanStartedAt)
      : null;
}

enum ScanStatus { idle, scanning, fetchingCves, completed, error }
