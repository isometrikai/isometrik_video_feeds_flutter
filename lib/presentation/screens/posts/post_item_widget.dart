import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:preload_page_view/preload_page_view.dart';

// -----------------------------------------------------------------------------
// DEBUG: Hardcoded media URLs inside the existing reels implementation
//
// Enable with:
//   flutter run --dart-define=USE_HARDCODED_MEDIA_URLS=true
//
// NOTE: URLs containing "…" are truncated and will NOT play. Paste full URLs.
// -----------------------------------------------------------------------------
const bool kUseHardcodedMediaUrls =
    bool.fromEnvironment('USE_HARDCODED_MEDIA_URLS', defaultValue: true);

/// Debug pagination size for `kHardcodedMediaUrls`.
/// Example:
/// `flutter run --dart-define=USE_HARDCODED_MEDIA_URLS=true --dart-define=HARDCODED_MEDIA_PAGE_SIZE=6`
const int kHardcodedPageSize = int.fromEnvironment('HARDCODED_MEDIA_PAGE_SIZE', defaultValue: 6);

const List<String> kHardcodedMediaUrls = <String>[
  // Paste FULL URLs here (no "…").
  // Cloudinary examples (your chat list is truncated with "…"):
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479513/WhatsApp_Video_2025-09-19_at_18.25.47_ssl9mu.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479510/WhatsApp_Video_2025-09-19_at_18.27.36_gzuwnx.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479505/WhatsApp_Video_2025-09-19_at_18.20.57_sb0ftf.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479509/WhatsApp_Video_2025-09-19_at_18.27.20_ww0hwm.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479508/WhatsApp_Video_2025-09-19_at_18.26.49_ce3pcc.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479507/WhatsApp_Video_2025-09-19_at_18.26.21_uchywh.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479505/WhatsApp_Video_2025-09-19_at_18.21.28_vqcrq7.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479504/WhatsApp_Video_2025-09-19_at_18.25.05_tq9csi.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479504/WhatsApp_Video_2025-09-19_at_18.24.35_dnmrjk.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479501/WhatsApp_Video_2025-09-19_at_18.24.04_z1bblu.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479500/WhatsApp_Video_2025-09-19_at_18.22.01_lnk9ib.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479499/WhatsApp_Video_2025-09-19_at_18.22.47_bamouf.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479499/WhatsApp_Video_2025-09-19_at_18.23.44_uo6erx.mp4',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/v1768479499/WhatsApp_Video_2025-09-19_at_18.23.27_bptd6u.mp4',

  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.25.47_ssl9mu.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.27.36_gzuwnx.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.20.57_sb0ftf.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.27.20_ww0hwm.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.26.49_ce3pcc.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.26.21_uchywh.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.21.28_vqcrq7.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.25.05_tq9csi.m3u8',
  // 'https://res.cloudinary.com/dcsujd521/video/upload/sp_hd/WhatsApp_Video_2025-09-19_at_18.24.35_dnmrjk.m3u8',

  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/69146193c9c41aedf3070fb3/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691468db9152d1a63ff08caf/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/690da5929fe0c40fc853f03e/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6932ca4f7d19d070280f1ca5/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6932ca4f7d19d070280f1cbb/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691463ff7955651226281cd8/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/693668d403bcee22ddf30523/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691313bcf1eaa49a649b692b/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6933235a7d19d0702817031a/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6913332ec9c41aedf3f6a6d9/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691336859152d1a63fdfdd60/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/69145dc3c9c41aedf306d058/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6914683dc9c41aedf3077ec1/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/69146133795565122627f0ae/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691427099152d1a63fec4403/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/68cd5da02b33c1c85758dbd7/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6948d7b579e0b4a2d62b9c97/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691467319152d1a63ff06fb5/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/690da22d22dd679fa2fe1365/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691439af9152d1a63fed697a/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/68d2c84204980dd753f6d1ce/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/68ef3fdd85d14eb3e3310773/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6914693cc9c41aedf307906f/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/69142b1b79556512262462ae/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/691465fa7955651226283f90/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6914322e9152d1a63fecef5e/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/68d6743a29d13fb683d1d4ed/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/68d6734f028ee75622046b5a/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/6914c8b2c9c41aedf30e792e/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/69409884616d7c8c6a5fac0c/main.m3u8',
  'https://video.gumlet.io/6890598d69cc5f5f003fdf04/694257bc616d7c8c6a8a5d0b/main.m3u8',

  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a816634a-ae8b-45fe-83e4-472b717e1252/FileGroup1/663ebd51fa971f80e6f29e6d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b3bf0ee3-d11d-4f5b-9739-ed3d658918f5/FileGroup1/664e1633137e15cf3389f7c1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/69b2e5e3-9f12-458a-896d-c10783f74664/FileGroup1/65935ade534ae706ffe0dc6f_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/be2a4fba-0fcf-4293-a6eb-c14b3957a025/FileGroup1/681cb143b419e6ac87786290_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ff0d281c-76dd-4462-a6a5-038a79220079/FileGroup1/68157f6f05cc8065415fa475_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/be1ffd48-8389-41b3-b83a-d7f8df15ba6c/FileGroup1/672e1c8e411d510ae1d14a0d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/4548788b-f69f-490f-94a4-e3b92263c1ec/FileGroup1/69680d846c08c344dc78149d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/78620206-f666-4a03-9e84-7d69865c5ab1/FileGroup1/67b4ae8ad3edf785a34bbed1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/79cc88fc-67c7-45a9-b019-ac687913bcd3/FileGroup1/66f20090e8afebe4d0de218c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/0d11fcdc-4de5-46cb-b5b9-e59410ffa6b3/FileGroup1/68afe3b3276b1c735682b0aa_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/6aaf621f-4242-4816-8b55-75ce43e8d463/FileGroup1/65509b3d5e5be71d7ed8b29e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d11ebcad-7fea-4303-b1cf-a7d2a6acbbb9/FileGroup1/69527a090b017a16d621018c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/f1ac06ef-951c-484b-b35e-11b1472b91ff/FileGroup1/6966bb156c08c3d504780d66_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5ebeeea3-651a-4889-9f90-bf7c4fbe2936/FileGroup1/6966a01a6c08c30082780cd8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3d4fc0cf-cf65-45bd-8e38-ad2f3850e418/FileGroup1/683d0e82abd572c5921f7d0e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ecc20219-1576-4ba3-a906-3f687336fb60/FileGroup1/6790db0a4694bd30098492a5_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3a8f45c3-a5b7-4086-97c6-b39f364fb008/FileGroup1/6825a73712a11409ae675da7_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/29577ba4-68a9-451e-ae3b-e2e05777152f/FileGroup1/68d71025c96e0f6fbd150076_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/48269fd3-4cba-4249-88b8-c599bb1e3ead/FileGroup1/696597246c08c30ce5780887_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5edba17d-18d7-454c-944c-cd63e9b272ed/FileGroup1/66ebbb7e2143aea01d9e8b19_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a60492b2-e5d8-4977-b7ef-290b1d3cd0ab/FileGroup1/6611e99d620ba21d35b7d968_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/f8bfe504-8f67-4492-8150-0fe6753a3cad/FileGroup1/66ed2d7f67a8988f183bd799_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/37c6eb2b-b0d9-45bd-8e87-2d2a89f32dce/FileGroup1/67edc2be4f2cfd067470f41c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/06cb5878-83c2-4c17-82cf-fce5325b96ff/FileGroup1/69020404722244b606250e6c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d0e85cd3-3356-4d0c-9ed2-60b5114bf3ca/FileGroup1/67d32950c27f63a64e7f1548_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/04bc9f69-aaf9-44f3-b58c-94cc529a6a10/FileGroup1/66c5cd5df4f64888c411ef7d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/16edcd6d-487c-413a-86ef-5a8918d13ecc/FileGroup1/693e6c8b49c77717fb3282c1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/4548788b-f69f-490f-94a4-e3b92263c1ec/FileGroup1/69680d846c08c344dc78149d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d8f27cad-c12c-40e0-9cde-e13f95bb2f6f/FileGroup1/68663f57413dd5ad742daf11_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/29fdc7e7-28cd-482a-82da-96774e14634e/FileGroup1/68809ebd49e1a7500082108d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/6848e25f-1b83-4fde-bbb1-cc0b5efd78ac/FileGroup1/660c019802c936aaf8301d4a_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/024a141a-152d-49ed-901e-72c349733030/FileGroup1/66c2e5bd18c4f1f5d62ce24e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/f1ac06ef-951c-484b-b35e-11b1472b91ff/FileGroup1/6966bb156c08c3d504780d66_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5ebeeea3-651a-4889-9f90-bf7c4fbe2936/FileGroup1/6966a01a6c08c30082780cd8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/2ff5543c-1b09-4e96-8d3a-b7088dd1d1b9/FileGroup1/665ba10260dd7567aacc0579_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b3656ec1-3f9e-4595-aa46-74ce9d602d54/FileGroup1/685b44570ba248783c8a2311_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e9c9d3c2-86d4-4db5-9918-5f45a1bde373/FileGroup1/672200bed95d0803d9e1a24b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/6a40d8fb-294b-4253-8bbe-f27462905b4d/FileGroup1/67352024ff358b78666eb4e2_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e0b0c019-6657-4298-820d-5095b4d3165d/FileGroup1/66115c6a620ba2ed07b7d67f_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/48269fd3-4cba-4249-88b8-c599bb1e3ead/FileGroup1/696597246c08c30ce5780887_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/236ab0f3-fcb5-4bc3-88fd-5459943c3ada/FileGroup1/6717b823e44e74ab3816c7a1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/45f75fdf-86da-4380-b12f-b2e83451745a/FileGroup1/67752de1477d836078b2220e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/91a610d0-829c-4e00-bc24-94569b179860/FileGroup1/66e965f42143ae6b629e6df6_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b1d9f2d5-ce36-411f-9d2c-ffae4f772a45/FileGroup1/66fd1876ef0701599a8325ef_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3a366562-e6fa-4ad4-86a9-9db04da4cb13/FileGroup1/6964978f6c08c3a137780324_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/83b464bd-bbf8-4da8-b350-10bc4d477216/FileGroup1/66c4ab6518c4f1f4ab2cf4d0_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/67434e38-f4dd-47a0-9cfc-a59a9f6303f0/FileGroup1/6826959212a11492f76767dc_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d6f3b004-2ea1-48dd-a1eb-4efc26074638/FileGroup1/664bf16e0f5fcb865cb59951_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/75618770-06c7-4e5b-a542-6f1c796d59d0/FileGroup1/65e294ef4b0c4a6bcef68ca3_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/9e250bfb-ae88-4fa3-b8b2-db1412a7b21c/FileGroup1/69629dee6c08c3131d77fa26_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3e8f8e60-9b51-4a0d-bf60-a689d545c633/FileGroup1/66d06254506d836f6dee8684_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/beb9cc6f-ebc9-4d38-9878-ba0c6fac16ee/FileGroup1/65e4cf724b0c4a26c7f6946c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/32139ee4-83c0-4d12-afb5-4487906ab9a1/FileGroup1/68420ac2632a77c569be706c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b362bebc-27ff-46fc-9176-95f0278c8b63/FileGroup1/679c28bca980944a0e8aa9aa_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/53e51fe9-9ab5-4cd0-a6bb-bd70f4b72fc4/FileGroup1/68123ad679ee767187b0b833_post_1.mp4',
  //
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5df9133a-e74e-49b5-8733-df2ae4dfe0d5/FileGroup1/6823271f70e6270e5faeb3c9_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a6430dab-7a24-45d0-a79d-80f44c4a04bd/FileGroup1/6462ae9792123117005bcd25_post_1output1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b362bebc-27ff-46fc-9176-95f0278c8b63/FileGroup1/679c28bca980944a0e8aa9aa_post_1',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/53e51fe9-9ab5-4cd0-a6bb-bd70f4b72fc4/FileGroup1/68123ad679ee767187b0b833_post_1',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3fafe86a-d932-497c-b9df-b7c3dfbd6006/FileGroup1/67cc7ae75ee146cf3c91582e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/2eb5af04-e177-4811-a0ad-6d0e4a9a3120/FileGroup1/66f1db33e8afeb047cde1fcf_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/15520680-2fec-4906-86c1-501fbe830d3c/FileGroup1/649af24a9dd781039d068ec9_post_1output2.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/71c8e1b2-26fe-4687-8cb0-a7ba85a77443/FileGroup1/696970176c08c31c01781cca_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b73cec55-fdbc-4429-9cba-47a8dd71d740/FileGroup1/68ab61856c65d257e36e52d8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d65d5890-8172-4d22-96dd-44cf03cfabcc/FileGroup1/67f9ae3f4d11ae2433973724_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/49a8ddaf-4276-438b-9c21-7d2082f04091/FileGroup1/696919c26c08c37b1e781a44_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/f3a8e649-05c6-4c01-a1d9-45963b8140f8/FileGroup1/675bd1bc03dae541316778d5_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/4548788b-f69f-490f-94a4-e3b92263c1ec/FileGroup1/69680d846c08c344dc78149d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/37ca4215-0129-4b58-8808-7ea1198bce9e/FileGroup1/68399a2f758067602f98541a_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ecea6b63-dd97-4b54-b799-4d2b9220059e/FileGroup1/66b58d71c4703438ae4e30fc_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3cf867c8-e0c2-45b1-9d03-9dacaa74ba17/FileGroup1/69680a096c08c38107781489_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/842a547a-f9a3-4e1a-8860-06e86d8e1a3f/FileGroup1/687955684a9dfe4a29ba3cc1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d0cb6e97-0e0d-4593-858f-aa80d1622f03/FileGroup1/6872f60b2223ee91e37308f0_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d71894b7-9033-4ad5-b06a-d7c7891e16bf/FileGroup1/686bc1eda0e4239e12f5b549_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/dc1b0230-6ae5-483a-b53e-b39eb4da7c29/FileGroup1/67d07f1d60865432049bfca8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5ebeeea3-651a-4889-9f90-bf7c4fbe2936/FileGroup1/6966a01a6c08c30082780cd8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/30948241-8230-48c6-8cf3-093084a10de8/FileGroup1/6789ded14694bd77be842eaa_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/342e6d20-6c1f-4fd9-8bd8-9a12f576af99/FileGroup1/696687056c08c39ae8780c3e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/914c6e36-d1f2-41c7-b2d0-1fbf970ebee3/FileGroup1/696678b46c08c378e0780c09_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/0f253adf-af66-4bb5-9602-fb60d215865c/FileGroup1/67250192d95d08a5dce1c1f1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/0fd7d0be-ce3e-4cdf-b227-c813e2d2d233/FileGroup1/68107ab6ea0257425ec8a0ee_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b8c89f90-6e86-4b8c-a177-5acb8ffb94af/FileGroup1/68798a8db6bc7a995553783a_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/c1d8137c-b949-473a-8899-639aa290d180/FileGroup1/669acd750ca585199c08f225_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/54e83dbf-4c13-4130-a1fb-841afbfdb211/FileGroup1/67be47ad829c396ace964723_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/68210d76-3c74-4d43-b5c1-0e8d1f540b19/FileGroup1/696500ae6c08c306f87804f0_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/c03af178-834d-4fe8-b08d-e708f925ab2f/FileGroup1/685f00b07f5b03fd9493e798_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/6b251639-e180-49be-83d7-1164619f5a7f/FileGroup1/6816911705cc8056ed5fb040_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a19b4e94-a62b-4d3d-8197-52f8c4e86c1f/FileGroup1/66ad5f9ec02d867e9b08bd80_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/47da5187-790a-48cf-b679-43e58914f168/FileGroup1/6963bec96c08c3911077ff13_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/9583c28b-1eed-46db-8483-d14b8b529c85/FileGroup1/6963be4b6c08c3043877ff0d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/74d95717-ec2e-451f-abc6-c5531c8e1f27/FileGroup1/66a6851b65e98e3b69c9b625_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a01542f8-ee13-4bdb-95c1-9221cb210519/FileGroup1/67ed9e204f2cfdbf4270f241_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/34dab589-4df1-41c0-9125-3e0896aaf3c1/FileGroup1/67bd18210197587d5b123394_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/30ed00a5-cc06-4a46-ab0d-26a49ce0b1e9/FileGroup1/685622d02090065aa470efb9_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/651329bd-9cd2-45f9-b96f-1100e547daca/FileGroup1/65ad35f7c68975b7a8bdddd7_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/00b733e8-0de0-4ae9-b2fb-9789cee9e3f8/FileGroup1/69629c9f6c08c32e0077fa10_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ab84c314-4ac4-46d2-a6f1-211454488e24/FileGroup1/689201c6fdca06594b7d6bc9_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e68f3000-3cd8-47f4-825a-b985e5c9d45f/FileGroup1/696177256c08c362de77f43a_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/4ba6a4ab-d236-4262-b7ee-6998074c8ce0/FileGroup1/696040c86c08c3659e77ec9b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/288fe9a8-dba2-4b8e-991b-bacbc7560f7b/FileGroup1/6827e0e612a114dbab67750d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/7f7b3e58-7e38-4689-88ea-37af00a8ee6e/FileGroup1/69610c066c08c34d1d77f187_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/1225b80f-a239-4b5d-92ae-65d25a3a7d2c/FileGroup1/676728af185e78904a957863_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e71e8e53-ea98-4c97-b118-ff84691efaca/FileGroup1/6961088f6c08c35bb477f165_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e947baf1-3f24-4d6a-ace8-9b0e74a635a4/FileGroup1/696108206c08c3696e77f15e_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/84a19c1b-38f1-421b-82b3-351fb1973c47/FileGroup1/68f32c01a0b4a6d523100f7b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d7e9b9dc-3747-4830-98de-60fcc54a76e6/FileGroup1/656f273ef14945eacad4ad44_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5691d83f-7113-4541-8413-f836c5c80fdc/FileGroup1/696041076c08c306c077eca5_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/cc677159-69c8-4102-9bd4-c044e8416a49/FileGroup1/67514621f18e6d06a31776d8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/9441ba9b-789b-417d-95f5-24657a522191/FileGroup1/67211b14d95d0841f7e196c3_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b5515f5f-5bc3-4949-b468-0d0a451e42ae/FileGroup1/65d0bf8f2cd06c3e1d967e98_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/367825c0-7686-4ef6-a8a3-9f91faf32a25/FileGroup1/658a2117187210a0b5febc8b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5b4e9a55-6832-47c8-a128-8304bf54d846/FileGroup1/695f748a7ed2cba2086cfb05_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/8dd4d97c-b263-43ec-9f05-560bbf955489/FileGroup1/665a4d5fed47a44c7918099b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/bfb1a47b-ed22-45cb-9dd7-f3654dd355fb/FileGroup1/67c35b9fef62c9696d4d9268_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/0c9867aa-88cf-41a4-aa1f-9623c2c3bcc2/FileGroup1/695f72127ed2cbad1a6cfaf2_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/6cdd46bf-c737-4bea-933a-bca398541811/FileGroup1/67d71d8dcd660e0b26eef882_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/6b2dba72-ded5-4b48-a484-7db78e0e5c2b/FileGroup1/68e8364aa5cb3b23061aab3f_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/21036f9f-bcdc-4fb9-a1ce-d4c1088e8081/FileGroup1/674b9f4bf18e6d2c0d1737a8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e40b5528-4cdc-40c8-aa40-28e0c4701606/FileGroup1/66e73b5c03a91f4941d8c913_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/eb1a364e-dfd2-4fca-a820-13673686f062/FileGroup1/679237822407b44bcb0e8fce_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/090990c0-ce26-455c-b4e1-614db3c3855b/FileGroup1/684341ac707a6bff1f51058b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/10f9695b-7d27-436e-9e27-f9badb3e1e4b/FileGroup1/6906c3db5228cb7bc7213522_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/0c918e9c-d517-4df1-95a9-144c65823778/FileGroup1/6770e280185e78642195e537_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/7e4c908d-6e1f-48d6-8aee-e5dc38d0cefa/FileGroup1/695adeb5115f3592a4f6383d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/2a76774b-7ccb-483c-b5ef-d45e77872d10/FileGroup1/6770290e185e78ee6295dbb1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/f417f589-1755-4485-8ca9-12f42b064618/FileGroup1/67bfa954ccbd9887bc69336b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/afc41a62-1fac-4bf8-9fa3-56719bfdca41/FileGroup1/6959deda115f3596d2f63244_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ba344621-9cf8-4c15-9a49-3804312aaba4/FileGroup1/671575e0e44e74130516abb0_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/01b8f1af-63e0-4e76-bf1a-d4f9d6022265/FileGroup1/6959c041115f355abcf631a2_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a829d409-72ef-451d-95c6-344017729070/FileGroup1/68127b3679ee76314fb0bafa_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5db9ff4e-5f86-404d-a096-645348ad2256/FileGroup1/695990e8115f35e76ef63081_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d2690d90-2bb0-4d72-a736-64de1be63b01/FileGroup1/69598c5e115f35c0fef63052_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/0bcb3bdf-77ce-47ce-b04c-beffe5819bf1/FileGroup1/68dbc195c96e0f49f115279c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/56f9fb6b-6262-4166-881b-7ad8cf6d66d7/FileGroup1/68eb5196a5cb3befb51ac1ee_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a74a5771-2d5a-420d-98cb-580d0757d4e1/FileGroup1/66df111803a91f3654d868a5_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ac1b7930-0330-4627-8e90-f4189e2d1352/FileGroup1/685efd017f5b03525a93e73d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/92121fc3-5b7a-404f-857d-19117a7aeb65/FileGroup1/6958d2d6115f3595b1f62bb5_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a2548384-9fa7-4703-aba3-802410d7eb83/FileGroup1/6766c318185e7885c3957460_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/105e6b8a-66eb-489e-8937-834008bb67c0/FileGroup1/65c788f92cd06c9910965fe4_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/11ae1233-bc35-4acc-89cb-0396f4824fef/FileGroup1/695751da0b017ac35121173b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/ddb4116d-4612-4277-ad49-44def95645f4/FileGroup1/6841940c632a776efabe6ab8_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/a83cc6b3-85ef-489b-b5fa-8ad22613072a/FileGroup1/695678b70b017a47b5211385_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/cfaed766-666f-45c6-adcb-f831f879c6b3/FileGroup1/683bb4117580679705986bc6_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/103c96d0-286c-4eba-9e55-d456b0230422/FileGroup1/687402f5fcf34bc5802c5536_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/e39b30b0-d5c8-4a0f-b71e-d314a0afd764/FileGroup1/68bcb019e159175e8dd7652b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b46e7839-3330-4294-9de4-596e1a729c68/FileGroup1/664db8c74d117de6261d5c0d_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/de11488e-748a-4f39-a835-9f8a282f32a7/FileGroup1/6953e35b0b017a37f02108f7_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5fafb63e-6043-4fb4-a974-3aa6af38c65a/FileGroup1/688171e3354d740978391c4a_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/57584866-0cd6-43f0-9044-9b0d3fc0fd6c/FileGroup1/6788e6e14694bd7508842137_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/5e1bf3e0-e1bf-4871-9e78-8bbff38163bb/FileGroup1/6953d6720b017a5e752108d7_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/339f5687-602e-415c-a586-e541af4deb32/FileGroup1/67598ee803dae511c6675ee1_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/3c5df374-e88b-4bac-a3a2-0c64dc116ad2/FileGroup1/695390e20b017a51d0210736_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/141a7158-a028-4630-bb06-fd06399d18d6/FileGroup1/67514554f18e6dbb681776cf_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b6b23b73-de59-4ea6-8481-a8dd80824c73/FileGroup1/66225ede91a2b269fe80b900_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/47e6c32c-5bf6-4744-9784-040c18a60c45/FileGroup1/6952b7290b017a77d721035b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/d11ebcad-7fea-4303-b1cf-a7d2a6acbbb9/FileGroup1/69527a090b017a16d621018c_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/978c1d7e-4e6b-4f45-bf6d-748d71fd2659/FileGroup1/69527d1e0b017aa57b21019b_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/550275aa-53fc-4016-ba6f-b3bcc779ce6b/FileGroup1/686a653f06da5e8c83a12cd6_post_1.mp4',
  // 'https://d1ctg5xxk9dxwo.cloudfront.net/b4ceb399-f7ed-4b36-aefa-ed51889adff7/FileGroup1/65ca2a7c2cd06cc6b99668c1_post_1.mp4',
];

String _sanitizeUrl(String url) => url.trim().replaceAll('\u2026', '');

String _cloudinaryThumbUrl(String videoUrl) {
  final url = _sanitizeUrl(videoUrl);
  if (!url.contains('res.cloudinary.com')) return '';
  // Cloudinary: generate a thumbnail from the video.
  // so_0 = grab first frame, f_jpg = return jpg.
  return url.replaceFirst('/video/upload/', '/video/upload/so_0,f_jpg/');
}

List<ReelsData> _buildHardcodedReels(List<String> urls) {
  final sanitized = urls.map(_sanitizeUrl).where((u) => u.startsWith('http'));
  var i = 0;
  return sanitized.map((url) {
    final idx = i++;
    return ReelsData(
      postId: 'debug_$idx',
      userId: 'debug_user',
      userName: 'Debug',
      firstName: 'Debug',
      lastName: 'User',
      description: url,
      createOn: DateTime.now().toUtc().toIso8601String(),
      mediaMetaDataList: [
        MediaMetaData(
          mediaUrl: url,
          thumbnailUrl: _cloudinaryThumbUrl(url),
          mediaType: MediaType.video.value, // int = 1 via extensions
        ),
      ],
    );
  }).toList(growable: false);
}

class PostItemWidget extends StatefulWidget {
  const PostItemWidget({
    super.key,
    this.onLoadMore,
    this.onRefresh,
    this.placeHolderWidget,
    this.postSectionType,
    this.onTapPlaceHolder,
    this.startingPostIndex = 0,
    this.loggedInUserId,
    this.allowImplicitScrolling = true,
    required this.reelsDataList,
    this.videoCacheManager,
    required this.reelsConfig,
    required this.tabConfig,
  });

  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;
  final List<ReelsData> reelsDataList;
  final VideoCacheManager? videoCacheManager;
  final ReelsConfig reelsConfig;
  final TabConfig tabConfig;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> with AutomaticKeepAliveClientMixin {
  late PreloadPageController _pageController;
  final Set<String> _cachedImages = {};
  late final VideoCacheManager _videoCacheManager;
  List<ReelsData> _reelsDataList = [];
  late final IsmSocialActionCubit _ismSocialActionCubit;
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  bool _isInitialized = false;

  bool get _isVideoCachingEnabled => VideoCacheManager.isCachingEnabled;

  // Track refresh count for each index to force rebuild
  final Map<int, int> _refreshCounts = {};

  // Debug-only hardcoded pagination cursor.
  int _hardcodedNextIndex = 0;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  /// Initialize the widget
  void _onStartInit() {
    _ismSocialActionCubit = context.getOrCreateBloc();
    _videoCacheManager = widget.videoCacheManager ?? VideoCacheManager();
    if (kUseHardcodedMediaUrls && kHardcodedMediaUrls.isNotEmpty) {
      final pageSize = kHardcodedPageSize.clamp(1, 50);
      _hardcodedNextIndex = pageSize;
      _reelsDataList = _buildHardcodedReels(
        kHardcodedMediaUrls.take(pageSize).toList(growable: false),
      );
    } else {
      _reelsDataList = widget.reelsDataList;
    }
    _pageController = PreloadPageController(initialPage: widget.startingPostIndex ?? 0);
    _initializeContent();
  }

  void _maybeLoadMoreHardcoded(int currentIndex) {
    if (!kUseHardcodedMediaUrls) return;
    if (kHardcodedMediaUrls.isEmpty) return;
    if (_hardcodedNextIndex >= kHardcodedMediaUrls.length) return;
    if (_reelsDataList.isEmpty) return;

    // Load more when user is within last 2 items.
    final remaining = _reelsDataList.length - 1 - currentIndex;
    if (remaining > 2) return;

    final pageSize = kHardcodedPageSize.clamp(1, 50);
    final endExclusive = (_hardcodedNextIndex + pageSize).clamp(0, kHardcodedMediaUrls.length);
    final nextBatch = kHardcodedMediaUrls
        .sublist(_hardcodedNextIndex, endExclusive)
        .map(_sanitizeUrl)
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    if (nextBatch.isEmpty) {
      _hardcodedNextIndex = endExclusive;
      return;
    }

    debugPrint('_maybeLoadMoreHardcoded page size $pageSize');

    // Append as additional posts.
    final startIdx = _reelsDataList.length;
    final appended = nextBatch.asMap().entries.map((e) {
      final idx = startIdx + e.key;
      final url = e.value;
      return ReelsData(
        postId: 'debug_$idx',
        userId: 'debug_user',
        userName: 'Debug',
        firstName: 'Debug',
        lastName: 'User',
        description: url,
        createOn: DateTime.now().toUtc().toIso8601String(),
        mediaMetaDataList: [
          MediaMetaData(
            mediaUrl: url,
            thumbnailUrl: _cloudinaryThumbUrl(url),
            mediaType: MediaType.video.value,
          ),
        ],
      );
    }).toList(growable: false);

    _hardcodedNextIndex = endExclusive;
    setState(() {
      _reelsDataList = [..._reelsDataList, ...appended];
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  void _initializeContent() async {
    if (_reelsDataList.isListEmptyOrNull == false) {
      // OPTIMIZATION: Separate critical (thumbnails) from non-critical (videos) loading
      final firstPost = _reelsDataList[0];
      final criticalUrls = <String>[]; // Thumbnails and images - must load first
      final nonCriticalUrls = <String>[]; // Videos - can load in background

      // Process ALL media items in the first post
      for (var mediaItem in firstPost.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          // Video - load thumbnail first (critical), video later (non-critical)
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            criticalUrls.add(mediaItem.thumbnailUrl);
            debugPrint('🚀 MainWidget: Prioritizing thumbnail: ${mediaItem.thumbnailUrl}');
          }
          if (_isVideoCachingEnabled) {
            nonCriticalUrls.add(mediaItem.mediaUrl);
          }
        } else {
          // Image - critical to show immediately
          criticalUrls.add(mediaItem.mediaUrl);
          debugPrint('🚀 MainWidget: Prioritizing image: ${mediaItem.mediaUrl}');
        }
      }

      // OPTIMIZATION: Only wait for critical thumbnails/images, not full videos
      if (criticalUrls.isNotEmpty) {
        // Load thumbnails and images first with high priority
        unawaited(MediaCacheFactory.precacheMedia(criticalUrls, highPriority: true).then((_) {
          debugPrint('✅ MainWidget: Critical media loaded (${criticalUrls.length} items)');

          // Preload profile images and other critical images in background
          unawaited(_preloadCriticalImages(firstPost));
        }));
      }

      // OPTIMIZATION: Start video loading immediately but don't wait for it
      if (_isVideoCachingEnabled && nonCriticalUrls.isNotEmpty) {
        unawaited(MediaCacheFactory.precacheMedia(nonCriticalUrls, highPriority: true).then((_) {
          debugPrint('✅ MainWidget: Videos loaded (${nonCriticalUrls.length} items)');
        }));
      }

      // Start caching other media in parallel (non-blocking)
      unawaited(_doMediaCaching(0));

      // Start background preloading of remaining posts (low priority)
      unawaited(_backgroundPreloadPosts());
    }

    if (!mounted) return;

    // OPTIMIZATION: Animate to target page after PageView is built
    // Must use post-frame callback because PageController is not attached yet in initState
    final targetPage = _pageController.initialPage >= _reelsDataList.length
        ? _reelsDataList.length - 1
        : _pageController.initialPage;
    if (targetPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(targetPage);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    // Don't clear all cache on dispose, only clear controllers
    // _videoCacheManager.clearControllers();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return context.attachBlocIfNeeded<IsmSocialActionCubit>(
      bloc: _ismSocialActionCubit,
      child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
        listenWhen: (previous, current) =>
            (current is IsmFollowActionListenerState &&
                widget.postSectionType == PostSectionType.following) ||
            (current is IsmSaveActionListenerState &&
                widget.postSectionType == PostSectionType.savedPost) ||
            (current is IsmDeletedPostActionListenerState) ||
            (current is IsmEditPostActionListenerState),
        listener: (context, state) {
          if (state is IsmFollowActionListenerState &&
              widget.postSectionType == PostSectionType.following) {
            _updateWithFollowAction(state);
          } else if (state is IsmSaveActionListenerState &&
              widget.postSectionType == PostSectionType.savedPost) {
            _updateWithSaveAction(state);
          } else if (state is IsmDeletedPostActionListenerState) {
            _updateWithDeleteAction(state);
          } else if (state is IsmEditPostActionListenerState) {
            _updateWithEditAction(state);
          }
        },
        child: _reelsDataList.isListEmptyOrNull == true
            ? _buildPlaceHolder(context)
            : _buildContent(context),
      ),
    );
  }

  Future<void> _updateWithEditAction(IsmEditPostActionListenerState state) async {
    debugPrint('IsmEditPostActionListenerState: ${state.postData?.toMap()}');
    if (state.postData != null && _reelsDataList.any((e) => e.postId == state.postId)) {
      final index = _reelsDataList.indexWhere(
        (element) => element.postId == state.postData!.id,
      );

      debugPrint('IsmEditPostActionListenerState: index $index');
      if (index != -1) {
        final postData = getReelData(state.postData!, loggedInUserId: widget.loggedInUserId);
        _reelsDataList[index] = postData; // replace
        await updateStateByKey();
      }
    }
  }

  Future<void> _updateWithDeleteAction(IsmDeletedPostActionListenerState state) async {
    if (_reelsDataList.any((e) => e.postId == state.postId)) {
      final deletedPost = _reelsDataList.firstWhere((e) => e.postId == state.postId);
      await evictDeletedPostMedia(deletedPost);
      _reelsDataList.removeWhere((element) => element.postId == state.postId);
      await updateStateByKey();
    }
  }

  Future<void> _updateWithSaveAction(IsmSaveActionListenerState state) async {
    if (!state.isSaved && widget.postSectionType == PostSectionType.savedPost) {
      _reelsDataList.removeWhere((element) => element.postId == state.postId);
      await updateStateByKey();
    }
  }

  Future<void> updateStateByKey() async {
    // Get current index before refresh
    final currentIndex = _pageController.page?.toInt() ?? 0;
    debugPrint('🔄 MainWidget: Starting update at index $currentIndex');

    // Increment refresh count to force rebuild
    _refreshCounts[currentIndex] = (_refreshCounts[currentIndex] ?? 0) + 1;
    _updateState();
    // Re-initialize caching for current index after successful refresh
    await _doMediaCaching(currentIndex);
  }

  Future<void> _updateWithFollowAction(IsmFollowActionListenerState state) async {
    var updateState = false;
    if (state.isFollowing && !_reelsDataList.any((element) => element.userId == state.userId)) {
      final followedUserReels = await _ismSocialActionCubit.getUserPostList(state.userId,
          forceMap: (post) => post.also((p) => p.isFollowing = true));
      if (followedUserReels.isEmpty) {
        followedUserReels.addAll(
            _ismSocialActionCubit.getPostList(filter: (post) => post.userId == state.userId));
      }
      if (followedUserReels.isNotEmpty) {
        _reelsDataList.addAll(
            followedUserReels.map((e) => getReelData(e, loggedInUserId: widget.loggedInUserId)));
        _reelsDataList.sort((a, b) {
          final dateA = DateTime.tryParse(a.createOn ?? '');
          final dateB = DateTime.tryParse(b.createOn ?? '');

          // Default fallback date when parsing fails
          final safeA = dateA ?? DateTime.fromMillisecondsSinceEpoch(0); // oldest
          final safeB = dateB ?? DateTime.fromMillisecondsSinceEpoch(0);

          return safeB.compareTo(safeA); // latest → oldest
        });

        updateState = true;
      }
    } else if (!state.isFollowing &&
        _reelsDataList.any((element) => element.userId == state.userId)) {
      _reelsDataList.removeWhere((element) => element.userId == state.userId);
      updateState = true;
    }
    if (updateState) {
      await updateStateByKey();
    }
  }

  Widget _buildPlaceHolder(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: widget.placeHolderWidget ??
                        PostPlaceHolderView(
                          postSectionType: widget.postSectionType,
                          onTap: () {
                            if (widget.onTapPlaceHolder != null) {
                              widget.onTapPlaceHolder!();
                            }
                          },
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildContent(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: PreloadPageView.builder(
                preloadPagesCount: 1,
                // key: _pageStorageKey,
                // allowImplicitScrolling: widget.allowImplicitScrolling ?? true,
                controller: _pageController,
                physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                onPageChanged: (index) {
                  debugPrint(
                    '📄 PostItemWidget: onPageChanged -> index=$index, '
                    'total=${_reelsDataList.length}, '
                    'hardcoded=$kUseHardcodedMediaUrls, '
                    'hardcodedNext=$_hardcodedNextIndex',
                  );
                  _currentIndex.value = index;
                  _maybeLoadMoreHardcoded(index);
                  _doMediaCaching(index);
                  final post = _reelsDataList[index];

                  // EventQueueProvider.instance.addEvent({
                  //   'type': EventType.view.value,
                  //   'postId': post.postId,
                  //   'userId': widget.loggedInUserId,
                  //   'timestamp': DateTime.now().toUtc().toIso8601String(),
                  // });
                  // Check if we're at 65% of the list
                  final threshold = (_reelsDataList.length * 0.65).floor();
                  if (index >= threshold || index == _reelsDataList.length - 1) {
                    if (!kUseHardcodedMediaUrls && widget.onLoadMore != null) {
                      widget.onLoadMore!().then(
                        (value) {
                          if (value.isListEmptyOrNull) return;
                          final newReels = value.where((newReel) => !_reelsDataList
                              .any((existingReel) => existingReel.postId == newReel.postId));
                          _reelsDataList.addAll(newReels);
                          if (_reelsDataList.isNotEmpty) {
                            _doMediaCaching(0);
                          }
                          _updateState();
                        },
                      );
                    }
                  }
                  if (widget.reelsConfig.onReelsChange != null) {
                    widget.reelsConfig.onReelsChange?.call(post, index);
                  }
                },
                itemCount: _reelsDataList.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final reelsData = _reelsDataList[index];
                  return RepaintBoundary(
                    child: IsmReelsVideoPlayerView(
                      index: index,
                      currentIndex: _currentIndex,
                      reelsData: reelsData,
                      postSectionType: widget.postSectionType ?? PostSectionType.following,
                      loggedInUserId: widget.loggedInUserId,
                      videoCacheManager: _videoCacheManager,
                      // Add refresh count to force rebuild
                      key: ValueKey('${reelsData.postId}_${_refreshCounts[index] ?? 0}'),
                      onVideoCompleted: (widget.tabConfig.autoMoveToNextPost)
                          ? () => _handleVideoCompletion(index)
                          : null,
                      reelsConfig: widget.reelsConfig,
                      onPressMoreButton: () async {
                        if (widget.reelsConfig.onPressMoreButton == null) {
                          return;
                        }
                        await widget.reelsConfig.onPressMoreButton!.call(reelsData);
                      },
                      onCreatePost: () async {
                        if (widget.reelsConfig.onCreatePost != null) {
                          final result = await widget.reelsConfig.onCreatePost!(reelsData);
                          if (result != null) {
                            _reelsDataList.insert(index, result);
                            _updateState();
                          }
                        }
                      },
                      onPressFollowButton: widget.reelsConfig.onPressFollow,
                      onPressLikeButton: widget.reelsConfig.onPressLike,
                      onPressSaveButton: widget.reelsConfig.onPressSave,
                      onTapMentionTag: (mentionedList) async {
                        if (widget.reelsConfig.onTapMentionTag != null) {
                          final result =
                              await widget.reelsConfig.onTapMentionTag!(reelsData, mentionedList);
                          if (result.isListEmptyOrNull == false) {
                            final index = _reelsDataList
                                .indexWhere((element) => element.postId == reelsData.postId);
                            if (index != -1) {
                              _reelsDataList[index].mentions = result ?? [];
                              _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
                              _updateState();
                            }
                          }
                        }
                      },
                      onTapCartIcon: (productId) {
                        widget.reelsConfig.onTaggedProduct?.call(reelsData);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );

  /// Background preloading of posts that are not immediately visible
  Future<void> _backgroundPreloadPosts() async {
    if (_reelsDataList.length <= 5) return; // Skip if not enough posts

    final backgroundUrls = <String>[];

    // OPTIMIZATION: Platform-specific background preloading
    // Android: Only preload 5-7 positions away (conservative)
    // iOS: Preload 5-10 positions away (more aggressive)
    final startIndex = 5;
    final endIndex = math.min(_reelsDataList.length - 1, Platform.isAndroid ? 7 : 10);

    for (var i = startIndex; i <= endIndex; i++) {
      final post = _reelsDataList[i];
      for (var mediaItem in post.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          if (_isVideoCachingEnabled) {
            backgroundUrls.add(mediaItem.mediaUrl);
          }
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            backgroundUrls.add(mediaItem.thumbnailUrl);
          }
        } else {
          backgroundUrls.add(mediaItem.mediaUrl);
        }
      }
    }

    if (backgroundUrls.isNotEmpty) {
      debugPrint('🔄 Background preloading ${backgroundUrls.length} media items');
      unawaited(MediaCacheFactory.precacheMedia(backgroundUrls, highPriority: false));
    }
  }

  // Handle media caching for both images and videos - OPTIMIZED FOR PERFORMANCE
  Future<void> _doMediaCaching(int index) async {
    if (_reelsDataList.isEmpty || index >= _reelsDataList.length) return;

    final reelsData = _reelsDataList[index];

    // Only log every 5th scroll to reduce performance impact
    if (index % 5 == 0) {
      debugPrint('🎯 MainWidget: Page changed to index $index (@${reelsData.userName})');
    }

    // OPTIMIZATION: Platform-specific preloading for smooth scrolling
    // Android: 2 ahead (balanced for smooth experience with increased cache)
    // iOS: 3 ahead (more aggressive for smoother experience)
    final preloadCount = Platform.isAndroid ? 2 : 3;
    final startIndex = math.max(0, index - 1); // 1 behind
    final endIndex = math.min(_reelsDataList.length - 1, index + preloadCount);

    // Collect media URLs for current post only (high priority)
    final currentPostMedia = <String>[];
    final currentPostThumbnails = <String>[];

    // Process current post with high priority
    for (var mediaItem in reelsData.mediaMetaDataList) {
      if (mediaItem.mediaUrl.isEmpty) continue;

      if (mediaItem.mediaType == MediaType.video.value) {
        // Video - cache thumbnail first (highest priority), then video
        if (mediaItem.thumbnailUrl.isNotEmpty) {
          currentPostThumbnails.add(mediaItem.thumbnailUrl);
        }
        if (_isVideoCachingEnabled) {
          currentPostMedia.add(mediaItem.mediaUrl);
        }
      } else {
        // Image - high priority
        currentPostMedia.add(mediaItem.mediaUrl);
      }
    }

    // OPTIMIZATION: Load thumbnails FIRST (instant display), then videos
    if (currentPostThumbnails.isNotEmpty) {
      unawaited(MediaCacheFactory.precacheMedia(currentPostThumbnails, highPriority: true));
    }

    // Cache current post videos/images with high priority (NON-BLOCKING)
    if (currentPostMedia.isNotEmpty) {
      unawaited(MediaCacheFactory.precacheMedia(currentPostMedia, highPriority: true));
    }

    // Background cache nearby posts (non-blocking) - now includes 3 posts ahead
    unawaited(_cacheNearbyPosts(startIndex, endIndex, index));
  }

  /// Cache nearby posts in background without blocking UI
  Future<void> _cacheNearbyPosts(int startIndex, int endIndex, int currentIndex) async {
    final nearbyMedia = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      if (i == currentIndex) continue; // Skip current post

      final post = _reelsDataList[i];
      for (var mediaItem in post.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          if (_isVideoCachingEnabled) {
            nearbyMedia.add(mediaItem.mediaUrl);
          }
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            nearbyMedia.add(mediaItem.thumbnailUrl);
          }
        } else {
          nearbyMedia.add(mediaItem.mediaUrl);
        }
      }
    }

    if (nearbyMedia.isNotEmpty) {
      await MediaCacheFactory.precacheMedia(nearbyMedia, highPriority: false);
    }
  }

// Updated _evictDeletedPostImage method to handle all media items
  Future<void> evictDeletedPostMedia(ReelsData deletedPost) async {
    // Loop through all media items in the deleted post
    for (var mediaIndex = 0; mediaIndex < deletedPost.mediaMetaDataList.length; mediaIndex++) {
      final mediaItem = deletedPost.mediaMetaDataList[mediaIndex];

      // Evict image or thumbnail
      final imageUrl = mediaItem.mediaType == MediaType.photo.value
          ? mediaItem.mediaUrl
          : mediaItem.thumbnailUrl;

      if (imageUrl.isNotEmpty) {
        // Evict from Flutter's memory cache
        await NetworkImage(imageUrl).evict();
        _cachedImages.remove(imageUrl);

        // Also evict from disk cache if using CachedNetworkImage
        try {
          await DefaultCacheManager().removeFile(imageUrl);
          debugPrint(
              '🗑️ MainWidget: Evicted deleted post image from cache - Media $mediaIndex: $imageUrl');
        } catch (_) {}
      }

      // For videos, also evict from video cache
      if (mediaItem.mediaType == MediaType.video.value && mediaItem.mediaUrl.isNotEmpty) {
        // Clear from appropriate cache manager based on media type
        final imageCacheManager = MediaCacheFactory.getCacheManager(MediaType.photo);
        final videoCacheManager = MediaCacheFactory.getCacheManager(MediaType.video);

        imageCacheManager.clearMedia(mediaItem.mediaUrl);
        videoCacheManager.clearMedia(mediaItem.mediaUrl);

        debugPrint(
            '🗑️ MainWidget: Evicted deleted post video from cache - Media $mediaIndex: ${mediaItem.mediaUrl}');
      }
    }
  }

  Future<void> clearAllCache() async {
    PaintingBinding.instance.imageCache.clear(); // removes decoded images
    PaintingBinding.instance.imageCache.clearLiveImages(); // removes "live" references

    // Clear all media caches using MediaCacheFactory
    MediaCacheFactory.clearAllCaches();

    // Clear disk cache from CachedNetworkImage
    await DefaultCacheManager().emptyCache();
  }

  /// Handles video completion - navigates to next post if available
  void _handleVideoCompletion(int currentIndex) {
    debugPrint('🎬 PostItemWidget: _handleVideoCompletion called with index $currentIndex');
    debugPrint(
        '🎬 PostItemWidget: mounted: $mounted, reelsDataList length: ${_reelsDataList.length}');

    if (!mounted || _reelsDataList.isEmpty) {
      debugPrint('🎬 PostItemWidget: Early return - not mounted or empty list');
      return;
    }

    // Check if there's a next post available
    if (currentIndex < _reelsDataList.length - 1) {
      final nextIndex = currentIndex + 1;
      debugPrint('🎬 PostItemWidget: Video completed, moving to next post at index $nextIndex');

      // Animate to next page
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint('🎬 PostItemWidget: Video completed, but no more posts available');
      // Optionally trigger load more if we're at the end
      if (widget.onLoadMore != null) {
        debugPrint('🎬 PostItemWidget: Triggering load more...');
        widget.onLoadMore!().then((value) {
          if (value.isListEmptyOrNull) return;
          final newReels = value.where((newReel) =>
              !_reelsDataList.any((existingReel) => existingReel.postId == newReel.postId));
          _reelsDataList.addAll(newReels);
          if (_reelsDataList.isNotEmpty) {
            _doMediaCaching(0);
          }
          _updateState();
        });
      }
    }
  }

  Future<void> _refreshPost() async {
    try {
      if (widget.onRefresh != null) {
        final result = await widget.onRefresh?.call();
        if (result == true) {
          // Get current index before refresh
          final currentIndex = _pageController.page?.toInt() ?? 0;
          debugPrint('🔄 MainWidget: Starting refresh at index $currentIndex');

          // Increment refresh count to force rebuild
          _refreshCounts[currentIndex] = (_refreshCounts[currentIndex] ?? 0) + 1;
          _updateState();
          // Re-initialize caching for current index after successful refresh
          await _doMediaCaching(currentIndex);
          debugPrint(
              '✅ MainWidget: Posts refreshed successfully with count: ${_refreshCounts[currentIndex]}');
        } else {
          debugPrint('⚠️ MainWidget: Refresh returned false');
        }
      }
    } catch (e) {
      debugPrint('❌ MainWidget: Error during refresh - $e');
    }
    return;
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Preload critical images that need to be displayed immediately
  Future<void> _preloadCriticalImages(ReelsData post) async {
    final criticalUrls = <String>[];

    // Add profile image
    if (post.profilePhoto?.isNotEmpty == true) {
      criticalUrls.add(post.profilePhoto!);
    }

    // Add thumbnails for videos (these are already loaded via MediaCacheFactory)
    // Only add if not already in the main loading queue
    for (final mediaItem in post.mediaMetaDataList) {
      if (mediaItem.mediaType == MediaType.video.value && mediaItem.thumbnailUrl.isNotEmpty) {
        criticalUrls.add(mediaItem.thumbnailUrl);
      }
    }

    // OPTIMIZATION: Preload in background without blocking
    if (criticalUrls.isEmpty) return;

    // Use the same cache manager that CachedNetworkImage uses
    final cacheManager = DefaultCacheManager();

    // Process images in parallel for better performance
    final futures = criticalUrls.map((url) async {
      try {
        // Check if already cached before downloading
        final cachedFile = await cacheManager.getFileFromCache(url);
        if (cachedFile != null) {
          debugPrint('✅ PostItemWidget: Image already cached: $url');
          return;
        }

        // Preload into CachedNetworkImage's disk cache
        await cacheManager.downloadFile(url);
        debugPrint('✅ PostItemWidget: Successfully preloaded critical image: $url');
      } catch (e) {
        debugPrint('❌ PostItemWidget: Error preloading critical image $url: $e');
      }
    });

    // OPTIMIZATION: Don't wait for all to complete, start in background
    unawaited(Future.wait(futures));
  }
}
