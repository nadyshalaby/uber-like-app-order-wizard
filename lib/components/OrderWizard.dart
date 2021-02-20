import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:map_tracking_mvp/components/MapSearchBar.dart';
import 'package:map_tracking_mvp/utils/keys.dart';
import 'package:map_tracking_mvp/utils/models.dart';
import 'package:numberpicker/numberpicker.dart';
import '../utils/sizing.dart';

class OrderWizard extends StatefulWidget {
  final Function zoomToRegion;
  final Function placeMarker;

  OrderWizard({this.zoomToRegion, this.placeMarker});

  @override
  _OrderWizardState createState() => _OrderWizardState();
}

class _OrderWizardState extends State<OrderWizard> {
  List<ItemModel> steps = <ItemModel>[
    ItemModel(
      header: 'Pickup Location',
      bodyModel: BodyModel(),
    ),
    ItemModel(
      header: 'Arrival Location',
      bodyModel: BodyModel(),
    ),
    ItemModel(
      header: 'Extra Information',
      bodyModel: BodyModel(startTime: DateTime.now()),
    ),
  ];

  Region _startRegion;
  Region _endRegion;
  Point _startPoint;
  Point _endPoint;
  List<Region> _regions;

  @override
  void initState() {
    this.getRegions().then((regions) {
      _regions = regions;
      setState(() {
        steps[0].bodyModel.regions = _regions;
        steps[1].bodyModel.regions = _regions;
      });
    });

    super.initState();
  }

  Future<List<Region>> getRegions() async {
    var response =
        await http.get("$API_BASE_URI/region?page_size=20", headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $API_ACCESS_TOKEN",
    });

    final List<Region> regions = [];

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);

      if (jsonResponse['success']) {
        for (var region in jsonResponse['data']['data']) {
          List<Point> bbox = [];
          for (var point in region['bbox']) {
            bbox.add(
              Point(
                lat: double.parse(point['lat'].toString()),
                lng: double.parse(point['lng'].toString()),
              ),
            );
          }

          regions.add(
            Region(
              id: region['id'],
              name: Translation(
                ar: region['name']['ar'],
                en: region['name']['en'],
              ),
              country: Translation(
                ar: region['country']['ar'],
                en: region['country']['en'],
              ),
              latlng: Point(
                lat: double.parse(region['latlng']['lat'].toString()),
                lng: double.parse(region['latlng']['lng'].toString()),
              ),
              bbox: bbox,
            ),
          );
        }
      } else {
        print('Request failed with message: ${jsonResponse.msg}.');
      }
    } else {
      print(
          'Request failed with status "${response.statusCode}" and message: ${response.reasonPhrase}.');
    }

    return regions;
  }

  Future<Region> searchForRegion(Point point) async {
    var response =
        await http.post("$API_BASE_URI/region/search", body: <String, String>{
      "lat": point.lat.toString(),
      "lng": point.lng.toString(),
    }, headers: {
      "Authorization": "Bearer $API_ACCESS_TOKEN",
    });

    var jsonResponse = convert.jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (jsonResponse['success'] == true) {
        var region = jsonResponse['data'];

        if (region == null) {
          return null;
        }

        List<Point> bbox = [];

        for (var point in region['bbox']) {
          bbox.add(
            Point(
              lat: double.parse(point['lat'].toString()),
              lng: double.parse(point['lng'].toString()),
            ),
          );
        }

        return Region(
          id: region['id'],
          name: Translation(
            ar: region['name']['ar'],
            en: region['name']['en'],
          ),
          country: Translation(
            ar: region['country']['ar'],
            en: region['country']['en'],
          ),
          latlng: Point(
            lat: double.parse(region['latlng']['lat'].toString()),
            lng: double.parse(region['latlng']['lng'].toString()),
          ),
          bbox: bbox,
        );
      } else {
        print('Request failed with message: ${jsonResponse.msg}.');
      }
    } else {
      print(
          'Request failed with status "${response.statusCode}" and message: ${response.reasonPhrase}.');
    }

    return null;
  }

  Widget _buildRegionsMenu(String type, List<Region> regions) => DropdownButton(
        hint: regions == null
            ? Text(
                "Loading...",
                style: TextStyle(color: Colors.black26),
              )
            : Text(
                "Choose Region",
                style: TextStyle(color: Colors.black26),
              ),
        isExpanded: true,
        value: type == 'start' ? _startRegion : _endRegion,
        items: regions
            ?.map(
              (e) => DropdownMenuItem<Region>(
                child: Text(e.name.en),
                value: e,
              ),
            )
            ?.toList(),
        onChanged: (region) {
          setState(() {
            if (type == 'start') {
              this._startRegion = region;
            } else {
              this._endRegion = region;
            }

            widget.zoomToRegion(region);
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: ListView.builder(
          itemCount: steps.length,
          itemBuilder: (BuildContext context, int index) {
            if (index > 1) {
              return ExpansionPanelList(
                animationDuration: Duration(milliseconds: 500),
                children: [
                  ExpansionPanel(
                    body: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      width: Sizing(context).wp(100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          RaisedButton(
                            onPressed: () {
                              _selectDate(context);
                            },
                            child: Text(
                              DateFormat('yyyy-MM-dd – kk:mm')
                                  .format(steps[2].bodyModel.startTime),
                            ),
                          ),
                          NumberPicker.integer(
                            initialValue: steps[2].bodyModel.seatsCount,
                            minValue: 0,
                            maxValue: 100,
                            onChanged: (newValue) => setState(
                                () => steps[2].bodyModel.seatsCount = newValue),
                          ),
                          RaisedButton(
                            textColor: Colors.white,
                            color: Colors.blueAccent,
                            onPressed: () {
                              _showOrderSummaryDialog();
                            },
                            child: Text('Place Order'),
                          )
                        ],
                      ),
                    ),
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return Container(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          steps[index].header,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                    isExpanded: steps[index].isExpanded,
                  )
                ],
                expansionCallback: (int item, bool status) {
                  setState(() {
                    steps[index].isExpanded = !steps[index].isExpanded;
                  });
                },
              );
            }

            return ExpansionPanelList(
              animationDuration: Duration(milliseconds: 500),
              children: [
                ExpansionPanel(
                  body: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    width: Sizing(context).wp(100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildRegionsMenu(
                          index == 0 ? 'start' : 'end',
                          steps[index].bodyModel.regions,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: RaisedButton(
                            onPressed: () {
                              MapSearchBar(
                                onError: (PlacesAutocompleteResponse response) {
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.errorMessage),
                                    ),
                                  );
                                },
                              ).show(context).then((value) {
                                Function processLocation = () async {
                                  Region region =
                                      await this.searchForRegion(value);

                                  if (region == null) {
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Our services isn\'t available yet in choosing location.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (index == 0) {
                                    this._startPoint = value;
                                    widget.placeMarker('start', value);
                                    _startRegion = _regions
                                        .firstWhere((r) => r.id == region.id);
                                  } else {
                                    this._endPoint = value;
                                    widget.placeMarker('end', value);
                                    _endRegion = _regions
                                        .firstWhere((r) => r.id == region.id);
                                    ;
                                  }
                                };

                                setState(() {
                                  processLocation();
                                });
                              });
                            },
                            child: Text('Choose Location'),
                          ),
                        )
                      ],
                    ),
                  ),
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return Container(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        steps[index].header,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 18,
                        ),
                      ),
                    );
                  },
                  isExpanded: steps[index].isExpanded,
                )
              ],
              expansionCallback: (int item, bool status) {
                setState(() {
                  steps[index].isExpanded = !steps[index].isExpanded;
                });
              },
            );
          },
        ),
      ),
    );
  }

  void _selectDate(BuildContext context) {
    DatePicker.showDateTimePicker(context,
        showTitleActions: true,
        minTime: DateTime.now(),
        maxTime: DateTime(DateTime.now().year + 50), onChanged: (date) {
      setState(() {
        steps[2].bodyModel.startTime = date;
      });
    }, onConfirm: (date) {
      setState(() {
        steps[2].bodyModel.startTime = date;
      });
    }, currentTime: DateTime.now(), locale: LocaleType.en);
  }

  Future<void> _showOrderSummaryDialog() async {
    if (_startPoint == null ||
        _startRegion == null ||
        _endPoint == null ||
        _endRegion == null) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete missing fields'),
        ),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Start Region: ${_startRegion.name.ar}"),
                Text("End Region: ${_endRegion.name.ar}"),
                Text(
                    "Start Point: (Lat: ${_startPoint.lat}, Lng: ${_startPoint.lng})"),
                Text(
                    "End Point: (Lat: ${_endPoint.lat}, Lng: ${_endPoint.lng})"),
                Text(
                    "Start Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(steps[2].bodyModel.startTime)}"),
                Text("Seats Count: ${steps[2].bodyModel.seatsCount}"),
                Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
