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
}

final apiKeyProvider =
  StateNotifierProvider<ApiKeyNotifier, AiAuth>((ref) {
    return ApiKeyNotifier();
  });


class Settings {
  final String language;
  final String voice;
  final String prompt;

  const Settings({
    required this.language,
    required this.voice,
    required this.prompt,
  });
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() 
    : super(const Settings(language: '', voice: '', prompt: ''));

  void setSettings(Settings settings) {
    state = settings;
  }
}

final settingsProvider =
  StateNotifierProvider<SettingsNotifier, Settings>((ref) {
    return SettingsNotifier();
  });