import 'package:flutter/material.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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
      name: json['name'] ?? 'No name available',
      img: json['img'] ?? '',
      description: json['description'] ?? 'No description available',
      characters: json['combat_style_character'] ?? [],
    );
  }
}


Future<List<CombatStyle>> fetchDemonSlayer() async {
  try {
    final response = await http.get(
      Uri.parse(
          'https://cors.bridged.cc/https://www.demonslayer-api.com/api/v1/combat-styles'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['content'];
      return data.map((json) => CombatStyle.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch data: $e');
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
        title: const Text("Unit 7 - API Calls"),
      ),
      body: FutureBuilder<List<CombatStyle>>(
        future: futureCombatStyles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
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
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        )
                      : const Icon(Icons.image_not_supported),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(style.description),
                      const SizedBox(height: 10),
                      ...style.characters.map((character) {
                        String characterName =
                            character['name'] ?? 'No name available';
                        String characterDescription =
                            character['description'] ??
                                'No description available';
                        return ListTile(
                          title: Text(characterName),
                          subtitle: Text(characterDescription),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text('No data available'),
            );
          }
        },
      ),
    );
  }
}
