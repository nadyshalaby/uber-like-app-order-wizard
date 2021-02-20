import 'dart:async';

import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/material.dart';
import 'package:map_tracking_mvp/utils/keys.dart';
import 'package:map_tracking_mvp/utils/models.dart';

const kGoogleApiKey = GOOGLE_API_KEY;

// to get places detail (lat/lng)
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

final customTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.dark,
  accentColor: Colors.redAccent,
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.00)),
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: 12.50,
      horizontal: 10.00,
    ),
  ),
);

class MapSearchBar {
  Function onError;

  MapSearchBar({this.onError});

  Future<Point> show(BuildContext context) async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: onError,
      mode: Mode.overlay,
      language: "ar",
    );

    return _displayPrediction(p);
  }

  Future<Point> _displayPrediction(Prediction p) async {
    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final double lat = detail.result.geometry.location.lat;
      final double lng = detail.result.geometry.location.lng;

      return Point(lat: lat, lng: lng);
    }

    return null;
  }
}
