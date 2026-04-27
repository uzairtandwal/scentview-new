import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:scentview/theme/app_theme.dart';
import 'app_logo.dart';
import '../search_results_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearch;
  final String? hintText;
  final VoidCallback? onMenuTap;
  final VoidCallback? onRefresh;
  final Function(String)? onSearchChanged;
  final List<Color>? gradientColors;
  final Color? iconColor;

  const CustomAppBar({
    super.key,
    this.showSearch = true,
    this.hintText,
    this.onMenuTap,
    this.onRefresh,
    this.onSearchChanged,
    this.onSubmitted, // NEW: added onSubmitted
    this.gradientColors,
    this.iconColor,
  });

  final Function(String)? onSubmitted; // NEW: field added

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final onPrimary = Colors.black;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      bool isDesktop = kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
                      return AppLogo(size: isDesktop ? 40 : 50);
                    },
                  ),
                  const SizedBox(width: 8),
                  if (showSearch)
                    Expanded(
                      child: _SearchBar(
                        hintText: hintText ?? 'SEARCH...',
                        onChanged: onSearchChanged,
                        onSubmitted: onSubmitted ?? (query) {
                          // Default fallback
                          if (query.trim().isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              SearchResultsScreen.routeName,
                              arguments: query.trim(),
                            );
                          }
                        },
                      ),
                    )
                  else
                    const Expanded(child: Center(child: Text('SCENTVIEW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)))),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (menuContext) => _AppBarButton(
                      icon: Icons.menu_outlined,
                      iconColor: onPrimary,
                      onTap: onMenuTap ?? () => Scaffold.of(menuContext).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // HIDDEN: Profile button hidden for now
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const _SearchBar({
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Center(
        child: TextField(
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textAlignVertical: TextAlignVertical.center,
          style: AppTheme.bodySans.copyWith(fontSize: 12, color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTheme.bodySans.copyWith(
              color: Colors.grey,
              fontSize: 11,
              letterSpacing: 1,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(
              Icons.search_outlined,
              color: Colors.black,
              size: 16,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 0),
          ),
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final int badgeCount;

  const _AppBarButton({
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
