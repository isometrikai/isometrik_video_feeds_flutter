import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_strip_widget.dart';

class IsmStoryWidget extends StatefulWidget {
  const IsmStoryWidget({
    super.key,
    this.autoLoad = true,
  });

  final bool autoLoad;

  @override
  State<IsmStoryWidget> createState() => _IsmStoryWidgetState();
}

class _IsmStoryWidgetState extends State<IsmStoryWidget> {
  late final StoryCubit _storyCubit;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _storyCubit = IsmInjectionUtils.getBloc<StoryCubit>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && widget.autoLoad) {
      _loaded = true;
      _storyCubit.loadStoryFeed();
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider<StoryCubit>.value(
        value: _storyCubit,
        child: const StoryStripWidget(),
      );
}
