import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  // Required
  final List<DrawerItem> menuItems;

  // Optional
  final String? headerTitle;
  final String? headerSubtitle;
  final Widget? headerAvatar;
  final Widget? customHeader;
  final Color? headerBackgroundColor;
  final Color? backgroundColor;
  final double? elevation;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? footerPadding;
  final TextStyle? headerTitleStyle;
  final TextStyle? headerSubtitleStyle;
  final TextStyle? itemTextStyle;
  final Color? itemIconColor;
  final Color? dividerColor;
  final bool showDividers;
  final Widget? footer;
  final ScrollController? scrollController;
  final Duration animationDuration;

  const CustomDrawer({
    super.key,
    required this.menuItems,
    this.headerTitle,
    this.headerSubtitle,
    this.headerAvatar,
    this.customHeader,
    this.headerBackgroundColor,
    this.backgroundColor,
    this.elevation,
    this.width,
    this.padding,
    this.footerPadding,
    this.headerTitleStyle,
    this.headerSubtitleStyle,
    this.itemTextStyle,
    this.itemIconColor,
    this.dividerColor,
    this.showDividers = true,
    this.footer,
    this.scrollController,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  final Map<int, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Navigation drawer',
      child: SizedBox(
        width: widget.width ?? 280,
        child: Drawer(
          elevation: widget.elevation ?? 4,
          backgroundColor:
              widget.backgroundColor ?? theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              if (widget.customHeader != null)
                widget.customHeader!
              else if (widget.headerTitle != null ||
                  widget.headerSubtitle != null ||
                  widget.headerAvatar != null)
                _buildHeader(context),

              Expanded(
                child: Padding(
                  padding:
                      widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
                  child: _buildMenuItems(context),
                ),
              ),

              if (widget.footer != null)
                Padding(
                  padding: widget.footerPadding ?? const EdgeInsets.all(8),
                  child: widget.footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: BoxDecoration(
        color: widget.headerBackgroundColor ?? theme.primaryColor,
        gradient:
            widget.headerBackgroundColor == null
                ? LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.headerAvatar != null) ...[
            widget.headerAvatar!,
            const SizedBox(height: 12),
          ],
          if (widget.headerTitle != null)
            Text(
              widget.headerTitle!,
              style:
                  widget.headerTitleStyle ??
                  theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              semanticsLabel: widget.headerTitle,
            ),
          if (widget.headerSubtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.headerSubtitle!,
              style:
                  widget.headerSubtitleStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
              semanticsLabel: widget.headerSubtitle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.menuItems.length,
      itemBuilder: (context, index) {
        final item = widget.menuItems[index];

        if (item.isDivider) {
          return Divider(
            color: widget.dividerColor ?? theme.dividerColor,
            thickness: 1,
            height: 16,
          );
        }

        if (item.isSectionHeader) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              item.title ?? '',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: .3,
              ),
              semanticsLabel: item.title,
            ),
          );
        }

        final isExpanded = _expandedItems[index] ?? false;

        return Column(
          children: [
            _AnimatedListTile(
              item: item,
              theme: theme,
              itemTextStyle: widget.itemTextStyle,
              itemIconColor: widget.itemIconColor,
              animationDuration: widget.animationDuration,
              hasSubItems: item.subItems.isNotEmpty,
              isExpanded: isExpanded,
              onTap: () {
                if (item.subItems.isNotEmpty) {
                  setState(() {
                    _expandedItems[index] = !isExpanded;
                  });
                }
                item.onTap?.call();
              },
            ),
            if (isExpanded && item.subItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  children:
                      item.subItems
                          .map(
                            (subItem) => _AnimatedListTile(
                              item: subItem,
                              theme: theme,
                              itemTextStyle: widget.itemTextStyle,
                              itemIconColor: widget.itemIconColor,
                              animationDuration: widget.animationDuration,
                            ),
                          )
                          .toList(),
                ),
              ),
            if (widget.showDividers &&
                index < widget.menuItems.length - 1 &&
                !widget.menuItems[index + 1].isDivider &&
                !widget.menuItems[index + 1].isSectionHeader)
              Divider(
                color:
                    widget.dividerColor ??
                    theme.dividerColor.withValues(alpha: 0.3),
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
              ),
          ],
        );
      },
    );
  }
}

class _AnimatedListTile extends StatefulWidget {
  final DrawerItem item;
  final ThemeData theme;
  final TextStyle? itemTextStyle;
  final Color? itemIconColor;
  final Duration animationDuration;
  final bool hasSubItems;
  final bool isExpanded;
  final VoidCallback? onTap;

  const _AnimatedListTile({
    required this.item,
    required this.theme,
    this.itemTextStyle,
    this.itemIconColor,
    required this.animationDuration,
    this.hasSubItems = false,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  State<_AnimatedListTile> createState() => _AnimatedListTileState();
}

class _AnimatedListTileState extends State<_AnimatedListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ListTile(
        leading:
            widget.item.icon != null
                ? Icon(
                  widget.item.icon,
                  color: widget.itemIconColor ?? widget.theme.iconTheme.color,
                  semanticLabel: widget.item.title,
                )
                : widget.item.leading,
        title: Text(
          widget.item.title ?? '',
          style: widget.itemTextStyle ?? widget.theme.textTheme.bodyLarge,
          maxLines: widget.item.maxTitleLines,
          overflow: TextOverflow.ellipsis,
          semanticsLabel: widget.item.title,
        ),
        subtitle:
            widget.item.subtitle != null
                ? Text(
                  widget.item.subtitle!,
                  style: widget.theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing:
            widget.hasSubItems
                ? Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.itemIconColor ?? widget.theme.iconTheme.color,
                )
                : widget.item.trailing,
        enabled: widget.item.enabled,
        selected: widget.item.isSelected,
        onTap:
            widget.item.enabled
                ? () {
                  _controller.forward().then((_) => _controller.reverse());
                  widget.item.onTap?.call();
                }
                : null,
        dense: widget.item.isDense,
        contentPadding:
            widget.item.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

class DrawerItem {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isSelected;
  final bool isDense;
  final bool isDivider;
  final bool isSectionHeader;
  final int maxTitleLines;
  final EdgeInsetsGeometry? contentPadding;
  final List<DrawerItem> subItems;

  const DrawerItem({
    this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.isSelected = false,
    this.isDense = false,
    this.isDivider = false,
    this.isSectionHeader = false,
    this.maxTitleLines = 1,
    this.contentPadding,
    this.subItems = const [],
  });

  factory DrawerItem.divider() => const DrawerItem(isDivider: true);

  factory DrawerItem.section(String title) =>
      DrawerItem(title: title, isSectionHeader: true, enabled: false);

  factory DrawerItem.item({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
    bool isSelected = false,
    bool isDense = false,
    int maxTitleLines = 1,
    EdgeInsetsGeometry? contentPadding,
    List<DrawerItem> subItems = const [],
  }) {
    return DrawerItem(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      enabled: enabled,
      isSelected: isSelected,
      isDense: isDense,
      maxTitleLines: maxTitleLines,
      contentPadding: contentPadding,
      subItems: subItems,
    );
  }
}
