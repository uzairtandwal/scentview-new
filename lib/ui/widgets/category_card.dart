import 'package:flutter/material.dart';
import 'package:scentview/theme/app_theme.dart';

class CategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final int productCount;

  const CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.productCount = 0,
    Key? key,
  }) : super(key: key);

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Fill effect trigger: either hovered or selected
    bool isActive = _isHovered || widget.isSelected;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: Colors.black,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isActive ? 0.2 : 0.04),
                blurRadius: isActive ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  key: ValueKey<bool>(isActive),
                  size: 26,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title.contains("Fragrances") ? widget.title : "${widget.title}\nFragrances",
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${widget.productCount} Products",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white70 : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
