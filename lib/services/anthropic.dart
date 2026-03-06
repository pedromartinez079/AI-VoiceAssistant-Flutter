import 'dart:convert';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

Future<String> messageRequest(
  List<Message> messagesList, String ai, 
  String apikey, String aiModel, double temperature
) async {
  Model? model;

  if (aiModel.isEmpty || aiModel == '') {
    model = Model.modelId('claude-haiku-4-5');
  } else { model = Model.modelId(aiModel); }

  if (temperature > 1) { temperature = 1; }

  final client = AnthropicClient(apiKey: apikey);

  try {
    final request = CreateMessageRequest(
      model: model,
      maxTokens: 1024,
      temperature: temperature,
      messages: messagesList,
    );
    final response = await client.createMessage(request: request,);
    return response.content.text;
  } catch (e) {
    if (e is AnthropicClientException) {
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


Future<bool> checkApiKeyAnthropic(String apiKey, Function setInformation) 
  async {
    
  final client = AnthropicClient(apiKey: apiKey);

  try {
    final models = await client.listModels();
    setInformation('Api Key Ok.\n\nModels in this API: ${models.data.length}');
    client.endSession();
    return true;
  } catch (e) {      
    if (e is AnthropicClientException) {
      setInformation(e.body.toString());
    }
    client.endSession();
    return false;
  }
}


// messageList = [{'role': 'user', 'content': 'query'},...]
List<Message> messageListAnthropic(messageList) {
  List<Message> messages = [];
  for (dynamic m in messageList) {
    if (m['role'] == 'user') {
      messages.add(Message(
        role: MessageRole.user,
        content: MessageContent.text(m['content']),
      ));
    }
    else if (m['role'] == 'assistant') {
      messages.add(Message(
        role: MessageRole.assistant,
        content: MessageContent.text(m['content']),
      ));
    }
    else {}
  }
  return messages;
}