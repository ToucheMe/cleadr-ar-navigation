import 'package:cleadr/src/screens/loading.dart';
import 'package:cleadr/src/util/constants.dart';
import 'package:cleadr/src/util/functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  bool _isLoading = true;

  late final UnityWidget _unityWidget;
  late final UnityWidgetController _unityWidgetController;
  // late final StreamSubscription<NavInfoEvent> _navInfoEventStream;

  late final String _unityGameObject;
  late final String _unityMethodName;

  List<Lane>? _lanes;

  String? _maneuver;
  int? _distance;
  int? _targetLane;

  @override
  void initState() {
    super.initState();
    _initUnity();
  }

  @override
  void dispose() {
    _unityWidgetController.pause();
    _unityWidgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ||
            kDebugMode // Emulator unable to render Flutter-Unity widget
        ? LoadingScreen()
        :
        // AR navigation
        _unityWidget;
  }

  void _initUnity() {
    _unityWidget = UnityWidget(onUnityCreated: (controller) {
      _unityWidgetController = controller;
      _unityWidgetController.resume();
    });

    // _navInfoEventStream = GoogleMapsNavigator.setNavInfoListener(
    //   _onNavInfoEvent,
    //   numNextStepsToPreview: null,
    // );

    GoogleMapsNavigator.setNavInfoListener(
      _onNavInfoEvent,
      numNextStepsToPreview: null,
    );

    _unityGameObject = "Flutter Unity Manager";
    _unityMethodName = "Render";

    _isLoading = false;
    setState(() {});
  }

  void _flutterToUnityJsonMessage(Map<String, dynamic> jsonMessage) {
    debugLog("_flutterToUnityJsonMessage() - Sent: $jsonMessage");
    _unityWidgetController.postJsonMessage(
        _unityGameObject, _unityMethodName, jsonMessage);
  }

  // Find the closest recommended lane
  int? _findTargetLane() {
    if (_lanes != null) {
      if (_lanes!.length > 1 && _lanes!.length < TARGET_LANE_LIMIT + 1) {
        // tflite limitation: max TARGET_LANE_LIMIT lanes
        // Iterate through "lanes" (_lanes)
        for (int lane = 0; lane < _lanes!.length; lane++) {
          // Iterate through "laneDirections"
          for (int laneDirection = 0;
              laneDirection < _lanes![lane].laneDirections.length;
              laneDirection++) {
            if (_lanes![lane].laneDirections[laneDirection].isRecommended ==
                true) {
              // Case: First lane
              if (lane == 0) {
                // Check after lane (lane + 1), whether isRecommended == false
                for (int laneDirection2 = 0;
                    laneDirection2 < _lanes![lane + 1].laneDirections.length;
                    laneDirection2++) {
                  if (_lanes![lane + 1]
                          .laneDirections[laneDirection2]
                          .isRecommended ==
                      false) {
                    return lane + 1;
                  }
                }
              }

              // Case: Last lane
              else if (lane == _lanes!.length - 1) {
                // Check before lane (lane - 1), whether isRecommended == false
                for (int laneDirection2 = 0;
                    laneDirection2 < _lanes![lane - 1].laneDirections.length;
                    laneDirection2++) {
                  if (_lanes![lane - 1]
                          .laneDirections[laneDirection2]
                          .isRecommended ==
                      false) {
                    return lane + 1;
                  }
                }
              }

              // Default case
              else {
                for (int laneDirection2 = 0;
                    laneDirection2 < _lanes![lane + 1].laneDirections.length;
                    laneDirection2++) {
                  if (_lanes![lane + 1]
                          .laneDirections[laneDirection2]
                          .isRecommended ==
                      false) {
                    return lane + 1;
                  }
                }

                for (int laneDirection2 = 0;
                    laneDirection2 < _lanes![lane - 1].laneDirections.length;
                    laneDirection2++) {
                  if (_lanes![lane - 1]
                          .laneDirections[laneDirection2]
                          .isRecommended ==
                      false) {
                    return lane + 1;
                  }
                }
              }
            }
          }
        }
      }
    }

    return null;
  }

  void _onNavInfoEvent(NavInfoEvent event) {
    _lanes = event.navInfo.currentStep!.lanes;

    _maneuver = event.navInfo.currentStep!.maneuver.name;
    _distance = event.navInfo.distanceToCurrentStepMeters;
    _targetLane = _findTargetLane();

    _flutterToUnityJsonMessage({
      "maneuver": _maneuver,
      "distance": _distance,
      "target_lane": _targetLane,
    });
  }
}
