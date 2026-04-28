part of 'follow_requests_cubit.dart';

class FollowRequestsState {
  const FollowRequestsState({
    this.incoming = const [],
    this.outgoing = const [],
    this.incomingLoading = false,
    this.outgoingLoading = false,
    this.incomingHasMore = true,
    this.outgoingHasMore = true,
    this.incomingPage = 1,
    this.outgoingPage = 1,
  });

  final List<FollowRequestItem> incoming;
  final List<FollowRequestItem> outgoing;
  final bool incomingLoading;
  final bool outgoingLoading;
  final bool incomingHasMore;
  final bool outgoingHasMore;
  final int incomingPage;
  final int outgoingPage;

  FollowRequestsState copyWith({
    List<FollowRequestItem>? incoming,
    List<FollowRequestItem>? outgoing,
    bool? incomingLoading,
    bool? outgoingLoading,
    bool? incomingHasMore,
    bool? outgoingHasMore,
    int? incomingPage,
    int? outgoingPage,
  }) =>
      FollowRequestsState(
        incoming: incoming ?? this.incoming,
        outgoing: outgoing ?? this.outgoing,
        incomingLoading: incomingLoading ?? this.incomingLoading,
        outgoingLoading: outgoingLoading ?? this.outgoingLoading,
        incomingHasMore: incomingHasMore ?? this.incomingHasMore,
        outgoingHasMore: outgoingHasMore ?? this.outgoingHasMore,
        incomingPage: incomingPage ?? this.incomingPage,
        outgoingPage: outgoingPage ?? this.outgoingPage,
      );
}
