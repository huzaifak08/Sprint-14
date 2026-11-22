import 'package:flutter/material.dart';
import 'package:sprint_14/components/app_toast.dart';
import 'package:flutter_svg/svg.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Returns an error message, or null when [value] looks like an email.
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
  return null;
}

void showAuthError(BuildContext context, Object error) => AppToast.error(error);

/// Logo + title + subtitle used at the top of the auth screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SvgPicture.asset("assets/images/logo.svg", width: 56),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Labelled text field with the auth screens' styling.
class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool enabled;

  /// Prefer this over [enabled] while a request runs: a disabled field
  /// drops out of Android's autofill session, so the "save password"
  /// prompt never appears.
  final bool readOnly;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 14),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscure,
          enableSuggestions: !obscure,
          autocorrect: !obscure && keyboardType != TextInputType.emailAddress,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 22),
            suffixIcon: suffix,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: border(Colors.transparent),
            enabledBorder: border(theme.dividerColor.withValues(alpha: 0.15)),
            focusedBorder: border(theme.colorScheme.primary, 1.5),
            errorBorder: border(theme.colorScheme.error),
            focusedErrorBorder: border(theme.colorScheme.error, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Full-width primary button that shows a spinner while [loading].
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.primary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
      ),
    );
  }
}

/// Background used by the auth screens.
class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.06),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

/// Email field that suggests emails used on this device, as you type.
/// (System autofill still works too: the field keeps its autofill hints.)
class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String> autofillHints;
  final String hint;

  const AuthEmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    this.readOnly = false,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.email, AutofillHints.username],
    this.hint = 'yourname@mail.com',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        return suggestions.where((e) => e != q && e.contains(q));
      },
      onSelected: (email) {
        controller.text = email;
        onSubmitted?.call(email);
      },
      fieldViewBuilder: (context, ctrl, focus, onFieldSubmitted) {
        return AuthTextField(
          label: 'Email address',
          controller: ctrl,
          focusNode: focus,
          hint: hint,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: autofillHints,
          readOnly: readOnly,
          onSubmitted: (v) {
            onFieldSubmitted();
            onSubmitted?.call(v);
          },
          validator: validateEmail,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              elevation: 8,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 240,
                  maxWidth: MediaQuery.of(context).size.width - 48,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  children: [
                    for (final email in options)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(email),
                        onTap: () => onSelected(email),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
