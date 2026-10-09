import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;

/// Uses Google Play Services' native "Turn on Location" dialog —
/// a one-tap inline prompt that enables GPS without leaving the app
/// (unlike opening the phone's Settings screen). This is the closest
/// thing Android allows to "automatically turning on location": the
/// OS still requires one tap for privacy/security reasons, but the
/// person never has to navigate away from BuildMart to do it.
class LocationService {
  static Future<void> ensureLocationEnabled(BuildContext context) async {
    final location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      // This call itself shows Android's native "Turn on Location?"
      // dialog with a one-tap "Yes" button — no Settings redirect.
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // User declined — nothing more we can do; proceed without it.
        return;
      }
    }

    var permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    // permission now granted, denied, or deniedForever — calling
    // screens that need a location simply handle a null/failed fetch
    // gracefully either way, so no further action needed here.
  }
}