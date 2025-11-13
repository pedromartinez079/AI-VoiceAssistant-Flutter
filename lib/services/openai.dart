
import 'package:openai_dart/openai_dart.dart';

Future<String> processQuery(
  List<ChatCompletionMessage> messagesList, String ai, 
  String apikey, Function setStatusText) async { 
    String? baseUrl;
    ChatCompletionModel model = ChatCompletionModel.modelId('');

    if (ai == 'openai') { 
      baseUrl = 'https://api.openai.com/v1'; 
      model = ChatCompletionModel.modelId('gpt-4.1');
    }
    if (ai == 'xai') { 
      baseUrl = 'https://api.x.ai/v1'; 
      model = ChatCompletionModel.modelId('grok-4');
    }

    final client = OpenAIClient(
       apiKey: apikey,
       baseUrl: baseUrl,
    );

    try {      
      final messages = messagesList;
      final request = CreateChatCompletionRequest(
        model: model, messages: messages, temperature: 0.75);
      final response = await client.createChatCompletion(
        request: request,
      );
      // message > role: ChatCompletionMessageRole.assistant, content: String
      return response.choices[0].message.content!;
    } catch(e) {
      if (e is OpenAIClientException) {
        setStatusText(e.body.toString());      
      }      
      return 'Answer from $ai failed.';
    } finally { client.endSession(); }
}