import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get('/reviews/me');
      final wrapper = res.data?['data'];
      final data = wrapper is Map ? wrapper['data'] : wrapper;
      if (mounted) {
        setState(() {
          _reviews = data is List
              ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Đánh giá của tôi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('Chưa có đánh giá nào', style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Mua sản phẩm và chia sẻ trải nghiệm của bạn', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _reviewCard(_reviews[i]),
                ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final product = review['product'];
    final productName = (product is Map ? product['name']?.toString() : null) ??
        review['product_name']?.toString() ??
        'Sản phẩm';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) => Icon(
              i < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            )),
          ),
          if (review['comment'] != null) ...[
            const SizedBox(height: 8),
            Text(review['comment'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
          ],
          const SizedBox(height: 6),
          Text(_formatDate(review['created_at']), style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}
