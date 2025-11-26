import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    this.onTapProfilePicture,
  });

  final String tagValue;
  TagType tagType;
  final String? searchQuery;
  Function(String)? onTapProfilePicture;

  @override
  State<PostListingView> createState() => _PostListingViewState();
}

class _PostListingViewState extends State<PostListingView> {
  final TextEditingController _hashtagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Get the BLoC from context (from the BlocProvider in the navigation tree)
    _postListingBloc = context.read<PostListingBloc>();

    // ✅ Now call init after we have the BLoC
    _onStartInit();
  }

  void _onStartInit() {
    _hashtagController.text = widget.searchQuery ?? '#${widget.tagValue}';
    _scrollController.addListener(_onScroll);

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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if widget is still mounted and has clients
    if (!mounted || !_scrollController.hasClients) return;

    // Check if scrolled to 65% of the content
    final scrollPercentage =
        _scrollController.position.pixels / _scrollController.position.maxScrollExtent;

    // Trigger pagination at 65% scroll for the selected tab
    if (scrollPercentage >= 0.65 &&
        !(_tabLoadingMore[_selectedTab] ?? false) &&
        (_tabHasMoreData[_selectedTab] ?? false)) {
      _loadMoreForSelectedTab();
    }
  }

  void _loadMoreForSelectedTab() {
    if (!mounted) return;

    final searchQuery = _hashtagController.text.trim().replaceFirst('#', '');
    if (searchQuery.isEmpty) return;

    debugPrint('🔄 LoadMore: Requesting next page for ${_selectedTab.name}');

    setState(() {
      _tabLoadingMore[_selectedTab] = true;
    });

    _postListingBloc.add(
      GetSearchResultsEvent(
        searchQuery: searchQuery,
        tabType: _selectedTab,
        isLoading: false,
        isFromPagination: true,
      ),
    );
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
        body: Column(
          children: [
            _buildTabNavigation(),
            Expanded(child: _buildBody()),
          ],
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
                  setState(() {
                    _selectedTab = tab;
                  });
                  _searchForSelectedTab();
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
            // Always reset loading state
            if (_tabLoadingMore[state.tabType] ?? false) {
              setState(() {
                _tabLoadingMore[state.tabType] = false;
              });
            }

            // If it's pagination and empty, mark no more data
            if (state.isFromPagination && state.results.isEmpty) {
              setState(() {
                _tabHasMoreData[state.tabType] = false;
              });
              debugPrint('⚠️ Listener: No more data for ${state.tabType.name}');
            }
          }
        },
        builder: (context, state) {
          // Handle different state types
          // Only show full screen loader if it's NOT pagination loading
          final isAnyTabLoadingMore = _tabLoadingMore.values.any((loading) => loading);
          if (state is PostListingLoadingState && state.isLoading && !isAnyTabLoadingMore) {
            return const Center(child: AppLoader());
          }

          // Update the list from state
          if (state is PostLoadedState) {
            _postList.clear();
            _postList.addAll(state.postList);
          }

          if (state is SearchResultsLoadedState) {
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
                // Empty results during pagination - keep existing data
                debugPrint(
                    '⚠️ Pagination: No more data for ${state.tabType.name}. Keeping existing ${_tabResults[state.tabType]?.length} items');
                // DON'T modify _tabResults - keep existing data intact
              }
            } else {
              // Fresh search: replace results completely
              _tabResults[state.tabType] = state.results;
              // Reset hasMoreData for fresh search
              _tabHasMoreData[state.tabType] = state.results.isNotEmpty;
              debugPrint(
                  '🔄 Fresh search: Loaded ${state.results.length} items for ${state.tabType.name}');
            }
            _tabLoading[state.tabType] = false;
            // Store the query for this tab to avoid unnecessary API calls
            final currentQuery = _hashtagController.text.trim().replaceFirst('#', '');
            _tabLastQuery[state.tabType] = currentQuery;
          }

          // Show content based on selected tab
          return _buildTabContent();
        },
      );

  Widget _buildTabContent() {
    final results = _tabResults[_selectedTab] ?? [];
    final isLoading = _tabLoading[_selectedTab] ?? false;
    final isLoadingMore = _tabLoadingMore[_selectedTab] ?? false;

    // Only show full screen loader if it's initial loading (not pagination)
    if (isLoading && !isLoadingMore && results.isEmpty) {
      return const Center(child: AppLoader());
    }

    if (results.isEmpty && !isLoading) {
      return _buildEmptyState(_selectedTab);
    }

    // Show content with pagination loader at bottom (if loading more)
    return Column(
      children: [
        Expanded(
          child: _buildTabSpecificContent(results),
        ),
      ],
    );
  }

  Widget _buildTabSpecificContent(List<dynamic> results) {
    switch (_selectedTab) {
      case SearchTabType.posts:
        return _buildPostsGrid(results.cast<TimeLineData>());
      case SearchTabType.tags:
        return _buildTagsList(results);
      case SearchTabType.places:
        return _buildPlacesList(results);
      case SearchTabType.account:
        return _buildAccountsList(results);
    }
  }

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

  Widget _buildPostsGrid(List<TimeLineData> postList) => CustomScrollView(
        controller: _scrollController,
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
                      IsrAppNavigator.navigateToReelsPlayer(
                        context,
                        postDataList: postList,
                        startingPostIndex: index,
                        postSectionType: PostSectionType.tagPost,
                        tagValue: widget.tagValue,
                        tagType: widget.tagType,
                        onTapProfilePicture: widget.onTapProfilePicture,
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

    IsrAppNavigator.navigateTagDetails(context, tagValue: tagText, tagType: TagType.hashtag);
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
    );
  }

  // Tab-specific content builders
  Widget _buildTagsList(List<dynamic> tags) => RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          controller: _scrollController,
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
        ),
      );

  Widget _buildPlacesList(List<dynamic> places) => RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          controller: _scrollController,
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
        ),
      );

  Widget _buildAccountsList(List<dynamic> accounts) => RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          controller: _scrollController,
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
                      // Profile Picture
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
                      // User Info
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
                      // Follow/Following Button
                      _buildFollowButton(user),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

  void _handleAccountTap(SocialUserData user) {
    if (widget.onTapProfilePicture != null) {
      widget.onTapProfilePicture?.call(user.id ?? '');
    }

    /// TODO need to decide
    // Navigate to user profile
    // IsmInjectionUtils.getRouteManagement().goToUserProfileDetail(
    //   userId: user.id ?? '',
    //   incomingFrom: 'search',
    // );
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
