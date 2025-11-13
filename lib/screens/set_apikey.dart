// Set and Save APIKEY for XAI and or OpenAI
// Verify apikey
// Save apikey in a file, encrypted

import 'package:ai_voice_assistant/providers/settings_provider.dart';
import 'package:ai_voice_assistant/screens/assistant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<String> _aiServices = ['openai', 'xai'];
  final _informationController = TextEditingController();

  Future<bool> checkapikey(String apiKey, String baseUrl) async {
    final client = OpenAIClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
    );

    try {
      final models = await client.listModels();
      setState(() {
        _informationController.text = 'Api Key Ok.\n\n$models.toString()';
      });
      client.endSession();
      return true;
    } catch (e) {      
      if (e is OpenAIClientException) {
        setState(() {
          _informationController.text = e.body.toString();
        });
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text(e.body.toString()),
          ),
        );*/
      }
      client.endSession();
      return false;
    }
  }

  Future<void> storeapikey(AiAuth aiauth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('ai', aiauth.ai);
    await prefs.setString('apikey', aiauth.apikey);
  }

  void _saveApiKey() async {
    bool? isApiKeyOk;
    final apiKey = _apiKeyController.text;
    final aiService = _selectedAi;
    
    if (apiKey.isEmpty || _selectedAi == null) {
      return;
    }

    if (_selectedAi == 'xai') {
      isApiKeyOk = await checkapikey(apiKey, 'https://api.x.ai/v1');
    } else if (_selectedAi == 'openai') {
      isApiKeyOk = await checkapikey(apiKey, 'https://api.openai.com/v1');
    } else { return; }
    
    if (!isApiKeyOk) { return; }

    ref.read(apiKeyProvider.notifier)
      .setApiKey(AiAuth(ai: aiService!, apikey: apiKey));

    storeapikey(AiAuth(ai: aiService, apikey: apiKey));
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const AiAssistantScreen(),
      )
    );
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
      body: SingleChildScrollView(
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
              maxLines: 12,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Information',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}