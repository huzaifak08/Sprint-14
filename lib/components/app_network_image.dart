import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String? path;
  final double size;
  final String fallbackLetter;
  final bool isCircle;
  final double borderRadius;

  const AppNetworkImage({
    super.key,
    required this.path,
    this.size = 50,
    this.fallbackLetter = 'U',
    this.isCircle = true,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (path == null || path!.isEmpty) {
      return _buildPlaceholder(theme);
    }

    if (!path!.startsWith('http')) {
      final file = File(path!);
      if (file.existsSync()) {
        return _buildFrame(
          theme,
          // 🔥 Fixed Image.file implementation
          child: Image.file(file, fit: BoxFit.cover, width: size, height: size),
        );
      }
      return _buildPlaceholder(theme);
    }

    return CachedNetworkImage(
      imageUrl: path!,
      width: size,
      height: size,
      // 🔥 The Fix: Ensure the image is drawn directly on the container decoration
      imageBuilder: (context, imageProvider) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      placeholder: (context, url) =>
          _buildPlaceholder(theme, showLoading: true),
      errorWidget: (context, url, error) => _buildPlaceholder(theme),
    );
  }

  Widget _buildFrame(ThemeData theme, {required Widget child}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildPlaceholder(ThemeData theme, {bool showLoading = false}) {
    return _buildFrame(
      theme,
      child: Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: showLoading
            ? SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              )
            : Text(
                fallbackLetter.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.4,
                ),
              ),
      ),
    );
  }
}
