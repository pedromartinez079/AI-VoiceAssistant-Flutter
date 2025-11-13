// Set app configuration
// Scaffold > Expanded > Column
// Language : DropdownButtonFormField
// Voice : DropdownButtonFormField
// Initial prompt : TextField
// Save Settings : ElevatedButton

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ai_voice_assistant/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {  
  List<String>? _languages;
  List<String> _voices = [];
  String? _selectedLanguage;
  String? _selectedVoice;
  final _promptController = TextEditingController();

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
      (v) => v["locale"] == _selectedLanguage && v["network_required"] == "0"
      //(v) => v["network_required"] == "0"
    );
    print(filteredVoices.length);
    
    List<String> voicesList = [];
    for (var v in filteredVoices) {
      //if (v['locale'].substring(0,2) == 'zh') print('\n' + v['locale'].toString());
      voicesList.add(v['name']);
      //print('\n' + v['locale'].toString());
    }

    setState(() {
      _voices = [];
      _voices = voicesList;
    });

    setState(() {
      _selectedVoice = null;
    });
  }

  void _saveSettings() {
    final settings = ref.read(settingsProvider.notifier);
    settings.setSettings(Settings(
      language: _selectedLanguage!,
      voice: _selectedVoice!,
      prompt: _promptController.text,
    ));
  }

  @override
  void initState() {
    setState(() {
      _languages = [
        'es-ES', 'es-US', 'pt-BR', 'pt-PT',
        'en-AU','en-US', 'en-GB', 'en-IN', 'en-NG',
        'de-DE', 'fr-CA','fr-FR', 'it-IT', 'nl-NL', 'nl-BE','pl-PL',       
        'ja-JP', 'ko-KR',       
        'zh-TW', 'zh-CN', 'ru-RU',
      ];      
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(settingsProvider).prompt;
    _promptController.text = prompt;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
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
    );
  }
}

/*final List<String> _languages = [
    'es-ES',
    'en-US',
    'fr-FR',
    'pt-BR',
    'de-DE',
    'ja-JP',
    'zh-CN',
  ];
  final List<String> _voices = [
    'es-PE-CamilaNeural',
    'es-PE-AlexNeural',
    'es-US-PalomaNeural',
    'es-US-AlonsoNeural',
    'es-AR-ElenaNeural',
    'es-CO-SalomeNeural',
    'es-ES-ElviraNeural',
    'es-MX-DaliaNeural',
    'es-VE-PaolaNeural',
    'en-US-AvaMultilingualNeural',
    'en-US-EmmaMultilingualNeural',
    'en-US-AndrewMultilingualNeural',
    'en-US-BrianMultilingualNeural',
  ];*/