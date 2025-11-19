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
      "name": voice, //"name": "es-es-x-eec-local",
      "locale": language, //"locale": "es-ES"
    });
    await tts.awaitSpeakCompletion(true);    
    try {
      await tts.speak(answer);
    } catch (_) {      
    } finally {
      setIsSpeaking(false);
    }
  }

Future<void> configureTts(String language, Object voice, FlutterTts tts) async {
  await tts.setLanguage(language);
  await tts.setSpeechRate(0.45);
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
  /*
  final voices = await tts.getVoices;  
  print(voices.length);
  print(voices.where((v) => v["locale"] == "es-ES")
    .map((v) => v["name"]).length);
  */
  await tts.setVoice({
    "name": "es-es-x-eec-local", 
    "locale": "es-ES"
  });
  await tts.awaitSpeakCompletion(true);
}

/* TTS Voice
{features: , latency: , name: , locale: , 
  network_required: , quality: ,}
*/