// lib/shared/widgets/side_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/providers/navigation_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SidePanel extends ConsumerWidget {
  const SidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSection = ref.watch(activeSectionProvider);

    return Container(
      width: 72,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.sidebarBorder),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: AppColors.white, size: 22),
          ),

          const SizedBox(height: 32),
          const Divider(height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 16),

          // Navigation items
          ...AppSection.values.map((section) {
            return _SidebarItem(
              section: section,
              isActive: activeSection == section,
              onTap: () =>
                  ref.read(activeSectionProvider.notifier).setSection(section),
            );
          }),

          const Spacer(),
          const Divider(height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 12),

          // Logout
          _LogoutButton(
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ).animate().slideX(begin: -1, end: 0, duration: 400.ms);
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.logout,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.charcoal,
          ),
        ),
        content: Text(
          AppStrings.logoutConfirm,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.cancel,
              style: GoogleFonts.inter(
                  color: AppColors.greyText, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Calls Firebase signOut — router will auto-redirect to /auth
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            child: Text(
              AppStrings.logout,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final AppSection section;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  IconData get _icon {
    switch (widget.section) {
      case AppSection.myAi:
        return Icons.psychology_outlined;
      case AppSection.doctorAi:
        return Icons.medical_services_outlined;
      case AppSection.hospital:
        return Icons.local_hospital_outlined;
    }
  }

  IconData get _iconActive {
    switch (widget.section) {
      case AppSection.myAi:
        return Icons.psychology;
      case AppSection.doctorAi:
        return Icons.medical_services;
      case AppSection.hospital:
        return Icons.local_hospital;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.section.label,
      preferBelow: false,
      verticalOffset: -8,
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.white,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.primary.withOpacity(0.12)
                  : _hovered
                      ? AppColors.grey
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: widget.isActive
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Icon(
              widget.isActive ? _iconActive : _icon,
              color: widget.isActive
                  ? AppColors.primary
                  : AppColors.sidebarInactive,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.logout,
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.white,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.coral.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: _hovered ? AppColors.coral : AppColors.greyText,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
