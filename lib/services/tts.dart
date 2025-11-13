import 'package:flutter_tts/flutter_tts.dart';

Future<void> speak(
  String answer, String language, String voice, 
  Function setIsSpeaking, FlutterTts tts, Function setChatMessage) async {
    setIsSpeaking(true);
    await tts.setLanguage(language);
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);    
    await tts.setVoice({
      "name": voice,
      "locale": language,
      //"name": "es-es-x-eec-local", 
      //"locale": "es-ES"
    });
    await tts.awaitSpeakCompletion(true);    
    try {
      await tts.speak(answer);
    } finally {
      setIsSpeaking(false);
    }
  }

Future<void> configureTts(String language, Object voice, FlutterTts tts) async {
  await tts.setLanguage(language);
  await tts.setSpeechRate(0.45);
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
  final voices = await tts.getVoices;
  print(voices.length);
  print(voices.where((v) => v["locale"] == "es-ES")
    .map((v) => v["name"]).length);
  await tts.setVoice({
    "name": "es-es-x-eec-local", 
    "locale": "es-ES"
  });
  await tts.awaitSpeakCompletion(true);
}

/*
{features: , latency: , name: , locale: , network_required: , quality: ,}
locale: es-ES
es-es-x-eee-local fem
es-es-x-eef-local mas
es-es-x-eec-network fem net-req
es-es-x-eea-local fem
es-es-x-eea-network fem net-req
es-es-x-eed-local mas
es-ES-language fem
es-es-x-eed-network mas net-req
es-es-x-eec-local fem

en-US-language fem
fr-FR-language fem
*/