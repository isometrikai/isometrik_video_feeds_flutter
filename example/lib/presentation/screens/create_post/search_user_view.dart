import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player_example/example_export.dart';

class SearchUserView extends StatefulWidget {
  @override
  _SearchUserViewState createState() => _SearchUserViewState();
}

class _SearchUserViewState extends State<SearchUserView> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];
  late AnimationController _loadingAnimationController;
  late AnimationController _resultsAnimationController;

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _resultsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _loadingAnimationController.dispose();
    _resultsAnimationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    _loadingAnimationController.repeat();

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _loadingAnimationController.stop();
        setState(() {
          _isSearching = false;
          _searchResults = _getMockResults(query);
        });
        _resultsAnimationController.forward();
      }
    });
  }

  List<SearchResult> _getMockResults(String query) {
    // Mock data based on your images
    if (query.toLowerCase().contains('cool')) {
      return [
        SearchResult(
          username: 'cookininshort',
          displayName: 'cookininshort',
          avatarUrl: null,
          isVerified: false,
        ),
        SearchResult(
          username: 'coolguy_swaroop',
          displayName: 'swaroop',
          avatarUrl: null,
          isVerified: false,
        ),
        SearchResult(
          username: 'cool_services',
          displayName: 'COOL SERVICE',
          avatarUrl: null,
          isVerified: false,
        ),
        SearchResult(
          username: 'that_cool_dude_sunil',
          displayName: 'Sunil',
          avatarUrl: null,
          isVerified: false,
        ),
        SearchResult(
          username: 'cookwithparul',
          displayName: 'Cook with Parul (ChefParulGupta)',
          avatarUrl: null,
          isVerified: true,
        ),
        SearchResult(
          username: 'cool_dude_2405',
          displayName: 'cool_dude_2405',
          avatarUrl: null,
          isVerified: false,
        ),
        SearchResult(
          username: 'cook_with_ashura',
          displayName: 'Ashura Sadiq',
          avatarUrl: null,
          isVerified: false,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF8F9FA),
          leadingWidth: 20,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          actions: [
            TapHandler(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (_isSearching) _buildLoadingIndicator(),
            Expanded(
              child: _searchResults.isEmpty && !_isSearching
                  ? _buildEmptyState()
                  : _buildSearchResults(),
            ),
          ],
        ),
      );

  Widget _buildLoadingIndicator() => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _loadingAnimationController,
              builder: (context, child) => Transform.rotate(
                angle: _loadingAnimationController.value * 2 * 3.14159,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Searching for "${_searchController.text}"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Start typing to search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchResults() => AnimatedBuilder(
        animation: _resultsAnimationController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - _resultsAnimationController.value)),
          child: Opacity(
            opacity: _resultsAnimationController.value,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return _buildSearchResultItem(result, index);
              },
            ),
          ),
        ),
      );

  Widget _buildSearchResultItem(SearchResult result, int index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.applyOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: _getAvatarColor(index),
            child: result.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      result.avatarUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    result.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  result.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (result.isVerified)
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 20,
                ),
            ],
          ),
          subtitle: Text(
            result.displayName,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          onTap: () {
            // Handle tap
            debugPrint('Tapped on ${result.username}');
          },
        ),
      );

  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }
}

class SearchResult {
  SearchResult({
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
}
