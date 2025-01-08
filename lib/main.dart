import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Модели
class Joke {
  final int id;
  final String type;
  final String setup;
  final String punchline;
  bool isFavorite;

  Joke({
    required this.id,
    required this.type,
    required this.setup,
    required this.punchline,
    this.isFavorite = false,
  });

  factory Joke.fromJson(Map<String, dynamic> json) {
    return Joke(
      id: json['id'],
      type: json['type'],
      setup: json['setup'],
      punchline: json['punchline'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

class JokeType {
  final String type;

  JokeType({required this.type});

  factory JokeType.fromJson(String type) {
    return JokeType(type: type);
  }
}

// API Service
class ApiService {
  static const String baseUrl = "https://official-joke-api.appspot.com";

  static Future<List<JokeType>> fetchJokeTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/types'));
    if (response.statusCode == 200) {
      List<String> types = List<String>.from(json.decode(response.body));
      return types.map((type) => JokeType(type: type)).toList();
    } else {
      throw Exception("Failed to load joke types");
    }
  }

  static Future<List<Joke>> fetchJokesByType(String type) async {
    final response = await http.get(Uri.parse('$baseUrl/jokes/$type/ten'));
    if (response.statusCode == 200) {
      List<dynamic> jokes = json.decode(response.body);
      return jokes.map((joke) => Joke.fromJson(joke)).toList();
    } else {
      throw Exception("Failed to load jokes of type $type");
    }
  }

  static Future<Joke> fetchRandomJoke() async {
    final response = await http.get(Uri.parse('$baseUrl/random_joke'));
    if (response.statusCode == 200) {
      return Joke.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load random joke");
    }
  }
}

// Главно
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jokes App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

// Почетен екран: Листа на типови шеги
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  get jokes => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Joke Types 213029'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoriteJokesScreen(
                    favoriteJokes: jokes.where((joke) => joke.isFavorite).toList(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RandomJokeScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<JokeType>>(
        future: ApiService.fetchJokeTypes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final jokeTypes = snapshot.data!;
            return ListView.builder(
              itemCount: jokeTypes.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(jokeTypes[index].type),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JokeTypeScreen(type: jokeTypes[index].type),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Екран: Листа на шеги по тип
class JokeTypeScreen extends StatelessWidget {
  final String type;

  const JokeTypeScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$type Jokes')),
      body: FutureBuilder<List<Joke>>(
        future: ApiService.fetchJokesByType(type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final jokes = snapshot.data!;
            return ListView.builder(
              itemCount: jokes.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(jokes[index].setup),
                    subtitle: Text(jokes[index].punchline),
                    trailing: IconButton(
                      icon: Icon(
                        jokes[index].isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: jokes[index].isFavorite ? Colors.red : null,
                      ),
                      onPressed: () {
                        jokes[index].isFavorite = !jokes[index].isFavorite;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Екран: Рандом шега
class RandomJokeScreen extends StatelessWidget {
  const RandomJokeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Random Joke')),
      body: FutureBuilder<Joke>(
        future: ApiService.fetchRandomJoke(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final joke = snapshot.data!;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(joke.setup, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(joke.punchline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// Екран: Омилени шеги
class FavoriteJokesScreen extends StatelessWidget {
  final List<Joke> favoriteJokes;

  const FavoriteJokesScreen({super.key, required this.favoriteJokes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Jokes')),
      body: favoriteJokes.isEmpty
          ? const Center(child: Text('No favorite jokes yet!'))
          : ListView.builder(
        itemCount: favoriteJokes.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(favoriteJokes[index].setup),
              subtitle: Text(favoriteJokes[index].punchline),
            ),
          );
        },
      ),
    );
  }
}
