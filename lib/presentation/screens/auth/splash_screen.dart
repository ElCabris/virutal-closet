import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
    // Fire-and-forget: the model can take minutes to download on a slow
    // connection, so this must not block the splash screen. Progress lands
    // in backgroundRemovalModelProgressProvider for AddGarmentScreen to
    // read whenever the user gets there. Deferred via Future() (not called
    // directly) because Riverpod forbids modifying provider state
    // synchronously from initState — it needs to run after this frame.
    unawaited(Future(_ensureBackgroundRemovalModel));
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  Future<void> _ensureBackgroundRemovalModel() async {
    final modelInstallService = ref.read(modelInstallServiceProvider);
    if (!modelInstallService.isSupported) return;

    final progressNotifier = ref.read(
      backgroundRemovalModelProgressProvider.notifier,
    );
    progressNotifier.state = 0;
    final subscription = modelInstallService.downloadProgress.listen(
      (pct) => progressNotifier.state = pct,
    );

    final ready = await modelInstallService.ensureSubjectSegmentationModel();
    await subscription.cancel();
    progressNotifier.state = ready ? 100 : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.checkroom_outlined,
                color: AppColors.primary,
                size: 44,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.7, 0.7)),
            const SizedBox(height: 28),
            Text(
              'Virtual Closet',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            Text(
              'CLOSET',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 6,
              ),
            )
                .animate()
                .fadeIn(delay: 450.ms, duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              'Your closet, curated.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
