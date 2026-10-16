import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenericSearchPage<T> extends StatefulWidget {
  final String searchPrefsKey;
  final String searchHint;
  final String emptyMessage;
  final String suggestionsMessage;
  final Color brandOrange;
  final Color brandGreen;
  final Color pageBg;

  final List<T> allItems;
  final List<T> Function(List<T> items, String query) onSearchMatch;
  final List<T> Function(List<T> items)? onCustomFilter;
  final String Function(T item) getKeywordName;
  final Widget Function(T item) buildItemCard;

  final Widget Function(BuildContext context, VoidCallback onApply)?
  buildFilterSheet;
  final int Function()? getActiveFilterCount;
  final List<Widget>? actions;

  final Widget? headerContent;
  final Widget? footerContent;
  final Widget? floatingActionButton;

  final bool isGrid;
  final SliverGridDelegate? gridDelegate;

  const GenericSearchPage({
    super.key,
    required this.searchPrefsKey,
    required this.searchHint,
    required this.allItems,
    required this.onSearchMatch,
    required this.getKeywordName,
    required this.buildItemCard,
    this.onCustomFilter,
    this.buildFilterSheet,
    this.getActiveFilterCount,
    this.actions,
    this.headerContent,
    this.footerContent,
    this.floatingActionButton,
    this.isGrid = false,
    this.gridDelegate,
    this.emptyMessage = 'Không tìm thấy kết quả nào',
    this.suggestionsMessage = 'Đề xuất cho bạn',
    this.brandOrange = const Color(0xFFFB5B2A),
    this.brandGreen = const Color(0xFF2E8B57),
    this.pageBg = const Color(0xFFF6F2FA),
  });

  @override
  State<GenericSearchPage<T>> createState() => _GenericSearchPageState<T>();
}

class _GenericSearchPageState<T> extends State<GenericSearchPage<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filtered = [];
  List<String> _history = [];
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _applyFilters();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant GenericSearchPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyFilters();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty && _hasSubmitted) {
      _hasSubmitted = false;
    }
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    List<T> filtered = widget.onSearchMatch(widget.allItems, query);

    if (widget.onCustomFilter != null) {
      filtered = widget.onCustomFilter!(filtered);
    }

    setState(() {
      _filtered = filtered;
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveHistory(query);
    setState(() {
      _hasSubmitted = true;
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _history = prefs.getStringList(widget.searchPrefsKey) ?? [];
      });
    }
  }

  Future<void> _saveHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(widget.searchPrefsKey) ?? [];
    history.remove(q);
    history.insert(0, q);
    if (history.length > 10) history = history.sublist(0, 10);

    await prefs.setStringList(widget.searchPrefsKey, history);
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.searchPrefsKey);
    if (mounted) {
      setState(() {
        _history = [];
      });
    }
  }

  Future<void> _removeHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(widget.searchPrefsKey) ?? [];
    history.remove(query);
    await prefs.setStringList(widget.searchPrefsKey, history);
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  void _openFilterSheet() {
    if (widget.buildFilterSheet == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return widget.buildFilterSheet!(context, () {
          _applyFilters();
        });
      },
    );
  }

  Widget _buildTag(String label, {required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.pageBg,
      floatingActionButton: widget.floatingActionButton,
      appBar: AppBar(
        backgroundColor: widget.brandOrange,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.actions,
        title: Container(
          margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: widget.brandOrange),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  autofocus: false,
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submitSearch,
                  style: GoogleFonts.beVietnamPro(),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: GoogleFonts.beVietnamPro(
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
      body: _searchController.text.isEmpty
          ? _buildIdleState()
          : (!_hasSubmitted
                ? _buildKeywordSuggestions()
                : _buildSearchResults()),
    );
  }

  Widget _buildKeywordSuggestions() {
    final keywordSuggestions = _filtered
        .map(widget.getKeywordName)
        .toSet()
        .take(10)
        .toList();

    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.search, color: widget.brandOrange),
          title: RichText(
            text: TextSpan(
              text: 'Tìm ',
              style: GoogleFonts.beVietnamPro(color: Colors.black),
              children: [
                TextSpan(
                  text: '"${_searchController.text}"',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    color: widget.brandOrange,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            _submitSearch(_searchController.text);
          },
        ),
        const Divider(height: 1),
        ...keywordSuggestions.map((suggestion) {
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.search, color: Colors.grey),
                title: Text(
                  suggestion,
                  style: GoogleFonts.beVietnamPro(color: Colors.grey.shade800),
                ),
                onTap: () {
                  _searchController.text = suggestion;
                  _submitSearch(suggestion);
                },
              ),
              const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildIdleState() {
    final suggestions = widget.allItems.take(6).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.headerContent != null) widget.headerContent!,
          if (_history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch sử tìm kiếm',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  InkWell(
                    onTap: _clearHistory,
                    child: Text(
                      'Xóa',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _history.map((h) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = h;
                      _submitSearch(h);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 8,
                        top: 6,
                        bottom: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            h,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              _removeHistoryItem(h);
                            },
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Gợi ý cho bạn',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Không có dữ liệu',
                  style: GoogleFonts.beVietnamPro(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return widget.buildItemCard(item);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: suggestions.length,
            ),
          const SizedBox(height: 20),
          if (widget.footerContent != null) widget.footerContent!,
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final activeFilters = widget.getActiveFilterCount?.call() ?? 0;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Kết quả tìm kiếm',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (widget.buildFilterSheet != null)
                InkWell(
                  onTap: _openFilterSheet,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20,
                        color: widget.brandOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lọc',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                          color: widget.brandOrange,
                        ),
                      ),
                      if (activeFilters > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildTag(
                            '$activeFilters',
                            color: widget.brandGreen,
                            bg: widget.brandGreen.withOpacity(0.14),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.emptyMessage,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thử tìm với từ khóa khác xem sao nhé!',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (widget.allItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.suggestionsMessage,
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final suggestionList = widget.allItems
                                .take(5)
                                .toList();
                            if (index >= suggestionList.length)
                              return const SizedBox();
                            final item = suggestionList[index];
                            return widget.buildItemCard(item);
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: widget.allItems.length > 5
                              ? 5
                              : widget.allItems.length,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                )
              : widget.isGrid
              ? ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (widget.headerContent != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: widget.headerContent!,
                      ),
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          widget.gridDelegate ??
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        return widget.buildItemCard(_filtered[index]);
                      },
                    ),
                    if (widget.footerContent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: widget.footerContent!,
                      ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtered.length + 2, // header + footer
                  separatorBuilder: (context, index) {
                    if (index == 0 || index == _filtered.length)
                      return const SizedBox();
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return widget.headerContent ?? const SizedBox();
                    }
                    if (index == _filtered.length + 1) {
                      return widget.footerContent ?? const SizedBox();
                    }
                    return widget.buildItemCard(_filtered[index - 1]);
                  },
                ),
        ),
      ],
    );
  }
}
