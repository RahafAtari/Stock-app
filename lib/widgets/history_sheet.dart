import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryRow {
  final String title;
  final String subtitle;
  final String? trailing;
  const HistoryRow({required this.title, required this.subtitle, this.trailing});
}

/// A bottom sheet that shows a simple scrollable list of records —
/// used for payment history and supplier-batch history.
Future<void> showHistorySheet(
  BuildContext context, {
  required String title,
  required Future<List<HistoryRow>> Function() loader,
}) {
  final future = loader();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryFont),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<HistoryRow>>(
                future: future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return const Center(
                      child: Text('تعذر التحميل',
                          style: TextStyle(color: AppColors.errorText)),
                    );
                  }
                  final rows = snap.data ?? [];
                  if (rows.isEmpty) {
                    return const Center(
                      child: Text('لا توجد سجلات',
                          style: TextStyle(color: AppColors.mutedFont)),
                    );
                  }
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(rows[i].title),
                      subtitle: Text(rows[i].subtitle,
                          style: const TextStyle(color: AppColors.mutedFont)),
                      trailing: rows[i].trailing == null
                          ? null
                          : Text(rows[i].trailing!,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
