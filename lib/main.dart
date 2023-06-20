import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import 'database_helper.dart';
import 'favorites_page.dart';

const String APIKey = 'LIVDSRZULELA';
const String searchEndpoint = 'https://g.tenor.com/v1/search';
const String autocompleteEndpoint = 'https://g.tenor.com/v1/autocomplete';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenor Pictures',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: GifSearchHomePage(),
      routes: {
        FavoritesPage.routeName: (context) => FavoritesPage(),
      },
    );
  }
}

class GifSearchHomePage extends StatefulWidget {
  @override
  _GifSearchHomePageState createState() => _GifSearchHomePageState();
}

class _GifSearchHomePageState extends State<GifSearchHomePage> {
  List<String> suggestions = [];
  List<dynamic> gifs = [];
  String? nextPos;
  bool _showSuggestions = true;

  TextEditingController _searchController = TextEditingController();

  Future<void> searchGifs(String query, {String? pos}) async {
    final url =
        'https://g.tenor.com/v1/search?q=$query&key=$APIKey&limit=8${pos != null ? '&pos=$pos' : ''}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'];

      setState(() {
        if (pos == null) {
          gifs = results;
        } else {
          gifs.insertAll(
              0, results); // Add new GIFs to the beginning of the list
        }
        nextPos = data['next'];
      });
      print('I will print details here: $gifs *the END  OF PRINT');
    } else {
      print('Error searching GIFs: ${response.statusCode}');
    }
  }

  void autocompleteSearch(String query) async {
    final url = '$autocompleteEndpoint?q=$query&key=$APIKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        suggestions = List<String>.from(data['results']);
      });
    } else {
      print(
          'Error retrieving autocomplete suggestions: ${response.statusCode}');
    }
  }

  void addToFavorites(Map<String, dynamic> gif) async {
    Map<String, dynamic> favGif = {};
    favGif['id'] = gif['id'];
    favGif['gif_url'] = gif['media'][0]['gif']['url'];
    favGif['tinygif_url'] = gif['media'][0]['tinygif']['url'];
    print("What is in favgif: $favGif");
    await DatabaseHelper.saveFavoriteGif(favGif);
    setState(() {
      gif['isFavorite'] = true;
    });
  }

  void removeFromFavorites(Map<String, dynamic> gif) async {
    final String id = gif['id'];
    await DatabaseHelper.deleteFavoriteGif(id);
    setState(() {
      gif['isFavorite'] = false;
    });
  }

  Future<bool> isFavorite(String id) async {
    final List<Map<String, dynamic>> favoriteGifs =
        await DatabaseHelper.getFavoriteGifs();
    return favoriteGifs.any((gif) => gif['id'] == id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenor Pictures'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  autocompleteSearch(value);
                } else {
                  setState(() {
                    suggestions = [];
                  });
                }
              },
              onSubmitted: (value) {
                setState(() {
                  _showSuggestions = false;
                });
                searchGifs(value);
              },
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showSuggestions = false;
                    });
                    searchGifs(_searchController.text);
                  },
                ),
              ),
            ),
          ),
          _showSuggestions && suggestions.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        title: Text(suggestion),
                        onTap: () {
                          setState(() {
                            _showSuggestions = false;
                          });
                          _searchController.text = suggestion;
                          searchGifs(suggestion);
                        },
                      );
                    },
                  ),
                )
              : SizedBox(),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: gifs.length,
              itemBuilder: (context, index) {
                final gif = gifs[index];
                final previewUrl = gif['media'][0]['tinygif']['url'];
                final fullScreenUrl = gif['media'][0]['gif']['url'];
                final isFavorite = gif['isFavorite'] ?? false;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullSizeImagePage(imageUrl: fullScreenUrl),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: previewUrl,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 30.0,
                          width: double.infinity,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.share),
                                onPressed: () {
                                  Share.share(fullScreenUrl);
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.star : Icons.star_border,
                                  color: isFavorite ? Colors.yellow : null,
                                ),
                                onPressed: () {
                                  if (isFavorite) {
                                    removeFromFavorites(gif);
                                  } else {
                                    addToFavorites(gif);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          nextPos != null
              ? ElevatedButton(
                  child: Text('Load More'),
                  onPressed: () =>
                      searchGifs(_searchController.text, pos: nextPos),
                )
              : SizedBox(),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: Text('Home'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
              ElevatedButton(
                child: Text('Favorites'),
                onPressed: () {
                  Navigator.pushNamed(context, FavoritesPage.routeName);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FullSizeImagePage extends StatelessWidget {
  final String imageUrl;

  FullSizeImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }
}
