import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Both Bhajan MP3 and LRC assets load successfully via rootBundle', () async {
    // 1. Bhagyada Lakshmi Baramma
    final bhajan1Audio = await rootBundle.load('assets/audio/normal/bhagyada_lakshmi_baramma.mp3');
    expect(bhajan1Audio.lengthInBytes, 2973692);

    final bhajan1Lrc = await rootBundle.loadString('assets/lyrics/bhagyada_lakshmi_baramma.lrc');
    expect(bhajan1Lrc.contains('Bhagyada Lakshmi Baramma'), isTrue);
    expect(bhajan1Lrc.contains('ಭಾಗ್ಯದ ಲಕ್ಷ್ಮಿ ಬಾರಮ್ಮಾ'), isTrue);

    // 2. Ksheerabdhi Kanyaka
    final bhajan2Audio = await rootBundle.load('assets/audio/normal/ksheerabdhi_kanyaka.mp3');
    expect(bhajan2Audio.lengthInBytes, 3802087);

    final bhajan2Lrc = await rootBundle.loadString('assets/lyrics/ksheerabdhi_kanyaka.lrc');
    expect(bhajan2Lrc.contains('Ksheerabdhi Kanyaku'), isTrue);
    expect(bhajan2Lrc.contains('క్షీరాబ్ధి కన్యకకు'), isTrue);
  });
}

