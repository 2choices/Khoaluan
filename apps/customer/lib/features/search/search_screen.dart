import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_cubit.dart';
import '../../shared/layout/customer_responsive.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);
const _kHistoryKey = 'search_history';
const _kMaxHistory = 10;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  List<String> _history = [];
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList(_kHistoryKey) ?? [];
    });
  }

  Future<void> _saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [
      query,
      ..._history.where((h) => h != query),
    ].take(_kMaxHistory).toList();
    await prefs.setStringList(_kHistoryKey, updated);
    setState(() => _history = updated);
  }

  Future<void> _removeHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = _history.where((h) => h != query).toList();
    await prefs.setStringList(_kHistoryKey, updated);
    setState(() => _history = updated);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
    setState(() => _history = []);
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _searchCtrl.text = q;
    _lastQuery = q;
    setState(() {
      _searching = true;
      _hasSearched = true;
    });
    _focusNode.unfocus();
    await _saveHistory(q);
    if (!mounted) return;

    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get<dynamic>(
        '/catalog/products',
        queryParams: {'search': q, 'limit': '30'},
      );
      final wrapper = res.data?['data'];
      final data = wrapper is Map ? wrapper['data'] : wrapper;
      if (mounted) {
        setState(() {
          _results = data is List
              ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFFAAAAAA),
                size: 20,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchCtrl,
                builder: (_, v, _) => v.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFAAAAAA),
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _hasSearched = false;
                            _results = [];
                          });
                          _focusNode.requestFocus();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_hasSearched) {
      return _buildResults();
    }
    return _buildHistoryAndSuggestions();
  }

  Widget _buildHistoryAndSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tìm kiếm gần đây',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((h) => _historyChip(h)).toList(),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Cà phê',
              'Trà sữa',
              'Bánh mì',
              'Nước ép',
              'Kem',
              'Sinh tố',
            ].map((s) => _suggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _historyChip(String query) {
    return GestureDetector(
      onTap: () => _search(query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 14, color: Color(0xFF999999)),
            const SizedBox(width: 6),
            Text(
              query,
              style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _removeHistory(query),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String label) {
    return GestureDetector(
      onTap: () => _search(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5D9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _kPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy "$_lastQuery"',
              style: const TextStyle(fontSize: 16, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thử từ khóa khác hoặc xem tất cả sản phẩm',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => context.go('/products'),
              child: const Text(
                'Xem tất cả sản phẩm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${_results.length} kết quả cho "$_lastQuery"',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: CustomerResponsive.productColumns(
                    constraints.maxWidth,
                  ),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: CustomerResponsive.productAspectRatio(
                    constraints.maxWidth,
                  ),
                ),
                itemCount: _results.length,
                itemBuilder: (_, i) => _productCard(_results[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    String? thumbnailUrl = product['thumbnail'] as String?;
    if (thumbnailUrl == null) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        final primary = images.firstWhere(
          (img) => img['is_primary'] == true,
          orElse: () => images.first,
        );
        thumbnailUrl =
            primary['thumbnail_url'] as String? ?? primary['url'] as String?;
      }
    }
    final price = (product['base_price'] as num?)?.toDouble() ?? 0;
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    return GestureDetector(
      onTap: () => context.push('/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: Image.network(
                          thumbnailUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$formattedđ',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
