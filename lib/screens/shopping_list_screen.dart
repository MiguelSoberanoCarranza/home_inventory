import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/inventory_models.dart';
import '../services/app_state.dart';

const List<String> _shoppingAisles = [
  'Frutas y verduras',
  'Carnes y pescados',
  'Deli y preparados',
  'Panaderia y tortillas',
  'Lacteos y huevos',
  'Abarrotes y enlatados',
  'Desayuno y cereal',
  'Botanas y dulces',
  'Bebidas',
  'Congelados',
  'Reposteria y especias',
  'Comida internacional',
  'Limpieza y hogar',
  'Cuidado personal y salud',
  'Bebes',
  'Mascotas',
  'Otros',
];

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
          ),
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
                    if (pending.isNotEmpty)
                      _ShoppingSection(
                        title: 'Pendientes',
                        items: pending,
                        onEdit: (item) => _showAddItemDialog(context, item),
                      ),
                    if (completed.isNotEmpty)
                      _ShoppingSection(
                        title: 'Completados',
                        items: completed,
                        titleColor: Colors.grey,
                        topPadding: pending.isNotEmpty ? 24 : 16,
                        onEdit: (item) => _showAddItemDialog(context, item),
                      ),
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
    String category = _resolveCategoryLabel(item?.category, fallbackName: item?.name ?? '');
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Pasillo'),
                  items: _shoppingAisles
                      .map((aisle) => DropdownMenuItem(
                            value: aisle,
                            child: Text(aisle),
                          ))
                      .toList(),
                  onChanged: (value) => setModalState(() => category = value!),
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
                                const SnackBar(content: Text('Cantidad invalida')),
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
                              'category': category,
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
      return 'Numero invalido';
    }
    if (parsed <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }
}

class _ShoppingSection extends StatelessWidget {
  final String title;
  final List<ShoppingItem> items;
  final Color? titleColor;
  final double topPadding;
  final Function(ShoppingItem) onEdit;

  const _ShoppingSection({
    required this.title,
    required this.items,
    required this.onEdit,
    this.titleColor,
    this.topPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByAisle(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: titleColor,
            ),
          ),
        ),
        for (final entry in groupedItems.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.store,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map((item) => _ShoppingListItem(item: item, onEdit: onEdit)),
        ],
      ],
    );
  }
}

class _ShoppingListItem extends StatelessWidget {
  final ShoppingItem item;
  final Function(ShoppingItem) onEdit;

  const _ShoppingListItem({required this.item, required this.onEdit});

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
      subtitle: Text(
        '${item.quantity} ${item.unit} • ${item.priority.toUpperCase()}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.blueGrey),
            onPressed: () => onEdit(item),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar producto'),
                  content: Text('¿Seguro que deseas eliminar "${item.name}" de la lista?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<AppState>().deleteShoppingItem(item.id);
              }
            },
            tooltip: 'Eliminar',
          ),
        ],
      ),
      onTap: () => onEdit(item),
    );
  }
}

Map<String, List<ShoppingItem>> _groupItemsByAisle(List<ShoppingItem> items) {
  final grouped = <String, List<ShoppingItem>>{};
  for (final item in items) {
    final aisle = _resolveCategoryLabel(item.category, fallbackName: item.name);
    grouped.putIfAbsent(aisle, () => []).add(item);
  }

  final sortedEntries = grouped.entries.toList()
    ..sort((a, b) {
      final aIndex = _shoppingAisles.indexOf(a.key);
      final bIndex = _shoppingAisles.indexOf(b.key);
      final normalizedAIndex = aIndex == -1 ? _shoppingAisles.length : aIndex;
      final normalizedBIndex = bIndex == -1 ? _shoppingAisles.length : bIndex;
      if (normalizedAIndex != normalizedBIndex) {
        return normalizedAIndex.compareTo(normalizedBIndex);
      }
      return a.key.compareTo(b.key);
    });

  for (final entry in sortedEntries) {
    entry.value.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  return Map<String, List<ShoppingItem>>.fromEntries(sortedEntries);
}

String _resolveCategoryLabel(String? rawCategory, {String fallbackName = ''}) {
  final normalized = _normalizeText(rawCategory);
  if (normalized.isEmpty) {
    return _inferAisleFromName(fallbackName);
  }

  if (normalized.contains('fruta') ||
      normalized.contains('verdura') ||
      normalized.contains('vegetal')) {
    return 'Frutas y verduras';
  }
  if (normalized.contains('carne') ||
      normalized.contains('pollo') ||
      normalized.contains('pescado') ||
      normalized.contains('marisco')) {
    return 'Carnes y pescados';
  }
  if (normalized.contains('deli') ||
      normalized.contains('fiambre') ||
      normalized.contains('jamon') ||
      normalized.contains('embutido') ||
      normalized.contains('preparad')) {
    return 'Deli y preparados';
  }
  if (normalized.contains('lacteo') ||
      normalized.contains('leche') ||
      normalized.contains('queso') ||
      normalized.contains('huevo') ||
      normalized.contains('yogurt')) {
    return 'Lacteos y huevos';
  }
  if (normalized.contains('pan') ||
      normalized.contains('panaderia') ||
      normalized.contains('tortilla')) {
    return 'Panaderia y tortillas';
  }
  if (normalized.contains('congel')) {
    return 'Congelados';
  }
  if (normalized.contains('bebida') ||
      normalized.contains('jugo') ||
      normalized.contains('refresco')) {
    return 'Bebidas';
  }
  if (normalized.contains('enlat') ||
      normalized.contains('conserva') ||
      normalized.contains('despensa') ||
      normalized.contains('abarrote') ||
      normalized.contains('grano') ||
      normalized.contains('pasta') ||
      normalized.contains('arroz') ||
      normalized.contains('frijol')) {
    return 'Abarrotes y enlatados';
  }
  if (normalized.contains('desayuno') ||
      normalized.contains('cereal') ||
      normalized.contains('avena') ||
      normalized.contains('mermelada')) {
    return 'Desayuno y cereal';
  }
  if (normalized.contains('snack') ||
      normalized.contains('botana') ||
      normalized.contains('galleta') ||
      normalized.contains('dulce') ||
      normalized.contains('chocolate') ||
      normalized.contains('candy')) {
    return 'Botanas y dulces';
  }
  if (normalized.contains('hornear') ||
      normalized.contains('repost') ||
      normalized.contains('harina') ||
      normalized.contains('azucar') ||
      normalized.contains('especia') ||
      normalized.contains('condimento')) {
    return 'Reposteria y especias';
  }
  if (normalized.contains('internacional') ||
      normalized.contains('mexican') ||
      normalized.contains('asian') ||
      normalized.contains('italian')) {
    return 'Comida internacional';
  }
  if (normalized.contains('limpieza') ||
      normalized.contains('hogar') ||
      normalized.contains('detergente')) {
    return 'Limpieza y hogar';
  }
  if (normalized.contains('personal') ||
      normalized.contains('higiene') ||
      normalized.contains('shampoo') ||
      normalized.contains('salud') ||
      normalized.contains('beauty')) {
    return 'Cuidado personal y salud';
  }
  if (normalized.contains('bebe') ||
      normalized.contains('baby') ||
      normalized.contains('panal')) {
    return 'Bebes';
  }
  if (normalized.contains('mascota') ||
      normalized.contains('perro') ||
      normalized.contains('gato')) {
    return 'Mascotas';
  }
  final directMatch = _shoppingAisles.cast<String?>().firstWhere(
        (aisle) => _normalizeText(aisle) == normalized,
        orElse: () => null,
      );
  return directMatch ?? _inferAisleFromName(fallbackName);
}

String _inferAisleFromName(String name) {
  final normalizedName = _normalizeText(name);
  if (normalizedName.contains('manzana') ||
      normalizedName.contains('platano') ||
      normalizedName.contains('jitomate') ||
      normalizedName.contains('cebolla')) {
    return 'Frutas y verduras';
  }
  if (normalizedName.contains('leche') ||
      normalizedName.contains('queso') ||
      normalizedName.contains('huevo')) {
    return 'Lacteos y huevos';
  }
  if (normalizedName.contains('jamon') ||
      normalizedName.contains('salchicha') ||
      normalizedName.contains('chorizo')) {
    return 'Deli y preparados';
  }
  if (normalizedName.contains('pollo') ||
      normalizedName.contains('carne') ||
      normalizedName.contains('atun')) {
    return 'Carnes y pescados';
  }
  if (normalizedName.contains('pan') || normalizedName.contains('tortilla')) {
    return 'Panaderia y tortillas';
  }
  if (normalizedName.contains('agua') ||
      normalizedName.contains('jugo') ||
      normalizedName.contains('cafe')) {
    return 'Bebidas';
  }
  if (normalizedName.contains('arroz') ||
      normalizedName.contains('frijol') ||
      normalizedName.contains('pasta') ||
      normalizedName.contains('aceite') ||
      normalizedName.contains('atun en lata')) {
    return 'Abarrotes y enlatados';
  }
  if (normalizedName.contains('cereal') ||
      normalizedName.contains('avena') ||
      normalizedName.contains('granola')) {
    return 'Desayuno y cereal';
  }
  if (normalizedName.contains('papas') ||
      normalizedName.contains('galletas') ||
      normalizedName.contains('chocolate')) {
    return 'Botanas y dulces';
  }
  if (normalizedName.contains('harina') ||
      normalizedName.contains('azucar') ||
      normalizedName.contains('canela')) {
    return 'Reposteria y especias';
  }
  if (normalizedName.contains('detergente') ||
      normalizedName.contains('cloro') ||
      normalizedName.contains('papel higienico')) {
    return 'Limpieza y hogar';
  }
  if (normalizedName.contains('shampoo') ||
      normalizedName.contains('pasta dental') ||
      normalizedName.contains('jabon')) {
    return 'Cuidado personal y salud';
  }
  if (normalizedName.contains('panal') || normalizedName.contains('toallitas')) {
    return 'Bebes';
  }
  if (normalizedName.contains('croqueta') || normalizedName.contains('comida para perro')) {
    return 'Mascotas';
  }
  return 'Otros';
}

String _normalizeText(String? value) {
  return (value ?? '')
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}
