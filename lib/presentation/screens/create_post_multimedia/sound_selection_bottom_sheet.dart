// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart' hide Image;
// import 'package:flutter/widgets.dart' as flutter;
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:ism_video_reel_player/di/di.dart';
// import 'package:ism_video_reel_player/domain/domain.dart';
// import 'package:ism_video_reel_player/presentation/presentation.dart';
// import 'package:ism_video_reel_player/res/res.dart';
// import 'package:ism_video_reel_player/utils/utils.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class SoundSelectionBottomSheet extends StatefulWidget {
//   const SoundSelectionBottomSheet({super.key});
//
//   static Future<MediaEditSoundItem?> show() async =>
//       await Utility.showBottomSheet<MediaEditSoundItem>(
//         child: const SoundSelectionBottomSheet(),
//         isScrollControlled: true,
//         height: 80.percentHeight,
//       );
//
//   @override
//   State<SoundSelectionBottomSheet> createState() =>
//       _SoundSelectionBottomSheetState();
// }
//
// class _SoundSelectionBottomSheetState extends State<SoundSelectionBottomSheet>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   List<SoundData> _trendingSounds = [];
//   List<SoundData> _savedSounds = [];
//   bool _isLoading = false;
//
//   // Audio player state
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   String? _currentlyPlayingSoundId;
//   bool _isPlaying = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _tabController.addListener(() {
//       if (_tabController.indexIsChanging) {
//         _loadSoundsForTab(_tabController.index);
//       }
//     });
//     _loadSoundsForTab(0);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _audioPlayer.dispose();
//     super.dispose();
//   }
//
//   void _loadSoundsForTab(int tabIndex) {
//     final socialPostBloc = InjectionUtils.getBloc<SocialPostBloc>();
//
//     switch (tabIndex) {
//       case 0: // For You (Trending)
//         if (_trendingSounds.isEmpty) {
//           setState(() => _isLoading = true);
//           socialPostBloc.add(GetTrendingSoundsEvent(isLoading: false));
//         }
//         break;
//       case 1: // Saved
//         if (_savedSounds.isEmpty) {
//           setState(() => _isLoading = true);
//           socialPostBloc.add(GetSavedSoundsEvent(isLoading: false));
//         }
//         break;
//       case 2: // Original Audio
//         // No API call needed, just return null
//         break;
//     }
//   }
//
//   void _onSoundSelected(SoundData sound) {
//     final mediaEditSoundItem = MediaEditSoundItem(
//       soundId: sound.id,
//       soundUrl: sound.url,
//       soundImage: sound.previewUrl,
//       soundArtist: sound.artist,
//       soundDuration: sound.duration?.toString(),
//       soundAlbum: sound.album,
//       soundMetadata: {
//         'title': sound.title,
//         'type': sound.type,
//         'usageCount': sound.usageCount,
//         'createdAt': sound.createdAt,
//       },
//     );
//
//     Navigator.pop(context, mediaEditSoundItem);
//   }
//
//   void _onOriginalAudioSelected() {
//     Navigator.pop(context, null);
//   }
//
//   Future<void> _togglePlayPause(SoundData sound) async {
//     try {
//       if (_currentlyPlayingSoundId == sound.id && _isPlaying) {
//         // Pause current sound
//         await _audioPlayer.pause();
//         setState(() {
//           _isPlaying = false;
//         });
//       } else {
//         // Stop any currently playing sound
//         if (_currentlyPlayingSoundId != null) {
//           await _audioPlayer.stop();
//         }
//
//         // Play new sound
//         if (sound.url != null && sound.url!.isNotEmpty) {
//           await _audioPlayer.play(UrlSource(sound.url!));
//           setState(() {
//             _currentlyPlayingSoundId = sound.id;
//             _isPlaying = true;
//           });
//
//           // Listen for completion
//           _audioPlayer.onPlayerComplete.listen((_) {
//             setState(() {
//               _isPlaying = false;
//               _currentlyPlayingSoundId = null;
//             });
//           });
//         }
//       }
//     } catch (e) {
//       // Handle error silently or show a snack bar
//       debugPrint('Error playing audio: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) =>
//       BlocListener<SocialPostBloc, SocialPostState>(
//         listener: (context, state) {
//           if (state is TrendingSoundsLoadedState) {
//             setState(() {
//               _trendingSounds = state.sounds;
//               _isLoading = false;
//             });
//           } else if (state is SavedSoundsLoadedState) {
//             setState(() {
//               _savedSounds = state.sounds;
//               _isLoading = false;
//             });
//           } else if (state is SoundsLoadingState) {
//             setState(() {
//               _isLoading = state.isLoading;
//             });
//           } else if (state is SoundsErrorState) {
//             setState(() {
//               _isLoading = false;
//             });
//             // Show error message
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(state.message)),
//             );
//           }
//         },
//         child: Container(
//           height: 80.percentHeight,
//           decoration: BoxDecoration(
//             color: IsrColors.white,
//             borderRadius: BorderRadius.vertical(
//               top: Radius.circular(Dimens.twentyFour),
//             ),
//           ),
//           child: Column(
//             children: [
//               // Search bar
//               Padding(
//                 padding: EdgeInsets.all(Dimens.sixteen),
//                 child: Container(
//                   height:IsrDimens.fortyEight,
//                   decoration: BoxDecoration(
//                     color: IsrColors.colorF2F2F2.withValues(alpha: 0.3),
//                     borderRadius: BorderRadius.circular(Dimens.twentyFour),
//                   ),
//                   child: Row(
//                     children: [
//                       SizedBox(width:IsrDimens.sixteen),
//                       AppImage.svg(
//                         AssetConstants.icSearchIcon,
//                         height:IsrDimens.twenty,
//                         width:IsrDimens.twenty,
//                         color: IsrColors.color9B9B9B,
//                       ),
//                       SizedBox(width:IsrDimens.twelve),
//                       Text(
//                         'Search Music',
//                         style: TextStyle(
//                           color: IsrColors.color9B9B9B,
//                           fontSize:IsrDimens.fourteen,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height:IsrDimens.sixteen),
//
//               // Tabs
//               Container(
//                 margin: EdgeInsets.symmetric(horizontal:IsrDimens.sixteen),
//                 height:IsrDimens.forty,
//                 decoration: BoxDecoration(
//                   color: IsrColors.colorF2F2F2.withValues(alpha: 0.3),
//                   borderRadius: BorderRadius.circular(Dimens.twenty),
//                 ),
//                 child: TabBar(
//                   controller: _tabController,
//                   indicator: BoxDecoration(
//                     color: IsrColors.appColor,
//                     borderRadius: BorderRadius.circular(Dimens.twenty),
//                   ),
//                   indicatorSize: TabBarIndicatorSize.tab,
//                   dividerColor: Colors.transparent,
//                   labelColor: IsrColors.white,
//                   unselectedLabelColor: IsrColors.black,
//                   labelStyle: IsrStyles.primaryText14.copyWith(
//                     fontWeight: FontWeight.w500,
//                   ),
//                   unselectedLabelStyle: IsrStyles.primaryText14.copyWith(
//                     fontWeight: FontWeight.w400,
//                   ),
//                   tabs: [
//                     const Tab(text: 'For You'),
//                     const Tab(text: 'Saved'),
//                     const Tab(text: 'Original Audio'),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height:IsrDimens.sixteen),
//
//               // Content
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     _buildSoundList(_trendingSounds, 'trending'),
//                     _buildSoundList(_savedSounds, 'saved'),
//                     _buildOriginalAudioTab(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//
//   Widget _buildSoundList(List<SoundData> sounds, String type) {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     if (sounds.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.music_note,
//               size:IsrDimens.fortyEight,
//               color: IsrColors.color9B9B9B,
//             ),
//             SizedBox(height:IsrDimens.sixteen),
//             Text(
//               type == 'trending'
//                   ? 'No trending sounds available'
//                   : 'No saved sounds available',
//               style: IsrStyles.primaryText16.copyWith(
//                 color: IsrColors.color9B9B9B,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: EdgeInsets.symmetric(horizontal:IsrDimens.sixteen),
//       itemCount: sounds.length,
//       itemBuilder: (context, index) {
//         final sound = sounds[index];
//         return _buildSoundItem(sound);
//       },
//     );
//   }
//
//   Widget _buildSoundItem(SoundData sound) => Container(
//         margin: EdgeInsets.only(bottom:IsrDimens.eight),
//         padding: EdgeInsets.symmetric(
//             horizontal:IsrDimens.sixteen, vertical:IsrDimens.twelve),
//         child: TapHandler(
//           onTap: () => _onSoundSelected(sound),
//           child: Row(
//             children: [
//               // Sound thumbnail with play/pause button
//               TapHandler(
//                 onTap: () => _togglePlayPause(sound),
//                 child: Container(
//                   width:IsrDimens.fortyEight,
//                   height:IsrDimens.fortyEight,
//                   decoration: BoxDecoration(
//                     color: IsrColors.appColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(Dimens.eight),
//                   ),
//                   child: Stack(
//                     children: [
//                       // Sound image or icon
//                       Expanded(
//                           child: sound.previewUrl != null &&
//                                   sound.previewUrl!.isNotEmpty
//                               ? ClipRRect(
//                                   borderRadius:
//                                       BorderRadius.circular(Dimens.eight),
//                                   child: flutter.Image.network(
//                                     sound.previewUrl!,
//                                     fit: BoxFit.cover,
//                                     width:IsrDimens.fortyEight,
//                                     height:IsrDimens.fortyEight,
//                                     errorBuilder:
//                                         (context, error, stackTrace) => Icon(
//                                       Icons.music_note,
//                                       color: IsrColors.appColor,
//                                       size:IsrDimens.twentyFour,
//                                     ),
//                                   ),
//                                 )
//                               : Center(
//                                 child: Icon(
//                                     Icons.music_note,
//                                     color: IsrColors.appColor,
//                                     size:IsrDimens.twentyFour,
//                                   ),
//                               )),
//
//                       // Play/Pause overlay
//                       Container(
//                         width:IsrDimens.fortyEight,
//                         height:IsrDimens.fortyEight,
//                         decoration: BoxDecoration(
//                           color: Colors.black.withValues(alpha: 0.3),
//                           borderRadius: BorderRadius.circular(Dimens.eight),
//                         ),
//                         child: Center(
//                           child: Icon(
//                             _currentlyPlayingSoundId == sound.id && _isPlaying
//                                 ? Icons.pause
//                                 : Icons.play_arrow,
//                             color: IsrColors.white,
//                             size:IsrDimens.twentyFour,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(width:IsrDimens.twelve),
//
//               // Sound details
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       sound.title ?? 'Unknown Title',
//                       style: IsrStyles.primaryText14.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: IsrColors.black,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height:IsrDimens.four),
//                     Row(
//                       children: [
//                         //Artist
//                         Text(
//                           sound.artist ?? 'Unknown Artist',
//                           style: IsrStyles.primaryText12.copyWith(
//                             color: IsrColors.color9B9B9B,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//
//                         SizedBox(height:IsrDimens.four),
//
//                         // Duration
//                         Text(
//                           _formatDuration(sound.duration),
//                           style: IsrStyles.primaryText12.copyWith(
//                             color: IsrColors.color9B9B9B,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//
//   Widget _buildOriginalAudioTab() => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width:IsrDimens.eighty,
//               height:IsrDimens.eighty,
//               decoration: BoxDecoration(
//                 color: IsrColors.appColor.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(Dimens.forty),
//               ),
//               child: Icon(
//                 Icons.mic,
//                 color: IsrColors.appColor,
//                 size:IsrDimens.forty,
//               ),
//             ),
//             SizedBox(height:IsrDimens.sixteen),
//             Text(
//               'Use Original Audio',
//               style: IsrStyles.primaryText18.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height:IsrDimens.eight),
//             Text(
//               'Keep the original sound from your video',
//               style: IsrStyles.primaryText14.copyWith(
//                 color: IsrColors.color9B9B9B,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height:IsrDimens.twentyFour),
//             TapHandler(
//               onTap: _onOriginalAudioSelected,
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal:IsrDimens.twentyFour,
//                   vertical:IsrDimens.twelve,
//                 ),
//                 decoration: BoxDecoration(
//                   color: IsrColors.appColor,
//                   borderRadius: BorderRadius.circular(Dimens.twentyFour),
//                 ),
//                 child: Text(
//                   'Use Original Audio',
//                   style: IsrStyles.primaryText14.copyWith(
//                     color: IsrColors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//
//   String _formatDuration(double? duration) {
//     if (duration == null) return '0:00';
//
//     final minutes = (duration / 60).floor();
//     final seconds = (duration % 60).floor();
//
//     return '$minutes:${seconds.toString().padLeft(2, '0')}';
//   }
// }
