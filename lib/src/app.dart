import 'package:cleadr/src/screens/maps.dart';
import 'package:cleadr/src/screens/loading.dart';
import 'package:cleadr/src/screens/loading_failed.dart';
import 'package:cleadr/src/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CleadrApp extends StatefulWidget {
  const CleadrApp({super.key});

  @override
  State<StatefulWidget> createState() => _CleadrAppState();
}

class _CleadrAppState extends State<CleadrApp> {
  bool _isLoading = true;
  bool _isLoadingFailed = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  @override
  Widget build(BuildContext context) {
    // Hide the status bar
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      // App Theme
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xFFF34235),
          secondary: Colors.white,
        ),
      ),

      // Cleadr App
      home: Scaffold(
        resizeToAvoidBottomInset:
            false, // Keyboard overlays instead of pushing the Scaffold()
        body: _isLoading

            // Loading Screen
            ? LoadingScreen()
            : _isLoadingFailed

                // Loading - Failed Screen
                ? LoadingFailedScreen()

                // Maps Screen
                : MapsScreen(),
      ),
    );
  }

  Future<void> _initServices() async {
    _isLoadingFailed = !await Services
        .checkAllServices(); // Update Services.serviceStatusesStr
    _isLoading = false;

    setState(() {});
  }
}
