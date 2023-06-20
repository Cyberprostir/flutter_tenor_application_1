import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'main.dart';

class FavoritesPage extends StatefulWidget {
  static const String routeName = '/favorites';

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favoriteGifs = [];

  @override
  void initState() {
    super.initState();
    loadFavoriteGifs();
  }

  Future<void> loadFavoriteGifs() async {
    final List<Map<String, dynamic>> gifs =
        await DatabaseHelper.getFavoriteGifs();
    setState(() {
      favoriteGifs = gifs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: ListView.builder(
        itemCount: favoriteGifs.length,
        itemBuilder: (context, index) {
          final gif = favoriteGifs[index];
          final previewUrl = gif['tinygif_url'];
          final fullScreenUrl = gif['gif_url'];

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
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: previewUrl,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 30.0,
                    width: double.infinity,
                    child: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(fullScreenUrl);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
