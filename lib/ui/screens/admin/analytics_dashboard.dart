// lib/ui/screens/admin/analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final _supabase = Supabase.instance.client;
  Timer? _refreshTimer;

  AnalyticsData? _data;
  bool _isLoading = true;
  String _selectedPeriod = '7days';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadAnalytics(silent: true),
    );
  }

  Future<void> _loadAnalytics({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final interval = _selectedPeriod == '24h' ? '1 day'
          : _selectedPeriod == '7days' ? '7 days'
          : '30 days';

      // Parallel queries for performance
      final results = await Future.wait([
        _getOverviewStats(interval),
        _getUserGrowth(interval),
        _getTopCategories(),
        _getRecentActivity(),
        _getGeographicData(),
      ]);

      setState(() {
        _data = AnalyticsData(
          overview: results[0] as OverviewStats,
          userGrowth: results[1] as List<DailyStats>,
          topCategories: results[2] as List<CategoryStat>,
          recentActivity: results[3] as List<ActivityItem>,
          geographic: results[4] as List<GeographicStat>,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<OverviewStats> _getOverviewStats(String interval) async {
    final stats = await _supabase.rpc('get_analytics_overview', params: {
      'time_interval': interval,
    });

    return OverviewStats.fromJson(stats);
  }

  Future<List<DailyStats>> _getUserGrowth(String interval) async {
    final growth = await _supabase.rpc('get_user_growth', params: {
      'time_interval': interval,
    });

    return (growth as List)
        .map((json) => DailyStats.fromJson(json))
        .toList();
  }

  Future<List<CategoryStat>> _getTopCategories() async {
    final categories = await _supabase
        .from('items')
        .select('category')
        .eq('status', 'active');

    final Map<String, int> counts = {};
    for (final item in categories) {
      final cat = item['category'] ?? 'Other';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    return counts.entries
        .map((e) => CategoryStat(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  Future<List<ActivityItem>> _getRecentActivity() async {
    final activities = await _supabase
        .from('user_interactions')
        .select('action, created_at, items!item_id(title)')
        .order('created_at', ascending: false)
        .limit(20);

    return (activities as List)
        .map((json) => ActivityItem.fromJson(json))
        .toList();
  }

  Future<List<GeographicStat>> _getGeographicData() async {
    // This is a simplified query. For production, you would want to
    // reverse geocode the lat/lng points to get actual city names.
    final response = await _supabase
        .from('items')
        .select('location')
        .neq('location', null);

    final Map<String, int> counts = {};
    for (final item in response) {
      final location = item['location'] as String?;
      if (location != null) {
        final parts = location.split(' ');
        if (parts.length >= 2) {
          final city = parts.first; // Very rough approximation
          counts[city] = (counts[city] ?? 0) + 1;
        }
      }
    }

    return counts.entries
        .map((e) => GeographicStat(city: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAnalytics(),
          ),
        ],
      ),
      body: _isLoading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadAnalytics(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildUserGrowthChart(),
                    const SizedBox(height: 24),
                    _buildCategoryDistribution(),
                    const SizedBox(height: 24),
                    _buildGeographicMap(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _periodButton('24h', 'Last 24h'),
          _periodButton('7days', 'Last 7 days'),
          _periodButton('30days', 'Last 30 days'),
        ],
      ),
    );
  }

  Widget _periodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadAnalytics();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2962FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (_data == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            '${_data!.overview.totalUsers}',
            Icons.people,
            const Color(0xFF2962FF),
            '+${_data!.overview.newUsers} new',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Items',
            '${_data!.overview.activeItems}',
            Icons.inventory,
            const Color(0xFF00E676),
            '+${_data!.overview.newItems} today',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '↑',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    if (_data == null || _data!.userGrowth.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: LineChartPainter(
                data: _data!.userGrowth,
                color: const Color(0xFF2962FF),
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    if (_data == null || _data!.topCategories.isEmpty) return const SizedBox();

    final total = _data!.topCategories.fold<int>(0, (sum, cat) => sum + cat.count);
    final colors = [
      const Color(0xFF2962FF),
      const Color(0xFF00E676),
      const Color(0xFFBB86FC),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            math.min(5, _data!.topCategories.length),
            (index) {
              final cat = _data!.topCategories[index];
              final percentage = (cat.count / total * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: colors[index % colors.length],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cat.count / total,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation(colors[index % colors.length]),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicMap() {
    if (_data == null || _data!.geographic.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Cities',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            math.min(5, _data!.geographic.length),
            (index) {
              final city = _data!.geographic[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2962FF).withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF2962FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  city.city,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Text(
                  '${city.count} items',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_data == null || _data!.recentActivity.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            math.min(10, _data!.recentActivity.length),
            (index) {
              final activity = _data!.recentActivity[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _getActivityIcon(activity.action),
                title: Text(
                  _getActivityText(activity),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  _formatRelativeTime(activity.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getActivityIcon(String action) {
    IconData icon;
    Color color;

    switch (action) {
      case 'swipe_right':
        icon = Icons.favorite;
        color = const Color(0xFF00E676);
        break;
      case 'offer_sent':
        icon = Icons.local_offer;
        color = const Color(0xFFBB86FC);
        break;
      case 'view':
        icon = Icons.visibility;
        color = Colors.blue;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getActivityText(ActivityItem activity) {
    switch (activity.action) {
      case 'swipe_right':
        return 'Someone liked "${activity.itemTitle}"';
      case 'offer_sent':
        return 'New offer on "${activity.itemTitle}"';
      case 'view':
        return 'Someone viewed "${activity.itemTitle}"';
      default:
        return 'Activity on "${activity.itemTitle}"';
    }
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// Custom Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<DailyStats> data;
  final Color color;

  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final maxValue = data.map((e) => e.count).reduce(math.max).toDouble();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].count / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Fill area under line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Models
class AnalyticsData {
  final OverviewStats overview;
  final List<DailyStats> userGrowth;
  final List<CategoryStat> topCategories;
  final List<ActivityItem> recentActivity;
  final List<GeographicStat> geographic;

  AnalyticsData({
    required this.overview,
    required this.userGrowth,
    required this.topCategories,
    required this.recentActivity,
    required this.geographic,
  });
}

class OverviewStats {
  final int totalUsers;
  final int newUsers;
  final int activeItems;
  final int newItems;
  final int totalOffers;
  final int revenue;

  OverviewStats({
    required this.totalUsers,
    required this.newUsers,
    required this.activeItems,
    required this.newItems,
    required this.totalOffers,
    required this.revenue,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalUsers: json['total_users'] ?? 0,
      newUsers: json['new_users'] ?? 0,
      activeItems: json['active_items'] ?? 0,
      newItems: json['new_items'] ?? 0,
      totalOffers: json['total_offers'] ?? 0,
      revenue: json['revenue'] ?? 0,
    );
  }
}

class DailyStats {
  final DateTime date;
  final int count;

  DailyStats({required this.date, required this.count});

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}

class CategoryStat {
  final String name;
  final int count;

  CategoryStat({required this.name, required this.count});
}

class ActivityItem {
  final String action;
  final String itemTitle;
  final DateTime timestamp;

  ActivityItem({
    required this.action,
    required this.itemTitle,
    required this.timestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      action: json['action'],
      itemTitle: json['items']?['title'] ?? 'Unknown item',
      timestamp: DateTime.parse(json['created_at']),
    );
  }
}

class GeographicStat {
  final String city;
  final int count;

  GeographicStat({required this.city, required this.count});
}
