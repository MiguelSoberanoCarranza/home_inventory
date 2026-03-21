import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = [
            _Stat(
              'Total Productos',
              '${state.totalProducts}',
              LucideIcons.package,
              Colors.blue,
            ),
            _Stat(
              'Lotes en Stock',
              '${state.totalLots}',
              LucideIcons.boxes,
              Colors.green,
            ),
            _Stat(
              'Vencen Pronto',
              '${state.expiringSoonCount}',
              LucideIcons.clock,
              Colors.orange,
            ),
             _Stat(
              'Vencidos',
              '${state.expiredCount}',
              LucideIcons.alertTriangle,
              Colors.red,
            ),
            _Stat(
              'Compras Pendientes',
              '${state.pendingShoppingItems}',
              LucideIcons.shoppingCart,
              Colors.purple,
            ),
          ];

          return RefreshIndicator(
            onRefresh: () => state.init(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      return stats[index];
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ubicaciones',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: state.countByLocation.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                _getLocationIcon(entry.key),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.outfit(fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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

  Widget _getLocationIcon(String location) {
    if (location.toLowerCase().contains('refri')) return const Icon(LucideIcons.snowflake, size: 20, color: Colors.blueAccent);
    if (location.toLowerCase().contains('congelador')) return const Icon(LucideIcons.thermometerSnowflake, size: 20, color: Colors.cyan);
    if (location.toLowerCase().contains('despensa')) return const Icon(LucideIcons.archive, size: 20, color: Colors.brown);
    return const Icon(LucideIcons.home, size: 20, color: Colors.grey);
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
