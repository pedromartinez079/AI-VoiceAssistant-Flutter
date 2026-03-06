import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_voice_assistant/providers/settings_provider.dart';
import 'package:ai_voice_assistant/screens/assistant.dart';
import 'package:ai_voice_assistant/services/ai_router.dart';

class SetApiKeyScreen extends ConsumerStatefulWidget {
  const SetApiKeyScreen({super.key});

  @override
  ConsumerState<SetApiKeyScreen> createState() {
    return _SetApiKeyScreenState();
  }
}

class _SetApiKeyScreenState extends ConsumerState<SetApiKeyScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  String? _selectedAi;
  final List<String> _aiServices = ['anthropic', 'openai', 'xai'];
  final _informationController = TextEditingController();

  // Save AI Service and Api Key
  Future<void> storeapikey(AiAuth aiauth) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      await prefs.setString('ai', aiauth.ai);
      await prefs.setString('apikey', aiauth.apikey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text('AI Service & Api Key saved.'),
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

  // Method for Set Api Key button
  void _saveApiKey() async {
    bool? isApiKeyOk;
    final apiKey = _apiKeyController.text;
    final aiService = _selectedAi;
    
    if (apiKey.isEmpty || _selectedAi == null) {
      return;
    }

    // Check if apikey is valid (ai_router.dart)
    isApiKeyOk = await checkApiKey(_selectedAi!, apiKey, _setInformationController);
    
    // Set data in provider & save if api key is valid, if not return
    if (!isApiKeyOk) { return; }
    
    ref.read(apiKeyProvider.notifier)
      .setApiKey(AiAuth(ai: aiService!, apikey: apiKey));

    storeapikey(AiAuth(ai: aiService, apikey: apiKey));
    
    // Wait and go to Assistant screen
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const AiAssistantScreen(),
      )
    );
  }

  _setInformationController(String s) {
    setState(() {
      _informationController.text = s;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _informationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Api Key'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: 'Api Key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey
                      ? Icons.visibility
                      : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureApiKey = !_obscureApiKey);
                    },
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height:40),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAi,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'AI Cloud or Service',
                      ),
                      items: _aiServices
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      onChanged: (value) { _selectedAi = value; }, //onAiSelect,
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveApiKey,
                      icon: const Icon(Icons.key),
                      label: const Text('Set Api Key'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height:40),
              TextField(
                controller: _informationController,
                readOnly: true,
                maxLines: 6,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Information',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}