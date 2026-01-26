import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/models/social_models.dart';
import 'package:villen_music/services/api_service.dart';

class ArtistSelectionScreen extends StatefulWidget {
  const ArtistSelectionScreen({super.key});

  @override
  State<ArtistSelectionScreen> createState() => _ArtistSelectionScreenState();
}

class _ArtistSelectionScreenState extends State<ArtistSelectionScreen> {
  List<Artist> _artists = [];
  final Set<String> _selectedArtistIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final api = context.read<ApiService>();
    try {
      final artists = await api.getSuggestedArtists();
      
      // Also fetch currently followed to pre-select?
      // For now, let's keep it clean as "Choose more artists"
      
      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedArtistIds.isEmpty) {
        Navigator.pop(context);
        return;
    }

    setState(() {
      _isSaving = true;
    });

    final api = context.read<ApiService>();
    int successCount = 0;

    // Parallel requests for speed
    await Future.wait(_selectedArtistIds.map((id) async {
       final artist = _artists.firstWhere((a) => a.id == id);
       final success = await api.followArtist(artist.id, artist.name, artist.image);
       if (success) successCount++;
    }));

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Followed $successCount artists. Your feed will be updated!'))
       );
       Navigator.pop(context, true); // Return true to indicate refresh needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Choose more artists you like.', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
          maxLines: 2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                hintStyle: const TextStyle(color: Colors.black54),
              ),
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                // Determine if we should filter client side or server side
                // Current flow just filters the fetched list for simplicity
              },
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _artists.length,
                  itemBuilder: (context, index) {
                    final artist = _artists[index];
                    final isSelected = _selectedArtistIds.contains(artist.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedArtistIds.remove(artist.id);
                          } else {
                            _selectedArtistIds.add(artist.id);
                          }
                        });
                      },
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: artist.image != null 
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(artist.image!),
                                        fit: BoxFit.cover,
                                        colorFilter: isSelected ? ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken) : null
                                      )
                                    : null,
                                  color: Colors.grey[800],
                                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                ),
                                child: artist.image == null ? const Icon(Icons.person, size: 40, color: Colors.white54) : null,
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.white, size: 40),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
          if (_selectedArtistIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: _isSaving 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                     : const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
