import 'package:ai_voice_assistant/providers/settings_provider.dart';
import 'package:ai_voice_assistant/screens/assistant.dart';
import 'package:ai_voice_assistant/screens/set_apikey.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


//import 'package:ai_voice_assistant/ui.dart';

final colorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 102, 6, 247),
  //surface: const Color.fromARGB(255, 56, 49, 66),
  surface: const Color.fromARGB(255, 102, 6, 247),
);

final theme = ThemeData().copyWith(
  // useMaterial3: true,
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
  //prefs.remove('ai');
  //prefs.remove('apikey');
  final bool hasAiAuth = prefs.containsKey('ai') && prefs.containsKey('apikey');
  final bool hasLanguage = prefs.containsKey('language');
  final bool hasVoice = prefs.containsKey('voice');
  final bool hasPrompt = prefs.containsKey('prompt');
  String? ai;
  String? apikey;
  String? language;
  String? voice;
  String? prompt;

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
    required this.prompt,
  });

  final bool hasAiAuth;
  final String ai;
  final String apikey;
  final String language;
  final String voice;
  final String prompt;  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apikeyNotifier = ref.read(apiKeyProvider.notifier);
      final settingsNotifier = ref.read(settingsProvider.notifier);
      if (hasAiAuth) {
        apikeyNotifier.setApiKey(AiAuth(ai: ai, apikey: apikey));
      }
      settingsNotifier.setSettings(
        Settings(language: language, voice: voice, prompt: prompt)
      );
    });

    return MaterialApp(
      title: 'AI Voice Assistant',
      theme: theme,
      home: hasAiAuth
        ? const AiAssistantScreen()
        : const SetApiKeyScreen()
    );
  }
}

