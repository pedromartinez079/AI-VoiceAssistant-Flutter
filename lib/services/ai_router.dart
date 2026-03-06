
import 'package:ai_voice_assistant/services/openai.dart';
import 'package:ai_voice_assistant/services/anthropic.dart';

Future<String> processQuery(List<dynamic> messagesList, String ai, 
  String apikey, String aiModel, double temperature, 
  Function setStatusText) async { 
  
  dynamic adaptedMessageList;
  String queryAnswer;
  
  if (ai == 'openai' || ai == 'xai') {
    adaptedMessageList = messageListOpenai(messagesList);
    queryAnswer = await chatCompletionRequest(
      adaptedMessageList, ai, apikey, aiModel, temperature,
    );
  } else if (ai == 'anthropic') {
    adaptedMessageList = messageListAnthropic(messagesList);
    queryAnswer = await messageRequest(
      adaptedMessageList, ai, apikey, aiModel, temperature
    );
  } else { queryAnswer = 'AI service not known.'; }

  return queryAnswer;
}

Future<bool> checkApiKey(String ai, String apikey, 
  Function setInformation) async {

  bool? isApiKeyOk;

  if (ai == 'xai' || ai == 'openai') {
    isApiKeyOk = await checkApiKeyOpenai(ai, apikey, setInformation);
  } else if (ai == 'anthropic') {
    isApiKeyOk = await checkApiKeyAnthropic(apikey, setInformation);
  } else { 
    setInformation('AI service not known.');
    isApiKeyOk = false; 
  }
  
  return isApiKeyOk;
}