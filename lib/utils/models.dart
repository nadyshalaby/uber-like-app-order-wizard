class Translation {
  String ar;
  String en;

  Translation({this.ar, this.en});
}

class Point {
  double lat;
  double lng;

  Point({this.lat, this.lng});
}

class Region {
  int id;
  Translation name;
  Translation country;
  Point latlng;
  List<Point> bbox = [];

  Region({
    this.id,
    this.name,
    this.country,
    this.latlng,
    this.bbox,
  });
}

class BodyModel {
  List<Region> regions = [];
  DateTime startTime;
  int seatsCount;
  Point point;

  BodyModel({this.regions, this.point, this.startTime, this.seatsCount = 1});
}

class ItemModel {
  bool isExpanded = false;
  String header;
  BodyModel bodyModel;

  ItemModel({this.header, this.bodyModel});
}
