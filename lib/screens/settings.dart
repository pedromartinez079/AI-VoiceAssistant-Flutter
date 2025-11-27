/*
To Do:
  - Add temperature: Slider widget
*/

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
  String? _selectedLanguage;
  String? _selectedVoice;
  final _promptController = TextEditingController();

  List<String>? _modelsOpenAI;
  List<String>? _modelsXAI;

  void _onSelectModel(value) {
    setState(() {
      _selectedModel = value;
    });
  }

  void _onSelectLanguage(value) {
    setState(() {
      _selectedLanguage = value;
    });
    _getVoices();
  }

  void _onSelectVoice(value) {
    setState(() {
      _selectedVoice = value;
    });
  }

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

    setState(() {
      _voices = [];
      _voices = voicesList;
    });

    setState(() {
      _selectedVoice = null;
    });
  }

  void _saveSettings() async {
    final settings = ref.read(settingsProvider.notifier);
    final prefs = await SharedPreferences.getInstance();
    
    if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      _selectedLanguage = settings.getLanguage();
    }
    if (_selectedVoice == null || _selectedVoice!.isEmpty) {
      _selectedVoice = settings.getVoice();
    }
    if (_selectedModel == null || _selectedModel!.isEmpty) {
      _selectedModel == settings.getModel();
    }
    if (_promptController.text.isEmpty) { return; }

    settings.setSettings(Settings(
      language: _selectedLanguage!,
      voice: _selectedVoice!,
      model: _selectedModel!,
      prompt: _promptController.text,
    ));

    try {
      prefs.setString('language', _selectedLanguage!);
      prefs.setString('voice', _selectedVoice!);
      prefs.setString('model', _selectedModel!);
      prefs.setString('prompt', _promptController.text);
      widget.updateInitialPrompt(_promptController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(e.toString()),
        ),
      );
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Settings saved.'),
        ),
      );
    }    
  }
  
  @override
  void initState() {    
    setState(() {
      _languages = [
        'es-ES', 'es-US', 'pt-BR', 'pt-PT',
        'en-AU','en-US', 'en-GB', 'en-IN',
        'de-DE', 'fr-CA','fr-FR', 'it-IT', 'nl-NL', 'nl-BE','pl-PL',       
        'ja-JP', 'ko-KR',       
        'zh-TW', 'zh-CN', 'ru-RU',
      ];
      _modelsOpenAI = ['gpt-5.1','gpt-5','gpt-5-mini','gpt-5-nano','gpt-4.1',
        'gpt-4.1-mini','gpt-4.1-nano'];
      _modelsXAI = ['grok-4-1-fast-reasoning','grok-4-1-fast-non-reasoning',
        'grok-4-1-fast', 'grok-4-fast-reasoning','grok-4-fast-non-reasoning',
        'grok-4'];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(settingsProvider).prompt;
    _promptController.text = prompt;
    final aiService = ref.watch(apiKeyProvider).ai;
    if (aiService == 'xai') { _models = _modelsXAI; }
    else { _models = _modelsOpenAI; }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 20,),              
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
    );
  }
}

/*
      _languages = [
        'es-ES', 'es-US', 'pt-BR', 'pt-PT',
        'en-AU','en-US', 'en-GB', 'en-IN', 'en-NG',
        'de-DE', 'fr-CA','fr-FR', 'it-IT', 'nl-NL', 'nl-BE','pl-PL',       
        'ja-JP', 'ko-KR',       
        'zh-TW', 'zh-CN', 'ru-RU',
      ]; 
  */