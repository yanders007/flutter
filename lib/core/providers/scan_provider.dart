// ============================================================
// Anderson CVE — Scan Orchestrator (Riverpod StateNotifier)
// Coordinates Steps A → B → C in sequence.
// State lives exclusively in RAM. On dispose() the Riverpod
// container releases all references → Dart GC reclaims memory.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_result.dart';
import '../services/dynamic_scanner_service.dart';
import '../services/nvd_api_service.dart';
import '../services/static_scanner_service.dart';

// ─── Providers ───────────────────────────────────────────────

final scanProvider =
    StateNotifierProvider.autoDispose<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(
    staticScanner: StaticScannerService(),
    dynamicScanner: DynamicScannerService(),
    nvdService: NvdApiService(),
  );
});

// ─── State ───────────────────────────────────────────────────

class ScanState {
  final ScanResult? result;
  final ScanPhase phase;
  final String statusMessage;
  final double progress; // 0.0 → 1.0

  const ScanState({
    this.result,
    this.phase = ScanPhase.idle,
    this.statusMessage = '',
    this.progress = 0.0,
  });

  ScanState copyWith({
    ScanResult? result,
    ScanPhase? phase,
    String? statusMessage,
    double? progress,
  }) {
    return ScanState(
      result: result ?? this.result,
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
    );
  }

  bool get isScanning => phase != ScanPhase.idle && phase != ScanPhase.done && phase != ScanPhase.error;
}

enum ScanPhase { idle, staticAnalysis, dynamicAnalysis, cveLookup, done, error }

// ─── Notifier ────────────────────────────────────────────────

class ScanNotifier extends StateNotifier<ScanState> {
  final StaticScannerService _staticScanner;
  final DynamicScannerService _dynamicScanner;
  final NvdApiService _nvdService;

  ScanNotifier({
    required StaticScannerService staticScanner,
    required DynamicScannerService dynamicScanner,
    required NvdApiService nvdService,
  })  : _staticScanner = staticScanner,
        _dynamicScanner = dynamicScanner,
        _nvdService = nvdService,
        super(const ScanState());

  /// Starts a full scan of [url]. Requires [context] for the
  /// headless WebView overlay (Step B).
  Future<void> startScan(String url, BuildContext context) async {
    if (state.isScanning) return;

    // Normalise URL
    final normUrl = url.trim().startsWith('http') ? url.trim() : 'https://${url.trim()}';

    final scanStart = DateTime.now();
    state = ScanState(
      result: ScanResult(
        targetUrl: normUrl,
        scanStartedAt: scanStart,
        status: ScanStatus.scanning,
      ),
      phase: ScanPhase.staticAnalysis,
      statusMessage: 'Step 1/3 — Passive network analysis…',
      progress: 0.05,
    );

    try {
      // ── Step A : Static / Passive ──────────────────────────
      List<DetectedTech> techs = await _staticScanner.scan(normUrl);

      _updateProgress(
        phase: ScanPhase.dynamicAnalysis,
        message: 'Step 2/3 — Dynamic JS evaluation…',
        progress: 0.33,
        techs: techs,
        scanStart: scanStart,
      );

      // ── Step B : Dynamic / JS Globals ─────────────────────
      if (context.mounted) {
        final dynamicTechs = await _dynamicScanner.scan(normUrl, context);
        techs = _mergeTechs(techs, dynamicTechs);
      }

      _updateProgress(
        phase: ScanPhase.cveLookup,
        message: 'Step 3/3 — Fetching CVEs from NIST NVD…',
        progress: 0.60,
        techs: techs,
        scanStart: scanStart,
      );

      // ── Step C : CVE enrichment ────────────────────────────
      techs = await _nvdService.enrichWithCves(
        techs,
        onProgress: (p, name) {
          if (!mounted) return;
          state = state.copyWith(
            statusMessage: name.isNotEmpty
                ? 'CVE lookup: $name'
                : 'CVE lookup complete',
            progress: 0.60 + (p * 0.38),
          );
        },
      );

      // ── Done ──────────────────────────────────────────────
      if (mounted) {
        state = ScanState(
          result: ScanResult(
            targetUrl: normUrl,
            scanStartedAt: scanStart,
            scanCompletedAt: DateTime.now(),
            status: ScanStatus.completed,
            technologies: techs,
          ),
          phase: ScanPhase.done,
          statusMessage: 'Scan complete — ${techs.length} technologies detected.',
          progress: 1.0,
        );
      }
    } on ScanException catch (e) {
      if (mounted) {
        state = ScanState(
          result: ScanResult(
            targetUrl: normUrl,
            scanStartedAt: scanStart,
            scanCompletedAt: DateTime.now(),
            status: ScanStatus.error,
            errorMessage: e.message,
          ),
          phase: ScanPhase.error,
          statusMessage: 'Error: ${e.message}',
          progress: 0.0,
        );
      }
    } catch (e) {
      if (mounted) {
        state = ScanState(
          result: ScanResult(
            targetUrl: normUrl,
            scanStartedAt: scanStart,
            scanCompletedAt: DateTime.now(),
            status: ScanStatus.error,
            errorMessage: e.toString(),
          ),
          phase: ScanPhase.error,
          statusMessage: 'Unexpected error: $e',
          progress: 0.0,
        );
      }
    }
  }

  /// Resets state — called by PopScope / back navigation.
  /// Setting state to default releases all object references;
  /// Dart GC will reclaim them on the next collection cycle.
  void reset() {
    state = const ScanState();
  }

  // ─── Private helpers ─────────────────────────────────────

  void _updateProgress({
    required ScanPhase phase,
    required String message,
    required double progress,
    required List<DetectedTech> techs,
    required DateTime scanStart,
  }) {
    if (!mounted) return;
    state = ScanState(
      result: ScanResult(
        targetUrl: state.result!.targetUrl,
        scanStartedAt: scanStart,
        status: ScanStatus.scanning,
        technologies: techs,
      ),
      phase: phase,
      statusMessage: message,
      progress: progress,
    );
  }

  /// Merges two tech lists, preferring entries with a version number
  /// and de-duplicating by name (case-insensitive).
  List<DetectedTech> _mergeTechs(
      List<DetectedTech> base, List<DetectedTech> extra) {
    final map = <String, DetectedTech>{
      for (final t in base) t.name.toLowerCase(): t,
    };
    for (final t in extra) {
      final key = t.name.toLowerCase();
      if (!map.containsKey(key) ||
          (t.version != null && map[key]!.version == null)) {
        map[key] = t;
      }
    }
    return map.values.toList();
  }
}
