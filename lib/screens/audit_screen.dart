import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/inventory_models.dart';
import '../services/app_state.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String _searchQuery = '';
  String? _selectedLocation;
  
  // Mapa para trackear cambios: id -> cantidad actual editada
  final Map<String, double> _editedQuantities = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Auditoría',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_editedQuantities.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveAllChanges,
              icon: _isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.save, color: Color(0xFF2E7D32)),
              label: Text(
                'Guardar (${_editedQuantities.length})',
                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final List<InventoryLot> filteredList = state.inventory.where((lot) {
            final matchesName = (lot.product?.name ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            final matchesLocation = _selectedLocation == null ||
                lot.locationName.toLowerCase() == _selectedLocation!.toLowerCase();
            return matchesName && matchesLocation;
          }).toList()
            ..sort((a, b) => (a.product?.name ?? '').toLowerCase().compareTo((b.product?.name ?? '').toLowerCase()));

          return Column(
            children: [
              _buildFilters(state),
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(child: Text('No hay productos para auditar'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final lot = filteredList[index];
                          final currentInputQuantity = _editedQuantities[lot.id] ?? lot.quantity;
                          final hasChanged = _editedQuantities.containsKey(lot.id);

                          return _AuditLotTile(
                            lot: lot,
                            currentQuantity: currentInputQuantity,
                            hasChanged: hasChanged,
                            onQuantityChanged: (newQuantity) {
                              setState(() {
                                if (newQuantity == lot.quantity) {
                                  _editedQuantities.remove(lot.id);
                                } else {
                                  _editedQuantities[lot.id] = newQuantity;
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(AppState state) {
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
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Ubicación: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _selectedLocation == null,
                  onSelected: (val) {
                    if (val) setState(() => _selectedLocation = null);
                  },
                ),
                ...locations.map((loc) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(loc),
                        selected: _selectedLocation == loc,
                        onSelected: (val) {
                          if (val) setState(() => _selectedLocation = loc);
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isSaving = true);
    final appState = context.read<AppState>();
    
    int successCount = 0;
    
    for (var entry in _editedQuantities.entries) {
      final lotId = entry.key;
      final newQuantity = entry.value;
      
      final currentLot = appState.inventory.firstWhere((l) => l.id == lotId);
      
      final data = {
        'id': currentLot.id,
        'product_id': currentLot.productId,
        'quantity': newQuantity,
        'unit': currentLot.unit,
        if (currentLot.locationId != null) 'location_id': currentLot.locationId,
        'location': currentLot.locationName, // Compatibilidad
        'status': currentLot.status,
        if (currentLot.expiresOn != null) 'expires_on': currentLot.expiresOn!.toIso8601String(),
        'notes': currentLot.notes,
        'source': currentLot.source,
      };
      
      final success = await appState.addOrEditLot(data);
      if (success) successCount++;
    }
    
    if (mounted) {
      setState(() {
        _isSaving = false;
        _editedQuantities.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se actualizaron $successCount lotes.')),
      );
    }
  }
}

class _AuditLotTile extends StatelessWidget {
  final InventoryLot lot;
  final double currentQuantity;
  final bool hasChanged;
  final Function(double) onQuantityChanged;

  const _AuditLotTile({
    required this.lot,
    required this.currentQuantity,
    required this.hasChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: hasChanged ? const Color(0xFFF1F8E9) : const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: hasChanged ? Colors.green : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.product?.name ?? 'Desconocido',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasChanged ? Colors.green.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(lot.locationName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  if (hasChanged) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Original: ${lot.quantity}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ]
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    final newQ = (currentQuantity - 0.5).clamp(0.0, double.infinity);
                    onQuantityChanged(newQ);
                  },
                  icon: const Icon(LucideIcons.minusCircle),
                  color: Colors.red.shade300,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    currentQuantity.toStringAsFixed(currentQuantity.truncateToDouble() == currentQuantity ? 0 : 1),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    onQuantityChanged(currentQuantity + 0.5);
                  },
                  icon: const Icon(LucideIcons.plusCircle),
                  color: Colors.green.shade400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
