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
                  Autocomplete<Product>(
                    initialValue: TextEditingValue(text: _nameController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Product>.empty();
                      }
                      return state.products.where((Product p) {
                        return p.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (Product p) => p.name,
                    onSelected: (Product p) {
                      setState(() {
                        _selectedProduct = p.id;
                        _nameController.text = p.name;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Producto',
                          hintText: 'Ej: Leche, Arroz...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(LucideIcons.package),
                        ),
                        onChanged: (v) {
                          _nameController.text = v;
                          final exists = state.products.any((p) =>
                              p.name.toLowerCase() == v.trim().toLowerCase());
                          if (!exists) _selectedProduct = null;
                        },
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa un nombre'
                            : null,
                      );
                    },
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

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final appState = context.read<AppState>();

    // 1. Resolver el producto (usar existente o crear uno nuevo)
    String? productId = _selectedProduct;
    
    // Si no tenemos ID seleccionado, buscamos por nombre exacto
    if (productId == null) {
      final existingProduct = appState.products.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
        orElse: () => Product(id: '', name: '', category: '', defaultUnit: '', createdAt: DateTime.now()), // Placeholder
      );

      if (existingProduct.id.isNotEmpty) {
        productId = existingProduct.id;
      } else {
        // Crear nuevo producto
        final newProduct = await appState.addOrEditProduct({
          'name': name,
          'category': 'General',
          'default_unit': _unitController.text,
        });
        if (newProduct == null) {
          setState(() => _isSaving = false);
          return; // El error ya se setea en appState
        }
        productId = newProduct.id;
      }
    } else {
      // Verificar si el nombre cambió para el producto existente y actualizarlo si es necesario
      final p = appState.products.firstWhere((p) => p.id == productId);
      if (p.name != name) {
        await appState.addOrEditProduct({
          'id': productId,
          'name': name,
        });
      }
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final data = {
      if (widget.lot != null) 'id': widget.lot!.id,
      'product_id': productId,
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