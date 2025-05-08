// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

class Place {
  // Place Details
  String? place_id;
  String? name;
  String? formatted_address;
  double? lat;
  double? lng;

  // Place Route Estimation
  String? distanceStr;
  String? durationStr;
  int? duration;
  DateTime? startTime;
  DateTime? endTime;

  Place({
    this.place_id,
    this.name,
    this.formatted_address,
    this.lat,
    this.lng,
  });

  Widget PlaceDetailsCard(VoidCallback onCancel) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(0.0),
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Place Name
                Expanded(
                  child: Text(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: false,
                    name!,
                  ),
                ),

                // Cancel
                IconButton(
                  icon: const Icon(
                    color: Colors.grey,
                    size: 30,
                    Icons.cancel,
                  ),
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 12.0),
            Row(
              spacing: 15.0,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,

              // Address
              children: [
                const Icon(
                  Icons.place,
                ),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: false,
                    formatted_address!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              spacing: 15.0,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,

              // Coordinates
              children: [
                const Icon(
                  Icons.map,
                ),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    "${lat!}, ${lng!}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35.0),
          ],
        ),
      ),
    );
  }

  Widget RoutePreviewCard(BuildContext context, VoidCallback onCancel) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(0.0),
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Place Name
                Expanded(
                  child: Text(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: false,
                    name!,
                  ),
                ),

                // Cancel
                IconButton(
                  icon: const Icon(
                    color: Colors.grey,
                    size: 30,
                    Icons.cancel,
                  ),
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 12.0),
            Row(
              spacing: 15.0,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,

              // Time, Distance
              children: [
                const Icon(
                  color: Colors.green,
                  Icons.arrow_right,
                ),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: false,
                    "$durationStr ($distanceStr)",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              spacing: 15.0,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,

              // ETA
              children: [
                const Icon(Icons.time_to_leave),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    "${TimeOfDay.fromDateTime(startTime!).format(context)} - ${TimeOfDay.fromDateTime(endTime!).format(context)}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35.0),
          ],
        ),
      ),
    );
  }
}
