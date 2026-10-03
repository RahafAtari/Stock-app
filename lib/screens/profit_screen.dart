import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ProfitScreen extends StatefulWidget {
  const ProfitScreen({super.key});

  @override
  State<ProfitScreen> createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  double? _today, _thisMonth, _allTime;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = SupabaseService.instance.watchSaleItems().listen((_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final epoch = DateTime(2000, 1, 1);

    final today = await SupabaseService.instance.calculateProfit(from: startOfDay, to: now);
    final month = await SupabaseService.instance.calculateProfit(from: startOfMonth, to: now);
    final all = await SupabaseService.instance.calculateProfit(from: epoch, to: now);

    if (mounted) {
      setState(() {
        _today = today;
        _thisMonth = month;
        _allTime = all;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الأرباح')),
        body: _today == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfitCard(title: 'ربح اليوم', value: _today!),
                  const SizedBox(height: 12),
                  _ProfitCard(title: 'ربح هذا الشهر', value: _thisMonth!),
                  const SizedBox(height: 12),
                  _ProfitCard(title: 'إجمالي الأرباح', value: _allTime!),
                ],
              ),
      ),
    );
  }
}

class _ProfitCard extends StatelessWidget {
  final String title;
  final double value;
  const _ProfitCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: AppColors.secondaryFont)),
            Text(value.toStringAsFixed(2),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
          ],
        ),
      ),
    );
  }
}
