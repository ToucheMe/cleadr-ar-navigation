import 'package:cleadr/src/screens/maps_search.dart';
import 'package:cleadr/src/screens/loading.dart';
import 'package:cleadr/src/screens/navigation.dart';
import 'package:cleadr/src/services/services.dart';
import 'package:cleadr/src/util/functions.dart';
import 'package:cleadr/src/util/place.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  bool _isLoading = true;
  bool _isRoutePreview = false;

  late LatLng _currentLocation;
  LatLng? _destinationLocation;

  double _zoom = 15.0;
  late final GoogleMapsNavigationView _navigationView;
  late final GoogleNavigationViewController _navigationViewController;
  Marker? _waypointMarker;
  late Place _destinationPlace;

  @override
  void initState() {
    super.initState();
    _initNavigator();
  }

  @override
  void dispose() {
    _disposeNavigator();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading

        // Loading Screen
        ? LoadingScreen()
        : Stack(
            children: [
              // Maps Screen
              _navigationView,

              _destinationLocation != null
                  ? _isRoutePreview == false

                      // Place Details Card
                      ? _destinationPlace.PlaceDetailsCard(() {
                          _removeWaypointMarker();
                          setState(() {});
                        })

                      // Route Preview Card
                      : _destinationPlace.RoutePreviewCard(
                          context,
                          () {
                            _removeRoutePreview();
                            _removeWaypointMarker();
                            setState(() {});
                          },
                        )
                  : Container(),

              _destinationLocation != null

                  // Route, Start
                  ? Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        backgroundColor: _isRoutePreview == false
                            // Route colour
                            ? Colors.blueAccent

                            // Start colour
                            : Colors.green,
                        child: _isRoutePreview == false

                            // Route icon
                            ? const Icon(
                                color: Colors.white,
                                Icons.directions,
                              )

                            // Start icon
                            : const Icon(
                                Icons.navigation,
                                color: Colors.white,
                              ),
                        onPressed: () {
                          if (_isRoutePreview == false) {
                            // Route button
                            _showRoutePreview();
                            _isRoutePreview = true;
                            setState(() {});
                          } else {
                            // Start button
                            _disposeNavigator();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    // Navigation Screen
                                    NavigationScreen(
                                  destinationLocation: _destinationLocation!,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    )
                  : Container(),

              // Search
              MapsSearchScreen(
                onDestinationClicked: _onDestinationClicked,
                destinationPlace: _destinationPlace,
              ),
            ],
          );
  }

  Future<void> _initNavigator() async {
    if (mounted) {
      // Get current location
      Position currentPosition = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
      );

      // Initialise maps session and view
      await GoogleMapsNavigator.initializeNavigationSession();
      _navigationView = GoogleMapsNavigationView(
        initialNavigationUIEnabledPreference:
            NavigationUIEnabledPreference.disabled, // Maps only session

        initialCameraPosition:
            CameraPosition(target: _currentLocation, zoom: _zoom),
        initialCompassEnabled: false,
        initialMapToolbarEnabled: false,
        initialZoomControlsEnabled: false,

        onViewCreated: _onViewCreated,
        onCameraMove: _onCameraMove,
        onMapClicked:
            _onDestinationClicked, // TODO: _onMapClicked - Snaps to closest place pin
        onMapLongClicked: _onDestinationClicked,
      );

      // Initialise _destinationPlace
      _destinationPlace = Place();

      _isLoading = false;
      setState(() {});
    }
  }

  Future<void> _disposeNavigator() async {
    await _removeRoutePreview();
    await GoogleMapsNavigator.clearDestinations();
    await GoogleMapsNavigator.cleanup();
  }

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    _navigationViewController = controller;
    await controller.setMyLocationEnabled(true);
  }

  void _onCameraMove(CameraPosition cameraPosition) {
    _zoom = cameraPosition.zoom;
    debugLog("_zoom: $_zoom");
  }

  Future<void> _onDestinationClicked(LatLng destinationLocation) async {
    // Update _destinationLocation, _waypointMarker, and new camera position
    _destinationLocation = destinationLocation;
    await _updateWaypointMarker(destinationLocation);
    await _navigationViewController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: destinationLocation,
          zoom: _zoom,
        ),
      ),
    );

    // Update _destinationPlace and route estimation
    String distanceStr, durationStr;
    int duration;
    DateTime startTime, endTime;

    // Place Details
    _destinationPlace = await Services.fetchPlaceDetails(destinationLocation);

    // Place Route Estimation
    (distanceStr, durationStr, duration) =
        await Services.fetchPlaceRouteEstimation(
      _currentLocation,
      destinationLocation,
    );
    startTime = DateTime.now();
    endTime = startTime.add(Duration(seconds: duration));

    _destinationPlace.distanceStr = distanceStr;
    _destinationPlace.durationStr = durationStr;
    _destinationPlace.duration = duration;
    _destinationPlace.startTime = startTime;
    _destinationPlace.endTime = endTime;

    setState(() {});
  }

  Future<void> _updateWaypointMarker(LatLng destinationLocation) async {
    // Destination marker options
    final MarkerOptions markerOptions = MarkerOptions(
      position: LatLng(
        latitude: _destinationLocation!.latitude,
        longitude: _destinationLocation!.longitude,
      ),
    );

    // New or Update _waypointMarker
    if (_waypointMarker == null) {
      _waypointMarker = (await _navigationViewController
              .addMarkers(<MarkerOptions>[markerOptions]))
          .first;
    } else {
      _waypointMarker = (await _navigationViewController.updateMarkers(
              <Marker>[_waypointMarker!.copyWith(options: markerOptions)]))
          .first;
    }
  }

  Future<void> _removeWaypointMarker() async {
    // Update _destinationLocation
    _destinationLocation = null;

    // Update _waypointMarker
    if (_waypointMarker != null) {
      await _navigationViewController.removeMarkers([_waypointMarker!]);
      _waypointMarker = null;
    }
  }

  Future<void> _showRoutePreview() async {
    await GoogleMapsNavigator.setDestinations(
      Destinations(
        waypoints: <NavigationWaypoint>[
          NavigationWaypoint.withLatLngTarget(
            title: "${_destinationPlace.name}",
            target: _destinationLocation,
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

    await _navigationViewController.showRouteOverview();
    setState(() {});
  }

  Future<void> _removeRoutePreview() async {
    await GoogleMapsNavigator.cleanup();
    _isRoutePreview = false;
  }
}
