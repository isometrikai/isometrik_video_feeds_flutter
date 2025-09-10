import 'package:flutter/material.dart';

class IsolatedPageView extends StatefulWidget {
  const IsolatedPageView({
    super.key,
    required this.controller,
    required this.currentPageIndex,
    required this.itemCount,
    required this.onPageChanged,
    required this.widgetFunction,
    required this.onTap,
  });
  final PageController controller;
  final int currentPageIndex;
  final int itemCount;
  final Function(int) onPageChanged;
  final Widget Function(int) widgetFunction;
  final VoidCallback onTap;

  @override
  State<IsolatedPageView> createState() => _IsolatedPageViewState();
}

class _IsolatedPageViewState extends State<IsolatedPageView> {
  int lastItemCount = 0;

  @override
  void didUpdateWidget(covariant IsolatedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      // only rebuild when itemCount actually changes
      setState(() {
        lastItemCount = widget.itemCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        child: PageView.builder(
          key: const ValueKey('page_view_builder'),
          controller: widget.controller,
          padEnds: false,
          pageSnapping: true,
          physics: const ClampingScrollPhysics(),
          itemCount: lastItemCount,
          onPageChanged: widget.onPageChanged,
          itemBuilder: (context, index) => widget.widgetFunction(index),
        ),
      );

  // Widget _buildPageViewItem(int index) {
  //   final media = widget.mediaList[index];
  //   final isCurrentPage = index == widget.currentPageIndex;
  //
  //   if (media.mediaType == kPictureType) {
  //     return _getImageWidget(
  //       imageUrl: media.mediaUrl,
  //       width: IsrDimens.getScreenWidth(context),
  //       height: IsrDimens.getScreenHeight(context),
  //       fit: BoxFit.contain,
  //     );
  //   } else {
  //     return isCurrentPage
  //         ? _buildCarousalVideoContent()
  //         : _getImageWidget(
  //             imageUrl: media.thumbnailUrl,
  //             width: IsrDimens.getScreenWidth(context),
  //             height: IsrDimens.getScreenHeight(context),
  //             fit: BoxFit.cover,
  //             filterQuality: FilterQuality.low,
  //           );
  //   }
  // }
}
