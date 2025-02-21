import 'package:ism_video_reel_player/domain/domain.dart';

class BestOffer {
  BestOffer({
    this.offerId,
    this.offerFor,
    this.offerName,
    this.images,
    this.webimages,
    this.discountType,
    this.discountValue,
    this.listComboProducts,
    this.status,
    this.statusString,
    this.globalClaimCount,
  });

  factory BestOffer.fromJson(Map<String, dynamic> json) => BestOffer(
        offerId: json['offerId'] as String? ?? '',
        offerFor: json['offerFor'] as num? ?? 0,
        offerName: json['offerName'] == null ? null : OfferName.fromJson(json['offerName'] as Map<String, dynamic>),
        images: json['images'] == null ? null : Images.fromJson(json['images'] as Map<String, dynamic>),
        webimages: json['webimages'] == null ? null : Images.fromJson(json['webimages'] as Map<String, dynamic>),
        discountType: json['discountType'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
        listComboProducts: json['listComboProducts'] == null
            ? []
            : List<dynamic>.from((json['listComboProducts'] as List).map((x) => x)),
        status: json['status'] as num? ?? 0,
        statusString: json['statusString'] as String? ?? '',
        globalClaimCount: json['globalClaimCount'] as num? ?? 0,
      );
  String? offerId;
  num? offerFor;
  OfferName? offerName;
  Images? images;
  Images? webimages;
  num? discountType;
  num? discountValue;
  List<dynamic>? listComboProducts;
  num? status;
  String? statusString;
  num? globalClaimCount;

  Map<String, dynamic> toJson() => {
        'offerId': offerId,
        'offerFor': offerFor,
        'offerName': offerName?.toJson(),
        'images': images?.toJson(),
        'webimages': webimages?.toJson(),
        'discountType': discountType,
        'discountValue': discountValue,
        'listComboProducts': listComboProducts == null ? [] : List<dynamic>.from(listComboProducts!.map((x) => x)),
        'status': status,
        'statusString': statusString,
        'globalClaimCount': globalClaimCount,
      };
}
