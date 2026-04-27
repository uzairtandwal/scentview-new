import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// ── Replace with your actual Product model/service ──

class SearchScreen extends StatefulWidget {
  static const routeName = '/search';
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ── Animation controllers ────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _chipController;
  late Animation<double> _fadeAnim;
  late Animation<double> _chipAnim;

  // ── State ────────────────────────────────────────────────────
  String _query = '';
  String _selectedCategory = 'All';
  String _selectedSort = 'Popular';
  RangeValues _priceRange = const RangeValues(0, 50000);
  bool _isSearching = false;
  bool _showFilters = false;

  // ── Mock recent searches ─────────────────────────────────────
  final List<String> _recentSearches = [
    'Dior Sauvage',
    'Chanel No. 5',
    'Tom Ford',
    'Oud Wood',
  ];

  // ── Categories ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Iconsax.category},
    {'label': 'Floral', 'icon': Iconsax.sun_1},
    {'label': 'Woody', 'icon': Iconsax.tree},
    {'label': 'Fresh', 'icon': Iconsax.wind_2},
    {'label': 'Oriental', 'icon': Iconsax.star},
    {'label': 'Citrus', 'icon': Iconsax.sun_1},
    {'label': 'Aquatic', 'icon': Iconsax.drop},
    {'label': 'Gourmand', 'icon': Iconsax.cup},
  ];

  final List<String> _sortOptions = [
    'Popular',
    'Price: Low to High',
    'Price: High to Low',
    'Newest',
    'Top Rated',
  ];

  // ── Mock products (replace with your actual Product model) ───
  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': '1',
      'name': 'Dior Sauvage EDT',
      'brand': 'Dior',
      'price': 8500,
      'rating': 4.8,
      'reviews': 1240,
      'category': 'Fresh',
      'size': '100ml',
      'isNew': false,
      'isBestseller': true,
    },
    {
      'id': '2',
      'name': 'Chanel No. 5 EDP',
      'brand': 'Chanel',
      'price': 12000,
      'rating': 4.9,
      'reviews': 3200,
      'category': 'Floral',
      'size': '100ml',
      'isNew': false,
      'isBestseller': true,
    },
    {
      'id': '3',
      'name': 'Tom Ford Black Orchid',
      'brand': 'Tom Ford',
      'price': 15500,
      'rating': 4.7,
      'reviews': 890,
      'category': 'Oriental',
      'size': '100ml',
      'isNew': true,
      'isBestseller': false,
    },
    {
      'id': '4',
      'name': 'Versace Eros EDT',
      'brand': 'Versace',
      'price': 7200,
      'rating': 4.6,
      'reviews': 1560,
      'category': 'Fresh',
      'size': '100ml',
      'isNew': false,
      'isBestseller': false,
    },
    {
      'id': '5',
      'name': 'Armani Code EDP',
      'brand': 'Armani',
      'price': 9800,
      'rating': 4.7,
      'reviews': 720,
      'category': 'Woody',
      'size': '75ml',
      'isNew': false,
      'isBestseller': false,
    },
    {
      'id': '6',
      'name': 'Creed Aventus',
      'brand': 'Creed',
      'price': 45000,
      'rating': 4.9,
      'reviews': 2100,
      'category': 'Fresh',
      'size': '100ml',
      'isNew': false,
      'isBestseller': true,
    },
    {
      'id': '7',
      'name': 'Bleu de Chanel',
      'brand': 'Chanel',
      'price': 13500,
      'rating': 4.8,
      'reviews': 1890,
      'category': 'Woody',
      'size': '100ml',
      'isNew': false,
      'isBestseller': true,
    },
    {
      'id': '8',
      'name': 'Maison Margiela Replica',
      'brand': 'Maison Margiela',
      'price': 22000,
      'rating': 4.6,
      'reviews': 650,
      'category': 'Fresh',
      'size': '100ml',
      'isNew': true,
      'isBestseller': false,
    },
    {
      'id': '9',
      'name': 'Lattafa Oud Mood',
      'brand': 'Lattafa',
      'price': 3500,
      'rating': 4.5,
      'reviews': 430,
      'category': 'Oriental',
      'size': '100ml',
      'isNew': true,
      'isBestseller': false,
    },
    {
      'id': '10',
      'name': 'YSL Libre EDP',
      'brand': 'Yves Saint Laurent',
      'price': 11000,
      'rating': 4.7,
      'reviews': 980,
      'category': 'Floral',
      'size': '90ml',
      'isNew': true,
      'isBestseller': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    var list = _allProducts.where((p) {
      final matchQuery = _query.isEmpty ||
          (p['name'] as String)
              .toLowerCase()
              .contains(_query.toLowerCase()) ||
          (p['brand'] as String)
              .toLowerCase()
              .contains(_query.toLowerCase());

      final matchCategory =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;

      final matchPrice =
          p['price'] >= _priceRange.start && p['price'] <= _priceRange.end;

      return matchQuery && matchCategory && matchPrice;
    }).toList();

    // Sort
    switch (_selectedSort) {
      case 'Price: Low to High':
        list.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
        break;
      case 'Top Rated':
        list.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'Newest':
        list = list.where((p) => p['isNew'] == true).toList()
          ..addAll(list.where((p) => p['isNew'] != true));
        break;
      default: // Popular
        list.sort(
            (a, b) => (b['reviews'] as int).compareTo(a['reviews'] as int));
    }

    return list;
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _chipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnim = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _chipAnim = CurvedAnimation(
        parent: _chipController, curve: Curves.easeOut);

    _fadeController.forward();

    // Auto-focus search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
        _isSearching = _query.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _isSearching = false;
    });
  }

  void _onRecentTap(String query) {
    _searchController.text = query;
    setState(() {
      _query = query;
      _isSearching = true;
    });
  }

  void _removeRecent(String query) {
    setState(() => _recentSearches.remove(query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 70,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF1F2937), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: _buildSearchBar(),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() => _showFilters = !_showFilters);
                    if (_showFilters) {
                      _chipController.forward();
                    } else {
                      _chipController.reverse();
                    }
                  },
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? const Color(0xFF6C63FF)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.setting_4,
                      color: _showFilters
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_showFilters ? 130 : 52),
                child: Column(
                  children: [
                    // Category chips
                    _buildCategoryChips(),
                    // Filter panel
                    if (_showFilters) _buildFilterPanel(),
                  ],
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────
            if (!_isSearching)
              _buildInitialState()
            else if (_filteredProducts.isEmpty)
              _buildEmptyResults()
            else
              _buildResults(),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search perfumes, brands...',
          hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400),
          prefixIcon: Icon(Iconsax.search_normal,
              color: Colors.grey.shade400, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Iconsax.close_circle,
                      color: Colors.grey.shade400, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
      ),
    );
  }

  // ── Category Chips ───────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat['label'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategory = cat['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Filter Panel ─────────────────────────────────────────────
  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              // Sort
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sort by',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          isDense: true,
                          isExpanded: true,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937)),
                          items: _sortOptions
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSort = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Price range display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price range',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      'PKR ${_priceRange.start.toInt()} – ${_priceRange.end.toInt()}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C63FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Price slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF6C63FF),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              overlayColor: const Color(0xFF6C63FF).withOpacity(0.15),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 50000,
              divisions: 100,
              onChanged: (values) => setState(() => _priceRange = values),
            ),
          ),
        ],
      ),
    );
  }

  // ── Initial State (no query) ─────────────────────────────────
  Widget _buildInitialState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.clock,
                            size: 14, color: Color(0xFF6C63FF)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Recent Searches',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937))),
                    ],
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _recentSearches.clear()),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Clear all',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches
                    .map((q) => _RecentChip(
                          label: q,
                          onTap: () => _onRecentTap(q),
                          onRemove: () => _removeRecent(q),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
            ],

            // Trending / Popular
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.trend_up,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text('Trending Now',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 14),

            ..._allProducts
                .where((p) => p['isBestseller'] == true)
                .take(4)
                .map((p) => _TrendingTile(
                      product: p,
                      onTap: () {},
                    )),

            const SizedBox(height: 24),

            // Popular brands
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.award,
                      size: 14, color: Color(0xFFEC4899)),
                ),
                const SizedBox(width: 8),
                const Text('Popular Brands',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 12),
            _buildBrandChips(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandChips() {
    final brands = ['Dior', 'Chanel', 'Tom Ford', 'Versace', 'Armani',
        'Creed', 'YSL', 'Lattafa'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: brands
          .map((b) => GestureDetector(
                onTap: () {
                  _searchController.text = b;
                  setState(() {
                    _query = b;
                    _isSearching = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(b,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937))),
                ),
              ))
          .toList(),
    );
  }

  // ── Empty Results ────────────────────────────────────────────
  Widget _buildEmptyResults() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.search_status,
                    size: 48, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                'No results for "$_query"',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different keyword or\nremove filters',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_selectedCategory != 'All' || _priceRange != const RangeValues(0, 50000))
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _selectedCategory = 'All';
                    _priceRange = const RangeValues(0, 50000);
                    _selectedSort = 'Popular';
                  }),
                  icon: const Icon(Iconsax.filter_remove, size: 16),
                  label: const Text('Clear filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Results Grid ─────────────────────────────────────────────
  Widget _buildResults() {
    final results = _filteredProducts;
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Results count + sort info
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${results.length} ',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6C63FF)),
                      ),
                      TextSpan(
                        text: 'results found',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _showFilters = !_showFilters);
                  },
                  child: Row(
                    children: [
                      Icon(Iconsax.sort,
                          size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(_selectedSort,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: results.length,
            itemBuilder: (_, i) => _ProductCard(
              product: results[i],
              index: i,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────

class _RecentChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.clock, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937))),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close,
                  size: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _TrendingTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.15),
                    const Color(0xFFEC4899).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.shop,
                  color: Color(0xFF6C63FF), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] as String,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(product['brand'] as String,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text('${product['rating']}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937))),
                      Text(' (${product['reviews']})',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${product['price']}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6C63FF)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.trend_up,
                          size: 10, color: Colors.orange.shade600),
                      const SizedBox(width: 3),
                      Text('Hot',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final int index;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Stack(
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(0.12),
                          const Color(0xFFEC4899).withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: Icon(Iconsax.shop,
                          size: 44,
                          color: const Color(0xFF6C63FF).withOpacity(0.6)),
                    ),
                  ),
                  // Badges
                  if (p['isNew'] == true)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFEC4899)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  if (p['isBestseller'] == true)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🔥 HOT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['brand'] as String,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(p['name'] as String,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${p['rating']}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937))),
                          Text(' (${p['reviews']})',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'PKR ${p['price']}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6C63FF)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.shopping_cart,
                                size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
