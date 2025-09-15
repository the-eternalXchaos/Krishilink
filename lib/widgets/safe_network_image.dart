import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Safe image widget that handles empty URLs gracefully
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default error widget
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        size: (height != null && height! < 100) ? height! * 0.4 : 40,
      ),
    );

    // Default placeholder widget
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
          strokeWidth: 2,
        ),
      ),
    );

    // Check if image URL is valid
    if (imageUrl.trim().isEmpty || !_isValidUrl(imageUrl)) {
      return errorWidget ?? defaultErrorWidget;
    }

    final cachedImage = CachedNetworkImage(
      imageUrl: imageUrl.trim(),
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) => errorWidget ?? defaultErrorWidget,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 100),
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: cachedImage);
    }

    return cachedImage;
  }

  /// Check if the URL is valid
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Safe circular network image for avatars and profile pictures
class SafeCircularNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? fallbackAsset;

  const SafeCircularNetworkImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;

    // Default error widget
    final defaultErrorWidget =
        fallbackAsset != null
            ? Image.asset(
              fallbackAsset!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
            : Icon(
              Icons.person,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: radius,
            );

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: SafeNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: placeholder,
          errorWidget: errorWidget ?? defaultErrorWidget,
        ),
      ),
    );
  }
}
