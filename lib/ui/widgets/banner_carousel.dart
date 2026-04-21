import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:scentview/models/banner.dart' as model;
import 'package:scentview/services/api_service.dart';

class BannerCarousel extends StatefulWidget {
  final List<model.Banner> banners;
  final Function(model.Banner) onTap;
  final double height;
  final double borderRadius;
  final bool showIndicators;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration animationDuration;

  const BannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
    this.height = 220.0,
    this.borderRadius = 20.0,
    this.showIndicators = true,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;

  // Infinite scroll: start from middle multiplier
  static const int _multiplier = 1000;
  int _realIndex = 0;

  bool get _canAutoPlay =>
      widget.autoPlay && widget.banners.length > 1;

  int get _initialPage => widget.banners.length * _multiplier;

  // Convert virtual page → real banner index
  int _toRealIndex(int page) => page % widget.banners.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.9,
    );
    _startTimer();
  }

  void _startTimer() {
    if (!_canAutoPlay) return;
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopTimer() => _timer?.cancel();

  void _resumeTimer() {
    _stopTimer();
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return _EmptyBanner(
        height: widget.height,
        borderRadius: widget.borderRadius,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ══════════════════ CAROUSEL ══════════════════
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _stopTimer(); // pause while user is dragging
              } else if (notification is ScrollEndNotification) {
                _resumeTimer(); // resume after user lifts finger
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              // itemCount: null → infinite
              onPageChanged: (virtualPage) {
                setState(() => _realIndex = _toRealIndex(virtualPage));
              },
              itemBuilder: (context, virtualPage) {
                final realIdx = _toRealIndex(virtualPage);
                final banner = widget.banners[realIdx];
                final imageUrl = ApiService.toAbsoluteUrl(banner.imageUrl);
                final isActive = _realIndex == realIdx;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () => widget.onTap(banner),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: isActive ? 1.0 : 0.95,
                      curve: Curves.easeOut,
                      child: _BannerCard(
                        imageUrl: imageUrl,
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ══════════════════ INDICATORS ══════════════════
        if (widget.showIndicators && widget.banners.length > 1)
          _DotsIndicator(
            count: widget.banners.length,
            current: _realIndex,
          ),
      ],
    );
  }
}

// ─── Banner Card ──────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;

  const _BannerCard({required this.imageUrl, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BannerImage(imageUrl: imageUrl),
            _GradientOverlay(),
          ],
        ),
      ),
    );
  }
}

// ─── Banner Image ─────────────────────────────────────────────────────────────
class _BannerImage extends StatelessWidget {
  final String? imageUrl;

  const _BannerImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _imagePlaceholder(theme);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => _imagePlaceholder(theme),
      errorWidget: (_, __, ___) => _imageError(theme),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );

  Widget _imageError(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 40,
          ),
        ),
      );
}

// ─── Gradient Overlay ─────────────────────────────────────────────────────────
class _GradientOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65],
        ),
      ),
    );
  }
}

// ─── Dots Indicator ───────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isActive ? 28.0 : 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyBanner extends StatelessWidget {
  final double height;
  final double borderRadius;

  const _EmptyBanner({required this.height, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          size: 48,
        ),
      ),
    );
  }
}
