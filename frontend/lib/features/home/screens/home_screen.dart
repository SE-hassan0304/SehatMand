import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/hospital/screens/hospital_screen.dart';
import '../../../shared/widgets/chat_screen.dart';
import '../../../shared/widgets/side_panel.dart';
import '../../../shared/widgets/top_navbar.dart';
import '../providers/navigation_provider.dart';
import 'package:sehatmand_pakistan/shared/models/ai_type.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSection = ref.watch(activeSectionProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Row(
        children: [
          // Side Panel
          const SidePanel(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Navbar
                const TopNavbar(),

                // Content Area
                Expanded(
                  child: _buildContent(activeSection),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppSection section) {
    switch (section) {
      case AppSection.myAi:
        return const ChatScreen(aiType: AiType.myAi);
      case AppSection.doctorAi:
        return const ChatScreen(aiType: AiType.doctorAi);
      case AppSection.hospital:
        return const HospitalScreen();
    }
  }
}
