import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert'; // To decode JSON



void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Guess Game',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
      ],
      locale: _locale, // Locale from state
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedLanguage = 'en'; // Default language
  List<String> wordPool = [];

  final TextEditingController _textController = TextEditingController();
  String hiddenWord = "";
  String displayWord = "";
  List<String> userGuesses = [];
  int remainingAttempts = 6;

  @override
  void initState() {
    super.initState();
    _loadWords(selectedLanguage).then((_) {
      _resetGame();
    });
  }

  // Load words based on selected language from JSON file
  Future<void> _loadWords(String language) async {
    final String wordJsonString = await rootBundle.loadString('assets/words_$language.json');
    final Map<String, dynamic> jsonData = jsonDecode(wordJsonString);
    setState(() {
      wordPool = List<String>.from(jsonData['words']);
    });
  }

  String formatDisplayWord(String word) {
    return word.split('').join(' ');
  }

  void checkGuess(String guess) {
    setState(() {
      String newDisplay = "";
      for (int i = 0; i < hiddenWord.length; i++) {
        if (guess.length > i && guess[i] == hiddenWord[i]) {
          newDisplay += hiddenWord[i];
        } else if (displayWord.replaceAll(' ', '')[i] != '_') {
          newDisplay += displayWord.replaceAll(' ', '')[i];
        } else {
          newDisplay += "_";
        }
      }
      displayWord = formatDisplayWord(newDisplay);
      userGuesses.add(guess);
      remainingAttempts--;

      if (displayWord.replaceAll(' ', '') == hiddenWord) {
        _showResultDialog(AppLocalizations.of(context)!.congratsMessage);
      } else if (remainingAttempts == 0) {
        _showResultDialog(AppLocalizations.of(context)!.failureMessage(hiddenWord));
      }
    });
  }

  void _showResultDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.gameOver),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text(AppLocalizations.of(context)!.playAgain),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      hiddenWord = wordPool.isNotEmpty ? wordPool[Random().nextInt(wordPool.length)] : '';
      displayWord = formatDisplayWord("_" * hiddenWord.length);
      userGuesses.clear();
      remainingAttempts = 6;
      _textController.clear();
    });
  }

  // Moved _getAllowedCharacters() here
  String _getAllowedCharacters(String language) {
    if (language == 'tr') {
      // Allow Turkish characters and lowercase Latin letters
      return r'[a-zA-ZşŞıİçÇğĞüÜöÖ]';
    } else {
      // Default to English, allow only Latin characters
      return r'[a-zA-Z]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title),
      ),
      body: Center(
        child: wordPool.isEmpty
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Language selection dropdown
                  DropdownButton<String>(
                    value: selectedLanguage,
                    onChanged: (String? newLanguage) {
                      if (newLanguage != null) {
                        setState(() {
                          selectedLanguage = newLanguage;
                          MyApp.setLocale(context, Locale(newLanguage));
                          _loadWords(selectedLanguage).then((_) {
                            _resetGame();
                          });
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'tr', child: Text('Turkish')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.guessTheWord(displayWord),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.enterGuess,
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      // Apply regex pattern based on selected language
                      FilteringTextInputFormatter.allow(RegExp(_getAllowedCharacters(selectedLanguage))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_textController.text.isNotEmpty) {
                        checkGuess(_textController.text);
                        _textController.clear();
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.enterGuess),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.remainingAttempts(remainingAttempts)),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.yourGuesses(userGuesses.join(", "))),
                ],
              ),
      ),
    );
  }
}
