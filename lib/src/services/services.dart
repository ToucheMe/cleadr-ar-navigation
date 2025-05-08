import 'dart:convert';

import 'package:cleadr/src/util/constants.dart';
import 'package:cleadr/src/util/functions.dart';
import 'package:cleadr/src/util/place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class Services {
  static const int numberOfServices = 5;

  // A list of bools to represent service statuses
  // true or false
  static final List<bool> serviceStatusesBool =
      List.filled(Services.numberOfServices, false);

  // A list of strings to represent service statuses
  // "✅" or "❌"
  static final List<String> serviceStatusesStr =
      List.filled(Services.numberOfServices, "");

  static Future<bool> checkAllServices() async {
    debugLog("Checking all required services...");

    // Update serviceStatusesBool
    serviceStatusesBool[0] = await checkInternet();
    serviceStatusesBool[1] = await checkTermsAndConditions();
    serviceStatusesBool[2] = await checkGoogleMapsApi();
    serviceStatusesBool[3] = await checkLocation();
    serviceStatusesBool[4] = await checkCamera();

    // Update serviceStatusesStr
    for (int service = 0; service < numberOfServices; service++) {
      if (serviceStatusesBool[service] == true) {
        serviceStatusesStr[service] = "✅";
      } else {
        serviceStatusesStr[service] = "❌";
      }
    }

    // Check if any failed services
    for (int service = 0; service < numberOfServices; service++) {
      if (serviceStatusesBool[service] == false) {
        debugLog("checkAllServices() - Failed");
        return false;
      }
    }

    debugLog("checkAllServices() - Success");
    return true;
  }

  // Service [0]: Internet
  static Future<bool> checkInternet() async {
    debugLog("Checking Internet...");

    // Ping request to Google.com
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugLog("Internet - OK");
        return true;
      } else {
        debugLog("Internet - Failed: Error ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugLog("Internet - Failed: $e");
      return false;
    }
  }

  // Service [1]: Terms & Conditions
  static Future<bool> checkTermsAndConditions() async {
    debugLog("Checking Terms & Conditions...");

    // Check if already accepted
    if (await GoogleMapsNavigator.areTermsAccepted()) {
      debugLog("Terms & Conditions - OK");
      return true;
    }

    // Prompt T&C
    if (await GoogleMapsNavigator.showTermsAndConditionsDialog(
        'Terms & Conditions', 'Cleadr')) {
      debugLog("Terms & Conditions - OK");
      return true;
    }

    // T&C not accepted
    debugLog("Terms & Conditions - Failed: T&C not accepted");
    return false;
  }

  // Service [2]: Google Maps API
  static Future<bool> checkGoogleMapsApi() async {
    debugLog("Checking Google Maps API...");

    // Request to Maps Embed API (Free Unlimited Requests)
    // Note: Does not check for Maps SDK for Android, Places API, Geocoding API, Directions API, and/or Navigation SDK.
    debugLog("Sending request to Google Maps API...");

    try {
      final String url =
          "https://www.google.com/maps/embed/v1/place?key=$GOOGLE_MAPS_API_KEY&q=Sitiawan";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        debugLog("Google Maps API - OK");
        return true;
      } else {
        debugLog("Google Maps API - Failed: Error ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugLog("Google Maps API - Failed: Error $e");
      return false;
    }
  }

  // Service [3]: Location
  static Future<bool> checkLocation() async {
    debugLog("Checking Location...");

    // Check if location service is enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!await Location.instance.requestService()) {
        debugLog("Location - Failed: Location service is disabled");
        return false;
      }
    }

    // Check if location permission is granted
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever ||
        locationPermission == LocationPermission.unableToDetermine) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever ||
          locationPermission == LocationPermission.unableToDetermine) {
        debugLog("Location - Failed: Location permission is denied");
        return false;
      }
    }

    debugLog("Location - OK");
    return true;
  }

  // Service [4]: Camera
  static Future<bool> checkCamera() async {
    debugLog("Checking Camera...");

    // Check if camera permission is granted
    if (!await Permission.camera.status.isGranted) {
      await Permission.camera.request();
      if (!await Permission.camera.status.isGranted) {
        debugLog("Camera - Failed: Camera permission is denied");
        return false;
      }
    }

    debugLog("Camera - OK");
    return true;
  }

  /*
    Place Predictions
    1. Place Autocomplete: place_id
    2. Place Details: name, formatted_address, lat, lng -> Place()
  */
  static Future<List<Place>> fetchPlacePredictions(String query) async {
    // 1. Place Autocomplete: place_id
    List<String> placeIds;

    String input = Uri.encodeComponent(query);
    double radius = 2000.0;
    Position position = await Geolocator.getCurrentPosition();
    String locationbias =
        "circle:$radius@${position.latitude},${position.longitude}";
    final String placeAutocompleteUrl =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&locationbias=$locationbias&key=$GOOGLE_MAPS_API_KEY";
    dynamic placeAutocompleteResponse;

    try {
      debugLog("Sending request to $placeAutocompleteUrl...");
      placeAutocompleteResponse =
          await http.get(Uri.parse(placeAutocompleteUrl));
    } catch (e) {
      debugLog("fetchPlacePredictions() - Place Autocomplete - Failed: $e");
      return [];
    }

    if (placeAutocompleteResponse.statusCode == 200) {
      final placeAutocompleteData = json.decode(placeAutocompleteResponse.body);

      if (placeAutocompleteData["status"] == "OK") {
        placeIds = (placeAutocompleteData["predictions"] as List)
            .map<String>((prediction) => prediction["place_id"] as String)
            .toList();
      } else {
        debugLog(
            "fetchPlacePredictions() - Place Autocomplete - Failed: ${placeAutocompleteData["status"]}");
        return [];
      }
    } else {
      debugLog(
          "fetchPlacePredictions() - Place Autocomplete - Failed: ${placeAutocompleteResponse.statusCode}");
      return [];
    }

    // 2. Place Details: name, formatted_address, lat, lng -> Place()
    List<Place> placePredictions;

    List<Future<Place?>> placePredictionsFutures =
        placeIds.map((placeId) async {
      final String placeDetailsUrl =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$GOOGLE_MAPS_API_KEY";
      dynamic placeDetailsResponse;

      try {
        debugLog("Sending request to $placeDetailsUrl...");
        placeDetailsResponse = await http.get(Uri.parse(placeDetailsUrl));
      } catch (e) {
        debugLog("fetchPlacePredictions() - Place Details - Failed: $e");
        return null;
      }

      if (placeDetailsResponse.statusCode == 200) {
        final placeDetailsData = json.decode(placeDetailsResponse.body);

        if (placeDetailsData["status"] == "OK") {
          return Place(
            place_id: placeId,
            name: placeDetailsData["result"]["name"],
            formatted_address: placeDetailsData["result"]["formatted_address"],
            lat: placeDetailsData["result"]["geometry"]["location"]["lat"],
            lng: placeDetailsData["result"]["geometry"]["location"]["lng"],
          );
        } else {
          debugLog(
              "fetchPlacePredictions() - Place Details - Failed: ${placeDetailsData["status"]}");
          return null;
        }
      } else {
        debugLog(
            "fetchPlacePredictions() - Place Details - Failed: ${placeAutocompleteResponse.statusCode}");
        return null;
      }
    }).toList();

    placePredictions = (await Future.wait(placePredictionsFutures))
        .whereType<Place>()
        .toList();

    debugLog("fetchPlacePredictions() - Success");
    return placePredictions;
  }

  /*
    Place Details
    1. Geocoding API: place_id
    2. Place Details: name, formatted_address, lat, lng -> Place()
  */
  static Future<Place> fetchPlaceDetails(LatLng destinationLocation) async {
    // 1. Geocoding API: place_id
    String placeId;

    String latlng =
        "${destinationLocation.latitude},${destinationLocation.longitude}";
    final String geocodingApiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latlng&key=$GOOGLE_MAPS_API_KEY";
    dynamic geocodingApiResponse;

    try {
      debugLog("Sending request to $geocodingApiUrl...");
      geocodingApiResponse = await http.get(Uri.parse(geocodingApiUrl));
    } catch (e) {
      debugLog("fetchPlaceDetails() - Geocoding API - Failed: $e");
      return Place();
    }

    if (geocodingApiResponse.statusCode == 200) {
      final geocodingApiData = json.decode(geocodingApiResponse.body);

      if (geocodingApiData["status"] == "OK") {
        placeId = geocodingApiData["results"][0]["place_id"];
      } else {
        debugLog(
            "fetchPlaceDetails() - Geocoding API - Failed: ${geocodingApiData["status"]}");
        return Place();
      }
    } else {
      debugLog(
          "fetchPlaceDetails() - Geocoding API - Failed: ${geocodingApiResponse.statusCode}");
      return Place();
    }

    // 2. Place Details: name, formatted_address, lat, lng -> Place()
    Place placeDetails;

    final String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$GOOGLE_MAPS_API_KEY";
    dynamic placeDetailsResponse;

    try {
      debugLog("Sending request to $placeDetailsUrl...");
      placeDetailsResponse = await http.get(Uri.parse(placeDetailsUrl));
    } catch (e) {
      debugLog("fetchPlaceDetails() - Place Details - Failed: $e");
      return Place();
    }

    if (placeDetailsResponse.statusCode == 200) {
      final placeDetailsData = json.decode(placeDetailsResponse.body);

      if (placeDetailsData["status"] == "OK") {
        placeDetails = Place(
          place_id: placeId,
          name: placeDetailsData["result"]["name"],
          formatted_address: placeDetailsData["result"]["formatted_address"],
          lat: placeDetailsData["result"]["geometry"]["location"]["lat"],
          lng: placeDetailsData["result"]["geometry"]["location"]["lng"],
        );
      } else {
        debugLog(
            "fetchPlaceDetails() - Place Detail - Failed: ${placeDetailsData["status"]}");
        return Place();
      }
    } else {
      debugLog(
          "fetchPlaceDetails() - Place Detail - Failed: ${placeDetailsResponse.statusCode}");
      return Place();
    }

    return placeDetails;
  }

  /*
    Directions API: distance, duration
  */
  static Future<(String distanceStr, String durationStr, int duration)>
      fetchPlaceRouteEstimation(
          LatLng currentLocation, LatLng destinationLocation) async {
    String distanceStr;
    String durationStr;
    int duration;

    final String directionsApiUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation.latitude},${currentLocation.longitude}&destination=${destinationLocation.latitude},${destinationLocation.longitude}&key=$GOOGLE_MAPS_API_KEY";
    dynamic directionsApiResponse;

    try {
      debugLog("Sending request to $directionsApiUrl...");
      directionsApiResponse = await http.get(Uri.parse(directionsApiUrl));
    } catch (e) {
      debugLog("fetchPlaceRouteEstimation() - Directions API - Failed: $e");
      return ("", "", 0);
    }

    if (directionsApiResponse.statusCode == 200) {
      final directionsApiData = json.decode(directionsApiResponse.body);

      if (directionsApiData["status"] == "OK") {
        distanceStr =
            directionsApiData["routes"][0]["legs"][0]["distance"]["text"];
        durationStr =
            directionsApiData["routes"][0]["legs"][0]["duration"]["text"];
        duration =
            directionsApiData["routes"][0]["legs"][0]["duration"]["value"];
      } else {
        debugLog(
            "fetchPlaceRouteEstimation() - Directions API - Failed: ${directionsApiData["status"]}");
        return ("", "", 0);
      }
    } else {
      debugLog(
          "fetchPlaceRouteEstimation() - Directions API - Failed: ${directionsApiResponse.statusCode}");
      return ("", "", 0);
    }

    return (distanceStr, durationStr, duration);
  }
}
