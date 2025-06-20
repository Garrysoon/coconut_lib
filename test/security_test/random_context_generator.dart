import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

Future<String> fetchRandomWords() async {
  final uri = Uri.parse('https://random-word-api.herokuapp.com/word?number=5');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> words = jsonDecode(response.body);
      return words[0];
    }
  } catch (e) {
    print('❗ 네트워크 오류: $e');
  }
  return "";
}

Future<String> fetchRandomQuote() async {
  final uri = Uri.parse('https://api.quotable.kurokeita.dev/api/quotes/random');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['quote'];
      return data["content"];
    }
  } catch (e) {
    print('❗ 오류: $e');
  }
  return "";
}

Future<String> getRandomContext() async {
  String context = "";
  if (Random().nextBool()) {
    context = await fetchRandomWords();
  } else {
    context = await fetchRandomQuote();
  }
  return context;
}
