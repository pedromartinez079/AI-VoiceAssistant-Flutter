import 'package:flutter_riverpod/legacy.dart';

class AiAuth {
  final String ai;
  final String apikey;

  const AiAuth({required this.ai, required this.apikey});
}

class ApiKeyNotifier extends StateNotifier<AiAuth> {
  ApiKeyNotifier() : super(const AiAuth(ai: '', apikey: ''));

  void setApiKey(AiAuth aiAuth) {
    state = aiAuth;
  }
  
  String getAi() { return state.ai; }
  String getApiKey() { return state.apikey; }
}

final apiKeyProvider =
  StateNotifierProvider<ApiKeyNotifier, AiAuth>((ref) {
    return ApiKeyNotifier();
  });


class Settings {
  final String language;
  final String voice;
  final String model;
  final double temperature;
  final String prompt;

  const Settings({
    required this.language,
    required this.voice,
    required this.model,
    required this.temperature,
    required this.prompt,
  });
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() 
    : super(const Settings(language: '', voice: '', model: '', temperature: 0.8, prompt: ''));

  void setSettings(Settings settings) {
    state = settings;
  }

  String getLanguage() { return state.language; }
  String getVoice() { return state.voice; }
  String getModel() { return state.model; }
  double getTemperature() { return state.temperature; }
  String getPrompt() { return state.prompt; }
}

final settingsProvider =
  StateNotifierProvider<SettingsNotifier, Settings>((ref) {
    return SettingsNotifier();
  });