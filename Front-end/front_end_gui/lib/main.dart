import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:front_end_gui/cubit/auth_cubit.dart';
import 'package:front_end_gui/cubit/shift_cubit.dart';
import 'package:front_end_gui/providers/carpool_provider.dart';
import 'package:front_end_gui/providers/user_provider.dart';
import 'package:front_end_gui/services/shift_service.dart';
import 'package:front_end_gui/views/auth/login_screen.dart';
import 'package:front_end_gui/views/auth/register_screen.dart';
import 'package:front_end_gui/views/home_screen.dart' as home_screen;
import 'package:front_end_gui/views/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for the current locale
  await initializeDateFormatting('es_ES', null);
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Always start with login screen
  runApp(MyApp(initialRoute: '/', prefs: prefs));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final SharedPreferences prefs;

  const MyApp({
    Key? key, 
    required this.initialRoute,
    required this.prefs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(prefs: prefs),
        ),
        BlocProvider<ShiftCubit>(
          create: (context) => ShiftCubit(
            shiftService: ShiftService(),
            prefs: prefs,
          ),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => UserProvider(prefs: prefs),
          ),
          ChangeNotifierProvider(
            create: (context) => CarpoolProvider(prefs: prefs),
          ),
        ],
        child: MaterialApp(
          title: 'Gestor de Trabajadores',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('es', 'ES'),
          ],
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          initialRoute: initialRoute,
          routes: {
            '/': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const home_screen.HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        ),
      ),
    );
  }
}
