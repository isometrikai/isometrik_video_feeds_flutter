/// Result returned when a stacked create-post flow step closes.
class CreatePostFlowResult {
  const CreatePostFlowResult({
    required this.succeeded,
    this.result,
  });

  final bool succeeded;

  final dynamic result;

  static const CreatePostFlowResult cancelled =
      CreatePostFlowResult(succeeded: false);

  static CreatePostFlowResult success(dynamic result) =>
      CreatePostFlowResult(succeeded: true, result: result);
}
