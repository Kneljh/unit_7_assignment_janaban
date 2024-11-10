import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';

class CombatStyle {
  final String name;
  final String img;
  final String description;
  final List<dynamic> characters;

  CombatStyle({
    required this.name,
    required this.img,
    required this.description,
    required this.characters,
  });

  factory CombatStyle.fromJson(Map<String, dynamic> json) {
    return CombatStyle(
      name: json['name'],
      img: json['img'] ?? '', // Handle missing image URL
      description: json['description'] ?? 'No description available',
      characters: json['combat_style_character'] ?? [],
    );
  }
}

Future<List<CombatStyle>> fetchDemonSlayer() async {
  try {
    final response = await http.get(Uri.parse(
        'https://cors.bridged.cc/https://www.demonslayer-api.com/api/v1/combat-styles'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['content'];
      return data.map((json) => CombatStyle.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load data: $e');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<CombatStyle>> futureCombatStyles;

  @override
  void initState() {
    super.initState();
    futureCombatStyles = fetchDemonSlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demon Slayer Combat Styles"),
      ),
      body: FutureBuilder<List<CombatStyle>>(
        future: futureCombatStyles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var style = snapshot.data![index];
                final controller = ExpandedTileController();

                return ExpandedTile(
                  controller: controller,
                  title: Text(style.name),
                  leading: style.img.isNotEmpty
                      ? Image.network(
                          style.img,
                          width: 50,
                          height: 50,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, size: 50);
                          },
                        )
                      : Icon(Icons.image_not_supported, size: 50),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(style.description),
                      const SizedBox(height: 10),
                      if (style.characters.isNotEmpty)
                        ...style.characters.map((character) {
                          String characterName =
                              character['name'] ?? 'No name available';
                          String characterDescription =
                              character['description'] ??
                                  'No description available';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              title: Text(characterName),
                              subtitle: Text(characterDescription),
                            ),
                          );
                        }).toList(),
                    ],
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
