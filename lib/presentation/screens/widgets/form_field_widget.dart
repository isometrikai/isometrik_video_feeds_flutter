import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// A form field widget which will handle form ui.
///
/// [focusNode] : FocusNode for the form field.
/// [autoFocus] : Allow auto focus for the form field if true.
/// [textEditingController] : Text editing controller for the form field
///                           to handle the text change and other stuff.
/// [isObscureText] : If true it will make the form text secure.
/// [obscureCharacter] : If [isObscureText] true this will be used for the
///                      character which will be shown.
/// [textCapitalization] : Type of text capitalization for the form field.
/// [isFilled] : If true the decoration colors will be filled.
/// [contentPadding] : Padding for the form field between the content and
///                    boundary of the form.
/// [fillColor] : The background color of the form field.
/// [hintText] : The hint text of the form field.
/// [hintStyle] : The hint style for the the form field.
/// [errorStyle] : The error style for the the form field.
/// [formBorder] : The border for the form field.
/// [errorText] : The error text of the form field.
/// [suffixIcon] : The suffix widget of the form field.
/// [prefixIcon] : The prefix widget of the form field.
/// [textInputAction] : The text input action for the form filed.
/// [textInputType] : The keyboard type of the form field.
/// [formStyle] : The style of the form field. This will be used for the style
///               of the content.
class FormFieldWidget extends StatelessWidget {
  const FormFieldWidget({
    super.key,
    this.focusNode,
    this.autoFocus = true,
    this.textEditingController,
    this.isObscureText = false,
    this.obscureCharacter = '•',
    this.textCapitalization = TextCapitalization.none,
    this.isFilled,
    this.contentPadding,
    this.fillColor,
    this.hintText,
    this.hintStyle,
    this.errorStyle,
    this.formBorder,
    this.focusedBorder,
    this.errorText,
    this.suffixIcon,
    this.prefixIcon,
    this.textInputAction = TextInputAction.done,
    this.textInputType = TextInputType.text,
    this.formStyle,
    this.onChange,
    this.isReadOnly = false,
    this.onTap,
    this.errorBorder,
    this.disabledBorder,
    this.inputFormatters,
    this.maxLength = TextField.noMaxLength,
    this.onEditingComplete,
    this.initialValue,
    this.cursorColor,
    this.maxlines = 1,
    this.enabled = true,
    this.validator,
    this.textAlign,
    this.focusedErrorBorder,
    this.autoValidate,
    this.suffixText,
    this.suffixTextStyle,
    this.minLines,
    this.scrollPadding,
    this.expands,
    this.textAlignVertical,
    this.labelText,
    this.labelStyle,
    this.alignLabelWithHint,
    this.onFieldSubmitted,
    this.enableInteractiveSelection = true,
    this.showCountBuilder,
    this.errorMaxLines = 3,
    this.focusColor,
    this.underLineInputBorder,
    this.enabledFormBorder,
    this.onTapOutside,
    this.scrollPhysics,
    this.cursorHeight,
    this.counterText,
    this.counterStyle,
    this.showCountCharacterText,
    this.strutStyle,
    this.showCursor = true,
    this.contextMenuBuilder,
    this.borderColor,
  });

  final FocusNode? focusNode;
  final bool autoFocus;
  final TextEditingController? textEditingController;
  final bool isObscureText;
  final String obscureCharacter;
  final TextCapitalization textCapitalization;
  final bool? isFilled;
  final EdgeInsets? contentPadding;
  final Color? fillColor;
  final Color? focusColor;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final OutlineInputBorder? formBorder;
  final String? errorText;
  final Widget? suffixIcon;
  final String? suffixText;
  final Widget? prefixIcon;
  final TextInputAction textInputAction;
  final TextInputType textInputType;
  final TextStyle? formStyle;
  final TextStyle? suffixTextStyle;
  final void Function(String value)? onChange;
  final bool isReadOnly;
  final Function()? onTap;
  final InputBorder? errorBorder;
  final List<TextInputFormatter>? inputFormatters;
  final OutlineInputBorder? focusedBorder;
  final OutlineInputBorder? focusedErrorBorder;
  final OutlineInputBorder? disabledBorder;
  final Function()? onEditingComplete;
  final Function(String)? onFieldSubmitted;
  final int? maxLength;
  final String? initialValue;
  final Color? cursorColor;
  final int? maxlines;
  final bool? enabled;
  final String? Function(String?)? validator;
  final TextAlign? textAlign;
  final AutovalidateMode? autoValidate;
  final int? minLines;
  final EdgeInsets? scrollPadding;
  final bool? expands;
  final TextAlignVertical? textAlignVertical;
  final String? labelText;
  final TextStyle? labelStyle;
  final bool? alignLabelWithHint;
  final bool? enableInteractiveSelection;
  final bool? showCountBuilder;
  final int? errorMaxLines;
  final UnderlineInputBorder? underLineInputBorder;
  final UnderlineInputBorder? enabledFormBorder;
  final Function(PointerDownEvent)? onTapOutside;
  final ScrollPhysics? scrollPhysics;
  final double? cursorHeight;
  final String? counterText;
  final TextStyle? counterStyle;
  final bool? showCountCharacterText;
  final StrutStyle? strutStyle;
  final bool? showCursor;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => TextFormField(
        strutStyle: strutStyle,
        showCursor: showCursor ?? true,
        enableSuggestions: false,
        cursorHeight: cursorHeight,
        scrollPhysics: scrollPhysics ?? null,
        onTapOutside: onTapOutside,
        textAlignVertical: textAlignVertical,
        expands: expands ?? false,
        scrollPadding: scrollPadding ?? const EdgeInsets.all(20.0),
        key: const Key('text-form-field'),
        readOnly: isReadOnly,
        maxLength: maxLength,
        validator: validator,
        autofocus: autoFocus,
        autocorrect: false,
        cursorErrorColor: Theme.of(context).primaryColor,
        contextMenuBuilder: contextMenuBuilder ??
            (context, editableTextState) {
              final buttonItems = editableTextState.contextMenuButtonItems;
              buttonItems.removeWhere((ContextMenuButtonItem buttonItem) =>
                  buttonItem.type != ContextMenuButtonType.copy &&
                  buttonItem.type != ContextMenuButtonType.cut &&
                  buttonItem.type != ContextMenuButtonType.paste);
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: buttonItems,
              );
            },
        buildCounter: (
          BuildContext context, {
          required int currentLength,
          required bool isFocused,
          required int? maxLength,
        }) =>
            (showCountBuilder ?? false) && maxLength != null && maxLength != -1
                ? Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$currentLength/$maxLength${(showCountCharacterText ?? false) ? ' ${IsrTranslationFile.characters}' : ''}', // Display the current length and max length
                      style: IsrStyles.primaryText12.copyWith(
                        color: IsrColors.color828282,
                      ),
                    ),
                  )
                : IsrDimens.boxHeight(0),
        focusNode: focusNode,
        textAlign: textAlign ?? TextAlign.left,
        controller: textEditingController,
        obscureText: isObscureText,
        obscuringCharacter: obscureCharacter,
        textCapitalization: textCapitalization,
        onTap: onTap,
        inputFormatters: inputFormatters,
        cursorColor: cursorColor ?? Theme.of(context).primaryColor,
        enableInteractiveSelection: enableInteractiveSelection ?? true,
        decoration: InputDecoration(
          counterStyle: IsrStyles.primaryText14Bold,
          labelText: labelText,
          labelStyle: labelStyle,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          focusedErrorBorder: focusedErrorBorder ?? defaultErrorBorder(),
          disabledBorder: disabledBorder ?? defaultBorder(borderColor: borderColor),
          focusedBorder: focusedBorder ??
              defaultBorder(
                borderColor: Theme.of(context).primaryColor,
              ),
          errorBorder: errorBorder ?? defaultErrorBorder(),
          filled: true,
          contentPadding: contentPadding ??
              IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.twelve, vertical: IsrDimens.fourteen),
          fillColor: fillColor ?? IsrColors.white,
          border: formBorder ?? defaultBorder(borderColor: borderColor),
          enabledBorder: formBorder ?? defaultBorder(borderColor: borderColor),
          hintText: hintText,
          isDense: true,
          hintStyle: hintStyle ??
              IsrStyles.secondaryText14.copyWith(
                  // color: IsrColors.color848484,
                  color: IsrColors.colorB5B3B3),
          errorText: errorText,
          errorStyle: errorStyle ??
              IsrStyles.secondaryText10.copyWith(
                color: IsrColors.error,
              ),
          suffixIcon: suffixIcon,
          suffixText: suffixText,
          suffixStyle: suffixTextStyle,
          prefixIcon: prefixIcon,
          errorMaxLines: errorMaxLines,
          alignLabelWithHint: alignLabelWithHint,
          focusColor: focusColor,
          prefixIconConstraints: BoxConstraints(
            minWidth: IsrDimens.twentyFour,
            minHeight: IsrDimens.twentyFour,
          ),
          suffixIconConstraints: const BoxConstraints(minHeight: 15, minWidth: 15),
        ),
        minLines: (expands == true) ? null : minLines,
        onChanged: onChange,
        maxLines: (expands == true) ? null : maxlines,
        textInputAction: textInputAction,
        keyboardType: textInputType,
        style: formStyle ??
            IsrStyles.secondaryText14.copyWith(
              color: IsrColors.color333333,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
        autovalidateMode: autoValidate ?? AutovalidateMode.onUserInteraction,
        onEditingComplete: onEditingComplete,
        initialValue: initialValue,
        enabled: enabled,
        onFieldSubmitted: onFieldSubmitted,
      );

  InputBorder defaultBorder({Color? borderColor}) => OutlineInputBorder(
        borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
        borderSide: BorderSide(
          color: borderColor ?? IsrColors.colorDBDBDB,
          width: IsrDimens.one,
        ),
      );

  InputBorder defaultErrorBorder({Color? borderColor}) => OutlineInputBorder(
        borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
        borderSide: BorderSide(
          color: borderColor ?? IsrColors.error,
          width: IsrDimens.one,
        ),
      );
}
