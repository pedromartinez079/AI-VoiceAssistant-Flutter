import 'dart:async';

Future<String?> listenOnce(stt, String language, Function setStatusText) async {
  final done = Completer<String?>();
  Timer? silenceTimer;
  const maxSilence = Duration(seconds: 12);
  void cancelAndReturnNull() {
    if (!done.isCompleted) {
      stt.stop();
      silenceTimer?.cancel();
      done.complete(null);
    }
  }
  silenceTimer = Timer(maxSilence, cancelAndReturnNull);

  bool initialize = !stt.isAvailable;
  if (initialize) {
    final available = await stt.initialize(
      debugLogging: true,
      onStatus: (status) {
        // print('STT Status: $status');
        // Android: 'listening' | 'notListening', iOS may send 'done'
        if (status == 'notListening' || status == 'done') {
          if (!done.isCompleted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!done.isCompleted) done.complete(null);
            });
          }
        }
      },
      onError: (e) {
        setStatusText('STT Error: ${e.errorMsg} (permanent: ${e.permanent})');
        Future.delayed(const Duration(milliseconds: 100));
        if (e.errorMsg.contains("no_match") || 
            e.errorMsg.contains("no recognition result")) {
          if (!done.isCompleted) done.complete(null);
        } else if (e.permanent) {
          // Other errors
          if (!done.isCompleted) done.complete(null);
        }     
      },
    );
    
    if (!available) {
      setStatusText('STT: Not available');
      await Future.delayed(const Duration(milliseconds: 100));
      return null;
    }
  }
  setStatusText('STT Listening');
  await Future.delayed(const Duration(milliseconds: 100));
  stt.listen(
    onResult: (res) {
      if (res.recognizedWords.isNotEmpty) {
        silenceTimer?.cancel();
        silenceTimer = Timer(maxSilence, cancelAndReturnNull);
      }
      if (res.finalResult) {
        silenceTimer?.cancel();
        final text = res.recognizedWords.trim();
        if (!done.isCompleted) {
          done.complete(text.isEmpty ? null : text);
        }
      }
    },
    localeId: '${language.substring(0,2)}_${language.substring(3,5)}',
    listenFor: const Duration(minutes: 5),
    pauseFor: const Duration(seconds: 10),
    partialResults: true,
    cancelOnError: false,
  );
  
  final result = await done.future.whenComplete(() {
    silenceTimer?.cancel();
  });
  
  try {
    await stt.stop();
  } catch (_) {}
  
  return result;
} 