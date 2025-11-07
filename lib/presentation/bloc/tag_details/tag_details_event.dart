part of 'tag_details_bloc.dart';

abstract class TagDetailsEvent {
  const TagDetailsEvent();
}

class GetTagDetailsEvent extends TagDetailsEvent {
  const GetTagDetailsEvent({
    required this.tagValue,
    required this.tagType,
    this.isFromPagination = false,
  });

  final String tagValue;
  final TagType tagType;
  final bool isFromPagination;
}

class RefreshTagDetailsEvent extends TagDetailsEvent {
  const RefreshTagDetailsEvent({
    required this.tagValue,
    required this.tagType,
  });

  final String tagValue;
  final TagType tagType;
}
