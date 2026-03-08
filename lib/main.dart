import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/config_provider.dart';
import 'providers/devices_provider.dart';
import 'screens/devices_screen.dart';

void main() {
  runApp(const GrowattControlApp());
}

class GrowattControlApp extends StatelessWidget {
  const GrowattControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => DevicesProvider()),
      ],
      child: MaterialApp(
        title: 'Growatt Control',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
          ),
        ),
        home: const DevicesScreen(),
      ),
    );
  }
}
