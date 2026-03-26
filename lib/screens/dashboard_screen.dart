import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_state.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final lots = state.inventory.where((lot) => lot.quantity > 0).toList();
          final expiredLots = lots.where((lot) => lot.statusColor == 'red').toList();
          final expiringSoonLots =
              lots.where((lot) => lot.statusColor == 'yellow').toList();
          final shoppingPending = state.shoppingList
              .where((item) => !item.completed)
              .toList();
          final locations = state.countByLocation.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final health = _buildHealthSummary(
            totalLots: state.totalLots,
            expiredCount: expiredLots.length,
            expiringSoonCount: expiringSoonLots.length,
            pendingShoppingCount: shoppingPending.length,
          );

          return RefreshIndicator(
            onRefresh: () => state.init(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _DashboardHero(
                          health: health,
                          totalLots: state.totalLots,
                          totalProducts: state.totalProducts,
                        ),
                        const SizedBox(height: 20),
                        _UrgencyStrip(
                          expiredCount: expiredLots.length,
                          expiringSoonCount: expiringSoonLots.length,
                          pendingShoppingCount: shoppingPending.length,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Resumen rápido',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _InsightCard(
                              title: 'Inventario activo',
                              value: '${state.totalLots}',
                              hint: 'Lotes disponibles en casa',
                              accent: const Color(0xFF2E7D32),
                              icon: LucideIcons.package,
                            ),
                            _InsightCard(
                              title: 'Productos únicos',
                              value: '${state.totalProducts}',
                              hint: 'Catálogo total registrado',
                              accent: const Color(0xFF1565C0),
                              icon: LucideIcons.archive,
                            ),
                            _InsightCard(
                              title: 'Por vencer',
                              value: '${expiringSoonLots.length}',
                              hint: expiringSoonLots.isEmpty
                                  ? 'Sin alertas esta semana'
                                  : 'Conviene revisarlos hoy',
                              accent: const Color(0xFFEF6C00),
                              icon: LucideIcons.clock,
                            ),
                            _InsightCard(
                              title: 'Lista pendiente',
                              value: '${shoppingPending.length}',
                              hint: shoppingPending.isEmpty
                                  ? 'No hace falta comprar'
                                  : 'Productos por reponer',
                              accent: const Color(0xFF6A1B9A),
                              icon: LucideIcons.shoppingCart,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Lo que necesita atención',
                          subtitle: 'Prioriza desperdicio, reposición y zonas más cargadas.',
                        ),
                        const SizedBox(height: 12),
                        _ActionPanel(
                          title: 'Vencidos',
                          countLabel: '${expiredLots.length}',
                          accent: const Color(0xFFC62828),
                          icon: LucideIcons.alertTriangle,
                          emptyMessage: 'No hay productos vencidos.',
                          items: expiredLots
                              .take(4)
                              .map(
                                (lot) => _ActionItemData(
                                  title: lot.product?.name ?? 'Producto desconocido',
                                  subtitle: lot.locationName,
                                  trailing: '${lot.quantity} ${lot.unit}',
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        _ActionPanel(
                          title: 'Por vencer pronto',
                          countLabel: '${expiringSoonLots.length}',
                          accent: const Color(0xFFEF6C00),
                          icon: LucideIcons.clock,
                          emptyMessage: 'No hay productos por vencer pronto.',
                          items: expiringSoonLots
                              .take(4)
                              .map(
                                (lot) => _ActionItemData(
                                  title: lot.product?.name ?? 'Producto desconocido',
                                  subtitle: lot.locationName,
                                  trailing: '${lot.quantity} ${lot.unit}',
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        _ActionPanel(
                          title: 'Pendientes de compra',
                          countLabel: '${shoppingPending.length}',
                          accent: const Color(0xFF6A1B9A),
                          icon: LucideIcons.shoppingCart,
                          emptyMessage: 'Tu lista de compras está al día.',
                          items: shoppingPending
                              .take(4)
                              .map(
                                (item) => _ActionItemData(
                                  title: item.name,
                                  subtitle: item.category,
                                  trailing: '${item.quantity} ${item.unit}',
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Mapa del hogar',
                          subtitle: 'Identifica dónde está concentrado tu inventario.',
                        ),
                        const SizedBox(height: 12),
                        if (locations.isEmpty)
                          const _SimpleEmptyState(
                            message: 'Aún no hay ubicaciones con inventario.',
                          )
                        else
                          ...locations.take(5).map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LocationBar(
                                    label: entry.key,
                                    count: entry.value,
                                    maxCount: locations.first.value,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final _HealthSummary health;
  final int totalLots;
  final int totalProducts;

  const _DashboardHero({
    required this.health,
    required this.totalLots,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16381F),
            Color(0xFF2E7D32),
            Color(0xFF78A85B),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Estado general del hogar',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            health.title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            health.message,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.84),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroMetric(label: 'Salud', value: '${health.score}%'),
              const SizedBox(width: 12),
              _HeroMetric(label: 'Lotes', value: '$totalLots'),
              const SizedBox(width: 12),
              _HeroMetric(label: 'Productos', value: '$totalProducts'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyStrip extends StatelessWidget {
  final int expiredCount;
  final int expiringSoonCount;
  final int pendingShoppingCount;

  const _UrgencyStrip({
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.pendingShoppingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatusCard(
            icon: LucideIcons.alertTriangle,
            label: 'Vencidos',
            value: '$expiredCount',
            accent: const Color(0xFFC62828),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatusCard(
            icon: LucideIcons.clock,
            label: 'Por vencer',
            value: '$expiringSoonCount',
            accent: const Color(0xFFEF6C00),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatusCard(
            icon: LucideIcons.shoppingCart,
            label: 'Compras',
            value: '$pendingShoppingCount',
            accent: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}

class _MiniStatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MiniStatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;
  final Color accent;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;

    return Container(
      width: width < 160 ? double.infinity : width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF102014),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.35,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final String title;
  final String countLabel;
  final Color accent;
  final IconData icon;
  final String emptyMessage;
  final List<_ActionItemData> items;

  const _ActionPanel({
    required this.title,
    required this.countLabel,
    required this.accent,
    required this.icon,
    required this.emptyMessage,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                countLabel,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _SimpleEmptyState(message: emptyMessage)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActionRow(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final _ActionItemData item;

  const _ActionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.trailing,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2E20),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;

  const _LocationBar({
    required this.label,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxCount == 0 ? 0.0 : count / maxCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _getLocationIcon(label),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleEmptyState extends StatelessWidget {
  final String message;

  const _SimpleEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _ActionItemData {
  final String title;
  final String subtitle;
  final String trailing;

  const _ActionItemData({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}

class _HealthSummary {
  final int score;
  final String title;
  final String message;

  const _HealthSummary({
    required this.score,
    required this.title,
    required this.message,
  });
}

_HealthSummary _buildHealthSummary({
  required int totalLots,
  required int expiredCount,
  required int expiringSoonCount,
  required int pendingShoppingCount,
}) {
  if (totalLots == 0) {
    return const _HealthSummary(
      score: 0,
      title: 'Todavía no hay inventario activo',
      message: 'Empieza registrando productos para ver alertas, compras y zonas clave.',
    );
  }

  final rawScore =
      100 - (expiredCount * 18) - (expiringSoonCount * 8) - (pendingShoppingCount * 4);
  final score = rawScore.clamp(12, 100);

  if (expiredCount > 0) {
    return _HealthSummary(
      score: score,
      title: 'Hay productos que requieren acción inmediata',
      message:
          '$expiredCount vencido${expiredCount == 1 ? '' : 's'} detectado${expiredCount == 1 ? '' : 's'}. Conviene revisar primero esa zona.',
    );
  }

  if (expiringSoonCount > 0) {
    return _HealthSummary(
      score: score,
      title: 'Tu inventario está estable, pero ya hay alertas cercanas',
      message:
          '$expiringSoonCount producto${expiringSoonCount == 1 ? '' : 's'} por vencer pronto. Buen momento para planear comidas o mover compras.',
    );
  }

  if (pendingShoppingCount > 0) {
    return _HealthSummary(
      score: score,
      title: 'La casa está en orden y solo faltan reposiciones',
      message:
          'No hay urgencias de caducidad. La siguiente tarea útil es completar tu lista de compras.',
    );
  }

  return _HealthSummary(
    score: score,
    title: 'Todo se ve bajo control',
    message:
        'No hay vencidos ni alertas cercanas. Tu inventario está sano y bien distribuido.',
  );
}

Widget _getLocationIcon(String location) {
  final normalized = location.toLowerCase();
  if (normalized.contains('refri')) {
    return const Icon(LucideIcons.snowflake, size: 20, color: Color(0xFF1565C0));
  }
  if (normalized.contains('congelador')) {
    return const Icon(
      LucideIcons.thermometerSnowflake,
      size: 20,
      color: Color(0xFF00838F),
    );
  }
  if (normalized.contains('despensa')) {
    return const Icon(LucideIcons.archive, size: 20, color: Color(0xFF6D4C41));
  }
  return const Icon(LucideIcons.home, size: 20, color: Color(0xFF546E7A));
}
