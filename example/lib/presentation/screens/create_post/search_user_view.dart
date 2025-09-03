import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/example_export.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

class SearchUserView extends StatefulWidget {
  const SearchUserView({super.key, required this.socialUserList});

  final List<SocialUserData> socialUserList;

  @override
  _SearchUserViewState createState() => _SearchUserViewState();
}

class _SearchUserViewState extends State<SearchUserView> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final _searchUserBloc = InjectionUtils.getBloc<SearchUserBloc>();
  final List<SocialUserData> _searchResults = [];
  late AnimationController _loadingAnimationController;
  late AnimationController _resultsAnimationController;
  final Set<SocialUserData> _selectedUsers = {};

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _resultsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _selectedUsers.clear();
    if (widget.socialUserList.isEmptyOrNull == false) {
      _selectedUsers.addAll(widget.socialUserList);
      setState(() {});
    }
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

    final completer = Completer<void>();
    _searchUserBloc.add(SearchUserEvent(
        searchText: query,
        onComplete: (userList) {
          completer.complete();
          _setResult(userList);
        }));
    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 1200), () {});
  }

  void _setResult(List<SocialUserData> userList) {
    if (mounted) {
      _loadingAnimationController.stop();
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _searchResults.addAll(userList);
      });
      _resultsAnimationController.forward();
    }
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
              onTap: () => Navigator.pop(context, _selectedUsers.toList()),
              child: const Text(
                'Done',
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
        body: SafeArea(
          child: Column(
            children: [
              if (_isSearching) _buildLoadingIndicator(),
              Expanded(
                child: _searchResults.isEmpty && !_isSearching
                    ? _buildEmptyState()
                    : _buildSearchResults(),
              ),
            ],
          ),
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

  Widget _buildSearchResultItem(SocialUserData result, int index) {
    final isSelected = _selectedUsers.contains(result);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.applyOpacity(0.1) : Colors.white,
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
        leading: AppImage.network(
          result.avatarUrl ?? '',
          isProfileImage: true,
          height: 30.scaledValue,
          width: 30.scaledValue,
          name: result.fullName ?? '',
        ),
        title: Text(
          result.username ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          result.displayName ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () => _toggleSelection(result),
      ),
    );
  }

  void _toggleSelection(SocialUserData user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }
}
