import 'dart:convert';

import 'package:openai_dart/openai_dart.dart';

Future<String> chatCompletionRequest(
  List<ChatCompletionMessage> messagesList, String ai, 
  String apikey, String aiModel, double temperature
) async { 
    String? baseUrl;
    ChatCompletionModel? model;

    if (ai == 'openai') { 
      baseUrl = 'https://api.openai.com/v1'; 
      if (aiModel.isEmpty || aiModel == '') {
        model = ChatCompletionModel.modelId('gpt-4.1');
      } else { model = ChatCompletionModel.modelId(aiModel); }
    } else if (ai == 'xai') { 
      baseUrl = 'https://api.x.ai/v1';
      if (aiModel.isEmpty || aiModel == '') {
        model = ChatCompletionModel.modelId('grok-4-fast-reasoning');
      } else { model = ChatCompletionModel.modelId(aiModel); }
    } else {
      return 'Unknown AI service';
    }

    if (['gpt-5', 'gpt-5-mini', 'gpt-5-nano'].contains(aiModel)) { 
      temperature = 1; 
    }

    final client = OpenAIClient(
       apiKey: apikey,
       baseUrl: baseUrl,
    );

    try {      
      final request = CreateChatCompletionRequest(
        model: model, messages: messagesList, temperature: temperature);
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


Future<bool> checkApiKeyOpenai(String ai, String apiKey, 
  Function setInformation) async {

  String? baseUrl;

  if (ai == 'openai') { 
    baseUrl = 'https://api.openai.com/v1';
  } else if (ai == 'xai') {
    baseUrl = 'https://api.x.ai/v1';
  } else { 
    setInformation('AI service not known.');
    return false; 
  }

  final client = OpenAIClient(
    apiKey: apiKey,
    baseUrl: baseUrl,
  );
  try {
    final models = await client.listModels();
    setInformation('Api Key Ok.\n\nModels in this API: ${models.data.length}');
    client.endSession();
    return true;
  } catch (e) {      
    if (e is OpenAIClientException) {
      setInformation(e.body.toString());
    }
    client.endSession();
    return false;
  }
}


// messageList = [{'role': 'user', 'content': 'query'},...]
List<ChatCompletionMessage> messageListOpenai(messageList) {
  List<ChatCompletionMessage> messages = [];
  for (dynamic m in messageList) {
    if (m['role'] == 'user') {
      messages.add(ChatCompletionMessage.user(
        role: ChatCompletionMessageRole.user,
        content: ChatCompletionUserMessageContent.string(m['content']),
      ));
    }
    else if (m['role'] == 'assistant') {
      messages.add(ChatCompletionMessage.assistant(
        role: ChatCompletionMessageRole.assistant,
        content: m['content'],
      ));
    }
    else {}
  }
  return messages;
}