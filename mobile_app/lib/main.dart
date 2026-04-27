import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..checkAuth()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo Assistant',
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // US English
        Locale('en', 'GB'), // British English
        Locale('es', ''),   // Spanish
        Locale('fr', ''),   // French
        Locale('de', ''),   // German
      ],
      home: Consumer<AppProvider>(
        builder: (context, auth, child) {
          if (auth.isLoading && auth.currentUser == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.currentUser == null ? const LoginScreen() : const MainLayout();
        },
      ),
    );
  }
}
