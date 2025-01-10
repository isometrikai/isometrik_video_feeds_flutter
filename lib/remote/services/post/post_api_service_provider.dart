import 'package:ism_video_reel_player/export.dart';

class PostApiServiceProvider extends PostApiService {
  PostApiServiceProvider({
    required this.apiWrapper,
  });

  final NetworkClient apiWrapper;

  @override
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  }) async =>
      await apiWrapper.makeRequest(
        PostApiEndPoints.postCreatePost,
        NetworkRequestType.post,
        createPostRequest?.removeEmptyValues(),
        {},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization':
              'Bearer eyJhbGciOiJSU0EtT0FFUCIsImN0eSI6IkpXVCIsImVuYyI6IkExMjhHQ00iLCJ0eXAiOiJKV1QifQ.BW36mQr2fLpTs53HHCXi6ATNQAQP_2ckRLA7Kf5ywg2DXWGkSnkvOqhTzA8xq4YhfhYNsyXjR1vTwwcE9JIjUU9aLZUyNWLh2AWx3wyEhnmEbgNqaKCqHEzEGOdiYJnwV8ajy9gUsrP3RVS2rjrKTSIi_ngWuamCWJeTo9EyLOg.McYaG_rZFLsKQwEY._iqJClO-I7H3B-htJIaKKfNG2hdc7aqHA4zqIT4uVdCsgzXoW75pPD60rxLz4syUzkmz9KPLRn2T6BEJmm669GwKLiBFaFLLulkWiWEE9XfZLoZwoTSo1pErkCV-nuQ8HrkqDyPlYgn3fgcK4zwswziwe5KEqCdzLIYZvcZUARzhqMQ8eBWhtYx0G0Ur1LOEIY-SHjCO-FDOaSjFSncA9wf0ctOArhCaXLrl0hQsbLrrxtBCZY-G8s0mWiF8K49HQm40WICzH4F2i6jJ-pB1wTM2yNAYP5l4WGJPk8S9zCvsD1mUbTLgvVfxTrT6i88br14hxMN9HXxBFsxdFHPy4HJ_wpIEaGoqKzkab--EsO_ArZlJg6LzPXhIefMI-qRK-skk7EP2T1cWTmqXZKZZ8Ck0rkcFwDzz5D-39hlTu_flf023YHO1xcorwMKAjx1jRWLEPWuQ4TL8fOYIYCLTiaQYmgEzpGtg1DHwSh6JTXqAHlHsf5mwF6O4bHs4-Y9NWOp0GvD9j_XpshOl_nX-W6_fMjCDzfnaqmMzKbG6bmCcPu_OaFzBA5WNVEU5HLgJJrJe2nUjlWOh8mNP02aYEZDiY8kAhECUnZglgEuIeJV8jSsAZigqWG2Mlzwdliw_PCo1agHPl8Sd3e98jopG8ayfJBDHJnLvpXBxwNMULqqwJqRyleTkI58UIrPgr6fb2gQGjeehRi6HzV3DTlWMuKkkiv83z0J4ddozwlodasxciSdmeSnO6QkeANG7DaYsXRyf0bS0eQp4hqj1QdgbH2dsCu9L2CvjhyPhC1l_QXLXmkfaX9DHPXLGWj8BB5a00k5-nV2swg7x8TMllcTZ31ZNEo9bjWpzYKKKLVPN8sPWxnJaIj2uhNwo3nFHK6BzaLvxZhQjnvLeCjZKGTD0HPnYMQhOU2usj2-BkPTHP7lehYlVI8l5oYTweEFb-JtsaUDKlVQko_2wS16XVArYH1o7BeGhkd8M_Q2YPEqyMMzah8lGTCoyDVzNr6WwDBI4sV_49oGVOmxq_Tr2SRwvyLwbRxc2J9l6Itz8uUYdytGSeI51iEu3Nw-O8zHc7lQPKX8Q1Ape5Dh3J4tG_Ks6GUCPaM2FuC5rytBibjZEVQffW1UAqdVh58UHhuvdMSql7dMsiVy0puKn5KddePC2kNWmbp7KZISTbHCugEVA_bjrSzQu99sV4NcFtN7BAk077phwLHk7HY6c5KCDJb0cxdkVpXlkQNM-32Ss4oCMjosk37eQHPyAJfohtfjuqfpT8H1Fem038YvAusk7o91CFzqcri43yP2PT4DK7RSSj0mQpMX8hHdxi2iZUTkgRRjtHh9ijxioCUyRb2oQ8ZEgSFo9MQ64x1uLakMahLFNTZYLWJ1lU7PpQ88MIs9YNCgViIvhwkyAMFMmPWZIGiTVz8eBAbwTXlpK4pqHL-zcInXZm_VTDAkHL92FF5A5KYQilp7Wpln1XAsvz6JY5mwJXBewGPQouiZ3nKJsq-JNzeZiCspzQBgDxl03yNLqXrFEEMsjXm3uotTYv_jBvWhRZ-QTYQvLXGbEQtWPDWmzrq1SCAdGtcL114IMpCpREBerKsNtlljn5UeF9YQuQ8NJPZ1XZJwRHBiHHBRS4n5PMdPmcWqvRmePCSvxjgiB2mHH56Z15E6VoRDO7rWR8vs1uMTaDkKZLNpd4lAeOd3pbLkdWr2p6O4yKew03SqzhCDnbMFVONdqgmGpOQf-yepBmYbLEp-gLO_cMnwGbxutXLiXvqdK9k_Xm5NlnWjlCkvsQubeWyj4yGnigtgI09n9zKFUvlKosZC2zhXTABsFdcFYShKJ6yxCkiNYrv97VVpQZEhnjkqrmYlH4-_g_S1vxnajBKonmwOSRaRoKLec2orw3BnHsf7orjO4j17BE4F2R4CAaQ.Sa8GeZ6MEDhh7GQJ3ftzzw',
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );
}
