import 'package:cleadr/src/app.dart';
import 'package:cleadr/src/services/services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LoadingFailedScreen extends StatelessWidget {
  const LoadingFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Service Statuses
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 100.0,
              horizontal: 50.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4.0,
                  ),
                ),
              ),
              child: Column(
                children: [
                  statusRow("🌐", "Internet", Services.serviceStatusesStr[0]),
                  statusRow("🧾", "Terms & Conditions",
                      Services.serviceStatusesStr[1]),
                  statusRow(
                      "🗺️", "Google Maps API", Services.serviceStatusesStr[2]),
                  statusRow("📍", "Location", Services.serviceStatusesStr[3]),
                  statusRow("📷", "Camera", Services.serviceStatusesStr[4]),
                ],
              ),
            ),
          ),

          // Description 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70.0),
            child: Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                children: [
                  TextSpan(
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    text: "Cleadr",
                  ),
                  TextSpan(
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                    text:
                        " requires the access of a few app permissions to work.",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30.0),

          // Description 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70.0),
            child: Text(
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              "Please try again.",
            ),
          ),
          const SizedBox(height: 50.0),

          // Retry, Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.0,
            children: [
              // Invisible button for alignment purposes
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                ),
                icon: Icon(
                  color: Colors.transparent,
                  Icons.circle,
                ),
                onPressed: null,
              ),

              // Retry
              IconButton(
                style: IconButton.styleFrom(
                  iconSize: 40.0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
                icon: Icon(
                  Icons.refresh,
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const CleadrApp()),
                  (route) => false, // Disable and remove previous screens
                ),
              ),

              // Settings
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  color: Colors.white,
                  Icons.settings,
                ),
                onPressed: () => openAppSettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget statusRow(String icon, String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon, label
          Text(
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
            "$icon  $label",
          ),

          // Status
          Text(
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
            status,
          ),
        ],
      ),
    );
  }
}
