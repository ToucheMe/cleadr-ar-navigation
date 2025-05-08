import 'package:cleadr/src/screens/ar_navigation.dart';
import 'package:cleadr/src/screens/maps_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destinationLocation;

  const NavigationScreen({super.key, required this.destinationLocation});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with WidgetsBindingObserver {
  bool _isArNavigationToggled = false;
  DeviceOrientation? _orientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOrientation();
  }

  @override
  void didChangeMetrics() {
    _updateOrientation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          !_isArNavigationToggled
              ?
              // Maps navigation
              MapsNavigationScreen(
                  isMinified: false,
                  destinationLocation: widget.destinationLocation,
                )
              :
              // AR navigation (portrait)
              ARNavigationScreen(),

          // Maps navigation (minified, portrait)
          _isArNavigationToggled
              ? _orientation != DeviceOrientation.landscapeLeft
                  ? Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: MapsNavigationScreen(
                          isMinified: true,
                          destinationLocation: widget.destinationLocation,
                        ),
                      ),
                    )
                  :
                  // Maps navigation (landscape)
                  Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: MapsNavigationScreen(
                        isMinified: false,
                        destinationLocation: widget.destinationLocation,
                      ),
                    )
              : Container(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 75,
              height: 40,
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              decoration: BoxDecoration(
                color: !_isArNavigationToggled
                    // Maps toggle colour
                    ? Colors.purple
                    // AR toggle colour
                    : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: !_isArNavigationToggled
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                        ),
                        Text(
                          !_isArNavigationToggled
                              // Maps toggle text
                              ? "MAPS"
                              // AR toggle text
                              : "AR",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedAlign(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: !_isArNavigationToggled
                        // Maps toggle alignment
                        ? Alignment.centerLeft
                        // AR toggle alignment
                        : Alignment.centerRight,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          !_isArNavigationToggled
                              // Maps toggle icon
                              ? Icons.map
                              // AR toggle icon
                              : Icons.view_in_ar,
                          color: !_isArNavigationToggled
                              // Maps toggle icon colour
                              ? Colors.purple
                              // AR toggle icon colour
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              _isArNavigationToggled = !_isArNavigationToggled;
              setState(() {});
            },
          ),
          const SizedBox(height: 15),

          // Cancel
          FloatingActionButton(
            backgroundColor: Colors.red,
            child: const Icon(
              color: Colors.white,
              Icons.cancel,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _updateOrientation() {
    final orientation = WidgetsBinding
                .instance.platformDispatcher.views.first.physicalSize.width >
            WidgetsBinding
                .instance.platformDispatcher.views.first.physicalSize.height
        ? DeviceOrientation.landscapeLeft
        : DeviceOrientation.portraitUp;

    _orientation = orientation;
    setState(() {});
  }
}
