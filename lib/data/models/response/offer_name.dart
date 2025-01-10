class OfferName {
  OfferName({
    this.en,
    this.pl,
    this.hi,
  });

  factory OfferName.fromJson(Map<String, dynamic> json) => OfferName(
        en: json['en'] as String? ?? '',
        pl: json['pl'] as String? ?? '',
        hi: json['hi'] as String? ?? '',
      );
  String? en;
  String? pl;
  String? hi;

  Map<String, dynamic> toJson() => {
        'en': en,
        'pl': pl,
        'hi': hi,
      };
}
