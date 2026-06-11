import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);

class AiAnalyticsScreen extends StatefulWidget {
  const AiAnalyticsScreen({super.key});

  @override
  State<AiAnalyticsScreen> createState() => _AiAnalyticsScreenState();
}

class _AiAnalyticsScreenState extends State<AiAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Forecast
  List<Map<String, dynamic>> _forecastPoints = [];
  bool _loadingForecast = false;

  // Segments
  List<Map<String, dynamic>> _segments = [];
  bool _loadingSegments = false;

  // Anomalies
  List<Map<String, dynamic>> _anomalies = [];
  bool _loadingAnomalies = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadForecast();
    _loadSegments();
    _loadAnomalies();
  }

  Future<void> _loadForecast() async {
    setState(() => _loadingForecast = true);
    try {
      final api = context.read<AuthCubit>().api;
      final res = await api.get<dynamic>('/ai/analytics/forecast', queryParams: {'periods': '30'});
      final raw = res.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      setState(() {
        _forecastPoints = data is List
            ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _loadingForecast = false;
      });
    } catch (_) {
      setState(() => _loadingForecast = false);
    }
  }

  Future<void> _loadSegments() async {
    setState(() => _loadingSegments = true);
    try {
      final api = context.read<AuthCubit>().api;
      final res = await api.get<dynamic>('/ai/analytics/segments', queryParams: {'clusters': '4'});
      final raw = res.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      setState(() {
        _segments = data is List
            ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _loadingSegments = false;
      });
    } catch (_) {
      setState(() => _loadingSegments = false);
    }
  }

  Future<void> _loadAnomalies() async {
    setState(() => _loadingAnomalies = true);
    try {
      final api = context.read<AuthCubit>().api;
      final res = await api.get<dynamic>('/ai/analytics/anomalies');
      final raw = res.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      setState(() {
        _anomalies = data is List
            ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _loadingAnomalies = false;
      });
    } catch (_) {
      setState(() => _loadingAnomalies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: OmnigoColors.background,
          padding: OmnigoBreakpoints.pagePadding(context).copyWith(bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _kPrimary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'AI Insights',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Làm mới',
                    onPressed: _loadAll,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Phân tích AI tự động: dự đoán doanh thu, phân nhóm khách hàng và cảnh báo bất thường.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: OmnigoColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tab,
                labelColor: _kPrimary,
                unselectedLabelColor: OmnigoColors.textSecondary,
                indicatorColor: _kPrimary,
                tabs: const [
                  Tab(text: 'Dự đoán'),
                  Tab(text: 'Phân nhóm KH'),
                  Tab(text: 'Bất thường'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildForecastTab(),
              _buildSegmentsTab(),
              _buildAnomaliesTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Forecast Tab ───────────────────────────────────────────────────────────
  Widget _buildForecastTab() {
    if (_loadingForecast) {
      return const Center(child: OmnigoLoading(message: 'Đang dự đoán...'));
    }
    if (_forecastPoints.isEmpty) {
      return _emptyState(
        icon: Icons.trending_up,
        message: 'Chưa đủ dữ liệu để dự đoán doanh thu.\nCần ít nhất 30 ngày giao dịch.',
      );
    }

    final maxValue = _forecastPoints
        .map((p) => (p['value'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          OmnigoCard(
            title: 'Doanh thu dự đoán 30 ngày tới',
            child: Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _forecastPoints.take(30).map((p) {
                      final val = (p['value'] as num?)?.toDouble() ?? 0;
                      final pct = maxValue > 0 ? val / maxValue : 0;
                      final isUpper = p['type'] == 'upper';
                      final isLower = p['type'] == 'lower';
                      return Expanded(
                        child: Tooltip(
                          message: '${_formatCurrency(val)}\n${p['date'] ?? ''}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: (pct * 180).clamp(4, 180).toDouble(),
                            decoration: BoxDecoration(
                              color: isUpper
                                  ? _kPrimary.withValues(alpha: 0.4)
                                  : isLower
                                  ? _kPrimary.withValues(alpha: 0.2)
                                  : _kPrimary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(_kPrimary, 'Dự đoán'),
                    const SizedBox(width: 16),
                    _legend(_kPrimary.withValues(alpha: 0.4), 'Giới hạn trên'),
                    const SizedBox(width: 16),
                    _legend(_kPrimary.withValues(alpha: 0.2), 'Giới hạn dưới'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OmnigoCard(
            title: 'Chi tiết dự đoán',
            child: Column(
              children: _forecastPoints.take(10).map((p) {
                final val = (p['value'] as num?)?.toDouble() ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(p['date']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 13, color: OmnigoColors.textSecondary)),
                      const Spacer(),
                      Text(_formatCurrency(val),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segments Tab ──────────────────────────────────────────────────────────
  Widget _buildSegmentsTab() {
    if (_loadingSegments) {
      return const Center(child: OmnigoLoading(message: 'Đang phân tích...'));
    }
    if (_segments.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline,
        message: 'Chưa đủ dữ liệu để phân nhóm khách hàng.\nCần ít nhất 10 khách hàng có lịch sử mua.',
      );
    }

    final segmentColors = [
      const Color(0xFFC84B1A),
      const Color(0xFF2563EB),
      const Color(0xFF2E7D32),
      const Color(0xFFE7A93C),
      const Color(0xFF7C3AED),
    ];

    return SingleChildScrollView(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _segments.length,
              itemBuilder: (_, i) {
                final seg = _segments[i];
                final color = segmentColors[i % segmentColors.length];
                final count = (seg['count'] as num?)?.toInt() ?? 0;
                final avgValue = (seg['avg_value'] as num?)?.toDouble() ?? 0;
                final label = seg['label']?.toString() ?? 'Nhóm ${i + 1}';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.group, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(label,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('$count khách hàng',
                                style: const TextStyle(fontSize: 12, color: OmnigoColors.textSecondary)),
                            if (avgValue > 0)
                              Text('TB: ${_formatCurrency(avgValue)}',
                                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 16),
          OmnigoCard(
            title: 'Thống kê RFM theo nhóm',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OmnigoColors.textSecondary),
                dataTextStyle: const TextStyle(fontSize: 12),
                columns: const [
                  DataColumn(label: Text('Nhóm')),
                  DataColumn(label: Text('Khách')),
                  DataColumn(label: Text('Recency')),
                  DataColumn(label: Text('Frequency')),
                  DataColumn(label: Text('Monetary')),
                ],
                rows: _segments.asMap().entries.map((e) {
                  final seg = e.value;
                  return DataRow(cells: [
                    DataCell(Text(seg['label']?.toString() ?? 'Nhóm ${e.key + 1}')),
                    DataCell(Text('${(seg['count'] as num?)?.toInt() ?? 0}')),
                    DataCell(Text('${(seg['avg_recency'] as num?)?.toStringAsFixed(1) ?? '-'} ngày')),
                    DataCell(Text('${(seg['avg_frequency'] as num?)?.toStringAsFixed(1) ?? '-'} lần')),
                    DataCell(Text(_formatCurrency((seg['avg_value'] as num?)?.toDouble() ?? 0))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Anomalies Tab ─────────────────────────────────────────────────────────
  Widget _buildAnomaliesTab() {
    if (_loadingAnomalies) {
      return const Center(child: OmnigoLoading(message: 'Đang kiểm tra...'));
    }
    if (_anomalies.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle_outline,
        message: 'Không phát hiện bất thường.\nMọi chỉ số đang hoạt động bình thường.',
        isSuccess: true,
      );
    }
    return SingleChildScrollView(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phát hiện ${_anomalies.length} bất thường cần chú ý',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._anomalies.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['metric']?.toString() ?? 'Chỉ số bất thường',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a['description']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: OmnigoColors.textSecondary),
                      ),
                      if (a['date'] != null)
                        Text(
                          'Ngày: ${a['date']}',
                          style: const TextStyle(fontSize: 11, color: OmnigoColors.textHint),
                        ),
                    ],
                  ),
                ),
                if (a['severity'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _severityColor(a['severity'].toString()).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a['severity'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _severityColor(a['severity'].toString()),
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _emptyState({required IconData icon, required String message, bool isSuccess = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: isSuccess ? OmnigoColors.success : Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], height: 1.5),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: OmnigoColors.textSecondary)),
      ],
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFE7A93C);
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M đ';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K đ';
    }
    return '${value.toStringAsFixed(0)} đ';
  }
}
