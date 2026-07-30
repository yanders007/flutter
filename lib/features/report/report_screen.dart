// ============================================================
// Anderson CVE — Report Screen
// Displays the complete in-memory scan result.
// PopScope → reset() → Dart GC purges all session data.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/scan_result.dart';
import '../../core/providers/scan_provider.dart';
import '../../shared/theme/app_theme.dart';

class ReportScreen extends ConsumerWidget {
  final ScanResult result;
  const ReportScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(scanProvider.notifier).reset();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SCAN REPORT'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${result.technologies.length} techs · ${result.totalCveCount} CVEs',
                style: GoogleFonts.spaceMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _SummaryHeader(result: result)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) =>
                      _TechCard(tech: result.technologies[i]),
                  childCount: result.technologies.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final ScanResult result;
  const _SummaryHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final critical = result.technologies
        .fold(0, (s, t) => s + t.cves.where((c) => c.severity == SeverityLevel.critical).length);
    final high = result.technologies
        .fold(0, (s, t) => s + t.cves.where((c) => c.severity == SeverityLevel.high).length);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL
          Text(
            'TARGET',
            style: GoogleFonts.spaceMono(
              color: AppColors.textSecondary,
              fontSize: 9,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.targetUrl,
            style: GoogleFonts.spaceMono(
              color: AppColors.cyan,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              _Stat(
                  label: 'TECHNOLOGIES',
                  value: '${result.technologies.length}',
                  color: AppColors.textPrimary),
              _Stat(
                  label: 'TOTAL CVE',
                  value: '${result.totalCveCount}',
                  color: AppColors.textPrimary),
              _Stat(
                  label: 'CRITICAL',
                  value: '$critical',
                  color: critical > 0 ? AppColors.critical : AppColors.none),
              _Stat(
                  label: 'HIGH',
                  value: '$high',
                  color: high > 0 ? AppColors.high : AppColors.none),
            ],
          ),
          if (result.scanDuration != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.textSecondary, size: 12),
                const SizedBox(width: 6),
                Text(
                  'Scan completed in ${result.scanDuration!.inSeconds}s',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.low.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.low.withOpacity(0.3)),
                  ),
                  child: Text(
                    '● ZERO TRACE',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.low,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              color: AppColors.textSecondary,
              fontSize: 8,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TechCard extends StatefulWidget {
  final DetectedTech tech;
  const _TechCard({required this.tech});

  @override
  State<_TechCard> createState() => _TechCardState();
}

class _TechCardState extends State<_TechCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tech = widget.tech;
    final hasCves = tech.cves.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasCves
              ? severityColor(tech.worstSeverity).withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: hasCves ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Severity indicator
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: hasCves
                          ? severityColor(tech.worstSeverity)
                          : AppColors.none,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tech.name,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (tech.version != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                'v${tech.version}',
                                style: GoogleFonts.spaceMono(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MiniChip(tech.category.label),
                            const SizedBox(width: 6),
                            _MiniChip(tech.detectionSource),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // CVE count badge
                  if (hasCves) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor(tech.worstSeverity)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: severityColor(tech.worstSeverity)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${tech.cves.length} CVE',
                        style: GoogleFonts.spaceMono(
                          color: severityColor(tech.worstSeverity),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NO CVE',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // CVE list (expanded)
          if (_expanded && hasCves)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: tech.cves
                    .map((cve) => _CveRow(cve: cve))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CveRow extends StatelessWidget {
  final CveItem cve;
  const _CveRow({required this.cve});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                cve.id,
                style: GoogleFonts.spaceMono(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor(cve.severity).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${cve.cvssScore.toStringAsFixed(1)}  ${cve.severity.label}',
                  style: GoogleFonts.spaceMono(
                    color: severityColor(cve.severity),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cve.description,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (cve.cvssVector != null) ...[
            const SizedBox(height: 6),
            Text(
              cve.cvssVector!,
              style: GoogleFonts.spaceMono(
                color: AppColors.border,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          color: AppColors.textSecondary,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
