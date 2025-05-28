part of 'auth_cubit.dart';

/// Estado base para la autenticación
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial de autenticación
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga para operaciones de autenticación
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado cuando el usuario está autenticado
class AuthAuthenticated extends AuthState {
  final String token;
  final Map<String, dynamic>? userData;

  const AuthAuthenticated({
    required this.token,
    this.userData,
  });

  @override
  List<Object?> get props => [token, userData];
  
  String? get userEmail => userData?['email'];
  String? get userName => userData?['nombre'];
  String? get userRole => userData?['rol'];
}

/// Estado cuando el usuario no está autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado cuando el registro es exitoso
class AuthRegistered extends AuthState {
  const AuthRegistered();
}

/// Estado cuando ocurre un error en la autenticación
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
