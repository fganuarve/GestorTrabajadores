import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/cubit/auth_cubit.dart';
import 'package:front_end_gui/views/auth/login_screen.dart';
import 'package:front_end_gui/views/auth/register_screen.dart';
import 'package:front_end_gui/views/home_screen.dart' as home_screen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Always start with login screen
  runApp(const MyApp(initialRoute: '/'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: MaterialApp(
        title: 'Gestor de Trabajadores',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const home_screen.HomeScreen(),
        },
      ),
    );
  }
}
