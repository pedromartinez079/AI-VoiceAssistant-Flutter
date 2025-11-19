import 'dart:async';

Future<String?> listenOnce(stt, String language, Function setStatusText) async {
  final completer = Completer<String?>();
  Timer? silenceTimer;
  const maxSilence = Duration(seconds: 12);
  void cancelAndReturnNull() {
    if (!completer.isCompleted) {
      stt.stop();
      silenceTimer?.cancel();
      completer.complete(null);
    }
  }
  silenceTimer = Timer(maxSilence, cancelAndReturnNull);

  bool initialize = !stt.isAvailable;
  if (initialize) {
    final available = await stt.initialize(
      debugLogging: true,
      onStatus: (status) {
        // Android: 'listening' | 'notListening', iOS: 'done'
        if (status == 'notListening' || status == 'done') {
          if (!completer.isCompleted) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (!completer.isCompleted) completer.complete(null);
            });
          }
        }
      },
      onError: (e) {
        setStatusText('STT Error: ${e.errorMsg} (permanent: ${e.permanent})');
        if (e.errorMsg.contains("no_match") || 
            e.errorMsg.contains("no recognition result")) {
          if (!completer.isCompleted) completer.complete(null);
        } else if (e.permanent) {
          // Other errors
          if (!completer.isCompleted) completer.complete(null);
        }
      },
    );
    
    if (!available) {
      setStatusText('STT: Not available');
      await Future.delayed(const Duration(milliseconds: 300));
      return null;
    }
  }

  setStatusText('STT Listening');
  //await Future.delayed(const Duration(milliseconds: 50));
  stt.listen(
    onResult: (res) {
      if (res.recognizedWords.isNotEmpty) {
        silenceTimer?.cancel();
        silenceTimer = Timer(maxSilence, cancelAndReturnNull);
      }
      if (res.finalResult) {
        silenceTimer?.cancel();
        final text = res.recognizedWords.trim();
        if (!completer.isCompleted) {
          completer.complete(text.isEmpty ? null : text);
        }
      }
    },
    localeId: '${language.substring(0,2)}_${language.substring(3,5)}',
    listenFor: const Duration(minutes: 5),
    pauseFor: const Duration(seconds: 10),
    partialResults: true,
    cancelOnError: false,
  );
  
  final result = await completer.future.whenComplete(() {
    silenceTimer?.cancel();
  });
  
  try {
    await stt.stop();
  } catch (_) {}
  
  return result;
} 