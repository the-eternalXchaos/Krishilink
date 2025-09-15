import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/src/features/product/presentation/widgets/filter_sheet.dart';

class SearchBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;

  const SearchBar({super.key, this.onSearch, this.searchController});

  @override
  State<SearchBar> createState() => _SearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

class _SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  final FilterController filterController =
      Get.isRegistered<FilterController>()
          ? Get.find<FilterController>()
          : Get.put(FilterController());
  final ProductController productController =
      Get.isRegistered<ProductController>()
          ? Get.find<ProductController>()
          : throw Exception('ProductController must be initialized first');

  late final TextEditingController _controller =
      widget.searchController ?? TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    if (widget.searchController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showFilterSheet() {
    Get.bottomSheet(
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent:
                ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: FilterSheet(),
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Obx(() {
      final filters = [
        ...filterController.selectedCategories.map((c) => _FilterItem(c, true)),
        ...filterController.selectedLocations.map((l) => _FilterItem(l, false)),
      ];

      if (filters.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                filters
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildFilterChip(
                        entry.value.label,
                        entry.value.isCategory,
                        entry.key,
                      ),
                    )
                    .toList(),
          ),
        ),
      );
    });
  }

  Widget _buildFilterChip(String label, bool isCategory, int index) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).chipTheme.backgroundColor,
          deleteIcon: Icon(
            Icons.close,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
          ),
          onDeleted: () {
            if (isCategory) {
              filterController.toggleCategory(label);
            } else {
              filterController.toggleLocation(label);
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'search_products'.tr,
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                    onPressed: _showFilterSheet,
                    tooltip: 'apply_filters'.tr,
                  ),
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.border,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (v) {
                  filterController.searchProducts(v);
                  widget.onSearch?.call(v);
                },
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          _buildActiveFilters(),
        ],
      ),
    );
  }
}

class _FilterItem {
  final String label;
  final bool isCategory;

  _FilterItem(this.label, this.isCategory);
}
