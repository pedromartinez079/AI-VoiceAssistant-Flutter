import 'package:ai_voice_assistant/screens/set_apikey.dart';
import 'package:ai_voice_assistant/screens/settings.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:openai_dart/openai_dart.dart';

import 'package:ai_voice_assistant/services/stt.dart';
import 'package:ai_voice_assistant/services/tts.dart';
import 'package:ai_voice_assistant/services/openai.dart';
import 'package:ai_voice_assistant/providers/settings_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({
    super.key,
  });

  @override
  ConsumerState<AiAssistantScreen> createState() {
    return _AiAssistantScreenState();
  }
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  String _statusText = 'Application Status';
  final _scrollController = ScrollController();
  String _chatMessage = '';
  final List<ChatCompletionMessage> _messages = [];
  bool _isInitialMessageSet = false;
  String? _ai;
  String? _apikey;

  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String? _language;
  String? _voice;

  bool _loopRunning = false;
  bool _end = false;
  bool _paused = false;
  bool _isSpeaking = false;
  
  void setIsSpeaking(bool b) { 
    setState(() {
      _isSpeaking = b;
    });
  }

  void setChatMessage(String s) {
    setState(() {
      _chatMessage += s;
    });
  }

  void setStatusText(String s) {
    setState(() {
      _statusText = s;
    });
  }

  Future<void> _startLoop() async {
    if (_loopRunning) return; // if running don't start again

    setState(() {
      _loopRunning = true;
      _end = false;
    });

    // Main loop for STT, AI answers and TTS processes
    while (_loopRunning && mounted) {
      if (!_loopRunning || _end) {
        break;
      }

      if (_paused) {
        setState(() => _statusText = 'On pause');
        continue;
      }

      if (_isSpeaking) {
        setState(() => _statusText = 'Speaking');
        // await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final query = await listenOnce(_stt, _language!, setStatusText);
      
      if (query == null || query.trim().isEmpty) {
        setState(() => _statusText = 'STT: Error or Empty');
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }
      
      setState(() {
        _chatMessage += '\nUser: $query';
        _statusText = 'Waiting for answer...';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      _messages.add(ChatCompletionMessage.user(
        role: ChatCompletionMessageRole.user,
        content: ChatCompletionUserMessageContent.string(query),
      ));
      final answer = await processQuery(
        _messages, _ai!, _apikey!, setStatusText
      );
      _messages.add(ChatCompletionMessage.assistant(
        role: ChatCompletionMessageRole.assistant,
        content: answer,
      ));

      setState(() {
        _chatMessage += '\nAI: $answer';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      setState(() {
        _statusText = 'Speaking';
      });
      await speak(answer, _language!, _voice!,
        setIsSpeaking, _tts);
    }

    setState(() => _loopRunning = false);
  }

  Future<void> _stopLoop() async {
    setState(() {
      _loopRunning = false;
      _statusText = 'Application Stopped';
    });
    try {
      await _stt.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
  }  

  @override
  void dispose() {
    _scrollController.dispose();
    _stopLoop();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiAuth = ref.watch(apiKeyProvider);
    final aiService = aiAuth.ai;
    final apiKey = aiAuth.apikey;

    setState(() {
      _ai = aiService;
      _apikey = apiKey;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.watch(settingsProvider);
      final initialMessage = ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(settings.prompt),
      );

      if (!_isInitialMessageSet) {
        setState(() {
          _isInitialMessageSet = true;
          _messages.add(initialMessage);
        });
      }

      setState(() {
        _language = settings.language;
        _voice = settings.voice;
      });
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SettingsScreen(),
                )
              );
            }, 
            icon: Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SetApiKeyScreen(),
                )
              );
            }, 
            icon: Icon(Icons.key),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Text(
              'AI Service: $aiService',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              ),
            ),            
            const SizedBox(height:10),
            // Application Status
            Center(
              child: Text(
                _statusText,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  ),
              ),
            ),
            const SizedBox(height:10),
            // Messages
            const Text('Messages:', style: TextStyle(color: Colors.white)),
            Expanded(              
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),                      
                  ),
                child: SingleChildScrollView(
                  controller: _scrollController,                    
                  child: Align(
                    alignment: Alignment.topLeft,                    
                    child: Text(
                      _chatMessage,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height:10),
            // Buttons Row
            Row(
              children: [
                // Start
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startLoop,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 5,),
                // Pause
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_loopRunning 
                      ? null 
                      : () => setState(() => _paused = !_paused),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 5,),
                // Stop
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stopLoop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}