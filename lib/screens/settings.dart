import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ai_voice_assistant/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.updateInitialPrompt});

  final Function updateInitialPrompt;

  @override
  ConsumerState<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {  
  List<String>? _models;
  List<String>? _languages;
  List<String> _voices = [];
  String? _selectedModel;
  double? _selectedTemperature;
  String? _selectedLanguage;
  String? _selectedVoice;
  final _promptController = TextEditingController();

  List<String>? _modelsOpenAI;
  List<String>? _modelsXAI;
  List<String>? _modelsAnthropic;

  void _onSelectModel(value) {
    setState(() {
      _selectedModel = value;
    });
  }

  void _onSelectTemperature(value) {
    final ai = ref.watch(apiKeyProvider).ai;
    if (ai == 'anthropic' && value > 1) {
      setState(() {
        _selectedTemperature = 1;
      });
    } else {
      setState(() {
        _selectedTemperature = value;
      });
    }
  }

  void _onSelectLanguage(value) {
    setState(() {
      _selectedLanguage = value;
    });
    _getVoices(); // Update available voices for selected language    
  }

  void _onSelectVoice(value) {
    setState(() {
      _selectedVoice = value;
    });
  }

  // After selecting language, get available voices in device
  void _getVoices() async {
    final FlutterTts tts = FlutterTts();
    final voices = await tts.getVoices;
    final filteredVoices = voices.where(
      (v) => v["locale"] == _selectedLanguage 
        && v["network_required"] == "0"
    );
    
    List<String> voicesList = [];
    for (var v in filteredVoices) {
      voicesList.add(v['name']);
    }
    
    _voices = [];
    setState(() {   
      if (voicesList.isNotEmpty) {   
        _voices = voicesList;
        _selectedVoice = voicesList[0];
      } else {
        _voices = ['en-US-language','en-GB-language'];
        _selectedVoice = _voices[0];
      }
    });
  }

  // Method for Save Settings button
  void _saveSettings() async {
    final settings = ref.read(settingsProvider.notifier);
    final prefs = await SharedPreferences.getInstance();
    
    // If not change for a parameter, try to keep old value
    if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      var language = settings.getLanguage();
      if (language.isNotEmpty) {
        _selectedLanguage = settings.getLanguage();
      } else {
        _selectedLanguage = 'en-US';
      }
    }
    if (_selectedVoice == null || _selectedVoice!.isEmpty) {
      var voice = settings.getVoice();
      if (voice.isNotEmpty) {
        _selectedVoice = settings.getVoice();
      } else {
        _selectedVoice = 'en-US-language';
      }
    }
    if (_selectedModel == null || _selectedModel!.isEmpty) {
      var model = settings.getModel();
      if (model.isNotEmpty) {
        _selectedModel = settings.getModel();
      } else {
        _selectedModel = _models![0];
      }
      
    }
    _selectedTemperature ??= settings.getTemperature();
    if (_promptController.text.isEmpty) { return; }

    // Update provider
    settings.setSettings(Settings(
      language: _selectedLanguage!,
      voice: _selectedVoice!,
      model: _selectedModel!,
      temperature: _selectedTemperature!,
      prompt: _promptController.text,
    ));

    // Update Shared Preferences, device storage
    try {
      prefs.setString('language', _selectedLanguage!);
      prefs.setString('voice', _selectedVoice!);
      prefs.setString('model', _selectedModel!);
      prefs.setDouble('temperature', _selectedTemperature!);
      prefs.setString('prompt', _promptController.text);
      // Update initial message for chat messages
      widget.updateInitialPrompt(_promptController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Settings saved.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(e.toString()),
        ),
      );
    }   
  }
  
  @override
  void initState() {    
    setState(() {
      _languages = ['am-ET','ar-DZ', 'ar-EG', 'ar-SD', 'bg-BG', 'cs-CZ', 'da-DK', 
        'de-DE', 'en-AU', 'en-GB', 'en-IN', 'en-KE', 'en-NG', 'en-UG', 'en-US', 'en-ZA', 'es-ES', 
        'es-US', 'fi-FI', 'fr-CA', 'fr-FR', 'he-IL', 'hi-IN', 'hr-HR', 
        'hu-HU', 'it-IT', 'is-IS', 'ja-JP', 'ko-KR', 'nb-NO', 'nl-BE', 
        'nl-NL', 'pl-PL', 'pt-BR', 'pt-PT', 'ro-RO', 'ru-RU', 'sl-SI', 
        'sr-RS', 'sk-SK', 'sv-SE', 'sw-TZ', 'th-TH', 'uk-UA', 'zh-CN', 'zh-TW'];
      _modelsOpenAI = ['gpt-5.2','gpt-5.1','gpt-5','gpt-5-mini',
        'gpt-5-nano','gpt-4.1','gpt-4.1-mini','gpt-4.1-nano'];
      _modelsXAI = ['grok-4-1-fast-reasoning','grok-4-1-fast-non-reasoning',
        'grok-4-1-fast', 'grok-4-fast-reasoning','grok-4-fast-non-reasoning',
        'grok-4'];
      _modelsAnthropic = ['claude-opus-4-6', 'claude-sonnet-4-5', 
        'claude-haiku-4-5'];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(settingsProvider).prompt;
    _promptController.text = prompt;
    _selectedTemperature ??= ref.watch(settingsProvider).temperature; // If null use value from provider
    final aiService = ref.watch(apiKeyProvider).ai;
    // Models depending on AI Service
    if (aiService == 'xai') { _models = _modelsXAI; }
    else if (aiService == 'anthropic') { _models = _modelsAnthropic; }
    else { _models = _modelsOpenAI; }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Select language
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Language',
                  ),
                  items: _languages!
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  onChanged: _onSelectLanguage,
                ),
                const SizedBox(height: 20,),
                // Select voice
                DropdownButtonFormField<String>(
                  initialValue: _selectedVoice,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Voice',
                  ),
                  items: _voices
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  onChanged: _onSelectVoice,
                ),
                const SizedBox(height: 20,),
                Row(
                  children: [
                    // Select model
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedModel,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'AI Model',
                        ),
                        items: _models!
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        onChanged: _onSelectModel,
                      ),
                    ),
                    // Select temperature
                    Expanded(
                      child: Slider(
                        value: _selectedTemperature!,
                        label: "Temperature $_selectedTemperature, "
                          "ignore for gpt-5 & gpt-5-* models, "
                          "anthropic [0-1]",
                        min: 0,
                        max: 2,
                        divisions: 200,
                        onChanged: _onSelectTemperature,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20,),              
                // Edit prompt or initial message
                TextField(
                  controller: _promptController,
                  readOnly: false,
                  maxLines: 7,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'AI Prompt',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20,),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
