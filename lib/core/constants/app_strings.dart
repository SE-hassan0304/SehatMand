class AppStrings {
  AppStrings._();

  static const String appName = 'SehatmandPakistan';
  static const String tagline = 'Your AI Health Companion';

  // Auth
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String signInWithGoogle = 'Continue with Google';
  static const String email = 'Email Address';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String confirmPassword = 'Confirm Password';
  static const String alreadyHaveAccount = "Already have an account? ";
  static const String dontHaveAccount = "Don't have an account? ";
  static const String loginTitle = 'Welcome Back!';
  static const String signupTitle = 'Create Account';
  static const String loginSubtitle = 'Sign in to continue';
  static const String signupSubtitle = 'Join SehatmandPakistan today';

  // Navigation
  static const String myAi = 'My AI';
  static const String doctorAi = 'Doctor AI';
  static const String hospitalNearMe = 'Hospital Near Me';
  static const String logout = 'Logout';

  // Greeting
  static String morningGreeting(String name) =>
      'Assalamu Alaikum, $name!\nHow can I help you this morning?';
  static String afternoonGreeting(String name) =>
      'Assalamu Alaikum, $name!\nHow can I help you this afternoon?';
  static String eveningGreeting(String name) =>
      'Assalamu Alaikum, $name!\nHow can I help you this evening?';

  // Chat
  static const String typeMessage = 'Type a message...';
  static const String myAiTyping = 'My AI is typing...';
  static const String doctorAiTyping = 'Doctor AI is typing...';

  // My AI
  static const String myAiWelcome =
      'Assalamu Alaikum! I\'m your personal health companion. I\'m here to listen, understand your symptoms, and help you figure out whether you need medical attention. What\'s bothering you today?';

  // Doctor AI
  static const String doctorAiWelcome =
      'Assalamu Alaikum! I\'m Doctor AI. Describe your symptoms and I\'ll suggest appropriate guidance, medications, or whether you should consult a specialist.';

  // Hospital
  static const String hospitalTitle = 'Hospitals Near Me';
  static const String hospitalSubtitle =
      'Find the nearest hospitals and clinics in Karachi';
  static const String findHospitals = 'Find Hospitals Near Me';
  static const String allowLocation = 'Allow Location Access';
  static const String locationPermission =
      'We need your location to find nearby hospitals';

  // Profile
  static const String profile = 'Profile';
  static const String logoutConfirm = 'Are you sure you want to logout?';
  static const String cancel = 'Cancel';

  // Errors
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String nameRequired = 'Full name is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
}
