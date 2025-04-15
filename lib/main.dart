import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create default theme data
    final defaultTheme = AppTheme.darkTheme;
    
    return MaterialApp(
      title: 'Tata Smart Grid',
      debugShowCheckedModeBanner: false,
      theme: defaultTheme.copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppTheme.darkPrimaryColor,
          secondary: AppTheme.darkSecondaryColor,
          background: AppTheme.backgroundColor,
          surface: AppTheme.surfaceColor,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppTheme.backgroundColor,
          selectedItemColor: AppTheme.darkSecondaryColor,
          unselectedItemColor: Colors.white.withOpacity(0.5),
        ),
        // Add dialog theme
        dialogTheme: DialogTheme(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.darkSecondaryColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
      darkTheme: defaultTheme,
      themeMode: ThemeMode.dark,
      home: const LoginScreen(),
      builder: (context, child) {
        // Add error boundary
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: AppTheme.backgroundColor,
              child: Center(
                child: Text(
                  'An error occurred.\nPlease restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.warningYellow,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class EnergyDashboard extends StatefulWidget {
  const EnergyDashboard({super.key, required this.title});
  final String title;

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends State<EnergyDashboard> {
  double monthlyAllocation = 150.0; // kW
  double currentUsage = 0.0;
  double availableToShare = 150.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Allocation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$monthlyAllocation kW',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Usage',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$currentUsage kW',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available to Share',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$availableToShare kW',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add energy trading dialog
        },
        tooltip: 'Trade Energy',
        child: const Icon(Icons.swap_horiz),
      ),
    );
  }
}
