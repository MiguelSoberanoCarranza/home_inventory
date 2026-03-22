import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/inventory_models.dart';
import '../services/app_state.dart';
import 'add_edit_lot_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String? _selectedLocation;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventario',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF2E7D32)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditLotScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final filteredList = state.inventory.where((lot) {
            final matchesName = (lot.product?.name ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            final matchesLocation = _selectedLocation == null ||
                lot.locationName.toLowerCase() == _selectedLocation!.toLowerCase();
            final matchesCategory = _selectedCategory == null ||
                (lot.product?.category ?? '').toLowerCase() ==
                    _selectedCategory!.toLowerCase();
            return matchesName && matchesLocation && matchesCategory;
          }).toList()
            ..sort((a, b) {
              final locationCompare =
                  a.locationName.toLowerCase().compareTo(b.locationName.toLowerCase());
              if (locationCompare != 0) {
                return locationCompare;
              }
              return (a.product?.name ?? '')
                  .toLowerCase()
                  .compareTo((b.product?.name ?? '').toLowerCase());
            });

          final groupedLots = _groupLotsByLocation(filteredList);

          return Column(
            children: [
              _buildSearchAndFilters(state, filteredList, groupedLots),
              Expanded(
                child: filteredList.isEmpty
                    ? const _InventoryEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        children: groupedLots.entries
                            .map(
                              (entry) => _LocationSection(
                                location: entry.key,
                                lots: entry.value,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(
    AppState state,
    List<InventoryLot> filteredList,
    Map<String, List<InventoryLot>> groupedLots,
  ) {
    final categories = state.products
        .map((p) => p.category)
        .toSet()
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort();
    final locations = state.locations.isNotEmpty
        ? state.locations.map((l) => l.name).toList()
        : ['Refri', 'Congelador', 'Despensa', 'Casa'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Ubicación',
                  options: locations,
                  selected: _selectedLocation,
                  onSelected: (v) =>
                      setState(() => _selectedLocation = (v == '' ? null : v)),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Categoría',
                  options: categories,
                  selected: _selectedCategory,
                  onSelected: (v) =>
                      setState(() => _selectedCategory = (v == '' ? null : v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(
                icon: LucideIcons.layoutGrid,
                label: '${groupedLots.length} ubicaciones',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: LucideIcons.package,
                label: '${filteredList.length} lotes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final Function(String?) onSelected;

  const _FilterChip({
    required this.label,
    required this.options,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(value: '', child: Text('Todo')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected != null ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text(
              selected ?? label,
              style: TextStyle(
                color: selected != null ? Colors.white : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: selected != null ? Colors.white : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.package, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No encontramos productos con esos filtros',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final String location;
  final List<InventoryLot> lots;

  const _LocationSection({
    required this.location,
    required this.lots,
  });

  @override
  Widget build(BuildContext context) {
    final expiringSoon = lots.where((lot) => lot.statusColor == 'yellow').length;
    final expired = lots.where((lot) => lot.statusColor == 'red').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.mapPin, color: Color(0xFF2E7D32)),
        ),
        title: Text(
          location,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${lots.length} producto${lots.length == 1 ? '' : 's'}'
          '${expired > 0 ? ' • $expired vencido${expired == 1 ? '' : 's'}' : ''}'
          '${expiringSoon > 0 ? ' • $expiringSoon por vencer' : ''}',
        ),
        children: lots.map((lot) => _LotTile(lot: lot)).toList(),
      ),
    );
  }
}

class _LotTile extends StatelessWidget {
  final InventoryLot lot;

  const _LotTile({required this.lot});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditLotScreen(lot: lot)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lot.product?.name ?? 'Producto desconocido',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Label(icon: LucideIcons.package, label: '${lot.quantity} ${lot.unit}'),
                  _Label(icon: LucideIcons.mapPin, label: lot.locationName),
                  if (lot.expiresOn != null)
                    _Label(
                      icon: LucideIcons.clock,
                      label: DateFormat('dd/MM/yy').format(lot.expiresOn!),
                      color: lot.statusColor == 'red' ? Colors.red : null,
                    ),
                ],
              ),
              if (lot.notes != null && lot.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lot.notes!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (lot.statusColor) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Label({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color ?? Colors.grey.shade700),
        ),
      ],
    );
  }
}

Map<String, List<InventoryLot>> _groupLotsByLocation(List<InventoryLot> lots) {
  final grouped = <String, List<InventoryLot>>{};
  for (final lot in lots) {
    final location = lot.locationName.trim().isEmpty ? 'Sin ubicación' : lot.locationName;
    grouped.putIfAbsent(location, () => []).add(lot);
  }

  final sortedEntries = grouped.entries.toList()
    ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

  return Map<String, List<InventoryLot>>.fromEntries(sortedEntries);
}
