import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/managers/local_event_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class PostListingView extends StatefulWidget {
  PostListingView({
    super.key,
    required this.tagValue,
    required this.tagType,
    this.searchQuery,
    this.tabConfig = const TabConfig(),
    this.postConfig = const PostConfig(),
  });

  final String tagValue;
  TagType tagType;
  final String? searchQuery;
  final TabConfig tabConfig;
  final PostConfig postConfig;

  @override
  State<PostListingView> createState() => _PostListingViewState();
}

class _PostListingViewState extends State<PostListingView> {
  final TextEditingController _hashtagController = TextEditingController();
  late PostListingBloc _postListingBloc;

  Timer? _debounceTimer;
  static const int _minCharacterLimit = 3;
  static const Duration _debounceDelay = Duration(milliseconds: 1000);
  final _postList = <TimeLineData>[];

  // Track last search query to avoid unnecessary API calls
  String _lastSearchQuery = '';

  // Tab management
  SearchTabType _selectedTab = SearchTabType.posts;
  final Map<SearchTabType, List<dynamic>> _tabResults = {};
  final Map<SearchTabType, bool> _tabLoading = {};
  final Map<SearchTabType, String> _tabLastQuery = {};

  // Pagination management per tab
  final Map<SearchTabType, bool> _tabLoadingMore = {};
  final Map<SearchTabType, bool> _tabHasMoreData = {};

  // Track follow state for users
  final Map<String, bool> _userFollowingState = {};

  // Flag to prevent multiple initializations
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Get the BLoC from context (from the BlocProvider in the navigation tree)
    _postListingBloc = context.read<PostListingBloc>();

    // ✅ Only call init once to prevent duplicate API calls
    if (!_isInitialized) {
      _isInitialized = true;
      _onStartInit();
    }
  }

  void _onStartInit() {
    _hashtagController.text = widget.searchQuery ?? '#${widget.tagValue}';

    // Initialize tab loading states
    for (final tab in SearchTabType.values) {
      _tabLoading[tab] = false;
      _tabResults[tab] = [];
      _tabLoadingMore[tab] = false;
      _tabHasMoreData[tab] = true;
    }

    // Load initial data based on search query or tag value
    final searchQuery = widget.searchQuery ?? _getHasTagValue();
    if (searchQuery.isNotEmpty) {
      _performSearch(searchQuery);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hashtagController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String hashtagValue) {
    if (!mounted) return;

    setState(() {});

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Only search if we have enough characters
    if (hashtagValue.length >= _minCharacterLimit) {
      _debounceTimer = Timer(_debounceDelay, () {
        // Check if the search query has actually changed
        final currentQuery = _getHasTagValue();
        if (currentQuery != _lastSearchQuery) {
          // Query has changed, clear cache and perform fresh search
          _clearCachedResults();
          _performSearch(currentQuery);
          _lastSearchQuery = currentQuery;
        }
        // If query hasn't changed, show cached data (no API call)
      });
    } else {
      _clearSearch();
    }
  }

  void _performSearch(String searchQuery) {
    final cleanQuery = searchQuery.replaceFirst('#', '');
    if (cleanQuery.isEmpty) return;

    if (!mounted) return;

    // Set loading state for all tabs (since cache was cleared)
    setState(() {
      for (final tab in SearchTabType.values) {
        _tabLoading[tab] = true;
      }
    });

    // Search all tabs (since cache was cleared, all tabs need fresh data)
    for (final tab in SearchTabType.values) {
      _postListingBloc.add(
        GetSearchResultsEvent(
          searchQuery: cleanQuery,
          tabType: tab,
          isLoading: true,
        ),
      );
    }
  }

  void _searchForSelectedTab() {
    final searchQuery = _hashtagController.text.trim().replaceFirst('#', '');
    if (searchQuery.isEmpty) return;

    if (!mounted) return;

    // Check if the selected tab already has results for the same query
    final lastQuery = _tabLastQuery[_selectedTab] ?? '';

    if (lastQuery == searchQuery) {
      // Tab already has results for the same query, just show them without API call
      setState(() {
        _tabLoading[_selectedTab] = false;
      });
      return;
    }

    // Set loading state for the selected tab
    setState(() {
      _tabLoading[_selectedTab] = true;
    });

    // Search only for the selected tab
    _postListingBloc.add(
      GetSearchResultsEvent(
        searchQuery: searchQuery,
        tabType: _selectedTab,
        isLoading: true,
      ),
    );
  }

  void _clearSearch() {
    if (!mounted) return;

    // Clear search and posts if less than minimum characters
    setState(() {
      _postList.clear();
      _lastSearchQuery = ''; // Reset last search query
      // Clear all tab results
      for (final tab in SearchTabType.values) {
        _tabResults[tab] = [];
        _tabLoading[tab] = false;
      }
    });
  }

  void _clearCachedResults() {
    if (!mounted) return;

    // Clear cached results for all tabs when search query changes
    setState(() {
      _lastSearchQuery = ''; // Reset last search query
      for (final tab in SearchTabType.values) {
        _tabResults[tab] = [];
        _tabLoading[tab] = false;
        _tabLastQuery[tab] = ''; // Clear query tracking for each tab
        _tabLoadingMore[tab] = false;
        _tabHasMoreData[tab] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: IsrColors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildTabNavigation(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      );

  Widget _buildTabNavigation() => Container(
        height: IsrDimens.fifty,
        decoration: const BoxDecoration(
          color: IsrColors.white,
          border: Border(
            bottom: BorderSide(
              color: IsrColors.colorEFEFEF,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: SearchTabType.values.map((tab) {
            final isSelected = _selectedTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!mounted) return;
                  if (_selectedTab != tab) {
                    debugPrint('👆 Tab tapped: from ${_selectedTab.name} to ${tab.name}');
                    setState(() {
                      _selectedTab = tab;
                    });
                    _searchForSelectedTab();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected
                        ? const Border(
                            bottom: BorderSide(
                              color: IsrColors.appColor,
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tab.displayName,
                      style: IsrStyles.primaryText14.copyWith(
                        color: isSelected ? IsrColors.appColor : IsrColors.color9B9B9B,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  PreferredSizeWidget _buildAppBar() => IsmCustomAppBarWidget(
        isBackButtonVisible: true,
        backgroundColor: IsrColors.white,
        titleWidget: _buildHashtagSearchBar(),
        showTitleWidget: true,
        showDivider: true,
        dividerColor: IsrColors.colorEFEFEF,
      );

  Widget _buildHashtagSearchBar() => Container(
        margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: IsrColors.colorF5F5F5,
                      borderRadius: BorderRadius.circular(IsrDimens.twenty),
                      border: Border.all(
                        color: IsrColors.colorDBDBDB,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _hashtagController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: '#viral',
                        hintStyle: IsrStyles.primaryText14.copyWith(
                          color: IsrColors.color9B9B9B,
                        ),
                        prefixIcon: Padding(
                          padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
                          child: AppImage.svg(
                            AssetConstants.icSearchIcon,
                            color: IsrColors.color9B9B9B,
                            width: 14.responsiveDimension,
                            height: 14.responsiveDimension,
                          ),
                        ),
                        suffixIcon: _hashtagController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _debounceTimer?.cancel();
                                  _hashtagController.clear();
                                  _clearSearch();
                                },
                                icon: Icon(
                                  Icons.clear,
                                  color: IsrColors.color9B9B9B,
                                  size: 16.responsiveDimension,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: 8.responsiveDimension,
                          vertical: 10.responsiveDimension,
                        ),
                      ),
                      style: IsrStyles.primaryText14,
                      onSubmitted: (value) {
                        _debounceTimer?.cancel();
                        final hashtag = _getHasTagValue();
                        if (hashtag.length >= _minCharacterLimit) {
                          _performSearch(hashtag);
                        } else {
                          _clearSearch();
                        }
                      },
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildBody() => BlocConsumer<PostListingBloc, PostListingState>(
        bloc: _postListingBloc,
        listener: (context, state) {
          // Handle pagination completion
          if (!mounted) return;

          if (state is SearchResultsLoadedState) {
            final currentQuery = _hashtagController.text.trim().replaceFirst('#', '');

            // Debug: Log what data type is being received
            final resultType =
                state.results.isNotEmpty ? state.results.first.runtimeType.toString() : 'empty';
            debugPrint(
                '📥 SearchResultsLoadedState: tabType=${state.tabType.name}, count=${state.results.length}, dataType=$resultType');

            setState(() {
              // Always reset loading more state
              _tabLoadingMore[state.tabType] = false;

              // Use isFromPagination from state
              if (state.isFromPagination) {
                // Pagination mode: only append if results are not empty
                if (state.results.isNotEmpty) {
                  // Append new results to existing ones
                  final existingResults = _tabResults[state.tabType] ?? [];
                  _tabResults[state.tabType] = [...existingResults, ...state.results];
                  debugPrint(
                      '✅ Pagination: Appended ${state.results.length} items to ${state.tabType.name}. Total: ${_tabResults[state.tabType]?.length}');
                } else {
                  // Empty results during pagination - mark no more data
                  _tabHasMoreData[state.tabType] = false;
                  debugPrint(
                      '⚠️ Pagination: No more data for ${state.tabType.name}. Keeping existing ${_tabResults[state.tabType]?.length} items');
                }
              } else {
                // Fresh search: replace results completely
                _tabResults[state.tabType] = state.results;
                // Reset hasMoreData for fresh search
                _tabHasMoreData[state.tabType] = state.results.isNotEmpty;
                debugPrint(
                    '🔄 Fresh search: Loaded ${state.results.length} items for ${state.tabType.name}, dataType=$resultType');
              }

              _tabLoading[state.tabType] = false;
              // Store the query for this tab to avoid unnecessary API calls
              _tabLastQuery[state.tabType] = currentQuery;
            });

            // Log search event only for fresh searches (not pagination), selected tab, and exclude places tab
            if (!state.isFromPagination &&
                state.tabType == _selectedTab &&
                state.tabType != SearchTabType.places) {
              _logSearchEvent(
                currentQuery,
                state.results.length,
                state.tabType.displayName.toLowerCase(),
              );
            }
          }

          if (state is PostLoadedState) {
            setState(() {
              _postList.clear();
              _postList.addAll(state.postList);
            });
          }
        },
        builder: (context, state) {
          // Handle different state types
          // Only show full screen loader if it's NOT pagination loading
          final isAnyTabLoadingMore = _tabLoadingMore.values.any((loading) => loading);
          if (state is PostListingLoadingState && state.isLoading && !isAnyTabLoadingMore) {
            return const Center(child: AppLoader());
          }

          // Show content based on selected tab
          return _buildTabContent();
        },
      );

  // Use GestureDetector for swipe + IndexedStack for reliable tab switching
  Widget _buildTabContent() => GestureDetector(
        onHorizontalDragEnd: (details) {
          if (!mounted) return;
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 300) return; // Ignore slow swipes

          final currentIndex = _selectedTab.index;
          int newIndex;

          if (velocity < 0) {
            // Swipe left - go to next tab
            newIndex = (currentIndex + 1).clamp(0, SearchTabType.values.length - 1);
          } else {
            // Swipe right - go to previous tab
            newIndex = (currentIndex - 1).clamp(0, SearchTabType.values.length - 1);
          }

          if (newIndex != currentIndex) {
            final newTab = SearchTabType.values[newIndex];
            debugPrint('👆 Swipe detected: from ${_selectedTab.name} to ${newTab.name}');
            setState(() {
              _selectedTab = newTab;
            });
            _searchForSelectedTab();
          }
        },
        child: IndexedStack(
          index: _selectedTab.index,
          children: SearchTabType.values.map(_buildTabPage).toList(),
        ),
      );

  Widget _buildTabPage(SearchTabType tab) {
    final results = _tabResults[tab] ?? [];
    final isLoading = _tabLoading[tab] ?? false;
    final isLoadingMore = _tabLoadingMore[tab] ?? false;
    final hasQuery = _tabLastQuery[tab]?.isNotEmpty ?? false;

    debugPrint(
        '📄 Building tab page: tab=${tab.name}, resultsCount=${results.length}, isLoading=$isLoading, hasQuery=$hasQuery');

    // Show loader if loading and no results yet
    if (isLoading && !isLoadingMore && results.isEmpty) {
      return Center(
        key: ValueKey('loader_${tab.name}'),
        child: const AppLoader(),
      );
    }

    // Show empty state only if not loading and we've completed a query
    if (results.isEmpty && !isLoading && hasQuery) {
      return _buildEmptyState(tab);
    }

    // Show loader if we haven't queried this tab yet
    if (results.isEmpty && !hasQuery) {
      return Center(
        key: ValueKey('initial_loader_${tab.name}'),
        child: const AppLoader(),
      );
    }

    // Show content
    debugPrint(
        '📄 Building content for tab=${tab.name}, resultsType=${results.isNotEmpty ? results.first.runtimeType : 'empty'}');
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _handleScrollNotification(notification, tab);
        }
        return false;
      },
      child: _buildTabSpecificContentForTab(tab, results),
    );
  }

  void _handleScrollNotification(ScrollNotification notification, SearchTabType tab) {
    if (!mounted) return;

    final metrics = notification.metrics;
    if (metrics.maxScrollExtent == 0) return;

    // Check if scrolled to 65% of the content
    final scrollPercentage = metrics.pixels / metrics.maxScrollExtent;

    // Trigger pagination at 65% scroll for the current tab
    if (scrollPercentage >= 0.65 &&
        !(_tabLoadingMore[tab] ?? false) &&
        (_tabHasMoreData[tab] ?? false)) {
      _loadMoreForTab(tab);
    }
  }

  void _loadMoreForTab(SearchTabType tab) {
    if (!mounted) return;

    final searchQuery = _hashtagController.text.trim().replaceFirst('#', '');
    if (searchQuery.isEmpty) return;

    debugPrint('🔄 LoadMore: Requesting next page for ${tab.name}');

    setState(() {
      _tabLoadingMore[tab] = true;
    });

    _postListingBloc.add(
      GetSearchResultsEvent(
        searchQuery: searchQuery,
        tabType: tab,
        isLoading: false,
        isFromPagination: true,
      ),
    );
  }

  Widget _buildTabSpecificContentForTab(SearchTabType tab, List<dynamic> results) {
    debugPrint(
        '🎨 _buildTabSpecificContentForTab: tab=${tab.name}, resultsCount=${results.length}');

    // Debug wrapper to visually show which tab content is being rendered
    Widget wrapWithDebugBanner(Widget child, String tabName, Color color) => Stack(
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: color.changeOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'DEBUG: $tabName TAB',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );

    switch (tab) {
      case SearchTabType.posts:
        debugPrint('🎨 Returning POSTS grid');
        return wrapWithDebugBanner(
          _buildPostsGridWithoutController(results.cast<TimeLineData>()),
          'POSTS',
          Colors.blue,
        );
      case SearchTabType.tags:
        debugPrint('🎨 Returning TAGS list');
        return wrapWithDebugBanner(
          _buildTagsListWithoutController(results),
          'TAGS',
          Colors.green,
        );
      case SearchTabType.places:
        debugPrint('🎨 Returning PLACES list');
        return wrapWithDebugBanner(
          _buildPlacesListWithoutController(results),
          'PLACES',
          Colors.orange,
        );
      case SearchTabType.account:
        debugPrint('🎨 Returning ACCOUNTS list');
        return wrapWithDebugBanner(
          _buildAccountsListWithoutController(results),
          'ACCOUNTS',
          Colors.purple,
        );
    }
  }

  // PageView compatible list builders
  Widget _buildPostsGridWithoutController(List<TimeLineData> postList) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: IsrDimens.four,
                mainAxisSpacing: IsrDimens.four,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = postList[index];
                  return TapHandler(
                    key: ValueKey('post_${post.id}'),
                    onTap: () {
                      _logSearchPostClickedEvent(post, _getHasTagValue());
                      IsrAppNavigator.navigateToReelsPlayer(
                        context,
                        postDataList: postList,
                        startingPostIndex: index,
                        postSectionType: PostSectionType.tagPost,
                        tagValue: widget.tagValue,
                        tagType: widget.tagType,
                        tabConfig: widget.tabConfig,
                        postConfig: widget.postConfig,
                      );
                    },
                    child: _buildPostCard(post, index),
                  );
                },
                childCount: postList.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
              ),
            ),
          ),
        ],
      );

  Widget _buildTagsListWithoutController(List<dynamic> tags) => ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final tagHashtag = tag?.hashtag ?? 'tag${index + 1}';
          return Container(
            key: ValueKey('tag_$tagHashtag'),
            height: IsrDimens.sixty,
            margin: IsrDimens.edgeInsetsSymmetric(
                vertical: 4.responsiveDimension, horizontal: 8.responsiveDimension),
            child: TapHandler(
              onTap: () {
                _onTagTapped(tag);
              },
              child: Padding(
                padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
                child: Row(
                  children: [
                    const AppImage.svg(AssetConstants.icTagIcon),
                    12.responsiveHorizontalSpace,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$tagHashtag',
                            style: IsrStyles.primaryText14Bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${tag?.usageCount ?? (index + 1) * 10} Posts',
                            style: IsrStyles.primaryText12.copyWith(
                              color: IsrColors.color9B9B9B,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildPlacesListWithoutController(List<dynamic> places) => ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final resultList =
              (places as List<Result>).map(UnifiedLocationItem.fromLocationResult).toList();

          final result = resultList[index];
          final placeName = result.title;
          return Container(
            key: ValueKey('place_${result.placeId}'),
            height: 60.responsiveDimension,
            margin: IsrDimens.edgeInsetsSymmetric(
                vertical: 4.responsiveDimension, horizontal: 8.responsiveDimension),
            child: TapHandler(
              onTap: () => _handlePlaceTap(
                result.placeId,
                placeName,
              ),
              child: Padding(
                padding: IsrDimens.edgeInsetsSymmetric(horizontal: 16.responsiveDimension),
                child: Row(
                  children: [
                    const AppImage.svg(AssetConstants.icPlacesIcon),
                    12.responsiveHorizontalSpace,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            style: IsrStyles.primaryText14Bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (result.subtitle?.isNotEmpty == true) ...[
                            Text(
                              result.subtitle ?? '',
                              style: IsrStyles.primaryText12.copyWith(
                                color: IsrColors.color9B9B9B,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

  Widget _buildAccountsListWithoutController(List<dynamic> accounts) => ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final user = accounts[index] as SocialUserData;
          return Container(
            key: ValueKey('account_${user.id}'),
            height: 80.responsiveDimension,
            margin: IsrDimens.edgeInsetsSymmetric(
              vertical: 4.responsiveDimension,
              horizontal: 8.responsiveDimension,
            ),
            child: TapHandler(
              onTap: () => _handleAccountTap(user),
              child: Padding(
                padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 16.responsiveDimension,
                  vertical: 12.responsiveDimension,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56.responsiveDimension,
                      height: 56.responsiveDimension,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: IsrColors.colorDBDBDB,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: AppImage.network(
                          user.avatarUrl ?? '',
                          height: 56.responsiveDimension,
                          width: 56.responsiveDimension,
                          fit: BoxFit.cover,
                          isProfileImage: true,
                          name: user.fullName ?? '',
                        ),
                      ),
                    ),
                    12.responsiveHorizontalSpace,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username ?? 'Unknown User',
                            style: IsrStyles.primaryText16Bold.copyWith(
                              color: IsrColors.color242424,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          4.responsiveVerticalSpace,
                          Text(
                            user.fullName ?? user.displayName ?? 'No description',
                            style: IsrStyles.primaryText14.copyWith(
                              color: IsrColors.color9B9B9B,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildFollowButton(user),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _buildEmptyState(SearchTabType tabType) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage.svg(
              AssetConstants.icNoProductsAvailable,
              width: IsrDimens.eighty,
              height: IsrDimens.eighty,
              color: IsrColors.color9B9B9B,
            ),
            IsrDimens.sixteen.responsiveVerticalSpace,
            Text(
              _getEmptyStateTitle(tabType),
              style: IsrStyles.primaryText16Bold.copyWith(
                color: IsrColors.color242424,
              ),
            ),
            IsrDimens.eight.responsiveVerticalSpace,
            Text(
              _getEmptyStateMessage(tabType),
              style: IsrStyles.primaryText14.copyWith(
                color: IsrColors.color9B9B9B,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  String _getEmptyStateTitle(SearchTabType tabType) {
    switch (tabType) {
      case SearchTabType.posts:
        return IsrTranslationFile.noPostsFound;
      case SearchTabType.tags:
        return 'No tags found';
      case SearchTabType.places:
        return 'No places found';
      case SearchTabType.account:
        return 'No accounts found';
    }
  }

  String _getEmptyStateMessage(SearchTabType tabType) {
    switch (tabType) {
      case SearchTabType.posts:
        return 'Try searching with a different hashtag';
      case SearchTabType.tags:
        return 'Try searching with a different tag';
      case SearchTabType.places:
        return 'Try searching with a different location';
      case SearchTabType.account:
        return 'Try searching with a different username';
    }
  }

  Widget _buildPostCard(TimeLineData post, int index) => Container(
        decoration: BoxDecoration(
          color: IsrColors.white,
          borderRadius: BorderRadius.circular(8.responsiveDimension),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.responsiveDimension),
          child: Stack(
            children: [
              _buildPostImage(post),
              _buildUserProfileOverlay(post),
              if (post.tags?.products?.isEmptyOrNull == false) _buildShopButtonOverlay(post),
              if (post.media?.first.mediaType?.mediaType == MediaType.video) _buildVideoIcon(),
            ],
          ),
        ),
      );

  Widget _buildPostImage(TimeLineData post) {
    var coverUrl = '';
    if (post.previews.isEmptyOrNull == false) {
      final previewUrl = post.previews?.first.url ?? '';
      if (previewUrl.isEmptyOrNull == false) {
        coverUrl = previewUrl;
      }
    }
    if (coverUrl.isEmptyOrNull && post.media.isEmptyOrNull == false) {
      coverUrl = post.media?.first.mediaType?.mediaType == MediaType.video
          ? (post.media?.first.previewUrl.toString() ?? '')
          : post.media?.first.url.toString() ?? '';
    }

    if (coverUrl.isEmptyOrNull) {
      return Container(
        color: IsrColors.colorF5F5F5,
        child: Icon(
          Icons.image,
          color: IsrColors.color9B9B9B,
          size: IsrDimens.forty,
        ),
      );
    }

    return AppImage.network(
      coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      showError: true,
    );
  }

  Widget _buildUserProfileOverlay(TimeLineData post) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
          child: Row(
            children: [
              AppImage.network(
                post.user?.avatarUrl ?? '',
                height: 20.responsiveDimension,
                width: 20.responsiveDimension,
                name: post.user?.fullName ?? '',
                isProfileImage: true,
                textColor: IsrColors.white,
              ),
              IsrDimens.eight.responsiveHorizontalSpace,
              Expanded(
                child: Text(
                  post.user?.fullName ?? 'Unknown User',
                  style: IsrStyles.primaryText12.copyWith(
                    color: IsrColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildShopButtonOverlay(TimeLineData post) => Positioned(
        bottom: IsrDimens.eight,
        left: IsrDimens.eight,
        right: IsrDimens.eight,
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.twelve,
            vertical: IsrDimens.eight,
          ),
          decoration: BoxDecoration(
            color: IsrColors.black.applyOpacity(0.6),
            borderRadius: BorderRadius.circular(8.responsiveDimension),
            border: Border.all(
              color: IsrColors.white.applyOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: IsrColors.black.applyOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppImage.svg(
                AssetConstants.icCartIcon,
                color: IsrColors.white,
              ),
              IsrDimens.six.responsiveHorizontalSpace,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop',
                    style: IsrStyles.primaryText12.copyWith(
                      color: IsrColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${post.tags?.products?.length ?? 0} Products',
                    style: IsrStyles.primaryText10.copyWith(
                      color: IsrColors.white.changeOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildVideoIcon() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Center(
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
            decoration: BoxDecoration(
              color: IsrColors.black.applyOpacity(0.3),
              borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
            ),
            child: Icon(
              Icons.play_arrow,
              color: IsrColors.white,
              size: IsrDimens.twentyFour,
            ),
          ),
        ),
      );

  String _getHasTagValue() => _hashtagController.text.trim().replaceFirst('#', '');

  void _onTagTapped(dynamic tag) {
    final tagText = (tag?.hashtag as String?) ?? '';

    // Log hashtag clicked event
    _logHashtagEvent(tagText);

    IsrAppNavigator.navigateTagDetails(context,
        tagValue: tagText,
        tagType: TagType.hashtag,
        tabConfig: widget.tabConfig,
        postConfig: widget.postConfig);
  }

  void _handlePlaceTap(String placeId, String placeName) {
    final completer = Completer<void>();

    // Use BLoC to handle place details fetching
    _postListingBloc.add(GetPlaceDetailsEvent(
        placeId: placeId,
        onComplete: (placeDetails) {
          completer.complete();
          _goToPlaceDetailsScreen(placeDetails);
        }));
  }

  void _goToPlaceDetailsScreen(PlaceDetails placeDetails) {
    final result = placeDetails.result;

    final lat = result?.geometry?.location?.lat?.toDouble() ?? 0;
    final long = result?.geometry?.location?.lng?.toDouble() ?? 0;

    // Navigate to place details with fetched data
    IsrAppNavigator.navigateToPlaceDetails(
      context,
      placeId: result?.placeId ?? '',
      placeName: result?.name ?? '',
      latitude: lat,
      longitude: long,
      tabConfig: widget.tabConfig,
      postConfig: widget.postConfig,
    );
  }

  void _handleAccountTap(SocialUserData user) {
    // Log profile viewed event
    _logSearchProfileEvent(user.id ?? '', user.username ?? '');

    if (widget.postConfig.postCallBackConfig?.onProfileClick != null) {
      widget.postConfig.postCallBackConfig?.onProfileClick?.call(null, user.id ?? '');
    }

    // Navigate to user profile
    // IsmInjectionUtils.getRouteManagement().goToUserProfileDetail(
    //   userId: user.id ?? '',
    //   incomingFrom: 'search',
    // );
  }

  /// Log search event when user performs a search
  void _logSearchEvent(String searchQuery, int searchResultsCount, String searchFilter) {
    final searchEventMap = {
      'search_query': searchQuery,
      'search_results_count': searchResultsCount,
      'search_filter': searchFilter,
    };
    EventQueueProvider.instance
        .logEvent(EventType.searchPerformed.value, searchEventMap.removeEmptyValues());
  }

  /// Log event when user clicks on a post in search results
  void _logSearchPostClickedEvent(TimeLineData post, String searchQuery) {
    // Determine post type based on media count
    final mediaCount = post.media?.length ?? 0;
    String postType;
    if (mediaCount > 1) {
      postType = 'carousel';
    } else if (post.media?.first.mediaType?.mediaType == MediaType.video) {
      postType = 'video';
    } else {
      postType = 'image';
    }

    // Extract hashtags from post
    final hashtags =
        post.tags?.hashtags?.map((h) => '#${h.tag}').where((tag) => tag.isNotEmpty).toList() ?? [];

    final eventMap = {
      'search_query': searchQuery,
      'result_post_id': post.id ?? '',
      'post_type': postType,
      'post_author_id': post.userId ?? '',
      'hashtags': hashtags,
    };
    EventQueueProvider.instance
        .logEvent(EventType.searchResultClicked.value, eventMap.removeEmptyValues());
  }

  /// Log event when user clicks on a tag in search results
  void _logHashtagEvent(String hashTag) {
    final hashTagEventMap = {'hashtag': hashTag};
    EventQueueProvider.instance
        .logEvent(EventType.hashTagClicked.value, hashTagEventMap.removeEmptyValues());
  }

  /// Log event when user clicks on an account in search results
  void _logSearchProfileEvent(String profileUserId, String profileUserName) {
    final profileEvent = {
      'profile_user_id': profileUserId,
      'profile_username': profileUserName,
    };
    EventQueueProvider.instance
        .logEvent(EventType.profileViewed.value, profileEvent.removeEmptyValues());
  }

  // Follow button widget with API integration
  Widget _buildFollowButton(SocialUserData user) {
    // Check if user is following from either the user model or local state
    final isFollowing = _userFollowingState[user.id] ?? user.isFollowing ?? false;

    // Hide button if user is already following
    if (isFollowing) {
      return const SizedBox.shrink();
    }

    return AppButton(
      height: 30.responsiveDimension,
      width: 80.responsiveDimension,
      borderRadius: 20,
      title: IsrTranslationFile.follow,
      textStyle: IsrStyles.primaryText12.copyWith(
        color: IsrColors.white,
        fontWeight: FontWeight.w600,
      ),
      onPress: () {
        _handleFollowUser(user);
      },
    );
  }

  // Handle follow user action
  void _handleFollowUser(SocialUserData user) {
    if (user.id == null || user.id!.isEmpty) return;

    _postListingBloc.add(
      FollowSocialUserEvent(
        followingId: user.id!,
        followAction: FollowAction.follow,
        onComplete: (isSuccess) {
          if (isSuccess && mounted) {
            // Update local state to hide the follow button
            setState(() {
              _userFollowingState[user.id!] = true;
            });
          }
        },
      ),
    );
  }
}
