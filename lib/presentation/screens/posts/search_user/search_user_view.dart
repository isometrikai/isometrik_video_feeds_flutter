import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post/user_mention_text_field.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';

class SearchUserView extends StatefulWidget {
  const SearchUserView({super.key, required this.socialUserList});

  final List<SocialUserData> socialUserList;

  @override
  _SearchUserViewState createState() => _SearchUserViewState();
}

class _SearchUserViewState extends State<SearchUserView> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  SearchUserBloc get _searchUserBloc => BlocProvider.of<SearchUserBloc>(context);
  final List<SocialUserData> _searchResults = [];
  late AnimationController _loadingAnimationController;
  late AnimationController _resultsAnimationController;
  final Set<SocialUserData> _selectedUsers = {};
  Timer? _debounce;
  String _currentSearchText = '';
  bool _isSelectingUser = false;

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

    // Initialize selected users from constructor parameter
    _selectedUsers.clear();
    if (widget.socialUserList.isNotEmpty) {
      _selectedUsers.addAll(widget.socialUserList);
      debugPrint('Initialized with ${_selectedUsers.length} selected users');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _loadingAnimationController.dispose();
    _resultsAnimationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // Don't perform search if we're currently selecting a user
    if (_isSelectingUser) {
      _isSelectingUser = false;
      return;
    }

    // Update current search text
    _currentSearchText = query;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      // Check if the search text is still the same (user hasn't typed more)
      if (_currentSearchText != query) return;

      // Don't search if we're in the middle of a user selection
      if (_isSelectingUser) return;

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

      // await _loadingAnimationController.repeat();

      final completer = Completer<void>();
      _searchUserBloc.add(
        SearchUserEvent(
          isLoading: false,
          searchText: query,
          onComplete: (userList) {
            completer.complete();
            _setResult(userList);
          },
        ),
      );
    });
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
        backgroundColor: Colors.white,
        appBar: IsmCustomAppBarWidget(
          backgroundColor: Colors.white,
          isCrossIcon: true,
          titleText: IsrTranslationFile.tagPeople,
          centerTitle: true,
          showActions: true,
          actions: [
            TapHandler(
              onTap: () => Navigator.pop(context, _selectedUsers.toList()),
              child: const Icon(Icons.check, color: Colors.black, size: 24),
            ),
            16.horizontalSpace,
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                margin: IsrDimens.edgeInsets(
                  left: 16.responsiveDimension,
                  top: 16.responsiveDimension,
                  right: 16.responsiveDimension,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (value) {
                    // Only perform search if we're not currently selecting a user
                    if (!_isSelectingUser) {
                      _performSearch(value);
                    }
                  },
                  style: IsrStyles.primaryText16,
                  decoration: InputDecoration(
                    hintText: IsrTranslationFile.search,
                    hintStyle: IsrStyles.primaryText14.copyWith(color: '767676'.toColor()),
                    prefixIconColor: '#878787'.toColor(),
                    prefix: Container(
                      margin: IsrDimens.edgeInsets(right: 10.responsiveDimension),
                      child: AppImage.svg(
                        AssetConstants.icSearchIcon,
                        color: '#878787'.toColor(),
                        height: 20,
                      ),
                    ),
                    suffixIcon: _currentSearchText.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _currentSearchText = '';
                              _performSearch('');
                            },
                            child: Container(
                              padding: IsrDimens.edgeInsetsAll(8.responsiveDimension),
                              child: Container(
                                width: 20.responsiveDimension,
                                height: 20.responsiveDimension,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF999999),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14.responsiveDimension,
                                ),
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: IsrDimens.edgeInsetsAll(10.responsiveDimension),
                  ),
                ),
              ),

              // Selected users display
              if (_selectedUsers.isNotEmpty) _buildSelectedUsers(),

              // Search results
              Expanded(
                child: _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _searchResults.isNotEmpty
                        ? _buildSearchResults()
                        : _buildEmptyState(),
              ),
            ],
          ),
        ),
      );

  /// Build selected users display
  Widget _buildSelectedUsers() => Container(
        margin: IsrDimens.edgeInsetsSymmetric(horizontal: 16.responsiveDimension, vertical: 8.responsiveDimension),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              IsrTranslationFile.selectedPeople,
              style: IsrStyles.primaryText14.copyWith(fontWeight: FontWeight.w600),
            ),
            8.verticalSpace,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8.responsiveDimension,
                children: _selectedUsers.map(_buildSelectedUserChip).toList(),
              ),
            ),
          ],
        ),
      );

  /// Build individual selected user chip
  Widget _buildSelectedUserChip(SocialUserData user) => Container(
        padding: IsrDimens.edgeInsetsSymmetric(horizontal: 12.responsiveDimension, vertical: 8.responsiveDimension),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1976D2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            !user.avatarUrl.isEmptyOrNull
                ? AppImage.network(
                    user.avatarUrl ?? '',
                    isProfileImage: true,
                    height: 20.responsiveDimension,
                    width: 20.responsiveDimension,
                    name: user.fullName ?? '',
                  )
                : CircleAvatar(
                    radius: IsrDimens.ten,
                    backgroundColor: '#E5F0FB'.color,
                    child: Text(
                      Utility.getInitials(
                        firstName:
                            user.displayName?.split(' ').firstOrNull ?? '',
                        lastName: user.displayName?.split(' ').lastOrNull ?? '',
                      ),
                      style: IsrStyles.primaryText12.copyWith(
                        fontSize: 9.responsiveDimension,
                        color: IsrColors.appColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            6.horizontalSpace,
            Flexible(
              child: Text(
                user.username ?? 'Unknown User',
                style: IsrStyles.primaryText14
                    .copyWith(fontWeight: FontWeight.w500, color: '1976D2'.toColor()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            6.horizontalSpace,
            GestureDetector(
              onTap: () => _toggleSelection(user),
              child: Container(
                padding: IsrDimens.edgeInsetsAll(2.responsiveDimension),
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14.responsiveDimension,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: IsrDimens.edgeInsetsSymmetric(horizontal: 32.responsiveDimension),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64.responsiveDimension,
                color: Colors.grey[300],
              ),
              24.verticalSpace,
              Text(
                _currentSearchText.isEmptyOrNull
                    ? IsrTranslationFile.searchForPeople
                    : IsrTranslationFile.noUserFound,
                style: IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w600),
              ),
              8.verticalSpace,
              Text(
                _currentSearchText.isEmptyOrNull
                    ? IsrTranslationFile.startTypingToFindPeopleToTag
                    : IsrTranslationFile.trySearchingWithADifferentName,
                style: IsrStyles.primaryText14.copyWith(color: '666666'.toColor()),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildSearchResults() => ListView.builder(
        padding: IsrDimens.edgeInsets(top: 16.responsiveDimension),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return Column(
            children: [
              _buildSearchResultItem(result, index),
              if (index != _searchResults.length - 1) const CustomDivider(),
            ],
          );
        },
      );

  Widget _buildSearchResultItem(SocialUserData result, int index) {
    final isSelected = _selectedUsers.contains(result);

    return InkWell(
      onTap: () => _toggleSelection(result),
      child: Container(
        padding: IsrDimens.edgeInsetsSymmetric(horizontal: 16.responsiveDimension, vertical: 12.responsiveDimension),
        child: Row(
          children: [
            // User avatar
            !result.avatarUrl.isEmptyOrNull
                ? AppImage.network(
                    result.avatarUrl ?? '',
                    isProfileImage: true,
                    height: 40.responsiveDimension,
                    width: 40.responsiveDimension,
                    name: result.fullName ?? '',
                    border: Border.all(color: IsrColors.colorCCCCCC),
                  )
                : CircleAvatar(
                    radius: IsrDimens.twenty,
                    backgroundColor: '#E5F0FB'.color,
                    child: Text(
                      Utility.getInitials(
                        firstName:
                            result.displayName?.split(' ').firstOrNull ?? '',
                        lastName:
                            result.displayName?.split(' ').lastOrNull ?? '',
                      ),
                      style: IsrStyles.primaryText14.copyWith(
                        color: IsrColors.appColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            12.horizontalSpace,
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName ?? '',
                    style: IsrStyles.primaryText16
                        .copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  2.verticalSpace,
                  Text(
                    result.username!,
                    style: IsrStyles.primaryText14.copyWith(color: '666666'.toColor()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Selection indicator
            Container(
              width: 16.responsiveDimension,
              height: 16.responsiveDimension,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1976D2) : '767676'.toColor(),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                    child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12.responsiveDimension,
                      ),
                  )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(SocialUserData user) {
    // Set flag to prevent search from being triggered
    _isSelectingUser = true;

    // Only call setState if there's actually a change
    final wasSelected = _selectedUsers.contains(user);
    var changed = false;

    if (wasSelected) {
      changed = _selectedUsers.remove(user);
    } else {
      _selectedUsers.add(user);
      changed = true;
    }

    // Only trigger rebuild if selection actually changed
    if (changed) {
      setState(() {
        // Selection state has been updated above
      });
    }

    // Reset the flag after a short delay to allow for any pending rebuilds
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSelectingUser = false;
    });
  }
}
