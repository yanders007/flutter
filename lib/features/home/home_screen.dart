// ============================================================
// Anderson CVE — Home Screen
// URL entry + scan initiation. Navigates to ScanScreen.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../scan/scan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScan() {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanScreen(targetUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildScannerCard(),
              const SizedBox(height: 32),
              _buildFeatureList(),
              const Spacer(),
              _buildFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withOpacity(_pulseAnim.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(_pulseAnim.value * 0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ANDERSON CVE',
              style: GoogleFonts.spaceMono(
                color: AppColors.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Web\nVulnerability\nScanner',
          style: GoogleFonts.spaceMono(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Fingerprints technologies & maps CVEs.\nZero data stored on device.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TARGET URL',
              style: GoogleFonts.spaceMono(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _urlController,
              autocorrect: false,
              keyboardType: TextInputType.url,
              style: GoogleFonts.spaceMono(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                prefixIcon: Icon(
                  Icons.link_rounded,
                  color: AppColors.cyanDim,
                  size: 18,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a URL';
                final url =
                    v.trim().startsWith('http') ? v.trim() : 'https://${v.trim()}';
                final uri = Uri.tryParse(url);
                if (uri == null || !uri.hasAuthority) {
                  return 'Enter a valid URL';
                }
                return null;
              },
              onFieldSubmitted: (_) => _startScan(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startScan,
                child: const Text('SCAN TARGET'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      ('HTTP headers & meta tags', Icons.wifi_rounded),
      ('JavaScript globals (headless)', Icons.code_rounded),
      ('NIST NVD CVE database', Icons.security_rounded),
      ('Stateless — no data stored', Icons.lock_outline_rounded),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(f.$2, color: AppColors.cyanDim, size: 16),
                  const SizedBox(width: 12),
                  Text(
                    f.$1,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.border,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Data sourced from NIST NVD API v2.0',
          style: GoogleFonts.spaceMono(
            color: AppColors.border,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.border,
          ),
        ),
      ],
    );
  }
}
