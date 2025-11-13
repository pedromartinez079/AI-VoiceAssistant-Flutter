import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';


Future<String?> listenOnce(stt, String language, Function setStatusText) async {
  SpeechRecognitionResult? last;
  final done = Completer<String?>();
  final available = await stt.initialize(
    onStatus: (status) {
      // Android: 'listening' | 'notListening', iOS may send 'done'
      if (status == 'notListening' || status == 'done') {
        if (!done.isCompleted) {
          final text = (last?.recognizedWords ?? '').trim();
          done.complete(text.isEmpty ? null : text);
        }
      }
    },
    onError: (e) {
      if (!done.isCompleted) done.complete(null);
      setStatusText('STT: ${e.errorMsg}');      
    },
  );
  await Future.delayed(const Duration(milliseconds: 200));
  if (!available) {
    setStatusText('STT: Not available');
    return null;
  }
  setStatusText('STT Listening');
  await Future.delayed(const Duration(milliseconds: 300));
  stt.listen(
    onResult: (res) {
      last = res;
      // If the engine does mark final, finish early
      if (res.finalResult && !done.isCompleted) {
        final text = res.recognizedWords.trim();
        done.complete(text.isEmpty ? null : text);
      }
    },
    localeId: language,
    listenFor: const Duration(seconds: 15),
    pauseFor: const Duration(seconds: 2),
    partialResults: true,
    cancelOnError: true,
  );
  final result = await done.future.timeout(
    const Duration(seconds: 3),
    onTimeout: () => null,
  );
  
  try {
    await stt.stop();
  } catch (_) {}
  
  return result;
} 