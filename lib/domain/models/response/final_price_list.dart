class FinalPriceList {
  FinalPriceList({
    this.basePrice,
    this.finalPrice,
    this.discountPrice,
    this.sellerPrice,
    this.discountPercentage,
    this.discountType,
    this.taxRate,
    this.discount,
    this.discountValue,
  });

  factory FinalPriceList.fromJson(Map<String, dynamic> json) => FinalPriceList(
        basePrice: json['basePrice'] as num? ?? 0,
        finalPrice: json['finalPrice'] as num? ?? 0,
        discountPrice: json['discountPrice'] as num? ?? 0,
        sellerPrice: json['sellerPrice'] as num? ?? 0,
        discountPercentage: json['discountPercentage'] as num? ?? 0,
        discountType: json['discountType'] as num? ?? 0,
        taxRate: json['taxRate'] as num? ?? 0,
        discount: json['discount'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
      );
  num? basePrice;
  num? finalPrice;
  num? discountPrice;
  num? sellerPrice;
  num? discountPercentage;
  num? discountType;
  num? taxRate;
  num? discount;
  num? discountValue;

  Map<String, dynamic> toJson() => {
        'basePrice': basePrice,
        'finalPrice': finalPrice,
        'discountPrice': discountPrice,
        'sellerPrice': sellerPrice,
        'discountPercentage': discountPercentage,
        'discountType': discountType,
        'taxRate': taxRate,
        'discount': discount,
        'discountValue': discountValue,
      };
}
