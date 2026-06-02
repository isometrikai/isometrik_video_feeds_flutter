import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/domain/models/sound_api_model.dart';

void main() {
  test('parses trending flat data array', () {
    const json = '''
    {"status":"success","message":"Trending sounds retrieved successfully","status_code":200,"code":"2000","data":[{"id":"snd_db864390818d","title":"aa","artist":"kk","album":"trial","duration":581.66,"url":"https://example.com/a.mp3","waveform_url":"https://example.com/a.mp3","preview_url":"https://example.com/a.mp3","type":"user_upload","user_id":null,"status":"approved","usage_count":0,"created_at":"2026-05-19T09:56:16.268623+00:00"}],"total":10,"page":1,"page_size":10,"total_pages":1}
    ''';
    final response =
        SoundsListResponse.fromMap(jsonDecode(json) as Map<String, dynamic>);
    expect(response.isSuccess, isTrue);
    expect(response.sounds.length, 1);
    expect(response.sounds.first.id, 'snd_db864390818d');
    expect(response.sounds.first.title, 'aa');
    expect(response.sounds.first.durationSeconds, 581.66);
    expect(response.pagination?.total, 10);
  });

  test('parses recommended nested data array', () {
    const json = '''
    {"status":"success","message":"Sounds retrieved successfully","status_code":200,"code":"2000","data":[[{"id":"snd_5b2a6005a99d","title":"Until","artist":"Stephen Sanchez","album":"Chill & LoFi","duration":184.93,"url":"https://example.com/b.mp3","waveform_url":"https://example.com/b.mp3","preview_url":"https://example.com/b.mp3","type":"user_upload","user_id":null,"status":"approved","usage_count":0,"created_at":"2026-05-21T07:06:47.790588+00:00"}],10],"total":2,"page":1,"page_size":10,"total_pages":1}
    ''';
    final response =
        SoundsListResponse.fromMap(jsonDecode(json) as Map<String, dynamic>);
    expect(response.sounds.length, 1);
    expect(response.sounds.first.id, 'snd_5b2a6005a99d');
    expect(response.sounds.first.album, 'Chill & LoFi');
    expect(response.sounds.first.categoryIds, contains('Chill & LoFi'));
  });

}
