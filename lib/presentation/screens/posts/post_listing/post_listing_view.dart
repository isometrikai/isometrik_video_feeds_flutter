import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class PostListingView extends StatefulWidget {
  PostListingView({
    super.key,
    this.tagValue = '',
    this.tagType = TagType.hashtag,
    this.searchQuery,
    this.tabList = SearchTabType.values,
    this.config,
  });

  final String tagValue;
  final TagType tagType;
  final String? searchQuery;
  final List<SearchTabType> tabList;
  final SearchScreenConfig? config;

  @override
  State<PostListingView> createState() => _PostListingViewState();
}

class _PostListingViewState extends State<PostListingView> {
  final TextEditingController _hashtagController = TextEditingController();
  late PostListingBloc _postListingBloc;

  Timer? _debounceTimer;
  Timer? _placesPermissionSyncTimer;
  static const int _minCharacterLimit = 3;
  static const Duration _debounceDelay = Duration(milliseconds: 1000);
  static const Duration _placesPermissionSyncInterval = Duration(seconds: 3);
  final _postList = <TimeLineData>[];

  // Track last search query to avoid unnecessary API calls
  String _lastSearchQuery = '';

  SearchTabType _selectedTab = SearchTabType.posts;
  final Map<SearchTabType, List<dynamic>> _tabResults = {};
  final Map<SearchTabType, bool> _tabLoading = {};
  final Map<SearchTabType, String> _tabLastQuery = {};

  // Pagination management per tab
  final Map<SearchTabType, bool> _tabLoadingMore = {};
  final Map<SearchTabType, bool> _tabHasMoreData = {};

  // Tracks whether the accounts tab is currently showing popular users
  // (i.e. no active search query and showPopularUsers config is true)
  final Map<SearchTabType, bool> _tabIsPopular = {};

  // Flag to prevent multiple initializations
  bool _isInitialized = false;
  bool _isCheckingPlacesPermission = false;
  bool _isPlacesPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  int _placesPermissionRequestId = 0;
  Future<void>? _inFlightPlacesPermissionSync;

  SearchScreenConfig get _searchScreenConfig =>
      widget.config ?? IsrVideoReelConfig.searchScreenConfig;

  // Configuration getters
  SearchScreenUIConfig? get _searchScreenUIConfig =>
      _searchScreenConfig.searchScreenUIConfig;

  int get _selectedTabListIndex {
    final i = widget.tabList.indexOf(_selectedTab);
    return i >= 0 ? i : 0;
  }

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

    if (widget.tabList.isNotEmpty) {
      _selectedTab = widget.tabList.first;
    }

    // Initialize tab loading states
    for (final tab in widget.tabList) {
      _tabLoading[tab] = false;
      _tabResults[tab] = [];
      _tabLoadingMore[tab] = false;
      _tabHasMoreData[tab] = true;
      _tabIsPopular[tab] = false;
    }

    // Load initial data based on search query or tag value.
    // For Places-enabled flows, verify permission/service status first.
    final searchQuery = widget.searchQuery ?? _getHasTagValue();
    if (widget.tabList.contains(SearchTabType.places)) {
      _syncPlacesPermissionStatus().whenComplete(() {
        if (!mounted) return;
        if (searchQuery.isNotEmpty) {
          _performSearch(searchQuery);
        } else {
          _loadPopularUsersIfNeeded();
        }
      });
    } else if (searchQuery.isNotEmpty) {
      _performSearch(searchQuery);
    } else {
      _loadPopularUsersIfNeeded();
    }
    _updatePlacesPermissionSyncLifecycle();
  }

  Future<void> _syncPlacesPermissionStatus() {
    if (_inFlightPlacesPermissionSync != null) {
      return _inFlightPlacesPermissionSync!;
    }

    final requestId = ++_placesPermissionRequestId;
    final future = _readPlacesPermissionSnapshot().then((snapshot) {
      _applyPlacesPermissionSnapshot(
        snapshot,
        requestId: requestId,
      );
    }).catchError((_) {
      // Ignore sync failures and keep the previous known state.
    }).whenComplete(() {
      _inFlightPlacesPermissionSync = null;
    });

    _inFlightPlacesPermissionSync = future;
    return future;
  }

  Future<_PlacesPermissionSnapshot> _readPlacesPermissionSnapshot() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    return _PlacesPermissionSnapshot(
      serviceEnabled: serviceEnabled,
      permissionGranted: permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse,
    );
  }

  void _applyPlacesPermissionSnapshot(
    _PlacesPermissionSnapshot snapshot, {
    required int requestId,
    bool isCheckingPermission = false,
  }) {
    if (!mounted || requestId != _placesPermissionRequestId) return;

    final hasStateChanged =
        _isLocationServiceEnabled != snapshot.serviceEnabled ||
            _isPlacesPermissionGranted != snapshot.permissionGranted ||
            _isCheckingPlacesPermission != isCheckingPermission;

    if (!hasStateChanged) return;

    setState(() {
      _isLocationServiceEnabled = snapshot.serviceEnabled;
      _isPlacesPermissionGranted = snapshot.permissionGranted;
      _isCheckingPlacesPermission = isCheckingPermission;
      if (!snapshot.serviceEnabled || !snapshot.permissionGranted) {
        _tabLoading[SearchTabType.places] = false;
        _tabLoadingMore[SearchTabType.places] = false;
      }
    });
  }

  bool get _shouldSyncPlacesPermission {
    if (!widget.tabList.contains(SearchTabType.places)) return false;
    final hasActiveQuery = _getHasTagValue().length >= _minCharacterLimit;
    return _selectedTab == SearchTabType.places || hasActiveQuery;
  }

  void _updatePlacesPermissionSyncLifecycle() {
    if (_shouldSyncPlacesPermission) {
      _placesPermissionSyncTimer ??= Timer.periodic(
        _placesPermissionSyncInterval,
        (_) => _syncPlacesPermissionStatus(),
      );
      return;
    }
    _placesPermissionSyncTimer?.cancel();
    _placesPermissionSyncTimer = null;
  }

  Future<void> _requestPlacesPermissionIfNeeded() async {
    if (_isCheckingPlacesPermission) return;

    final requestId = ++_placesPermissionRequestId;
    setState(() => _isCheckingPlacesPermission = true);
    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }

      // Re-verify both values after settings/permission prompts for atomic UI update.
      final snapshot = await _readPlacesPermissionSnapshot();
      _applyPlacesPermissionSnapshot(
        snapshot,
        requestId: requestId,
        isCheckingPermission: false,
      );
      _updatePlacesPermissionSyncLifecycle();
    } catch (_) {
      if (!mounted || requestId != _placesPermissionRequestId) return;
      setState(() => _isCheckingPlacesPermission = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _placesPermissionSyncTimer?.cancel();
    _hashtagController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String hashtagValue) {
    if (!mounted) return;

    setState(() {});
    _updatePlacesPermissionSyncLifecycle();

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

  Future<void> _performSearch(String searchQuery) async {
    final cleanQuery = searchQuery.replaceFirst('#', '');
    if (cleanQuery.isEmpty) return;

    if (!mounted) return;

    // Re-verify Places permission/service state before permission-dependent search flow.
    if (widget.tabList.contains(SearchTabType.places)) {
      await _syncPlacesPermissionStatus();
      if (!mounted) return;
    }

    _updatePlacesPermissionSyncLifecycle();

    // Store the search query for pagination
    _lastSearchQuery = cleanQuery;

    // Set loading state for all tabs (since cache was cleared)
    setState(() {
      for (final tab in widget.tabList) {
        if (tab == SearchTabType.places &&
            (!_isLocationServiceEnabled || !_isPlacesPermissionGranted)) {
          _tabLoading[tab] = false;
        } else {
          _tabLoading[tab] = true;
        }
        _tabLastQuery[tab] = cleanQuery;
      }
    });

    // Search all tabs (since cache was cleared, all tabs need fresh data)
    for (final tab in widget.tabList) {
      if (tab == SearchTabType.places &&
          (!_isLocationServiceEnabled || !_isPlacesPermissionGranted)) {
        continue;
      }
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
    if (_selectedTab == SearchTabType.places &&
        (!_isLocationServiceEnabled || !_isPlacesPermissionGranted)) {
      setState(() {
        _tabLoading[_selectedTab] = false;
      });
      return;
    }

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

  /// Loads popular users for the accounts tab when:
  ///   • the accounts tab is in the tab list,
  ///   • the search field is empty, and
  ///   • the host app has opted-in via [AccountsListConfig.showPopularUsers].
  ///
  /// If the tab already has popular-user results cached this is a no-op.
  void _loadPopularUsersIfNeeded() {
    if (!mounted) return;
    if (!widget.tabList.contains(SearchTabType.account)) return;
    if (_searchScreenUIConfig?.accountsListConfig?.showPopularUsers != true) {
      return;
    }

    final searchQuery = _hashtagController.text.trim().replaceFirst('#', '');
    if (searchQuery.isNotEmpty) return; // user is actively searching

    // No-op if popular results are already loaded or loading
    if (_tabIsPopular[SearchTabType.account] == true &&
        (_tabResults[SearchTabType.account]?.isNotEmpty == true ||
            _tabLoading[SearchTabType.account] == true)) {
      return;
    }

    debugPrint('⭐ Loading popular users for accounts tab');

    setState(() {
      _tabIsPopular[SearchTabType.account] = true;
      _tabLoading[SearchTabType.account] = true;
      _tabLastQuery[SearchTabType.account] = '';
    });

    _postListingBloc.add(
      GetSearchResultsEvent(
        searchQuery: '',
        tabType: SearchTabType.account,
        isLoading: false, // Use tab-level loading instead of full-screen loader
        isPopular: true,
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
      for (final tab in widget.tabList) {
        _tabResults[tab] = [];
        _tabLoading[tab] = false;
        _tabIsPopular[tab] = false;
      }
    });
    _updatePlacesPermissionSyncLifecycle();
    // When search is cleared, reload popular users for the account tab if configured
    _loadPopularUsersIfNeeded();
  }

  void _clearCachedResults() {
    if (!mounted) return;

    // Clear cached results for all tabs when search query changes
    setState(() {
      _lastSearchQuery = ''; // Reset last search query
      for (final tab in widget.tabList) {
        _tabResults[tab] = [];
        _tabLoading[tab] = false;
        _tabLastQuery[tab] = ''; // Clear query tracking for each tab
        _tabLoadingMore[tab] = false;
        _tabHasMoreData[tab] = true;
        _tabIsPopular[tab] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor:
            _searchScreenUIConfig?.scaffoldConfig?.backgroundColor ??
                IsrColors.white,
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
        height: _searchScreenUIConfig?.tabNavigationConfig?.height ??
            IsrDimens.fifty,
        decoration: BoxDecoration(
          color: _searchScreenUIConfig?.tabNavigationConfig?.backgroundColor ??
              IsrColors.white,
          border: Border(
            bottom: BorderSide(
              color: _searchScreenUIConfig?.tabNavigationConfig?.borderColor ??
                  IsrColors.colorEFEFEF,
              width:
                  _searchScreenUIConfig?.tabNavigationConfig?.borderWidth ?? 1,
            ),
          ),
        ),
        child: Row(
          children: widget.tabList.map((tab) {
            final isSelected = _selectedTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!mounted) return;
                  if (_selectedTab != tab) {
                    debugPrint(
                      '👆 Tab tapped: from ${_selectedTab.name} to ${tab.name}',
                    );
                    setState(() {
                      _selectedTab = tab;
                    });
                    if (tab == SearchTabType.places) {
                      _syncPlacesPermissionStatus();
                    }
                    _updatePlacesPermissionSyncLifecycle();
                    _searchForSelectedTab();
                    _loadPopularUsersIfNeeded();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border(
                            bottom: BorderSide(
                              color: _searchScreenUIConfig
                                      ?.tabNavigationConfig?.indicatorColor ??
                                  IsrColors.appColor,
                              width: _searchScreenUIConfig
                                      ?.tabNavigationConfig?.indicatorWidth ??
                                  2,
                            ),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tab.displayName,
                      style: isSelected
                          ? (_searchScreenUIConfig
                                  ?.tabNavigationConfig?.selectedTextStyle ??
                              IsrStyles.primaryText14.copyWith(
                                color: _searchScreenUIConfig
                                        ?.tabNavigationConfig
                                        ?.selectedTextColor ??
                                    IsrColors.appColor,
                                fontWeight: FontWeight.bold,
                              ))
                          : (_searchScreenUIConfig
                                  ?.tabNavigationConfig?.unselectedTextStyle ??
                              IsrStyles.primaryText14.copyWith(
                                color: _searchScreenUIConfig
                                        ?.tabNavigationConfig
                                        ?.unselectedTextColor ??
                                    IsrColors.color9B9B9B,
                                fontWeight: FontWeight.normal,
                              )),
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
        backgroundColor: _searchScreenUIConfig?.appBarConfig?.backgroundColor ??
            IsrColors.white,
        titleWidget: _buildHashtagSearchBar(),
        showTitleWidget: true,
        showDivider: _searchScreenUIConfig?.appBarConfig?.showDivider ?? true,
        dividerColor: _searchScreenUIConfig?.appBarConfig?.dividerColor ??
            IsrColors.colorEFEFEF,
        showActions:
            _searchScreenUIConfig?.appBarConfig?.showFollowRequestsAction ==
                true,
        actions:
            _searchScreenUIConfig?.appBarConfig?.showFollowRequestsAction ==
                    true
                ? [
                    TapHandler(
                      onTap: () =>
                          IsrAppNavigator.navigateToFollowRequests(context),
                      child: Padding(
                        padding: EdgeInsets.only(right: IsrDimens.eight),
                        child: Icon(
                          Icons.person_add_alt_1_outlined,
                          color: IsrColors.appColor,
                          size: 22.responsiveDimension,
                        ),
                      ),
                    ),
                  ]
                : null,
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
                    decoration:
                        _searchScreenUIConfig?.searchBarConfig?.decoration ??
                            BoxDecoration(
                              color: _searchScreenUIConfig
                                      ?.searchBarConfig?.backgroundColor ??
                                  IsrColors.colorF5F5F5,
                              borderRadius: BorderRadius.circular(
                                _searchScreenUIConfig
                                        ?.searchBarConfig?.borderRadius ??
                                    IsrDimens.twenty,
                              ),
                              border: Border.all(
                                color: _searchScreenUIConfig
                                        ?.searchBarConfig?.borderColor ??
                                    IsrColors.colorDBDBDB,
                                width: _searchScreenUIConfig
                                        ?.searchBarConfig?.borderWidth ??
                                    1,
                              ),
                            ),
                    child: TextField(
                      controller: _hashtagController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText:
                            _searchScreenUIConfig?.searchBarConfig?.hintText ??
                                '#viral',
                        hintStyle:
                            _searchScreenUIConfig?.searchBarConfig?.hintStyle ??
                                IsrStyles.primaryText14.copyWith(
                                  color: IsrColors.color9B9B9B,
                                ),
                        prefixIcon: Padding(
                          padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
                          child: _searchScreenUIConfig?.searchBarConfig
                                      ?.prefixIconConfig?.icon !=
                                  null
                              ? AppImage.svg(
                                  _searchScreenUIConfig!
                                      .searchBarConfig!.prefixIconConfig!.icon!,
                                  color: _searchScreenUIConfig?.searchBarConfig
                                          ?.prefixIconConfig?.color ??
                                      IsrColors.color9B9B9B,
                                  width: _searchScreenUIConfig?.searchBarConfig
                                          ?.prefixIconConfig?.size ??
                                      14.responsiveDimension,
                                  height: _searchScreenUIConfig?.searchBarConfig
                                          ?.prefixIconConfig?.size ??
                                      14.responsiveDimension,
                                )
                              : AppImage.svg(
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
                                  _searchScreenUIConfig?.searchBarConfig
                                          ?.suffixIconConfig?.iconData ??
                                      Icons.clear,
                                  color: _searchScreenUIConfig?.searchBarConfig
                                          ?.suffixIconConfig?.color ??
                                      IsrColors.color9B9B9B,
                                  size: _searchScreenUIConfig?.searchBarConfig
                                          ?.suffixIconConfig?.size ??
                                      16.responsiveDimension,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: _searchScreenUIConfig
                                ?.searchBarConfig?.contentPadding ??
                            IsrDimens.edgeInsetsSymmetric(
                              horizontal: 8.responsiveDimension,
                              vertical: 10.responsiveDimension,
                            ),
                      ),
                      style:
                          _searchScreenUIConfig?.searchBarConfig?.textStyle ??
                              IsrStyles.primaryText14,
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
            if (state.tabType == SearchTabType.places &&
                (!_isLocationServiceEnabled || !_isPlacesPermissionGranted)) {
              setState(() {
                _tabLoading[state.tabType] = false;
                _tabLoadingMore[state.tabType] = false;
              });
              return;
            }

            final currentQuery = _hashtagController.text.trim().replaceFirst(
                  '#',
                  '',
                );

            // Debug: Log what data type is being received
            final resultType = state.results.isNotEmpty
                ? state.results.first.runtimeType.toString()
                : 'empty';
            debugPrint(
              '📥 SearchResultsLoadedState: tabType=${state.tabType.name}, count=${state.results.length}, dataType=$resultType',
            );

            setState(() {
              // Always reset loading more state
              _tabLoadingMore[state.tabType] = false;

              // Use isFromPagination from state
              if (state.isFromPagination) {
                // Pagination mode: only append if results are not empty
                if (state.results.isNotEmpty) {
                  // Append new results to existing ones
                  final existingResults = _tabResults[state.tabType] ?? [];
                  _tabResults[state.tabType] = [
                    ...existingResults,
                    ...state.results,
                  ];
                  debugPrint(
                    '✅ Pagination: Appended ${state.results.length} items to ${state.tabType.name}. Total: ${_tabResults[state.tabType]?.length}',
                  );
                } else {
                  // Empty results during pagination - mark no more data
                  _tabHasMoreData[state.tabType] = false;
                  debugPrint(
                    '⚠️ Pagination: No more data for ${state.tabType.name}. Keeping existing ${_tabResults[state.tabType]?.length} items',
                  );
                }
              } else {
                // Fresh search: replace results completely
                _tabResults[state.tabType] = state.results;
                // Reset hasMoreData for fresh search
                _tabHasMoreData[state.tabType] = state.results.isNotEmpty;
                debugPrint(
                  '🔄 Fresh search: Loaded ${state.results.length} items for ${state.tabType.name}, dataType=$resultType',
                );
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
          final isAnyTabLoadingMore = _tabLoadingMore.values.any(
            (loading) => loading,
          );
          if (state is PostListingLoadingState &&
              state.isLoading &&
              !isAnyTabLoadingMore) {
            return Center(
              child: _searchScreenUIConfig?.loadingConfig?.indicator ??
                  const AppLoader(),
            );
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

          final currentIndex = _selectedTabListIndex;
          int newIndex;

          if (velocity < 0) {
            // Swipe left - go to next tab
            newIndex = (currentIndex + 1).clamp(0, widget.tabList.length - 1);
          } else {
            // Swipe right - go to previous tab
            newIndex = (currentIndex - 1).clamp(0, widget.tabList.length - 1);
          }

          if (newIndex != currentIndex) {
            final newTab = widget.tabList[newIndex];
            debugPrint(
              '👆 Swipe detected: from ${_selectedTab.name} to ${newTab.name}',
            );
            setState(() {
              _selectedTab = newTab;
            });
            if (newTab == SearchTabType.places) {
              _syncPlacesPermissionStatus();
            }
            _updatePlacesPermissionSyncLifecycle();
            _searchForSelectedTab();
            _loadPopularUsersIfNeeded();
          }
        },
        child: IndexedStack(
          index: _selectedTabListIndex,
          children: widget.tabList.map(_buildTabPage).toList(),
        ),
      );

  Widget _buildTabPage(SearchTabType tab) {
    if (tab == SearchTabType.places &&
        (!_isLocationServiceEnabled || !_isPlacesPermissionGranted)) {
      return _buildPlacesPermissionState();
    }

    final results = _tabResults[tab] ?? [];
    final isLoading = _tabLoading[tab] ?? false;
    final isLoadingMore = _tabLoadingMore[tab] ?? false;
    final hasQuery = _tabLastQuery[tab]?.isNotEmpty ?? false;

    debugPrint(
      '📄 Building tab page: tab=${tab.name}, resultsCount=${results.length}, isLoading=$isLoading, hasQuery=$hasQuery',
    );

    // Show loader if loading and no results yet
    if (isLoading && !isLoadingMore && results.isEmpty) {
      return Center(
        key: ValueKey('loader_${tab.name}'),
        child: _searchScreenUIConfig?.loadingConfig?.indicator ??
            const AppLoader(),
      );
    }

    // Show empty state only if not loading and we've completed a query
    if (results.isEmpty && !isLoading) {
      return _buildEmptyState(tab);
    }

    // Show loader if we haven't queried this tab yet
    if (results.isEmpty && !hasQuery) {
      return Center(
        key: ValueKey('initial_loader_${tab.name}'),
        child: _searchScreenUIConfig?.loadingConfig?.indicator ??
            const AppLoader(),
      );
    }

    // Show content
    debugPrint(
      '📄 Building content for tab=${tab.name}, resultsType=${results.isNotEmpty ? results.first.runtimeType : 'empty'}',
    );
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

  void _handleScrollNotification(
    ScrollNotification notification,
    SearchTabType tab,
  ) {
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

    // Skip pagination for Places tab (Google Places API doesn't support pagination well)
    if (tab == SearchTabType.places) return;

    final isPopular = _tabIsPopular[tab] ?? false;

    // Use stored search query for pagination to maintain consistency
    final searchQuery = _tabLastQuery[tab] ?? _lastSearchQuery;
    if (searchQuery.isEmpty && !isPopular) return;

    debugPrint(
      '🔄 LoadMore: Requesting next page for ${tab.name} with query: $searchQuery (popular: $isPopular)',
    );

    setState(() {
      _tabLoadingMore[tab] = true;
    });

    _postListingBloc.add(
      GetSearchResultsEvent(
        searchQuery: searchQuery,
        tabType: tab,
        isLoading: false,
        isFromPagination: true,
        isPopular: isPopular,
      ),
    );
  }

  Widget _buildTabSpecificContentForTab(
    SearchTabType tab,
    List<dynamic> results,
  ) {
    debugPrint(
      '🎨 _buildTabSpecificContentForTab: tab=${tab.name}, resultsCount=${results.length}',
    );

    // Debug wrapper to visually show which tab content is being rendered
    Widget wrapWithDebugBanner(Widget child, String tabName, Color color) =>
        Stack(children: [child]);

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
  Widget _buildPostsGridWithoutController(List<TimeLineData> postList) =>
      CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: _searchScreenUIConfig?.postsGridConfig?.padding ??
                IsrDimens.edgeInsetsAll(IsrDimens.eight),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    _searchScreenUIConfig?.postsGridConfig?.crossAxisCount ?? 2,
                crossAxisSpacing:
                    _searchScreenUIConfig?.postsGridConfig?.crossAxisSpacing ??
                        IsrDimens.four,
                mainAxisSpacing:
                    _searchScreenUIConfig?.postsGridConfig?.mainAxisSpacing ??
                        IsrDimens.four,
                childAspectRatio:
                    _searchScreenUIConfig?.postsGridConfig?.childAspectRatio ??
                        0.75,
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

  Widget _buildTagsListWithoutController(List<dynamic> tags) =>
      ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final tagHashtag = tag?.hashtag ?? 'tag${index + 1}';
          return Container(
            key: ValueKey('tag_$tagHashtag'),
            height: IsrDimens.sixty,
            margin: IsrDimens.edgeInsetsSymmetric(
              vertical: 4.responsiveDimension,
              horizontal: 8.responsiveDimension,
            ),
            child: TapHandler(
              onTap: () {
                _onTagTapped(tag);
              },
              child: Padding(
                padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.sixteen,
                ),
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

  Widget _buildPlacesListWithoutController(
    List<dynamic> places,
  ) =>
      ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final resultList = (places as List<Result>)
              .map(UnifiedLocationItem.fromLocationResult)
              .toList();

          final result = resultList[index];
          final placeName = result.title;
          return Container(
            key: ValueKey('place_${result.placeId}'),
            margin: _searchScreenUIConfig?.placesListConfig?.margin ??
                IsrDimens.edgeInsetsSymmetric(
                  vertical: 4.responsiveDimension,
                  horizontal: 8.responsiveDimension,
                ),
            child: TapHandler(
              onTap: () => _handlePlaceTap(result.placeId, placeName),
              child: Padding(
                padding: _searchScreenUIConfig?.placesListConfig?.padding ??
                    IsrDimens.edgeInsetsSymmetric(
                      horizontal: 16.responsiveDimension,
                      vertical: 12.responsiveDimension,
                    ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.responsiveDimension),
                      child: _searchScreenUIConfig?.placesListConfig?.icon !=
                              null
                          ? AppImage.svg(
                              _searchScreenUIConfig!.placesListConfig!.icon!,
                              width: _searchScreenUIConfig
                                  ?.placesListConfig?.iconSize,
                              height: _searchScreenUIConfig
                                  ?.placesListConfig?.iconSize,
                              color: _searchScreenUIConfig
                                  ?.placesListConfig?.iconColor,
                            )
                          : const AppImage.svg(AssetConstants.icPlacesIcon),
                    ),
                    SizedBox(
                      width: _searchScreenUIConfig?.placesListConfig?.spacing ??
                          12.responsiveDimension,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            style: _searchScreenUIConfig
                                    ?.placesListConfig?.titleStyle ??
                                IsrStyles.primaryText14Bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (result.subtitle?.isNotEmpty == true) ...[
                            SizedBox(
                              height: _searchScreenUIConfig
                                      ?.placesListConfig?.spacing ??
                                  4.responsiveDimension,
                            ),
                            Text(
                              result.subtitle ?? '',
                              style: _searchScreenUIConfig
                                      ?.placesListConfig?.subtitleStyle ??
                                  IsrStyles.primaryText12.copyWith(
                                    color: IsrColors.color9B9B9B,
                                  ),
                              maxLines: 2,
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

  Widget _buildAccountsListWithoutController(
    List<dynamic> accounts,
  ) =>
      ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final user = accounts[index] as SocialUserData;
          return Container(
            key: ValueKey('account_${user.id}'),
            height: _searchScreenUIConfig?.accountsListConfig?.itemHeight ??
                80.responsiveDimension,
            margin: _searchScreenUIConfig?.accountsListConfig?.margin ??
                IsrDimens.edgeInsetsSymmetric(
                  vertical: 4.responsiveDimension,
                  horizontal: 8.responsiveDimension,
                ),
            child: TapHandler(
              onTap: () => _handleAccountTap(user),
              child: Padding(
                padding: _searchScreenUIConfig?.accountsListConfig?.padding ??
                    IsrDimens.edgeInsetsSymmetric(
                      horizontal: 16.responsiveDimension,
                      vertical: 12.responsiveDimension,
                    ),
                child: Row(
                  children: [
                    Container(
                      width: _searchScreenUIConfig
                              ?.accountsListConfig?.avatarSize ??
                          56.responsiveDimension,
                      height: _searchScreenUIConfig
                              ?.accountsListConfig?.avatarSize ??
                          56.responsiveDimension,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _searchScreenUIConfig
                                  ?.accountsListConfig?.avatarBorderColor ??
                              IsrColors.colorDBDBDB,
                          width: _searchScreenUIConfig
                                  ?.accountsListConfig?.avatarBorderWidth ??
                              1,
                        ),
                      ),
                      child: ClipOval(
                        child: AppImage.network(
                          user.avatarUrl ?? '',
                          height: _searchScreenUIConfig
                                  ?.accountsListConfig?.avatarSize ??
                              56.responsiveDimension,
                          width: _searchScreenUIConfig
                                  ?.accountsListConfig?.avatarSize ??
                              56.responsiveDimension,
                          fit: BoxFit.cover,
                          isProfileImage: true,
                          name: user.fullName ?? '',
                        ),
                      ),
                    ),
                    SizedBox(
                      width:
                          _searchScreenUIConfig?.accountsListConfig?.spacing ??
                              12.responsiveDimension,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username ?? 'Unknown User',
                            style: _searchScreenUIConfig
                                    ?.accountsListConfig?.usernameStyle ??
                                IsrStyles.primaryText16Bold.copyWith(
                                  color: IsrColors.color242424,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          4.responsiveVerticalSpace,
                          Text(
                            user.fullName ??
                                user.displayName ??
                                'No description',
                            style: _searchScreenUIConfig
                                    ?.accountsListConfig?.fullNameStyle ??
                                IsrStyles.primaryText14.copyWith(
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
        child: tabType == SearchTabType.places &&
                (!_isLocationServiceEnabled || !_isPlacesPermissionGranted)
            ? _buildPlacesPermissionState()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _searchScreenUIConfig?.emptyStateConfig?.icon != null
                      ? AppImage.svg(
                          _searchScreenUIConfig!.emptyStateConfig!.icon!,
                          width: _searchScreenUIConfig
                                  ?.emptyStateConfig?.iconSize ??
                              IsrDimens.eighty,
                          height: _searchScreenUIConfig
                                  ?.emptyStateConfig?.iconSize ??
                              IsrDimens.eighty,
                          color: _searchScreenUIConfig
                                  ?.emptyStateConfig?.iconColor ??
                              IsrColors.color9B9B9B,
                        )
                      : AppImage.svg(
                          AssetConstants.icNoProductsAvailable,
                          width: IsrDimens.eighty,
                          height: IsrDimens.eighty,
                          color: IsrColors.color9B9B9B,
                        ),
                  SizedBox(
                    height: _searchScreenUIConfig?.emptyStateConfig?.spacing ??
                        IsrDimens.sixteen.responsiveDimension,
                  ),
                  Text(
                    _getEmptyStateTitle(tabType),
                    style:
                        _searchScreenUIConfig?.emptyStateConfig?.titleStyle ??
                            IsrStyles.primaryText16Bold.copyWith(
                              color: IsrColors.color242424,
                            ),
                  ),
                  IsrDimens.eight.responsiveVerticalSpace,
                  Text(
                    _getEmptyStateMessage(tabType),
                    style:
                        _searchScreenUIConfig?.emptyStateConfig?.messageStyle ??
                            IsrStyles.primaryText14.copyWith(
                              color: IsrColors.color9B9B9B,
                            ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      );

  Widget _buildPlacesPermissionState() => LocationPermissionPlaceholder(
        subtitle: _isLocationServiceEnabled
            ? 'To include nearby places, allow location permission'
            : 'To include nearby places, turn on location services',
        buttonText: _isLocationServiceEnabled
            ? 'Allow Location Permission'
            : 'Turn On Location Services',
        isLoading: _isCheckingPlacesPermission,
        onPressed: _requestPlacesPermissionIfNeeded,
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
        decoration: _searchScreenUIConfig?.postCardConfig?.decoration ??
            BoxDecoration(
              color: _searchScreenUIConfig?.postCardConfig?.backgroundColor ??
                  IsrColors.white,
              borderRadius: BorderRadius.circular(
                _searchScreenUIConfig?.postCardConfig?.borderRadius ??
                    8.responsiveDimension,
              ),
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            _searchScreenUIConfig?.postCardConfig?.borderRadius ??
                8.responsiveDimension,
          ),
          child: Stack(
            children: [
              _buildPostImage(post),
              _buildUserProfileOverlay(post),
              if (post.tags?.products?.isEmptyOrNull == false)
                _buildShopButtonOverlay(post),
              if (post.media?.first.mediaType?.mediaType == MediaType.video)
                _buildVideoIcon(),
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
        color: _searchScreenUIConfig
                ?.postCardConfig?.placeholderConfig?.backgroundColor ??
            IsrColors.colorF5F5F5,
        child: Icon(
          _searchScreenUIConfig?.postCardConfig?.placeholderConfig?.icon ??
              Icons.image,
          color: _searchScreenUIConfig
                  ?.postCardConfig?.placeholderConfig?.iconColor ??
              IsrColors.color9B9B9B,
          size: _searchScreenUIConfig
                  ?.postCardConfig?.placeholderConfig?.iconSize ??
              IsrDimens.forty,
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
          padding: _searchScreenUIConfig
                  ?.postCardConfig?.userProfileOverlayConfig?.padding ??
              IsrDimens.edgeInsetsAll(IsrDimens.eight),
          child: Row(
            children: [
              AppImage.network(
                post.user?.avatarUrl ?? '',
                height: _searchScreenUIConfig?.postCardConfig
                        ?.userProfileOverlayConfig?.avatarSize ??
                    20.responsiveDimension,
                width: _searchScreenUIConfig?.postCardConfig
                        ?.userProfileOverlayConfig?.avatarSize ??
                    20.responsiveDimension,
                name: post.user?.fullName ?? '',
                isProfileImage: true,
                textColor: _searchScreenUIConfig
                        ?.postCardConfig?.userProfileOverlayConfig?.textColor ??
                    IsrColors.white,
              ),
              IsrDimens.eight.responsiveHorizontalSpace,
              Expanded(
                child: Text(
                  post.user?.fullName ?? 'Unknown User',
                  style: _searchScreenUIConfig?.postCardConfig
                          ?.userProfileOverlayConfig?.textStyle ??
                      IsrStyles.primaryText12.copyWith(
                        color: _searchScreenUIConfig?.postCardConfig
                                ?.userProfileOverlayConfig?.textColor ??
                            IsrColors.white,
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
            border:
                Border.all(color: IsrColors.white.applyOpacity(0.2), width: 1),
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
              AppImage.svg(AssetConstants.icCartIcon, color: IsrColors.white),
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
            padding: _searchScreenUIConfig
                    ?.postCardConfig?.videoIconConfig?.padding ??
                IsrDimens.edgeInsetsAll(IsrDimens.eight),
            decoration: _searchScreenUIConfig
                    ?.postCardConfig?.videoIconConfig?.decoration ??
                BoxDecoration(
                  color: _searchScreenUIConfig
                          ?.postCardConfig?.videoIconConfig?.backgroundColor ??
                      IsrColors.black.applyOpacity(0.3),
                  borderRadius: BorderRadius.circular(
                    _searchScreenUIConfig
                            ?.postCardConfig?.videoIconConfig?.borderRadius ??
                        IsrDimens.twentyFour,
                  ),
                ),
            child: Icon(
              _searchScreenUIConfig?.postCardConfig?.videoIconConfig?.icon ??
                  Icons.play_arrow,
              color: _searchScreenUIConfig
                      ?.postCardConfig?.videoIconConfig?.iconColor ??
                  IsrColors.white,
              size: _searchScreenUIConfig
                      ?.postCardConfig?.videoIconConfig?.iconSize ??
                  IsrDimens.twentyFour,
            ),
          ),
        ),
      );

  String _getHasTagValue() =>
      _hashtagController.text.trim().replaceFirst('#', '');

  void _onTagTapped(dynamic tag) {
    final tagText = (tag?.hashtag as String?) ?? '';

    // Log hashtag clicked event
    _logHashtagEvent(tagText);

    IsrAppNavigator.navigateTagDetails(
      context,
      tagValue: tagText,
      tagType: TagType.hashtag,
    );
  }

  void _handlePlaceTap(String placeId, String placeName) {
    final completer = Completer<void>();

    // Use BLoC to handle place details fetching
    _postListingBloc.add(
      GetPlaceDetailsEvent(
        placeId: placeId,
        onComplete: (placeDetails) {
          completer.complete();
          _goToPlaceDetailsScreen(placeDetails);
        },
      ),
    );
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

  void _handleAccountTap(SocialUserData user) {
    // Log profile viewed event
    _logSearchProfileEvent(user.id ?? '', user.username ?? '');

    if (IsrVideoReelConfig.postConfig.postCallBackConfig?.onProfileClick !=
        null) {
      IsrVideoReelConfig.postConfig.postCallBackConfig?.onProfileClick?.call(
        null,
        user.id ?? '',
        user.isFollowing,
      );
    }

    // Navigate to user profile
    // IsmInjectionUtils.getRouteManagement().goToUserProfileDetail(
    //   userId: user.id ?? '',
    //   incomingFrom: 'search',
    // );
  }

  /// Log search event when user performs a search
  void _logSearchEvent(
    String searchQuery,
    int searchResultsCount,
    String searchFilter,
  ) {
    final searchEventMap = {
      'search_query': searchQuery,
      'search_results_count': searchResultsCount,
      'search_filter': searchFilter,
    };
    EventQueueProvider.instance.logEvent(
      EventType.searchPerformed.value,
      searchEventMap.removeEmptyValues(),
    );
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
    final hashtags = post.tags?.hashtags
            ?.map((h) => '#${h.tag}')
            .where((tag) => tag.isNotEmpty)
            .toList() ??
        [];

    final eventMap = {
      'search_query': searchQuery,
      'result_post_id': post.id ?? '',
      'post_type': postType,
      'post_author_id': post.userId ?? '',
      'hashtags': hashtags,
    };
    EventQueueProvider.instance.logEvent(
      EventType.searchResultClicked.value,
      eventMap.removeEmptyValues(),
    );
  }

  /// Log event when user clicks on a tag in search results
  void _logHashtagEvent(String hashTag) {
    final hashTagEventMap = {'hashtag': hashTag};
    EventQueueProvider.instance.logEvent(
      EventType.hashTagClicked.value,
      hashTagEventMap.removeEmptyValues(),
    );
  }

  /// Log event when user clicks on an account in search results
  void _logSearchProfileEvent(String profileUserId, String profileUserName) {
    final profileEvent = {
      'profile_user_id': profileUserId,
      'profile_username': profileUserName,
    };
    EventQueueProvider.instance.logEvent(
      EventType.profileViewed.value,
      profileEvent.removeEmptyValues(),
    );
  }

  // Follow button widget with API integration
  Widget _buildFollowButton(SocialUserData user) {
    final followCfg =
        _searchScreenUIConfig?.accountsListConfig?.followButtonConfig;
    final isPrivate = (user.isPrivate ?? 0) == 1;
    return FollowActionWidget(
      userId: user.id ?? '',
      isFollowing: user.isFollowing ?? false,
      callProfileApi: false,
      isTargetPrivate: isPrivate,
      initialFollowStatus: user.followStatus,
      initialIsRequested: user.isRequested,
      builder: (isLoading, isFollowing, followRequestPending, onTap) {
        if (isLoading) {
          return Utility.loaderWidget(isAdaptive: false);
        }
        if (followRequestPending) {
          return AppButton(
            height: followCfg?.height ?? 30.responsiveDimension,
            width: followCfg?.width ?? 95.responsiveDimension,
            borderRadius: followCfg?.borderRadius ?? 20,
            title: followCfg?.requestedText ?? IsrTranslationFile.requested,
            type: ButtonType.secondary,
            borderColor: followCfg?.backgroundColor ?? IsrColors.appColor,
            backgroundColor:
                followCfg?.requestedBackgroundColor ?? IsrColors.white,
            textStyle: followCfg != null && followCfg.textStyle != null
                ? followCfg.textStyle!.copyWith(
                    color: followCfg.textColor ?? IsrColors.appColor,
                  )
                : IsrStyles.primaryText12.copyWith(
                    color: followCfg?.textColor ?? IsrColors.appColor,
                    fontWeight: FontWeight.w600,
                  ),
            onPress: () {
              onTap.call();
            },
          );
        }
        if (!isFollowing) {
          final showRequest = FollowRelationshipUi.showRequestPrimaryLabel(
            isFollowing: isFollowing,
            isPrivateAccount: isPrivate,
            isRequested: user.isRequested,
            followStatus: user.followStatus,
          );
          final title = showRequest
              ? (followCfg?.requestText ?? IsrTranslationFile.request)
              : (followCfg?.text ?? IsrTranslationFile.follow);
          return AppButton(
            height: followCfg?.height ?? 30.responsiveDimension,
            width: followCfg?.width ?? 90.responsiveDimension,
            borderRadius: followCfg?.borderRadius ?? 20,
            title: title,
            backgroundColor: followCfg?.backgroundColor,
            textStyle: followCfg?.textStyle ??
                IsrStyles.primaryText12.copyWith(
                  color: followCfg?.textColor ?? IsrColors.white,
                  fontWeight: FontWeight.w600,
                ),
            onPress: () {
              onTap.call();
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PlacesPermissionSnapshot {
  const _PlacesPermissionSnapshot({
    required this.serviceEnabled,
    required this.permissionGranted,
  });

  final bool serviceEnabled;
  final bool permissionGranted;
}
