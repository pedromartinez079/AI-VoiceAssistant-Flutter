import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_voice_assistant/providers/settings_provider.dart';
import 'package:ai_voice_assistant/screens/assistant.dart';
import 'package:ai_voice_assistant/screens/set_apikey.dart';

final colorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 10, 51, 186),
  surface: const Color.fromARGB(255, 10, 51, 186),
);

final theme = ThemeData().copyWith(
  scaffoldBackgroundColor: colorScheme.surface,
  colorScheme: colorScheme,
  textTheme: GoogleFonts.ubuntuCondensedTextTheme().copyWith(
    titleSmall: GoogleFonts.ubuntuCondensed(
      fontWeight: FontWeight.bold,
    ),
    titleMedium: GoogleFonts.ubuntuCondensed(
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.ubuntuCondensed(
      fontWeight: FontWeight.bold,
    ),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool hasAiAuth = prefs.containsKey('ai') && prefs.containsKey('apikey');
  final bool hasLanguage = prefs.containsKey('language');
  final bool hasVoice = prefs.containsKey('voice');
  final bool hasModel = prefs.containsKey('model');
  final bool hasTemperature = prefs.containsKey('temperature');
  final bool hasPrompt = prefs.containsKey('prompt');
  String? ai;
  String? apikey;
  String? language;
  String? voice;
  String? model;
  double? temperature;
  String? prompt;

  // Check if setting values exist, if not use default values
  if (hasAiAuth) {
    ai = prefs.getString('ai');
    apikey = prefs.getString('apikey');    
  } else {
    ai = '';
    apikey = '';
  }

  if (hasLanguage) { language = prefs.getString('language'); }
  else { language = 'es-ES'; }

  if (hasVoice) { voice = prefs.getString('voice'); }
  else { voice = 'es-es-x-eea-local'; }

  if (hasModel) { model = prefs.getString('model'); }
  else { model = ''; }

  if (hasTemperature) { temperature = prefs.getDouble('temperature'); }
  else { temperature = 0.8; }

  if (hasPrompt) { prompt = prefs.getString('prompt'); }
  else { prompt = (
    'Eres un asistente personal inteligente y amable. Tus respuestas son convertidas a voz usando servicios de TTS, evita respuestas muy largas o caracteres que no se puedan convertir a voz.'
  ); }

  runApp(
    ProviderScope(child: AIVoiceAssistant(
      hasAiAuth: hasAiAuth,
      ai: ai!,
      apikey: apikey!,
      language: language!,
      voice: voice!,
      model: model!,
      temperature: temperature!,
      prompt: prompt!,
    )),
  );
}

class AIVoiceAssistant extends ConsumerWidget {
  const AIVoiceAssistant({
    super.key,
    required this.hasAiAuth,
    required this.ai,
    required this.apikey,
    required this.language,
    required this.voice,
    required this.model,
    required this.temperature,
    required this.prompt,
  });

  final bool hasAiAuth;
  final String ai;
  final String apikey;
  final String language;
  final String voice;
  final String model;
  final double temperature;
  final String prompt;  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apikeyNotifier = ref.read(apiKeyProvider.notifier);
      final settingsNotifier = ref.read(settingsProvider.notifier);
      // Load values into providers
      if (hasAiAuth) {
        apikeyNotifier.setApiKey(AiAuth(ai: ai, apikey: apikey));
      }
      settingsNotifier.setSettings(
        Settings(language: language, voice: voice, model: model, 
          temperature: temperature, prompt: prompt)
      );
    });

    return MaterialApp(
      title: 'AI Voice Assistant',
      theme: theme,
      home: hasAiAuth // If api key isn't set, first set Ai Service and api key
        ? const AiAssistantScreen()
        : const SetApiKeyScreen()
    );
  }
}

