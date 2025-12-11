import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart'; // for attachBlocIfNeeded

/// Defines which BLoC widget type should be used internally.
/// - [consumer] → Uses `BlocConsumer` (builder + listener)
/// - [builder]  → Uses `BlocBuilder` (UI rebuild only)
/// - [listener] → Uses `BlocListener` (side effects only)
enum SocialActionMode { consumer, builder, listener }

/// A convenience widget that automatically attaches an
/// `IsmSocialActionCubit` to the widget tree (using
/// `attachBlocIfNeeded`) and internally renders either:
///
/// * `BlocConsumer`
/// * `BlocBuilder`
/// * `BlocListener`
///
/// depending on which constructor is used.
///
/// ## Why use this widget?
/// - Reduces boilerplate in UI widgets
/// - Automatically attaches/creates Cubit if missing
/// - Makes API type-safe via dedicated constructors
///
/// ## Constructors:
///
/// ### `IsmSocialActionWidget.consumer`
/// - Provides both `builder` and `listener`.
///
/// ### `IsmSocialActionWidget.builder`
/// - Provides UI rebuild logic only.
///
/// ### `IsmSocialActionWidget.listener`
/// - Provides side-effect logic only; the UI is static.
///
/// This ensures clean usage without nullable traps or runtime errors.
class IsmSocialActionWidget extends StatelessWidget {
  //---------------------------------------------------------------------------
  // Named constructors (safe API)
  //---------------------------------------------------------------------------

  /// Creates a widget that uses `BlocConsumer`.
  /// Must provide both [builder] and [listener].
  const IsmSocialActionWidget.consumer({
    super.key,
    required this.builder,
    required this.listener,
    this.buildWhen,
    this.listenWhen,
  })  : mode = SocialActionMode.consumer,
        child = null;

  /// Creates a widget that uses `BlocBuilder` only.
  /// Must provide [builder]. No listener.
  const IsmSocialActionWidget.builder({
    super.key,
    required this.builder,
    this.buildWhen,
  })  : mode = SocialActionMode.builder,
        listener = null,
        listenWhen = null,
        child = null;

  /// Creates a widget that uses `BlocListener` only.
  /// Must provide [listener]. UI remains constant via [child].
  const IsmSocialActionWidget.listener({
    super.key,
    required this.listener,
    this.listenWhen,
    this.child,
  })  : mode = SocialActionMode.listener,
        builder = null,
        buildWhen = null;

  //---------------------------------------------------------------------------
  // Fields
  //---------------------------------------------------------------------------

  /// Determines which BLoC widget type to build internally.
  final SocialActionMode mode;

  /// UI builder function (for `consumer` and `builder` modes).
  final Widget Function(BuildContext, IsmSocialActionState)? builder;

  /// Listener function for side effects (for `consumer` and `listener` modes).
  final void Function(BuildContext, IsmSocialActionState)? listener;

  /// Static child (used in listener-only mode).
  final Widget? child;

  /// Optional builder condition (used by `BlocBuilder` / `BlocConsumer`).
  final BlocBuilderCondition<IsmSocialActionState>? buildWhen;

  /// Optional listener condition (used by `BlocListener` / `BlocConsumer`).
  final BlocListenerCondition<IsmSocialActionState>? listenWhen;

  //---------------------------------------------------------------------------
  // Main build
  //---------------------------------------------------------------------------

  // @attachBlocIfNeeded
  // Ensures the IsmSocialActionCubit is available in the tree.
  // If not found, it automatically attaches/creates it.
  @override
  Widget build(BuildContext context) => context.attachBlocIfNeeded<IsmSocialActionCubit>(
      child: _buildInternal(context),
    );

  //---------------------------------------------------------------------------
  // Internal builder
  //---------------------------------------------------------------------------

  /// Builds the appropriate BLoC widget based on [mode].
  Widget _buildInternal(BuildContext context) {
    switch (mode) {
      case SocialActionMode.consumer:
        return BlocConsumer<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: buildWhen,
          listenWhen: listenWhen,
          builder: builder!,
          listener: listener!,
        );

      case SocialActionMode.builder:
        return BlocBuilder<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: buildWhen,
          builder: builder!,
        );

      case SocialActionMode.listener:
        return BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
          listenWhen: listenWhen,
          listener: listener!,
          child: child ?? const SizedBox.shrink(),
        );
    }
  }
}
