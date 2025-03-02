class Images {
  Images({
    this.image,
    this.thumbnail,
    this.mobile,
  });

  factory Images.fromJson(Map<String, dynamic> json) => Images(
        image: json['image'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
      );
  String? image;
  String? thumbnail;
  String? mobile;

  Map<String, dynamic> toJson() => {
        'image': image,
        'thumbnail': thumbnail,
        'mobile': mobile,
      };
}
