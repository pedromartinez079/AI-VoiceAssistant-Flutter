import 'package:flutter_tts/flutter_tts.dart';

Future<void> speak(
  String answer, String language, String voice, 
  Function setIsSpeaking, FlutterTts tts) async {
    setIsSpeaking(true);
    await tts.setLanguage(language);
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);    
    await tts.setVoice({
      "name": voice, // Example "name": "es-es-x-eec-local",
      "locale": language, // Example "locale": "es-ES"
    });
    await tts.awaitSpeakCompletion(true);    
    try {
      await tts.speak(answer);
    } catch (_) {      
    } finally {
      setIsSpeaking(false);
    }
  }

/* TTS Voice map
{features: , latency: , name: , locale: , 
  network_required: , quality: ,}
*/
