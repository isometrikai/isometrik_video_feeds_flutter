import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class SchedulePostView extends StatefulWidget {
  const SchedulePostView({Key? key, this.onLinkProduct}) : super(key: key);
  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
      onLinkProduct;

  @override
  State<SchedulePostView> createState() => _SchedulePostViewState();
}

class _SchedulePostViewState extends State<SchedulePostView> {
  late final PostListingBloc _postListingBloc;
  final _postList = <TimeLineData>[];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  static const int _pageSize = 30;

  @override
  void initState() {
    _postListingBloc = context.getOrCreateBloc<PostListingBloc>();
    _postListingBloc.add(GetUserPostListEvent(scheduledOnly: true));
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    _postListingBloc.add(GetUserPostListEvent(
      scheduledOnly: true,
      page: _currentPage,
      pageSize: _pageSize,
    ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider<PostListingBloc>(
        create: (BuildContext context) => _postListingBloc,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: const IsmCustomAppBarWidget(
            titleText: IsrTranslationFile.scheduledPosts,
            centerTitle: true,
          ),
          body: SafeArea(
            child: BlocConsumer<PostListingBloc, PostListingState>(
              buildWhen: (previous, current) =>
                  current is PostLoadedState ||
                  current is PostListingLoadingState,
              listenWhen: (previous, current) =>
                  current is PostLoadedState ||
                  current is PostListingLoadingState,
              listener: (context, state) {
                if (state is PostLoadedState) {
                  setState(() {
                    if (state.isLoadMore) {
                      _postList.addAll(state.postList);
                    } else {
                      _postList.clear();
                      _postList.addAll(state.postList);
                      _currentPage = 1;
                    }
                    _isLoadingMore = false;
                    _hasMoreData = state.postList.length >= _pageSize;
                  });
                }
              },
              builder: (context, state) => RefreshIndicator(
                onRefresh: () {
                  final completer = Completer<void>();
                  _postListingBloc.add(GetUserPostListEvent(
                      scheduledOnly: true,
                      page: 1,
                      pageSize: _pageSize,
                      onComplete: (posts) {
                        setState(() {
                          _postList.clear();
                          _postList.addAll(posts);
                          _currentPage = 1;
                          _hasMoreData = posts.length >= _pageSize;
                        });
                        completer.complete();
                      }));
                  return completer.future;
                },
                child: (_postList.isNotEmpty)
                    ? ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _postList.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index == _postList.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: AppLoader(),
                              ),
                            );
                          }
                          return _buildScheduledPostItem(
                              context, _postList[index]);
                        },
                      )
                    : (state is PostListingLoadingState
                        ? const Center(child: AppLoader())
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: _buildEmptyState(SearchTabType.posts),
                            ),
                          )),
              ),
            ),
          ),
        ),
      );

  Widget _buildScheduledPostItem(BuildContext context, TimeLineData data) =>
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Post thumbnail image
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 75.responsiveDimension,
                height: 75.responsiveDimension,
                color: Colors.grey[300],
                child: AppImage.network(
                  data.previews?.firstOrNull?.url ??
                      data.media
                          ?.where(
                              (e) => e.mediaType?.mediaType == MediaType.photo)
                          .firstOrNull
                          ?.url ??
                      '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Post content and schedule info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Post text
                  Text(
                    data.caption ?? '',
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: IsrStyles.primaryText12.copyWith(
                      fontSize: 13.responsiveDimension,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scheduled time
                  Text(
                    'Scheduled for ${_getFormatedData(data.scheduledAt ?? '')}',
                    style: IsrStyles.primaryText12.copyWith(
                      color: '#848484'.color,
                    ),
                  ),
                ],
              ),
            ),

            // Three-dot menu button
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: () {
                _showPostOptionsMenu(context, data);
              },
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  String _getFormatedData(String utcDateTime) {
    try {
      final dateTime =
          DateTime.parse(utcDateTime).toLocal(); // convert UTC → local
      final formatted = DateFormat('MMM d, hh:mm a').format(dateTime);
      return formatted.replaceAll('AM', 'am').replaceAll('PM', 'pm');
    } catch (e) {
      return '';
    }
  }

  void _showPostOptionsMenu(BuildContext context, TimeLineData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Divider(height: 1),
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(
                  IsrTranslationFile.postNow,
                  textAlign: TextAlign.center,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: IsrColors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handlePostNow(data);
                },
              ),
              const Divider(height: 1),
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(
                  IsrTranslationFile.modifySchedule,
                  textAlign: TextAlign.center,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: IsrColors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleModifySchedule(data);
                },
              ),
              const Divider(height: 1),
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(
                  IsrTranslationFile.editPost,
                  textAlign: TextAlign.center,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: IsrColors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleEditPost(data);
                },
              ),
              const Divider(height: 1),
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(
                  IsrTranslationFile.deletePost,
                  textAlign: TextAlign.center,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: IsrColors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeletePost(data);
                },
              ),
              const Divider(height: 1),
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(
                  IsrTranslationFile.cancel,
                  textAlign: TextAlign.center,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: IsrColors.black,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchTabType tabType) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage.svg(
              AssetConstants.icNoScheduledPost,
              width: IsrDimens.eighty,
              height: IsrDimens.eighty,
              color: IsrColors.color9B9B9B,
            ),
            IsrDimens.sixteen.responsiveVerticalSpace,
            Text(
              IsrTranslationFile.noScheduledPosts,
              style: IsrStyles.primaryText16Bold.copyWith(
                color: IsrColors.color242424,
              ),
            ),
            IsrDimens.eight.responsiveVerticalSpace,
            Text(
              IsrTranslationFile.addNewScheduledPosts,
              style: IsrStyles.primaryText14.copyWith(
                color: IsrColors.color9B9B9B,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _handlePostNow(TimeLineData data) {
    Utility.showToastMessage('upcoming');
    debugPrint('Post now at index: ${data.toMap()}');
  }

  void _handleModifySchedule(TimeLineData data) {
    _showScheduleBottomSheet(data, (dateTime) {
      final selectedDateUtc =
          DateTimeUtil.getIsoDate(dateTime.millisecondsSinceEpoch, isUtc: true);
      _postListingBloc.add(ModifyPostScheduleEvent(
        postId: data.id ?? '',
        scheduleTime: selectedDateUtc,
        onComplete: (success) {
          if (success) {
              setState(() {
                _postList
                    .where((post) => post.id == data.id)
                    .firstOrNull
                    ?.scheduledAt = selectedDateUtc;
              });
            }
          }
      ));
    });
  }

  void _handleEditPost(TimeLineData data) async {
    final postDataString = await IsrAppNavigator.goToEditPostView(context,
        postData: data, onTagProduct: widget.onLinkProduct);
    try {
      final postData = TimeLineData.fromMap(
          jsonDecode(postDataString!) as Map<String, dynamic>);
      final index =
          _postList.indexWhere((element) => element.id == postData.id);
      if (index != -1) {
        setState(() {
          _postList[index] = postData;
        });
        Utility.showToastMessage(IsrTranslationFile.postUpdatedSuccessfully);
      }
    } catch (e) {
      debugPrint('Error handling edit post: $e');
    }
  }

  void _handleDeletePost(TimeLineData data) async {
    final result = await _showDeletePostDialog(context);
    if (result == true) {
      _postListingBloc.add(DeleteUserPostEvent(
          postId: data.id ?? '',
          onComplete: (isSuccess) {
            if (isSuccess) {
              Utility.showToastMessage(
                  IsrTranslationFile.postDeletedSuccessfully);
              setState(() {
                _postList.remove(data);
              });
            }
          }));
    }
  }

  Future<bool?> _showDeletePostDialog(BuildContext context) => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.deletePost,
                  style: IsrStyles.primaryText18
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                16.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.deletePostConfirmation,
                  style: IsrStyles.primaryText14.copyWith(
                    color: '4A4A4A'.toColor(),
                  ),
                ),
                32.responsiveVerticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AppButton(
                      title: IsrTranslationFile.delete,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(true),
                      backgroundColor: 'E04755'.toColor(),
                    ),
                    AppButton(
                      title: IsrTranslationFile.cancel,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(false),
                      backgroundColor: 'F6F6F6'.toColor(),
                      textColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  DateTime getBufferedDate() {
    final now = DateTime.now();
    final bufferedDate = now.add(const Duration(minutes: 15));
    return bufferedDate;
  }

  /// Show schedule bottom sheet
  void _showScheduleBottomSheet(
      TimeLineData data, Function(DateTime) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScheduleBottomSheet(data, onSelected),
    );
  }

  /// Build schedule bottom sheet
  Widget _buildScheduleBottomSheet(
      TimeLineData data, Function(DateTime) onSelected) {
    var selectedDate = DateTime.parse(data.scheduledAt ?? '').toLocal();
    var selectedTime = TimeOfDay.fromDateTime(selectedDate);

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: IsrDimens.edgeInsets(
                  top: 12.responsiveDimension, bottom: 16.responsiveDimension),
              width: 40.responsiveDimension,
              height: 4.responsiveDimension,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 20.responsiveDimension,
                  vertical: 8.responsiveDimension),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      IsrTranslationFile.schedulePost,
                      style: IsrStyles.primaryText20
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Date field
            Container(
              margin: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 20.responsiveDimension,
                  vertical: 8.responsiveDimension),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${IsrTranslationFile.date}*',
                    style: IsrStyles.primaryText12,
                  ),
                  8.verticalSpace,
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: getBufferedDate(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.black,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                              secondary: Colors.black,
                              onSecondary: Colors.white,
                              surfaceContainerHighest: Color(0xFFF5F5F5),
                              onSurfaceVariant: Colors.black54,
                            ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              elevation: 8,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                            datePickerTheme: const DatePickerThemeData(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              headerBackgroundColor: Colors.white,
                              headerForegroundColor: Colors.black,
                              weekdayStyle: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              dayStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              yearStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedDate != null) {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        setModalState(() {});
                      }
                    },
                    child: Container(
                      padding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: 16.responsiveDimension,
                          vertical: 16.responsiveDimension),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(selectedDate),
                              style: IsrStyles.primaryText14,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time field
            Container(
              margin: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 20.responsiveDimension,
                  vertical: 8.responsiveDimension),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${IsrTranslationFile.time}*',
                    style: IsrStyles.primaryText12,
                  ),
                  8.verticalSpace,
                  GestureDetector(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.black,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                              outline: Color(0xFFE0E0E0),
                              secondary: Colors.black,
                              onSecondary: Colors.white,
                            ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                            // timePickerTheme: const TimePickerThemeData(
                            //   backgroundColor: Colors.white,
                            //   dialBackgroundColor: Color(0xFFF5F5F5),
                            //   dialHandColor: Colors.black,
                            //   dialTextColor: Colors.black,
                            //   hourMinuteTextColor: Colors.black,
                            //   hourMinuteColor: Color(0xFFF5F5F5),
                            //   dayPeriodTextColor: Colors.black,
                            //   dayPeriodColor: Color(0xFFF5F5F5),
                            //   dayPeriodBorderSide: BorderSide(
                            //     color: Color(0xFFE0E0E0),
                            //     width: 1,
                            //   ),
                            //   entryModeIconColor: Colors.black,
                            //   helpTextStyle: TextStyle(color: Colors.black),
                            // ),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedTime != null) {
                        selectedTime = pickedTime;
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setModalState(() {});
                      }
                    },
                    child: Container(
                      padding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: 16.responsiveDimension,
                          vertical: 16.responsiveDimension),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatTime(selectedTime),
                              style: IsrStyles.primaryText14,
                            ),
                          ),
                          Icon(Icons.access_time, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Save button
            AppButton(
              height: 44.responsiveDimension,
              margin: IsrDimens.edgeInsetsAll(20.responsiveDimension),
              borderRadius: 22.responsiveDimension,
              textStyle:
                  IsrStyles.white14.copyWith(fontWeight: FontWeight.w600),
              onPress: () {
                debugPrint('Selected date: $selectedDate');
                debugPrint('Current time: ${DateTime.now()}');
                debugPrint(
                    'Is future: ${selectedDate.isAfter(DateTime.now())}');

                // Validate buffer time before saving
                if (_validateScheduleTime(selectedDate)) {
                  debugPrint('✅ Validation passed - saving schedule');
                  onSelected.call(selectedDate);
                  Navigator.pop(context);
                } else {
                  debugPrint('❌ Validation failed - showing error');
                  // Show error message for invalid time
                  Utility.showAppDialog(
                    message: IsrTranslationFile.pleaseSelectAFutureTime,
                  );
                }
              },
              title: IsrTranslationFile.save,
            ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format time for display
  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Validate schedule time with buffer logic from bloc
  bool _validateScheduleTime(DateTime selectedDate) {
    final now = DateTime.now();

    // Basic check: must be at least 1 minute in the future
    final oneMinuteLater = now.add(const Duration(minutes: 1));
    if (selectedDate.isBefore(oneMinuteLater)) {
      return false;
    }

    return true;
  }
}
