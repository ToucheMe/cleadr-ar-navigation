import 'package:cleadr/src/screens/loading.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class MapsNavigationScreen extends StatefulWidget {
  final bool isMinified;
  final LatLng destinationLocation;

  const MapsNavigationScreen({
    super.key,
    required this.isMinified,
    required this.destinationLocation,
  });

  @override
  State<MapsNavigationScreen> createState() => _MapsNavigationScreenState();
}

class _MapsNavigationScreenState extends State<MapsNavigationScreen> {
  bool _isLoading = true;

  late final GoogleMapsNavigationView _navigationView;
  // late final GoogleNavigationViewController _navigationViewController;

  @override
  void initState() {
    super.initState();
    _initNavigator();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? LoadingScreen()
        :
        // Maps navigation
        _navigationView;
  }

  Future<void> _initNavigator() async {
    if (mounted) {
      // Get current location
      Position currentPosition = await Geolocator.getCurrentPosition();

      // Navigation session
      await GoogleMapsNavigator.initializeNavigationSession();
      _navigationView = GoogleMapsNavigationView(
        initialNavigationUIEnabledPreference:
            NavigationUIEnabledPreference.automatic,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            latitude: currentPosition.latitude,
            longitude: currentPosition.longitude,
          ),
        ),
        onViewCreated: _onViewCreated,
      );

      _isLoading = false;
      setState(() {});
    }
  }

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    await GoogleMapsNavigator.setDestinations(
      Destinations(
        waypoints: <NavigationWaypoint>[
          NavigationWaypoint.withLatLngTarget(
            title: "Destination",
            target: widget.destinationLocation,
          )
        ],
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: true,
          showStopSigns: true,
          showTrafficLights: true,
        ),
        routingOptions:
            RoutingOptions(travelMode: NavigationTravelMode.driving),
      ),
    );

    await controller.setNavigationUIEnabled(true);
    await controller.setMyLocationEnabled(true);
    await controller.setSpeedometerEnabled(true);
    await controller.setSpeedLimitIconEnabled(true);
    if (widget.isMinified) {
      await controller.setNavigationHeaderEnabled(false);
      await controller.setNavigationFooterEnabled(false);
    } else {
      await controller.setNavigationTripProgressBarEnabled(true);
    }

    await GoogleMapsNavigator.startGuidance();
    await controller.followMyLocation(CameraPerspective.tilted);
    setState(() {});
  }
}
