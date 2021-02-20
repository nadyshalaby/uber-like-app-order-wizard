import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracking_mvp/components/Locationpath.dart';
import 'package:map_tracking_mvp/utils/models.dart';
import './OrderWizard.dart';
import 'package:map_tracking_mvp/utils/sizing.dart';

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  static final center = LatLng(15.508457, 32.522854);

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Set<Polyline> _polyLines = {};
  MarkerId selectedMarker;
  MarkerId _startMarker;
  MarkerId _endMarker;
  PolylineId _polylineId;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            mapToolbarEnabled: true,
            initialCameraPosition: CameraPosition(target: center, zoom: 19),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: Set<Marker>.of(markers.values),
            polylines: _polyLines,
          ),
          Positioned(
            bottom: 100,
            child: Container(
              padding: EdgeInsets.all(10),
              height: Sizing(context).hp(30),
              width: Sizing(context).wp(100),
              child: OrderWizard(
                zoomToRegion: _goToTheLake,
                placeMarker: _placeMarker,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _goToTheLake(Region region) async {
    Point southwest = Point(lat: double.maxFinite, lng: double.maxFinite);
    Point northeast =
        Point(lat: double.negativeInfinity, lng: double.negativeInfinity);
    for (Point point in region.bbox) {
      southwest.lat = min(southwest.lat, point.lat);
      southwest.lng = min(southwest.lng, point.lng);

      northeast.lat = max(northeast.lat, point.lat);
      northeast.lng = max(northeast.lng, point.lng);
    }
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(southwest.lat, southwest.lng),
            northeast: LatLng(northeast.lat, northeast.lng),
          ),
          0),
    );
  }

  Future<void> _placeMarker(String type, Point point) async {
    _add(type, point);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(point.lat, point.lng)),
    );
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        if (markers.containsKey(selectedMarker)) {
          final Marker resetOld = markers[selectedMarker]
              .copyWith(iconParam: BitmapDescriptor.defaultMarker);
          markers[selectedMarker] = resetOld;
        }
        selectedMarker = markerId;
        final Marker newMarker = tappedMarker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        );
        markers[markerId] = newMarker;
      });
    }
  }

  void _onMarkerDragEnd(MarkerId markerId, LatLng newPosition) async {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      _moveMarker(
        markerId,
        Point(
          lat: newPosition.latitude,
          lng: newPosition.longitude,
        ),
      );

      _updateRoute();
    }
  }

  void _add(String type, Point point) async {
    if (type == 'start') {
      if (_startMarker == null) {
        _startMarker = MarkerId(type);
        _addMarker(_startMarker, 'Pickup', point);
      } else {
        _moveMarker(_startMarker, point);
      }
    } else if (type == 'end') {
      if (_endMarker == null) {
        _endMarker = MarkerId(type);
        _addMarker(_endMarker, 'Arrival', point);
      } else {
        _moveMarker(_endMarker, point);
      }
    }

    _updateRoute();
  }

  void _updateRoute() async {
    if (_startMarker != null && _endMarker != null) {
      createRoute(
        await Locationpath().getRouteCoordinates(
          markers[_startMarker].position,
          markers[_endMarker].position,
        ),
      );
    }
  }

  void _addMarker(MarkerId markerId, String title, Point point) {
    final Marker marker = Marker(
      draggable: true,
      markerId: markerId,
      position: LatLng(point.lat, point.lng),
      infoWindow: InfoWindow(title: title, snippet: "*"),
      onTap: () {
        _onMarkerTapped(markerId);
      },
      onDragEnd: (LatLng position) {
        _onMarkerDragEnd(markerId, position);
      },
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  void _moveMarker(MarkerId markerId, Point point) {
    final Marker marker = markers[markerId];

    if (marker == null) {
      return;
    }

    setState(() {
      markers[markerId] = marker.copyWith(
        positionParam: LatLng(
          point.lat,
          point.lng,
        ),
      );
    });
  }

  // ! TO CREATE ROUTE
  void createRoute(String encondedPoly) {
    Polyline polyline;
    if (_polylineId == null) {
      _polylineId = PolylineId('journey-route');

      polyline = Polyline(
          polylineId: _polylineId,
          width: 4,
          points: _convertToLatLng(_decodePoly(encondedPoly)),
          color: Colors.deepPurple);
    } else {
      polyline = _polyLines.first.copyWith(
        pointsParam: _convertToLatLng(
          _decodePoly(encondedPoly),
        ),
      );
    }

    setState(() {
      _polyLines.clear();
      _polyLines.add(polyline);
    });
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  // DECODE POLY
  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;

    if (poly.isEmpty) {
      return lList;
    }

    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);

      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    /*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    return lList;
  }
}
