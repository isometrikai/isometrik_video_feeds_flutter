// To parse this JSON data, do
//
//     final signupResponseModel = signupResponseModelFromJson(jsonString);

import 'dart:convert';

SignupResponseModel signupResponseModelFromJson(String str) =>
    SignupResponseModel.fromJson(json.decode(str) as Map<String, dynamic>);

String signupResponseModelToJson(SignupResponseModel data) => json.encode(data.toJson());

class SignupResponseModel {
  SignupResponseModel({
    this.message,
    this.data,
  });

  factory SignupResponseModel.fromJson(Map<String, dynamic> json) => SignupResponseModel(
        message: json['message'] as String? ?? '',
        data: json['data'] == null ? LoginSignupData() : LoginSignupData.fromJson(json['data'] as Map<String, dynamic>),
      );
  String? message;
  LoginSignupData? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'data': data!.toJson(),
      };
}

class LoginSignupData {
  LoginSignupData({
    this.token,
    this.storeToken,
    this.userId,
    this.userType,
    this.customerType,
    this.institutionType,
    this.countryCode,
    this.currencySymbol,
    this.currencyCode,
    this.email,
    this.private,
    this.businessProfile,
    this.isActiveBusinessProfile,
    this.fcmTopic,
    this.mqttTopic,
    this.city,
    this.cityId,
    this.region,
    this.country,
    this.countryName,
    this.location,
    this.userName,
    this.name,
    this.firstName,
    this.mobile,
    this.number,
    this.qrCode,
    this.profilePic,
    this.profileVideoThumbnail,
    this.isKycApproved,
    this.isKycStatus,
    this.isKycStatusText,
    this.isKycReason,
    this.stream,
    this.status,
    this.statusMsg,
    this.userTypeText,
    this.customerTypeText,
    this.institutionTypeText,
    this.postal,
    this.lastName,
    this.googleMapKeyMqtt,
    this.mmjCard,
    this.identityCard,
    this.institutionsRes,
    this.institutionsDetails,
    this.currency,
    this.profileVideo,
    this.groupCallStreamId,
    this.accountId,
    this.keysetId,
    this.projectId,
    this.licenseKey,
    this.keysetName,
    this.rtcAppId,
    this.arFiltersAppId,
    this.role,
    this.roleType,
    this.roleTypeText,
    this.isStar,
    this.storeId,
    this.ownedbyStoreId,
    this.ownedbyUserId,
    this.isomatricChatUserId,
    this.gender,
    this.genderText,
    this.nationality,
    this.invoiceSent,
    this.isTeamMember,
    this.isContactPerson,
    this.contactPersonUserId,
    this.isUserContact,
    this.isRechargeWallet,
    this.isTeamMemberAddRemove,
    this.isContactDelete,
    // this.idProof,
  });

  factory LoginSignupData.fromJson(Map<String, dynamic> json) => LoginSignupData(
        token: json['token'] == null ? Tokens() : Tokens.fromJson(json['token'] as Map<String, dynamic>),
        // storeToken: json['storeToken'] == null ? InstitutionsDetails() : InstitutionsDetails.fromJson(json['storeToken'] as Map<String, dynamic>),
        userId: json['userId'] as String? ?? '',
        userType: json['userType'] as int? ?? 0,
        customerType: json['customerType'] as int? ?? 0,
        institutionType: json['institutionType'] as int? ?? 0,
        countryCode: json['countryCode'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? '',
        currencyCode: json['currencyCode'] as String? ?? '',
        email: json['email'] as String? ?? '',
        private: json['private'] as int? ?? 0,
        // businessProfile:
        //     List<dynamic>.from(json['businessProfile'].map((x) => x)),
        isActiveBusinessProfile: json['isActiveBusinessProfile'] as bool? ?? false,
        fcmTopic: json['fcmTopic'] as String? ?? '',
        mqttTopic: json['mqttTopic'] as String? ?? '',
        city: json['city'] as String? ?? '',
        cityId: json['cityId'] as String? ?? '',
        region: json['region'] as String? ?? '',
        country: json['country'] as String? ?? '',
        countryName: json['countryName'] as String? ?? '',
        location: json['location'] == null
            ? LoginSignupLocation()
            : LoginSignupLocation.fromJson(json['location'] as Map<String, dynamic>),
        userName: json['userName'] as String? ?? '',
        name: json['name'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        number: json['number'] as String? ?? '',
        qrCode: json['qrCode'] as String? ?? '',
        profilePic: json['profilePic'] as String? ?? '',
        profileVideoThumbnail: json['profileVideoThumbnail'] as String? ?? '',
        isKycApproved: json['isKYCApproved'] as bool? ?? false,
        isKycStatus: json['isKYCStatus'] as int? ?? 0,
        isKycStatusText: json['isKYCStatusText'] as String? ?? '',
        isKycReason: json['isKYCReason'] as String? ?? '',
        // stream: InstitutionsDetails.fromJson(json['stream']),
        status: json['status'] as int? ?? 0,
        statusMsg: json['statusMsg'] as String? ?? '',
        userTypeText: json['userTypeText'] as String? ?? '',
        customerTypeText: json['customerTypeText'] as String? ?? '',
        institutionTypeText: json['institutionTypeText'] as String? ?? '',
        postal: json['postal'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        googleMapKeyMqtt: json['googleMapKeyMqtt'] as String? ?? '',
        // mmjCard: Card.fromJson(json['mmjCard']),
        // identityCard: Card.fromJson(json['identityCard']),
        // institutionsRes:
        //     List<dynamic>.from(json['institutionsRes'].map((x) => x)),
        // institutionsDetails:
        //     InstitutionsDetails.fromJson(json['institutionsDetails']),
        currency: json['currency'] as String? ?? '',
        profileVideo: json['profileVideo'] as String? ?? '',
        groupCallStreamId: json['groupCallStreamId'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        keysetId: json['keysetId'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        licenseKey: json['licenseKey'] as String? ?? '',
        keysetName: json['keysetName'] as String? ?? '',
        rtcAppId: json['rtcAppId'] as String? ?? '',
        arFiltersAppId: json['arFiltersAppId'] as String? ?? '',
        role: json['role'] as String? ?? '',
        roleType: json['roleType'] as int? ?? 0,
        roleTypeText: json['roleTypeText'] as String? ?? '',
        isStar: json['isStar'] as bool? ?? false,
        storeId: json['storeId'] as String? ?? '',
        ownedbyStoreId: json['ownedbyStoreID'] as String? ?? '',
        ownedbyUserId: json['ownedbyUserId'] as String? ?? '',
        isomatricChatUserId: json['isomatricChatUserId'] as String? ?? '',
        gender: json['gender'] as int? ?? 0,
        genderText: json['genderText'] as String? ?? '',
        nationality: json['nationality'] as String? ?? '',
        invoiceSent: json['invoiceSent'] as bool? ?? false,
        isTeamMember: json['isTeamMember'] as bool? ?? false,
        isContactPerson: json['isContactPerson'] as int? ?? 0,
        contactPersonUserId: json['contactPersonUserId'] as String? ?? '',
        isUserContact: json['isUserContact'] as bool? ?? false,
        isRechargeWallet: json['isRechargeWallet'] as bool? ?? false,
        isTeamMemberAddRemove: json['isTeamMemberAddRemove'] as bool? ?? false,
        isContactDelete: json['isContactDelete'] as bool? ?? false,
        // idProof: IdProof.fromJson(json['idProof']),
      );
  Tokens? token;
  InstitutionsDetails? storeToken;
  String? userId;
  int? userType;
  int? customerType;
  int? institutionType;
  String? countryCode;
  String? currencySymbol;
  String? currencyCode;
  String? email;
  int? private;
  List<dynamic>? businessProfile;
  bool? isActiveBusinessProfile;
  String? fcmTopic;
  String? mqttTopic;
  String? city;
  String? cityId;
  String? region;
  String? country;
  String? countryName;
  LoginSignupLocation? location;
  String? userName;
  String? name;
  String? firstName;
  String? mobile;
  String? number;
  String? qrCode;
  String? profilePic;
  String? profileVideoThumbnail;
  bool? isKycApproved;
  int? isKycStatus;
  String? isKycStatusText;
  String? isKycReason;
  InstitutionsDetails? stream;
  int? status;
  String? statusMsg;
  String? userTypeText;
  String? customerTypeText;
  String? institutionTypeText;
  String? postal;
  String? lastName;
  String? googleMapKeyMqtt;
  LoginSignupCard? mmjCard;
  LoginSignupCard? identityCard;
  List<dynamic>? institutionsRes;
  InstitutionsDetails? institutionsDetails;
  String? currency;
  String? profileVideo;
  String? groupCallStreamId;
  String? accountId;
  String? keysetId;
  String? projectId;
  String? licenseKey;
  String? keysetName;
  String? rtcAppId;
  String? arFiltersAppId;
  String? role;
  int? roleType;
  String? roleTypeText;
  bool? isStar;
  String? storeId;
  String? ownedbyStoreId;
  String? ownedbyUserId;
  String? isomatricChatUserId;
  int? gender;
  String? genderText;
  String? nationality;
  bool? invoiceSent;
  bool? isTeamMember;
  int? isContactPerson;
  String? contactPersonUserId;
  bool? isUserContact;
  bool? isRechargeWallet;
  bool? isTeamMemberAddRemove;
  bool? isContactDelete;

  // IdProof? idProof;

  Map<String, dynamic> toJson() => {
        'token': token!.toJson(),
        'storeToken': storeToken!.toJson(),
        'userId': userId,
        'userType': userType,
        'customerType': customerType,
        'institutionType': institutionType,
        'countryCode': countryCode,
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
        'email': email,
        'private': private,
        'businessProfile': List<dynamic>.from(businessProfile!.map((x) => x)),
        'isActiveBusinessProfile': isActiveBusinessProfile,
        'fcmTopic': fcmTopic,
        'mqttTopic': mqttTopic,
        'city': city,
        'cityId': cityId,
        'region': region,
        'country': country,
        'countryName': countryName,
        'location': location!.toJson(),
        'userName': userName,
        'name': name,
        'firstName': firstName,
        'mobile': mobile,
        'number': number,
        'qrCode': qrCode,
        'profilePic': profilePic,
        'profileVideoThumbnail': profileVideoThumbnail,
        'isKYCApproved': isKycApproved,
        'isKYCStatus': isKycStatus,
        'isKYCStatusText': isKycStatusText,
        'isKYCReason': isKycReason,
        'stream': stream!.toJson(),
        'status': status,
        'statusMsg': statusMsg,
        'userTypeText': userTypeText,
        'customerTypeText': customerTypeText,
        'institutionTypeText': institutionTypeText,
        'postal': postal,
        'lastName': lastName,
        'googleMapKeyMqtt': googleMapKeyMqtt,
        'mmjCard': mmjCard!.toJson(),
        'identityCard': identityCard!.toJson(),
        'institutionsRes': List<dynamic>.from(institutionsRes!.map((x) => x)),
        'institutionsDetails': institutionsDetails!.toJson(),
        'currency': currency,
        'profileVideo': profileVideo,
        'groupCallStreamId': groupCallStreamId,
        'accountId': accountId,
        'keysetId': keysetId,
        'projectId': projectId,
        'licenseKey': licenseKey,
        'keysetName': keysetName,
        'rtcAppId': rtcAppId,
        'arFiltersAppId': arFiltersAppId,
        'role': role,
        'roleType': roleType,
        'roleTypeText': roleTypeText,
        'isStar': isStar,
        'storeId': storeId,
        'ownedbyStoreID': ownedbyStoreId,
        'ownedbyUserId': ownedbyUserId,
        'isomatricChatUserId': isomatricChatUserId,
        'gender': gender,
        'genderText': genderText,
        'nationality': nationality,
        'invoiceSent': invoiceSent,
        'isTeamMember': isTeamMember,
        'isContactPerson': isContactPerson,
        'contactPersonUserId': contactPersonUserId,
        'isUserContact': isUserContact,
        'isRechargeWallet': isRechargeWallet,
        'isTeamMemberAddRemove': isTeamMemberAddRemove,
        'isContactDelete': isContactDelete,
        // 'idProof': idProof!.toJson(),
      };
}

// class IdProof {
//   IdProof({
//     this.idProofTypeId,
//     this.idProofTypeTitle,
//     this.idProofFront,
//     this.idProofBack,
//     this.idProofStatus,
//   });

//   factory IdProof.fromJson(Map<String, dynamic> json) => IdProof(
//         idProofTypeId: json['idProofTypeId'] as String? ?? '',
//         idProofTypeTitle: json['idProofTypeTitle'] as String? ?? '',
//         idProofFront: json['idProofFront'] as String? ?? '',
//         idProofBack: json['idProofBack'] as String? ?? '',
//         idProofStatus: json['idProofStatus'] as int? ?? 0,
//       );
//   String? idProofTypeId;
//   String? idProofTypeTitle;
//   String? idProofFront;
//   String? idProofBack;
//   int? idProofStatus;

//   Map<String, dynamic> toJson() => {
//         'idProofTypeId': idProofTypeId,
//         'idProofTypeTitle': idProofTypeTitle,
//         'idProofFront': idProofFront,
//         'idProofBack': idProofBack,
//         'idProofStatus': idProofStatus,
//       };
// }

class LoginSignupCard {
  LoginSignupCard({
    this.url,
    this.verified,
  });

  factory LoginSignupCard.fromJson(Map<String, dynamic> json) => LoginSignupCard(
        url: json['url'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
      );
  String? url;
  bool? verified;

  Map<String, dynamic> toJson() => {
        'url': url,
        'verified': verified,
      };
}

class InstitutionsDetails {
  InstitutionsDetails();

  factory InstitutionsDetails.fromJson() => InstitutionsDetails();

  Map<String, dynamic> toJson() => {};
}

class LoginSignupLocation {
  LoginSignupLocation({
    this.lat,
    this.long,
  });

  factory LoginSignupLocation.fromJson(Map<String, dynamic> json) => LoginSignupLocation(
        lat: json['lat'] as num? ?? 0,
        long: json['lon'] as num? ?? 0,
      );
  num? lat;
  num? long;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'long': long,
      };
}

class Tokens {
  Tokens({
    this.accessExpireAt,
    this.accessToken,
    this.refreshToken,
    this.userData,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) => Tokens(
        accessExpireAt: json['accessExpireAt'] as int? ?? 0,
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        userData: json['userData'] == null ? null : UserData.fromJson(json['userData'] as Map<String, dynamic>),
      );
  int? accessExpireAt;
  String? accessToken;
  String? refreshToken;
  UserData? userData;

  Map<String, dynamic> toJson() => {
        'accessExpireAt': accessExpireAt,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userData': userData?.toJson(),
      };
}

class UserData {
  UserData({
    this.userId,
    this.createdTimestamp,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        userId: json['userId'] as String? ?? '',
        createdTimestamp: json['createdTimestamp'] as num? ?? 0,
      );
  String? userId;
  num? createdTimestamp;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'createdTimestamp': createdTimestamp,
      };
}
