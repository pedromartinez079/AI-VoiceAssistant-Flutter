import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:openai_dart/openai_dart.dart';

import 'package:ai_voice_assistant/screens/set_apikey.dart';
import 'package:ai_voice_assistant/screens/settings.dart';
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
  String? _aimodel;
  double? _temperature;

  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String? _language;
  String? _voice;

  bool _loopRunning = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isStopEnabled = false;
  
  void setIsSpeaking(bool b) { 
    if (mounted) {
      setState(() {
        _isSpeaking = b;
      });
    }
  }

  void setIsListening(bool b) { 
    if (mounted) {
      setState(() {
        _isListening = b;
        _isStopEnabled = !b;
      });
    }
  }

  void setChatMessage(String s) {
      if (mounted) {
      setState(() {
        _chatMessage += s;
      });
    }
  }

  void setStatusText(String s) {
    if (mounted) {
      setState(() {
        _statusText = s;
      });
    }
  }

  // Set Prompt as the first message of the list for chat messages
  void updateInitialPrompt(String s) {
    final initialPrompt = ChatCompletionMessage.user(
      content: ChatCompletionUserMessageContent.string(s),
    );
    
    if (_messages.isNotEmpty) {
      _messages[0] = initialPrompt;
    } else {
      _messages.add(initialPrompt);
    }
  }

  // Auto scroll for chat messages
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Method to start assistant
  Future<void> _startLoop() async {
    if (_loopRunning) return; // if lopp active, don't start again

    setState(() {
      _loopRunning = true;
      _isStopEnabled = true;
    });

    // Main loop for STT, AI answers and TTS processes
    while (_loopRunning && mounted) {
      if (!_loopRunning || !mounted) break;
      
      if (_isSpeaking || _isListening) {
        continue;
      }      
      
      // STT - Speech to text
      final query = await listenOnce(_stt, _language!, setStatusText,
        setIsListening).catchError((_) => null);
      if (!_loopRunning || !mounted) break;
      if (query == null || query.trim().isEmpty) {
        setState(() => _statusText = 'STT: Error or Empty');
        await Future.delayed(const Duration(milliseconds: 2000));
        continue;
      }      
      setState(() {
        _chatMessage += '\nUser: $query';
        _statusText = 'Waiting for answer...';
      });
      _scrollToBottom();
      
      if (!_loopRunning || !mounted) break;

      // AI answer
      _messages.add(ChatCompletionMessage.user(
        role: ChatCompletionMessageRole.user,
        content: ChatCompletionUserMessageContent.string(query),
      ));      
      
      final answer = await processQuery(
        _messages, _ai!, _apikey!, _aimodel!, _temperature!, setStatusText
      );
      
      _messages.add(ChatCompletionMessage.assistant(
        role: ChatCompletionMessageRole.assistant,
        content: answer,
      ));
      if (mounted) {
        setState(() {
          _chatMessage += '\nAI: $answer';
        });      
        _scrollToBottom();
      }
      
      if (!_loopRunning || !mounted) break;
      
      // TTS - Text to speech
      setState(() {
        _statusText = 'Speaking';
      });
      await speak(answer, _language!, _voice!,
        setIsSpeaking, _tts);
    }

    if (mounted) {
      setState(() => _loopRunning = false);
    }
  }

  // Method to stop assistant
  Future<void> _stopLoop() async {
    if (_isListening) { return; } // Avoid problems during STT process

    _loopRunning = false;
    _isStopEnabled = false;
    _isListening = false;
    _isSpeaking = false;

    await Future.wait([
      _stt.cancel().catchError((_) => null),
      _tts.stop().catchError((_) => null),
    ]);
    if (mounted) setState(() => _statusText = 'Application is stopped');
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
    _stt.cancel();
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
    
    // Load assistant parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.watch(settingsProvider);
      final initialMessage = ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(settings.prompt),
      );

      // Insert initial message
      if (!_isInitialMessageSet) {
        setState(() {
          _isInitialMessageSet = true;
          _messages.add(initialMessage);
        });
      }

      // Parameters for STT, TTS and OpenAI
      setState(() {
        _language = settings.language;
        _voice = settings.voice;
        _aimodel = settings.model;
        _temperature = settings.temperature;
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
                  builder: (ctx) => SettingsScreen(updateInitialPrompt: updateInitialPrompt),
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
            // AI Service
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
            // Chat messages
            const Text('Chat messages:', style: TextStyle(color: Colors.white)),
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
                // Stop
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStopEnabled ? _stopLoop : null,
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