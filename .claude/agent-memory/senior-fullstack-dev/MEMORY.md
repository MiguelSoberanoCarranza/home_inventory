# Home Inventory App - Code Review Notes

## Project Overview
- **Framework**: Flutter (Dart SDK ^3.11.0)
- **Backend**: Supabase (PostgreSQL + Auth)
- **State Management**: Provider
- **UI Libraries**: Google Fonts, Lucide Icons, flutter_staggered_grid_view

## Architecture
- `lib/main.dart` - App entry point, navigation
- `lib/models/inventory_models.dart` - Data models (Product, InventoryLot, Location, ShoppingItem)
- `lib/services/supabase_service.dart` - Database operations
- `lib/services/app_state.dart` - Global state management with ChangeNotifier
- `lib/screens/` - UI screens (Dashboard, Inventory, Expiry, Shopping List, Add/Edit)

## Key Patterns Identified
- Uses ChangeNotifier/Provider pattern for state management
- Models use factory constructors from JSON (Supabase response parsing)
- Separation of concerns: Services layer separate from UI

## Common Issues Found
1. **Hardcoded credentials** in main.dart (Supabase URL and anon key exposed)
2. **No error handling** in SupabaseService methods
3. **No input validation** in forms
4. **Test file outdated** - references non-existent MyApp widget
5. **No authentication flow** despite using Supabase

## Supabase Tables (inferred)
- `products` - Product catalog
- `inventory_lots` - Inventory items with expiry tracking
- `shopping_list` - Shopping items
- `locations` - Storage locations