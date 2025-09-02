class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String classesCollection = 'classes';
  static const String reservationsCollection = 'reservations';
  static const String packsCollection = 'packs';
  static const String purchasesCollection = 'purchases';
  static const String reportsCollection = 'reports';

  // Shared Preferences Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // App Configuration
  static const int maxClassCapacity = 30;
  static const int minCreditsToReserve = 1;
  static const Duration reservationCancelWindow = Duration(hours: 2);

  // Error Messages
  static const String networkErrorMessage =
      'Error de conexión. Verifica tu internet.';
  static const String authErrorMessage =
      'Error de autenticación. Intenta nuevamente.';
  static const String insufficientCreditsMessage =
      'No tienes suficientes créditos.';
  static const String classFullMessage = 'La clase está llena.';
  static const String reservationNotFoundMessage = 'Reserva no encontrada.';
  static const String genericErrorMessage = 'Ocurrió un error inesperado.';

  // Routes
  static const String splashRoute = '/';
  static const String authRoute = '/auth';
  static const String homeRoute = '/home';
  static const String classesRoute = '/classes';
  static const String reservationsRoute = '/reservations';
  static const String profileRoute = '/profile';
  static const String adminRoute = '/admin';
  static const String reportsRoute = '/reports';

  // API Endpoints
  static const String baseUrl = 'https://your-api.com/api/v1';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
}
