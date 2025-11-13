import 'package:flutter/material.dart';

class UI extends StatefulWidget {
  const UI({super.key});

  @override
  State<UI> createState() => _UIState();
}

enum AppRunState { stopped, running, paused }

class _UIState extends State<UI> {
  // Controllers
  final _apiKeyController = TextEditingController();
  final _conversationController = TextEditingController();

  // State
  bool _obscureApiKey = true;
  String? _selectedAi; // 'openai', 'xai'
  String? _selectedLanguage; // 'es-ES', 'en-US', ...
  String? _selectedVoice; // The voice list
  String _statusText = 'Estados de la aplicación';
  AppRunState _runState = AppRunState.stopped;

  // Data
  final List<String> _ais = ['openai', 'xai'];
  final List<String> _languages = [
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
  ];

  // Actions
  void checkApikey() {
    final key = _apiKeyController.text.trim();
    setState(() {
      if (key.isEmpty) {
        _statusText = 'Ingrese una API key válida';
      } else {
        _statusText = 'API key establecida';
      }
    });
  }

  void onAiSelect(String? value) {
    setState(() {
      _selectedAi = value;
      _statusText = 'IA seleccionada: ${_selectedAi ?? ''}';
    });
  }

  void onLanguageSelect(String? value) {
    setState(() {
      _selectedLanguage = value;
      _statusText = 'Idioma seleccionado: ${_selectedLanguage ?? ''}';
    });
  }

  void onVoiceSelect(String? value) {
    setState(() {
      _selectedVoice = value;
      _statusText = 'Voz seleccionada: ${_selectedVoice ?? ''}';
    });
  }

  void togglePause() {
    setState(() {
      switch (_runState) {
        case AppRunState.stopped:
          _runState = AppRunState.running;
          _statusText = 'Ejecutando...';
          break;
        case AppRunState.running:
          _runState = AppRunState.paused;
          _statusText = 'Pausado';
          break;
        case AppRunState.paused:
          _runState = AppRunState.running;
          _statusText = 'Continuando...';
          break;
      }
    });
  }

  String get _mainButtonText {
    switch (_runState) {
      case AppRunState.stopped:
        return 'Inicio';
      case AppRunState.running:
        return 'Pausar';
      case AppRunState.paused:
        return 'Continuar';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _conversationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Top controls proportion (0.4, 0.1, 0.1, 0.1, 0.3)
    // Use Expanded with flex [4, 1, 1, 1, 3]
    return Scaffold(
      appBar: AppBar(title: const Text('IA Asistente de Voz')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Top controls bar
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          labelText: 'Ingrese IA API Key',
                          border: const OutlineInputBorder(),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: checkApikey,
                          child: const Text('API Key'),
                        ),
                      ),
                    ),                    
                  ],
                ),
              ),

              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [                    
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedAi,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'IA',
                        ),
                        items: _ais
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: onAiSelect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Idioma',
                        ),
                        items: _languages
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: onLanguageSelect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVoice,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Selecciona voz',
                        ),
                        items: _voices
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: onVoiceSelect,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status label area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 20),
                ),
              ),

              const SizedBox(height: 12),

              // Conversation TextInput (multiline)
              Expanded(
                child: TextField(
                  controller: _conversationController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Conversación...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Start/Pause/Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: togglePause,
                  child: Text(
                    _mainButtonText,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}