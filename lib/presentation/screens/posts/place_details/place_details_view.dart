import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// A view that displays place details with Google Map and related posts
class PlaceDetailsView extends StatefulWidget {
  PlaceDetailsView({
    super.key,
    this.placeId,
    this.placeName,
    this.latitude,
    this.longitude,
    this.onTapProfilePicture,
  });

  final String? placeId;
  final String? placeName;
  final double? latitude;
  final double? longitude;
  Function(String)? onTapProfilePicture;

  @override
  State<PlaceDetailsView> createState() => _PlaceDetailsViewState();
}

class _PlaceDetailsViewState extends State<PlaceDetailsView> {
  late PlaceDetailsBloc _placeDetailsBloc;

  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  CameraPosition? _initialCameraPosition;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final List<TimeLineData> _postsList = [];
  var _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    // ✅ Get the BLoC from context (from the BlocProvider in the navigation tree)
    _placeDetailsBloc = context.read<PlaceDetailsBloc>();
    _initializeMap();
    _loadPosts();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Check if widget is still mounted and has clients
      if (!mounted || !_scrollController.hasClients) return;

      // Check if scrolled to 65% of the content
      final scrollPercentage = _scrollController.position.pixels /
          _scrollController.position.maxScrollExtent;

      // Trigger pagination at 65% scroll
      if (scrollPercentage >= 0.65 && !_isLoadingMore && _hasMoreData) {
        _loadMorePosts();
      }
    });
  }

  void _loadMorePosts() {
    if (!mounted || _isLoadingMore || widget.placeId.isEmptyOrNull) return;

    setState(() {
      _isLoadingMore = true;
    });

    _placeDetailsBloc.add(GetPlacePostsEvent(
      placeId: widget.placeId ?? '',
      latitude: widget.latitude,
      longitude: widget.longitude,
      isFromPagination: true,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeMap() {
    try {
      final lat = (widget.latitude == null || widget.latitude == 0.0)
          ? 12.9716 // Default to Bangalore
          : widget.latitude!;
      final lng = (widget.longitude == null || widget.longitude == 0.0)
          ? 77.5946 // Default to Bangalore
          : widget.longitude!;

      _initialCameraPosition = CameraPosition(
        target: LatLng(lat, lng),
        zoom: 15.0,
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('place_marker'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: widget.placeName ?? 'Location',
          ),
        ),
      );
    } catch (e) {
      // Fallback to default location if there's an error
      _initialCameraPosition = const CameraPosition(
        target: LatLng(12.9716, 77.5946), // Bangalore
        zoom: 15.0,
      );
    }
  }

  void _loadPosts() {
    if (widget.placeId.isStringEmptyOrNull == false) {
      _placeDetailsBloc.add(GetPlacePostsEvent(
        placeId: widget.placeId ?? '',
        latitude: widget.latitude,
        longitude: widget.longitude,
        isFromPagination: false,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Map Section
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // Google Map
                  if (_initialCameraPosition != null)
                    GoogleMap(
                      initialCameraPosition: _initialCameraPosition!,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        if (!_mapController.isCompleted) {
                          _mapController.complete(controller);
                        }
                      },
                      mapType: MapType.normal,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    )
                  else
                    Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Back Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top +
                        10.responsiveDimension,
                    left: 16.responsiveDimension,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40.responsiveDimension,
                        height: 40.responsiveDimension,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.applyOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20.responsiveDimension,
                        ),
                      ),
                    ),
                  ),

                  // Open in Google Maps Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top +
                        10.responsiveDimension,
                    right: 16.responsiveDimension,
                    child: GestureDetector(
                      onTap: () {
                        final lat = widget.latitude ?? 12.9716;
                        final lng = widget.longitude ?? 77.5946;
                        final placeName = widget.placeName ?? 'Location';
                        openGoogleMaps(lat, lng, placeName);
                      },
                      child: Container(
                        width: 40.responsiveDimension,
                        height: 40.responsiveDimension,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.applyOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions,
                          color: const Color(0xFF1976D2),
                          size: 20.responsiveDimension,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Posts Section
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Section Header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.responsiveDimension,
                        vertical: 12.responsiveDimension,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.placeName.isEmptyOrNull == false
                                ? (widget.placeName ?? '')
                                : 'India - Bengaluru',
                            style: TextStyle(
                              fontSize: 16.responsiveDimension,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Posts Grid with BlocConsumer
                    Expanded(
                      child: BlocConsumer<PlaceDetailsBloc, PlaceDetailsState>(
                        bloc: _placeDetailsBloc,
                        listener: (context, state) {
                          // Reset loading flag when pagination completes
                          if (!mounted) return;

                          if (state is PlacePostsLoadedState ||
                              state is PlaceDetailsErrorState) {
                            if (_isLoadingMore) {
                              setState(() {
                                _isLoadingMore = false;
                              });
                            }
                            if (state is PlacePostsLoadedState) {
                              _hasMoreData = state.hasMoreData;
                              _postsList.clear();
                              _postsList.addAll(state.posts);
                            }
                          }
                        },
                        builder: (context, state) {
                          if (state is PlaceDetailsLoadingState &&
                              state.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is PlaceDetailsErrorState) {
                            return _buildErrorState(state.error);
                          }
                          if (_postsList.isEmptyOrNull) {
                            return _buildEmptyState();
                          } else {
                            return _buildPostsGrid(_postsList);
                          }
                        },
                      ),
                    ),
                  ],
                ),
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
              Icons.location_off,
              size: 64.responsiveDimension,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.responsiveDimension),
            Text(
              IsrTranslationFile.noPostsFound,
              style: TextStyle(
                fontSize: 16.responsiveDimension,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.responsiveDimension),
            Text(
              IsrTranslationFile.noPostsDescription,
              style: TextStyle(
                fontSize: 14.responsiveDimension,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

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
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == postList.length) {
                  return _isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                final post = postList[index];
                return TapHandler(
                  key: ValueKey('post_${post.id}'),
                  onTap: () {
                    IsrAppNavigator.navigateToReelsPlayer(
                      context,
                      postDataList: postList,
                      startingPostIndex: index,
                      postSectionType: PostSectionType.tagPost,
                      tagValue: widget.placeId,
                      tagType: TagType.place,
                      onTapProfilePicture: widget.onTapProfilePicture,
                    );
                  },
                  child: _buildPostCard(post, index),
                );
              },
                  childCount: postList.length + (_isLoadingMore ? 1 : 0),
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true),
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
              if (post.tags?.products?.isListEmptyOrNull == false)
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
    if (coverUrl.isStringEmptyOrNull && post.media.isListEmptyOrNull == false) {
      coverUrl = post.media?.first.mediaType?.mediaType == MediaType.video
          ? (post.media?.first.previewUrl.toString() ?? '')
          : post.media?.first.url.toString() ?? '';
    }

    if (coverUrl.isStringEmptyOrNull) {
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
              CircleAvatar(
                radius: IsrDimens.twelve,
                backgroundColor: IsrColors.colorF5F5F5,
                backgroundImage: post.user?.avatarUrl != null
                    ? NetworkImage(post.user!.avatarUrl!)
                    : null,
                child: post.user?.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        color: IsrColors.color9B9B9B,
                        size: IsrDimens.sixteen,
                      )
                    : null,
              ),
              SizedBox(width: 8.responsiveDimension),
              Expanded(
                child: Text(
                  post.user?.fullName ?? 'Unknown User',
                  style: IsrStyles.primaryText12.copyWith(
                    color: IsrColors.white,
                    fontWeight: FontWeight.w800,
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
            color: IsrColors.black.changeOpacity(0.6),
            borderRadius: BorderRadius.circular(8.responsiveDimension),
            border: Border.all(
              color: IsrColors.white.changeOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: IsrColors.black.changeOpacity(0.1),
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
              SizedBox(width: 6.responsiveDimension),
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
                    '${post.tags?.products?.length ?? 0} ${IsrTranslationFile.products}',
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
              color: IsrColors.black.changeOpacity(0.3),
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

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.responsiveDimension,
              color: Colors.red[400],
            ),
            SizedBox(height: 16.responsiveDimension),
            Text(
              IsrTranslationFile.somethingWentWrong,
              style: TextStyle(
                fontSize: 16.responsiveDimension,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.responsiveDimension),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.responsiveDimension,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.responsiveDimension),
            ElevatedButton(
              onPressed: () {
                _placeDetailsBloc.add(RefreshPlacePostsEvent(
                  placeId: widget.placeId ?? '',
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                ));
              },
              child: const Text(IsrTranslationFile.retry),
            ),
          ],
        ),
      );

  /// Returns true if the map was opened successfully, false otherwise
  /// First tries to open Google Maps app, then falls back to webview
  Future<bool> openGoogleMaps(
      double latitude, double longitude, String placeName) async {
    try {
      // URL encode the place name for safe URL usage
      final encodedPlaceName = Uri.encodeComponent(placeName);

      // Platform-specific URL schemes for Google Maps app
      Uri googleMapsAppUri;

      if (Platform.isIOS) {
        // iOS: comgooglemaps://
        googleMapsAppUri = Uri.parse(
          'comgooglemaps://?q=$encodedPlaceName&center=$latitude,$longitude&zoom=15',
        );
      } else if (Platform.isAndroid) {
        // Android: geo: with label
        googleMapsAppUri = Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude($encodedPlaceName)',
        );
      } else {
        // Fallback for other platforms
        googleMapsAppUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedPlaceName&query_place_id=$latitude,$longitude',
        );
      }

      // Try to launch Google Maps app
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(
          googleMapsAppUri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }

      // Fallback to webview if app is not installed
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$encodedPlaceName';
      final webUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(webUri)) {
        await launchUrl(
          webUri,
          mode: LaunchMode.inAppWebView, // Opens in webview
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        return true;
      } else {
        debugPrint('Could not launch Google Maps');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
      return false;
    }
  }
}
