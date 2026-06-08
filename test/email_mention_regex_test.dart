import 'package:flutter_test/flutter_test.dart';

void main() {
  test('old mention regex breaks emails', () {
    const text = 'email me at appscrip13@yopmail.com';
    final old = RegExp(r'(@[a-zA-Z0-9_]+)|(#[a-zA-Z0-9_]+)|(https?:\/\/\S+|www\.\S+)');
    final matches = old.allMatches(text).map((m) => m.group(0)).toList();
    expect(matches, contains('@yopmail'));
  });

  test('fixed mention regex ignores email @', () {
    const text = 'email me at appscrip13@yopmail.com';
    final fixed = RegExp(
      r'((?<![a-zA-Z0-9._%+-])@[a-zA-Z0-9_]+)|(#[a-zA-Z0-9_]+)|(https?:\/\/\S+|www\.\S+)',
    );
    final matches = fixed.allMatches(text).map((m) => m.group(0)).toList();
    expect(matches, isEmpty);
  });

  test('fixed mention regex still matches real mentions', () {
    const text = 'hey @john check this';
    final fixed = RegExp(
      r'((?<![a-zA-Z0-9._%+-])@[a-zA-Z0-9_]+)|(#[a-zA-Z0-9_]+)|(https?:\/\/\S+|www\.\S+)',
    );
    final matches = fixed.allMatches(text).map((m) => m.group(0)).toList();
    expect(matches, contains('@john'));
  });
}
