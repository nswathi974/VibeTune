import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Demo audio and English LRC assets load successfully via rootBundle', () async {
    // 1. Agar Tum Saath Ho (Hindi)
    final hindiAudio = await rootBundle.load('assets/audio/normal/agar_tum_saath_ho.mp3');
    expect(hindiAudio.lengthInBytes, greaterThan(100000));

    final hindiLrc = await rootBundle.loadString('assets/lyrics/agar_tum_saath_ho.lrc');
    expect(hindiLrc.contains('Pal Bhar Thehar Jaao'), isTrue);

    // 2. Anisuthide (Kannada)
    final kannadaAudio = await rootBundle.load('assets/audio/normal/anisuthide.mp3');
    expect(kannadaAudio.lengthInBytes, greaterThan(100000));

    final kannadaLrc = await rootBundle.loadString('assets/lyrics/anisuthide.lrc');
    expect(kannadaLrc.contains('Anisuthide yaako indu'), isTrue);

    // 3. Thuli Thuli (Tamil)
    final tamilAudio = await rootBundle.load('assets/audio/normal/thuli_thuli.mp3');
    expect(tamilAudio.lengthInBytes, greaterThan(100000));

    final tamilLrc = await rootBundle.loadString('assets/lyrics/thuli_thuli.lrc');
    expect(tamilLrc.contains('Thuli thuli thuli mazhaiyaai vandhaale'), isTrue);
  });
}
