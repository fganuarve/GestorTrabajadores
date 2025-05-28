class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiBaseUrl = '$baseUrl/api';
  
  // Endpoints
  static const String registerUser = '$apiBaseUrl/user/create';
  static const String login = '$apiBaseUrl/login';
  static const String getUserByEmail = '$apiBaseUrl/user/getByEmail';
}
