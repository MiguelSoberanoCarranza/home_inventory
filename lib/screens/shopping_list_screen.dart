import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/app_state.dart';
import '../models/inventory_models.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  String? _selectedPriority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Compras',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Color(0xFF2E7D32)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filtrar por prioridad'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Todas'),
                        onTap: () {
                          setState(() => _selectedPriority = null);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Alta'),
                        leading: const Icon(LucideIcons.alertCircle, color: Colors.red),
                        onTap: () {
                          setState(() => _selectedPriority = 'alta');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Media'),
                        leading: const Icon(LucideIcons.clock, color: Colors.orange),
                        onTap: () {
                          setState(() => _selectedPriority = 'media');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Baja'),
                        leading: const Icon(LucideIcons.checkCircle, color: Colors.green),
                        onTap: () {
                          setState(() => _selectedPriority = 'baja');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Filtrar por prioridad',
          )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final pending = state.shoppingList
              .where((item) =>
                  !item.completed &&
                  (_selectedPriority == null ||
                      item.priority.toLowerCase() == _selectedPriority))
              .toList();
          final completed = state.shoppingList
              .where((item) =>
                  item.completed &&
                  (_selectedPriority == null ||
                      item.priority.toLowerCase() == _selectedPriority))
              .toList();

          return state.shoppingList.isEmpty
              ? const Center(child: Text('Tu lista está vacía.'))
              : ListView(
                  children: [
                    if (pending.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Pendientes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ...pending.map((item) => _ShoppingListItem(item: item)),
                    ],
                    if (completed.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Completados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...completed.map((item) => _ShoppingListItem(item: item)),
                    ],
                  ],
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(LucideIcons.plus, color: Colors.white),
        tooltip: 'Agregar producto',
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, [ShoppingItem? item]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name);
    final quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '1');
    final unitController = TextEditingController(text: item?.unit ?? 'Unidad(es)');
    String priority = item?.priority ?? 'media';
    final categoryController = TextEditingController(text: item?.category ?? 'Despensa');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item == null ? 'Agregar Producto' : 'Editar Producto',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa un nombre' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: _validateQuantity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Ingresa una unidad' : null,
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: ['baja', 'media', 'alta']
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) => setModalState(() => priority = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final quantity = double.tryParse(quantityController.text);
                            if (quantity == null || quantity <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cantidad inválida')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            final data = {
                              if (item != null) 'id': item.id,
                              'name': nameController.text.trim(),
                              'quantity': quantity,
                              'unit': unitController.text.trim(),
                              'priority': priority,
                              'category': categoryController.text.trim(),
                              'completed': item?.completed ?? false,
                            };

                            final success =
                                await context.read<AppState>().addOrEditShoppingItem(data);

                            if (context.mounted) {
                              if (success) {
                                Navigator.pop(context);
                              } else {
                                final error = context.read<AppState>().lastError;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error ?? 'Error al guardar')),
                                );
                                setModalState(() => isSaving = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una cantidad';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Número inválido';
    }
    if (parsed <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }
}

class _ShoppingListItem extends StatelessWidget {
  final ShoppingItem item;

  const _ShoppingListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.completed,
        activeColor: Colors.green,
        onChanged: (v) => context.read<AppState>().toggleShoppingItem(item.id, v!),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.completed ? TextDecoration.lineThrough : null,
          color: item.completed ? Colors.grey : null,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle:
          Text('${item.quantity} ${item.unit} • ${item.priority.toUpperCase()}'),
      trailing: IconButton(
        icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.grey),
        onPressed: () => context.read<AppState>().deleteShoppingItem(item.id),
        tooltip: 'Eliminar',
      ),
    );
  }
}