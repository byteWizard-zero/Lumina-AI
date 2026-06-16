import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/providers/connectivity_provider.dart';
import 'glass_container.dart';

class OfflineOverlay extends ConsumerWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Only display when offline
    if (connectivity.isOnline) {
      return const SizedBox.shrink();
    }

    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    return PopScope(
      canPop: false, // Prevent dismissing via back button
      child: Stack(
        children: [
          // Dimmed background
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
          
          // Glassmorphic Dialog Panel in Center
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
              child: GlassContainer(
                blur: 28,
                opacity: isDarkMode ? 0.22 : 0.65,
                borderRadius: BorderRadius.circular(LuminaRadius.card),
                border: Border.all(
                  color: isDarkMode ? const Color(0x2BFFFFFF) : const Color(0x1F000000),
                  width: 1.2,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(LuminaSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cozy Offline Icon with slow breathing pulse
                      const AnimatedOfflineIcon(),
                      const SizedBox(height: LuminaSpacing.lg),

                      // Offline Title
                      Text(
                        'Lost Connection',
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: LuminaSpacing.xs),

                      // Status sub-details
                      Text(
                        'Lost connection to the stars.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: LuminaColors.accentAmber,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: LuminaSpacing.md),

                      // Cozy Message description
                      Text(
                        'Grab a warm cup of tea ☕ while we wait for your device to reconnect to the network...',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.5,
                          color: secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: LuminaSpacing.xl),

                      // Pulsing loader indicator
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.accentAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Breathing animation for offline icon
class AnimatedOfflineIcon extends StatefulWidget {
  const AnimatedOfflineIcon({super.key});

  @override
  State<AnimatedOfflineIcon> createState() => _AnimatedOfflineIconState();
}

class _AnimatedOfflineIconState extends State<AnimatedOfflineIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(LuminaSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0x11B04040),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LuminaColors.accentRed.withValues(alpha: 0.15),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: LuminaColors.accentRed,
              size: 42,
            ),
          ),
        );
      },
    );
  }
}
