import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/app_state.dart';
import '../models/inventory_models.dart';
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
          )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final filteredList = state.inventory.where((lot) {
            final matchesName = (lot.product?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            // Filtrado insensible a mayúsculas para las ubicaciones
            final matchesLocation = _selectedLocation == null || 
              lot.locationName.toLowerCase() == _selectedLocation!.toLowerCase();
            final matchesCategory = _selectedCategory == null || 
              (lot.product?.category ?? '').toLowerCase() == _selectedCategory!.toLowerCase();
            return matchesName && matchesLocation && matchesCategory;
          }).toList();

          return Column(
            children: [
              _buildSearchAndFilters(state),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final lot = filteredList[index];
                    return _LotTile(lot: lot);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(AppState state) {
    final categories = state.products.map((p) => p.category).toSet().where((c) => c.isNotEmpty).toList();
    // Usar ubicaciones de la BD si existen, sino usar las quemadas
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
                  onSelected: (v) => setState(() => _selectedLocation = (v == '' ? null : v)),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Categoría',
                  options: categories,
                  selected: _selectedCategory,
                  onSelected: (v) => setState(() => _selectedCategory = (v == '' ? null : v)),
                ),
              ],
            ),
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

  const _FilterChip({required this.label, required this.options, this.selected, required this.onSelected});

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

class _LotTile extends StatelessWidget {
  final InventoryLot lot;

  const _LotTile({required this.lot});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
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
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
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
              Row(
                children: [
                  _Label(icon: LucideIcons.package, label: '${lot.quantity} ${lot.unit}'),
                  const SizedBox(width: 12),
                  _Label(icon: LucideIcons.mapPin, label: lot.locationName),
                  if (lot.expiresOn != null) ...[
                    const SizedBox(width: 12),
                    _Label(
                      icon: LucideIcons.clock,
                      label: DateFormat('dd/MM/yy').format(lot.expiresOn!),
                      color: lot.statusColor == 'red' ? Colors.red : null,
                    ),
                  ],
                ],
              ),
              if (lot.notes != null && lot.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lot.notes!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
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
      case 'red': return Colors.red;
      case 'yellow': return Colors.orange;
      default: return Colors.green;
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
