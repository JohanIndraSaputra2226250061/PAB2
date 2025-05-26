import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> searchHistory = ['Gending Sriwijaya', 'Rumah Honai'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _removeSearchItem(String item) {
    setState(() {
      searchHistory.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar dengan Back Button di samping
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search Bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              if (!searchHistory.contains(value)) {
                                searchHistory.add(value);
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search History
            if (searchHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: searchHistory.map((query) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              query,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeSearchItem(query),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  ).toList(),
                ),
              ),
            
            // Search Results
            Expanded(
              child: _searchController.text.isEmpty
                  ? Container() // Jika search kosong, tampilkan container kosong
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('cultures').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading data',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No cultures found',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }

                        final cultures = snapshot.data!.docs
                            .map((doc) => Culture.fromFirestore(doc))
                            .where((culture) =>
                                culture.title.toLowerCase().contains(_searchController.text.toLowerCase()))
                            .toList();

                        if (cultures.isEmpty) {
                          return Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: cultures.length,
                          itemBuilder: (context, index) {
                            final culture = cultures[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/detail',
                                  arguments: culture,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          culture.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              culture.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              culture.category,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
