class Location {
  Location({
    this.lat,
    this.long,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        lat: json['lat'] as String? ?? '',
        long: json['long'] as String? ?? '',
      );
  String? lat;
  String? long;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'long': long,
      };
}
