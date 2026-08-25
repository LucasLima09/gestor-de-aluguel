import 'package:alugala/screens/dashboard_screen.dart';
import 'package:alugala/screens/login_screen.dart';
import 'package:alugala/util/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");

    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_URL e SUPABASE_ANON_KEY precisam estar definidos em assets/.env',
      );
    }

    await Supabase.initialize(url: url, publishableKey: key);
    runApp(const MyApp());
  } catch (error, stackTrace) {
    debugPrint('Falha ao iniciar o app: $error\n$stackTrace');
    runApp(StartupErrorApp(message: error.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: "AlugaLá",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: session != null ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível iniciar o app.\n\n$message',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}