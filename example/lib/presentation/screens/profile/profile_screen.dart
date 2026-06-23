import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/ism_data_provider.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

/// Full profile screen with brief user details and a posts grid.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Future<void> show(BuildContext context) => Navigator.of(
        context,
        rootNavigator: true,
      ).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const ProfileScreen(),
        ),
      );

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final isr.PostListingBloc _postListingBloc;
  final _posts = <isr.TimeLineData>[];
  final _scrollController = ScrollController();

  var _displayName = '';
  var _username = '';
  var _avatarUrl = '';
  var _isLoadingProfile = true;
  var _isLoadingMore = false;
  var _hasMoreData = true;
  var _currentPage = 1;
  static const _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _postListingBloc = context.getOrCreateBloc<isr.PostListingBloc>();
    _scrollController.addListener(_onScroll);
    unawaited(_loadProfile());
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final local = InjectionUtils.getUseCase<LocalDataUseCase>();
    final firstName = await local.getFirstName();
    final lastName = await local.getLastName();
    final profilePic = await local.getProfilePic();
    final userId = await local.getUserId();

    if (!mounted) return;
    setState(() {
      _displayName = '$firstName $lastName'.trim();
      _avatarUrl = profilePic;
      _isLoadingProfile = false;
    });

    if (userId.isEmpty) return;

    unawaited(
      IsmDataProvider.instance.getSocialUserDetails(
        userId: userId,
        onSuccess: (json, _) {
          if (!mounted) return;
          try {
            final response = isr.SearchUserResponse.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            );
            final user = response.data?.isNotEmpty == true ? response.data!.first : null;
            if (user == null) return;
            setState(() {
              if (user.username?.isNotEmpty == true) {
                _username = user.username!;
              }
              if (user.fullName?.isNotEmpty == true) {
                _displayName = user.fullName!;
              } else if (user.displayName?.isNotEmpty == true) {
                _displayName = user.displayName!;
              }
              if (user.avatarUrl?.isNotEmpty == true) {
                _avatarUrl = user.avatarUrl!;
              }
            });
          } catch (_) {}
        },
      ),
    );
  }

  void _loadPosts({int page = 1, bool loadMore = false}) {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    }
    _postListingBloc.add(isr.GetUserPostListEvent(
      page: page,
      pageSize: _pageSize,
      onComplete: (posts) {
        if (!mounted) return;
        setState(() {
          if (loadMore) {
            _posts.addAll(posts);
          } else {
            _posts
              ..clear()
              ..addAll(posts);
            _currentPage = 1;
          }
          _isLoadingMore = false;
          _hasMoreData = posts.length >= _pageSize;
        });
      },
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200 ||
        _isLoadingMore ||
        !_hasMoreData) {
      return;
    }
    _currentPage++;
    _loadPosts(page: _currentPage, loadMore: true);
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    _loadPosts();
    await _loadProfile();
  }

  Future<void> _onPostTap(int index) async {
    final post = _posts[index];
    final handled = await isr.IsrPostTapHandler.tryHandleTap(
      context,
      postData: post,
      postSectionType: isr.PostSectionType.myPost,
      postDataList: _posts,
      postIndex: index,
      onPostUpdated: () {
        _currentPage = 1;
        _loadPosts();
      },
    );
    if (handled || !mounted) return;

    await isr.IsrAppNavigator.navigateToReelsPlayer(
      context,
      postDataList: _posts,
      startingPostIndex: index,
      postSectionType: isr.PostSectionType.myPost,
      skipOnTapPostCallback: true,
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider<isr.PostListingBloc>(
        create: (_) => _postListingBloc,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            centerTitle: false,
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildProfileHeader()),
                if (_posts.isEmpty && !_isLoadingProfile)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No posts yet',
                        style: TextStyle(color: Color(0xFF848484)),
                      ),
                    ),
                  )
                else
                  _buildPostsGrid(),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: AppLoader()),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildProfileHeader() {
    if (_isLoadingProfile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: AppLoader()),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFEBF0F5),
            backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
            child: _avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 44, color: Color(0xFF829CB6))
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _displayName.isNotEmpty ? _displayName : 'My Profile',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF182028),
            ),
            textAlign: TextAlign.center,
          ),
          if (_username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$_username',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF848484),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Posts', '${_posts.length}'),
              _buildStatDivider(),
              _buildStatItem('Followers', '—'),
              _buildStatDivider(),
              _buildStatItem('Following', '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF182028),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF848484),
              ),
            ),
          ],
        ),
      );

  Widget _buildStatDivider() => Container(
        width: 1,
        height: 28,
        color: const Color(0xFFE8EEF3),
      );

  Widget _buildPostsGrid() => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => isr.TapHandler(
              onTap: () => _onPostTap(index),
              child: isr.PostGridThumbnailTile(post: _posts[index]),
            ),
            childCount: _posts.length,
          ),
        ),
      );
}
