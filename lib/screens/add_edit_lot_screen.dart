import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/app_state.dart';
import '../models/inventory_models.dart';

class AddEditLotScreen extends StatefulWidget {
  final InventoryLot? lot;

  const AddEditLotScreen({super.key, this.lot});

  @override
  State<AddEditLotScreen> createState() => _AddEditLotScreenState();
}

class _AddEditLotScreenState extends State<AddEditLotScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  String? _selectedLocationId;
  String? _selectedProduct;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lot?.product?.name);
    _quantityController =
        TextEditingController(text: widget.lot?.quantity.toString() ?? '1');
    _unitController =
        TextEditingController(text: widget.lot?.unit ?? 'Unidad(es)');
    _notesController = TextEditingController(text: widget.lot?.notes);
    _selectedDate = widget.lot?.expiresOn;
    _selectedLocationId = widget.lot?.locationId;
    _selectedProduct = widget.lot?.productId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lot == null ? 'Nuevo Lote' : 'Editar Lote',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.lot != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              onPressed: () => _confirmDelete(),
              tooltip: 'Eliminar lote',
            )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('Producto y Cantidad'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Producto (Catálogo)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    items: state.products
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProduct = v),
                    validator: (v) =>
                        v == null ? 'Selecciona un producto' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateQuantity,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Ingresa una unidad' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildHeader('Ubicación y Caducidad'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    items: state.locations
                        .map((l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLocationId = v),
                    validator: (v) =>
                        v == null ? 'Selecciona una ubicación' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Seleccionar Caducidad'
                                : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(LucideIcons.calendar),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildHeader('Notas'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Añade notas (opcional)...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveLot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Guardar Lote',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 0.5,
      ),
    );
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una cantidad';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Ingresa un número válido';
    }
    if (parsed <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    return null;
  }

  Future<void> _saveLot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      if (widget.lot != null) 'id': widget.lot!.id,
      'product_id': _selectedProduct,
      'quantity': quantity,
      'unit': _unitController.text,
      'location_id': _selectedLocationId,
      'status': 'ok',
      'expires_on': _selectedDate?.toIso8601String(),
      'notes': _notesController.text,
    };

    try {
      final success = await context.read<AppState>().addOrEditLot(data);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          final error = context.read<AppState>().lastError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Error al guardar')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Lote'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este lote del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success =
                  await context.read<AppState>().deleteLot(widget.lot!.id);
              if (mounted) {
                if (success) {
                  Navigator.pop(context); // Close screen
                } else {
                  final error = context.read<AppState>().lastError;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Error al eliminar')),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}