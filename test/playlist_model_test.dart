import 'package:flutter_test/flutter_test.dart';
import 'package:vibetune/models/playlist_model.dart';

void main() {
  group('PlaylistModel Tests', () {
    test('Constructs correctly with defaults', () {
      const model = PlaylistModel(
        id: 'pl_01',
        name: 'Chill Vibes',
      );

      expect(model.id, equals('pl_01'));
      expect(model.name, equals('Chill Vibes'));
      expect(model.description, equals(''));
      expect(model.songIds, isEmpty);
      expect(model.songCount, equals(0));
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('Deserializes from backend JSON with MongoDB _id and string songs', () {
      final json = {
        '_id': '64a000000000000000000010',
        'name': 'Telugu Classics',
        'description': 'Handpicked melodies',
        'songs': ['vt_studio_te', 'c_telugu_01'],
        'createdAt': '2026-11-12T05:00:00.000Z',
        'updatedAt': '2026-11-12T05:15:00.000Z',
      };

      final model = PlaylistModel.fromJson(json);

      expect(model.id, equals('64a000000000000000000010'));
      expect(model.name, equals('Telugu Classics'));
      expect(model.description, equals('Handpicked melodies'));
      expect(model.songIds, equals(['vt_studio_te', 'c_telugu_01']));
      expect(model.songCount, equals(2));
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
    });

    test('Serializes to JSON correctly', () {
      final now = DateTime.parse('2026-11-12T05:00:00.000Z');
      final model = PlaylistModel(
        id: 'pl_test',
        name: 'Karaoke Practice',
        description: 'Vocal warmups',
        songIds: const ['vt_studio_hi', 'vt_studio_ka'],
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();

      expect(json['id'], equals('pl_test'));
      expect(json['name'], equals('Karaoke Practice'));
      expect(json['description'], equals('Vocal warmups'));
      expect(json['songs'], equals(['vt_studio_hi', 'vt_studio_ka']));
      expect(json['createdAt'], equals('2026-11-12T05:00:00.000Z'));
    });

    test('copyWith updates specified fields only', () {
      const original = PlaylistModel(
        id: 'pl_copy',
        name: 'Original Name',
        description: 'Original Description',
        songIds: ['song_01'],
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        songIds: ['song_01', 'song_02'],
      );

      expect(updated.id, equals('pl_copy'));
      expect(updated.name, equals('Updated Name'));
      expect(updated.description, equals('Original Description'));
      expect(updated.songCount, equals(2));
      expect(updated.songIds, equals(['song_01', 'song_02']));
    });
  });
}

