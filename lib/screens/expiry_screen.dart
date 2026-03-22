import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/app_state.dart';
import '../models/inventory_models.dart';
import 'add_edit_lot_screen.dart';

class ExpiryScreen extends StatelessWidget {
  const ExpiryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Caducidades',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vencidos'),
              Tab(text: 'Semana'),
              Tab(text: 'Mes'),
            ],
          ),
        ),
        body: Consumer<AppState>(
          builder: (context, state, child) {
            final now = DateTime.now();
            final oneWeekFromNow = now.add(const Duration(days: 7));
            final endOfMonth = DateTime(now.year, now.month + 1, 0);
            final lotsWithStock =
                state.inventory.where((lot) => lot.quantity > 0).toList();

            final expired = lotsWithStock
                .where((lot) => lot.expiresOn != null && lot.expiresOn!.isBefore(now))
                .toList();
            final thisWeek = lotsWithStock
                .where((lot) =>
                    lot.expiresOn != null &&
                    lot.expiresOn!.isAfter(now) &&
                    lot.expiresOn!.isBefore(oneWeekFromNow))
                .toList();
            final thisMonth = lotsWithStock
                .where((lot) =>
                    lot.expiresOn != null &&
                    lot.expiresOn!.isAfter(now) &&
                    lot.expiresOn!.isBefore(endOfMonth))
                .toList();

            return TabBarView(
              children: [
                _ExpiryList(lots: expired, emptyMessage: '¡Nada vencido! 🎉'),
                _ExpiryList(lots: thisWeek, emptyMessage: '¡Sin vencimientos esta semana!'),
                _ExpiryList(lots: thisMonth, emptyMessage: '¡Sin vencimientos este mes!'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpiryList extends StatelessWidget {
  final List<InventoryLot> lots;
  final String emptyMessage;

  const _ExpiryList({required this.lots, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.checkCircle2, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lot = lots[index];
        final isExpired = lot.expiresOn!.isBefore(DateTime.now());

        return Card(
           elevation: 0,
           color: Colors.white,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
           child: ListTile(
             onTap: () => Navigator.push(
               context,
               MaterialPageRoute(builder: (_) => AddEditLotScreen(lot: lot)),
             ),
             leading: Container(
               width: 32,
               height: 32,
               decoration: BoxDecoration(
                 color: isExpired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(
                 isExpired ? LucideIcons.alertCircle : LucideIcons.clock,
                 size: 20, 
                 color: isExpired ? Colors.red : Colors.orange,
               ),
             ),
             title: Text(lot.product?.name ?? 'Producto desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text('Caduca: ${DateFormat('dd/MM/yy').format(lot.expiresOn!)} (${lot.locationName})'),
             trailing: Text('${lot.quantity} ${lot.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           ),
        );
      },
    );
  }
}
