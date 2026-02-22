import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSection { myAi, doctorAi, hospital }

extension AppSectionExtension on AppSection {
  String get label {
    switch (this) {
      case AppSection.myAi:
        return 'My AI';
      case AppSection.doctorAi:
        return 'Doctor AI';
      case AppSection.hospital:
        return 'Hospital Near Me';
    }
  }

  String get description {
    switch (this) {
      case AppSection.myAi:
        return 'Your personal health companion';
      case AppSection.doctorAi:
        return 'AI-powered medical guidance';
      case AppSection.hospital:
        return 'Find hospitals near you';
    }
  }
}

final activeSectionProvider =
    StateNotifierProvider<ActiveSectionNotifier, AppSection>((ref) {
  return ActiveSectionNotifier();
});

class ActiveSectionNotifier extends StateNotifier<AppSection> {
  ActiveSectionNotifier() : super(AppSection.myAi);

  void setSection(AppSection section) {
    state = section;
  }
}
