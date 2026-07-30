// ============================================================
// Anderson CVE — Scan Screen
// Displays live progress through Steps A→B→C.
// On back navigation, PopScope triggers state.reset() which
// nulls all references → Dart GC purges the scan session.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/scan_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../report/report_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final String targetUrl;
  const ScanScreen({super.key, required this.targetUrl});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanProvider.notifier).startScan(widget.targetUrl, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    // Auto-navigate to report when done
    ref.listen<ScanState>(scanProvider, (prev, next) {
      if (next.phase == ScanPhase.done && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReportScreen(result: next.result!),
          ),
        );
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(scanProvider.notifier).reset();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SCANNING'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              ref.read(scanProvider.notifier).reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: scanState.phase == ScanPhase.error
                ? _buildError(scanState)
                : _buildProgress(scanState),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ScanState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _UrlBadge(url: widget.targetUrl),
        const SizedBox(height: 48),
        _PhaseIndicator(current: state.phase),
        const SizedBox(height: 48),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: state.progress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.statusMessage,
          style: GoogleFonts.spaceMono(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        if (state.result != null &&
            state.result!.technologies.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'DETECTED SO FAR',
            style: GoogleFonts.spaceMono(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...state.result!.technologies.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.name,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (t.version != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'v${t.version}',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.cyanDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    t.category.label,
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(ScanState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.critical, size: 40),
        const SizedBox(height: 16),
        Text(
          'SCAN FAILED',
          style: GoogleFonts.spaceMono(
            color: AppColors.critical,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.result?.errorMessage ?? 'Unknown error',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            ref.read(scanProvider.notifier).reset();
            Navigator.pop(context);
          },
          child: const Text('GO BACK'),
        ),
      ],
    );
  }
}

class _UrlBadge extends StatelessWidget {
  final String url;
  const _UrlBadge({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.cyanDim, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: GoogleFonts.spaceMono(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final ScanPhase current;
  const _PhaseIndicator({required this.current});

  static const _phases = [
    (ScanPhase.staticAnalysis, 'Passive Analysis', 'HTTP headers, meta, DOM'),
    (ScanPhase.dynamicAnalysis, 'Dynamic JS', 'window.* global evaluation'),
    (ScanPhase.cveLookup, 'CVE Lookup', 'NIST NVD database query'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _phases.asMap().entries.map((entry) {
        final i = entry.key;
        final phase = entry.value;
        final isDone = current.index > phase.$1.index;
        final isActive = current == phase.$1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Step circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.cyan.withOpacity(0.15)
                      : isActive
                          ? AppColors.cyan.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                  border: Border.all(
                    color: isDone
                        ? AppColors.cyan
                        : isActive
                            ? AppColors.cyan
                            : AppColors.border,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.cyan, size: 14)
                      : isActive
                          ? const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cyan,
                              ),
                            )
                          : Text(
                              '${i + 1}',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.$2,
                    style: GoogleFonts.inter(
                      color: isDone || isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    phase.$3,
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
