// ============================================================
// Anderson CVE — Unit Tests
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:anderson_cve/core/models/scan_result.dart';

void main() {
  group('SeverityLevel', () {
    test('fromCvss maps scores correctly', () {
      expect(SeverityLevelExtension.fromCvss(9.8), SeverityLevel.critical);
      expect(SeverityLevelExtension.fromCvss(9.0), SeverityLevel.critical);
      expect(SeverityLevelExtension.fromCvss(8.9), SeverityLevel.high);
      expect(SeverityLevelExtension.fromCvss(7.0), SeverityLevel.high);
      expect(SeverityLevelExtension.fromCvss(6.9), SeverityLevel.medium);
      expect(SeverityLevelExtension.fromCvss(4.0), SeverityLevel.medium);
      expect(SeverityLevelExtension.fromCvss(3.9), SeverityLevel.low);
      expect(SeverityLevelExtension.fromCvss(0.1), SeverityLevel.low);
      expect(SeverityLevelExtension.fromCvss(0.0), SeverityLevel.none);
    });

    test('label returns uppercase string', () {
      expect(SeverityLevel.critical.label, 'CRITICAL');
      expect(SeverityLevel.none.label, 'NONE');
    });
  });

  group('CveItem', () {
    test('parses NVD API JSON correctly', () {
      final json = {
        'cve': {
          'id': 'CVE-2023-1234',
          'published': '2023-06-01T00:00:00.000',
          'descriptions': [
            {'lang': 'en', 'value': 'A critical vulnerability in WordPress.'},
            {'lang': 'es', 'value': 'Una vulnerabilidad crítica.'},
          ],
          'metrics': {
            'cvssMetricV31': [
              {
                'cvssData': {
                  'baseScore': 9.8,
                  'vectorString': 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H',
                },
              }
            ],
          },
        },
      };

      final cve = CveItem.fromNvdJson(json);
      expect(cve.id, 'CVE-2023-1234');
      expect(cve.cvssScore, 9.8);
      expect(cve.severity, SeverityLevel.critical);
      expect(cve.description, contains('WordPress'));
      expect(cve.cvssVector, startsWith('CVSS:3.1'));
      expect(cve.publishedDate, isNotNull);
    });

    test('falls back to v30 metrics when v31 absent', () {
      final json = {
        'cve': {
          'id': 'CVE-2022-9999',
          'descriptions': [
            {'lang': 'en', 'value': 'Test CVE.'},
          ],
          'metrics': {
            'cvssMetricV30': [
              {
                'cvssData': {
                  'baseScore': 7.5,
                  'vectorString': 'CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N',
                },
              }
            ],
          },
        },
      };

      final cve = CveItem.fromNvdJson(json);
      expect(cve.cvssScore, 7.5);
      expect(cve.severity, SeverityLevel.high);
    });
  });

  group('DetectedTech', () {
    test('worstSeverity returns highest severity from CVEs', () {
      final cves = [
        CveItem(
            id: 'CVE-A',
            description: '',
            cvssScore: 4.0,
            severity: SeverityLevel.medium),
        CveItem(
            id: 'CVE-B',
            description: '',
            cvssScore: 9.1,
            severity: SeverityLevel.critical),
        CveItem(
            id: 'CVE-C',
            description: '',
            cvssScore: 7.5,
            severity: SeverityLevel.high),
      ];

      final tech = DetectedTech(
        name: 'WordPress',
        version: '6.4.2',
        category: TechCategory.cms,
        detectionSource: 'meta:generator',
        cves: cves,
      );

      expect(tech.worstSeverity, SeverityLevel.critical);
      expect(tech.criticalCount, 1);
      expect(tech.highCount, 1);
    });

    test('copyWith preserves all fields except CVEs', () {
      final tech = DetectedTech(
        name: 'jQuery',
        version: '3.6.0',
        category: TechCategory.jsLibrary,
        detectionSource: 'js_global',
      );
      final newCves = [
        CveItem(
            id: 'CVE-X',
            description: 'test',
            cvssScore: 5.0,
            severity: SeverityLevel.medium),
      ];
      final updated = tech.copyWith(cves: newCves);
      expect(updated.name, 'jQuery');
      expect(updated.version, '3.6.0');
      expect(updated.cves.length, 1);
    });
  });

  group('ScanResult', () {
    test('totalCveCount sums all CVEs across technologies', () {
      final result = ScanResult(
        targetUrl: 'https://example.com',
        scanStartedAt: DateTime.now(),
        technologies: [
          DetectedTech(
            name: 'WordPress',
            category: TechCategory.cms,
            detectionSource: 'meta',
            cves: List.generate(
                3,
                (i) => CveItem(
                    id: 'CVE-$i',
                    description: '',
                    cvssScore: 5.0,
                    severity: SeverityLevel.medium)),
          ),
          DetectedTech(
            name: 'jQuery',
            category: TechCategory.jsLibrary,
            detectionSource: 'dom',
            cves: List.generate(
                2,
                (i) => CveItem(
                    id: 'CVE-J-$i',
                    description: '',
                    cvssScore: 7.0,
                    severity: SeverityLevel.high)),
          ),
        ],
      );
      expect(result.totalCveCount, 5);
    });

    test('scanDuration is null when not completed', () {
      final result = ScanResult(
        targetUrl: 'https://example.com',
        scanStartedAt: DateTime.now(),
      );
      expect(result.scanDuration, isNull);
    });
  });
}
