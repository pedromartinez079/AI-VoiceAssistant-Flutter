import 'dart:convert';

import 'package:openai_dart/openai_dart.dart';

Future<String> processQuery(
  List<ChatCompletionMessage> messagesList, String ai, 
  String apikey, String aiModel, double temperature, Function setStatusText) async { 
    String? baseUrl;
    ChatCompletionModel? model;

    if (ai == 'openai') { 
      baseUrl = 'https://api.openai.com/v1'; 
      if (aiModel.isEmpty || aiModel == '') {
        model = ChatCompletionModel.modelId('gpt-4.1');
      } else { model = ChatCompletionModel.modelId(aiModel); }
    }
    if (ai == 'xai') { 
      baseUrl = 'https://api.x.ai/v1';
      if (aiModel.isEmpty || aiModel == '') {
        model = ChatCompletionModel.modelId('grok-4');
      } else { model = ChatCompletionModel.modelId(aiModel); }
    }
    if (['gpt-5', 'gpt-5-mini', 'gpt-5-nano'].contains(aiModel)) { temperature = 1; }

    final client = OpenAIClient(
       apiKey: apikey,
       baseUrl: baseUrl,
    );

    try {      
      final messages = messagesList;
      final request = CreateChatCompletionRequest(
        model: model!, messages: messages, temperature: temperature);
      final response = await client.createChatCompletion(
        request: request,
      );
      return response.choices[0].message.content!;
    } catch(e) {
      if (e is OpenAIClientException) {
        final body = e.body;
        final parsed = body is String ? jsonDecode(body) : body;
        if (parsed is Map<String, dynamic> &&
          parsed.containsKey('error') &&
          parsed['error'] is Map<String, dynamic> &&
          (parsed['error'] as Map<String, dynamic>).containsKey('message')) {
          return 'Answer from $ai failed. ${parsed["error"]["message"]}';
        }
        else if (parsed is Map<String, dynamic> &&
          parsed.containsKey('error')) {
          return 'Answer from $ai failed. ${parsed["error"]}';
        }
      }      
      return 'Answer from $ai failed. ${e.toString()}';
    } finally { client.endSession(); }
}