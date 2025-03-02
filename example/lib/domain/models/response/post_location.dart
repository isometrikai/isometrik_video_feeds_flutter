class PostLocation {
  PostLocation({
    this.lat,
    this.long,
  });

  factory PostLocation.fromJson(Map<String, dynamic> json) => PostLocation(
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
