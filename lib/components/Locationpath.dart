import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:map_tracking_mvp/utils/keys.dart';

const apiKey = GOOGLE_API_KEY;

class Locationpath {
  Future<String> getRouteCoordinates(LatLng l1, LatLng l2) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude}, ${l2.longitude}&key=$apiKey";
    http.Response response = await http.get(url);
    if (response.statusCode == 200) {
      Map values = jsonDecode(response.body);
      if (values['status'] == 'OK') {
        return values["routes"][0]["overview_polyline"]["points"];
      } else {
        return "";
      }
    }

    print(response.reasonPhrase);
    return "";
  }
}
