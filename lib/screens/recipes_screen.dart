import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/inventory_models.dart';
import '../services/app_state.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recetas Sugeridas',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading && state.recipes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.recipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bookOpen, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No hay recetas guardadas todavía.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agrega recetas en Supabase para verlas aquí.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final inventoryKeywords = _getInventoryKeywords(state);

          final recipesWithScore = state.recipes.map((recipe) {
            final availableMatches = recipe.ingredients.where(
              (ingredient) => _hasIngredient(ingredient, inventoryKeywords),
            ).toList();

            final matchScore =
                recipe.ingredients.isEmpty ? 0.0 : availableMatches.length / recipe.ingredients.length;

            return _RecipeScore(
              recipe: recipe,
              score: matchScore,
              availableIngredients: availableMatches,
            );
          }).toList();

          recipesWithScore.sort((a, b) => b.score.compareTo(a.score));

          return RefreshIndicator(
            onRefresh: () => state.fetchRecipes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipesWithScore.length,
              itemBuilder: (context, index) {
                final item = recipesWithScore[index];
                return _RecipeCard(recipeScore: item);
              },
            ),
          );
        },
      ),
    );
  }

  Set<String> _getInventoryKeywords(AppState state) {
    final keywords = <String>{};
    for (final lot in state.inventory) {
      if (lot.quantity > 0) {
        final nameWords = (lot.product?.name ?? '').toLowerCase().split(' ');
        keywords.addAll(nameWords);
      }
    }
    return keywords;
  }

  bool _hasIngredient(String requiredIngredient, Set<String> inventoryKeywords) {
    final searchParam = _normalize(requiredIngredient);
    return inventoryKeywords.any((word) => _normalize(word).contains(searchParam));
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
  }
}

class _RecipeScore {
  final Recipe recipe;
  final double score;
  final List<String> availableIngredients;

  _RecipeScore({
    required this.recipe,
    required this.score,
    required this.availableIngredients,
  });
}

class _RecipeCard extends StatelessWidget {
  final _RecipeScore recipeScore;

  const _RecipeCard({required this.recipeScore});

  @override
  Widget build(BuildContext context) {
    final matchPercentage = (recipeScore.score * 100).round();
    Color badgeColor = Colors.green;
    if (matchPercentage < 50) badgeColor = Colors.red;
    else if (matchPercentage < 80) badgeColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showRecipeDetails(context),
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
                      recipeScore.recipe.title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$matchPercentage% Match',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipeScore.recipe.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.chefHat, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Ingredientes necesarios: ${recipeScore.recipe.ingredients.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                recipeScore.recipe.title,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                recipeScore.recipe.description,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Text(
                    'Ingredientes de tu inventario',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recipeScore.recipe.ingredients.map((ingredient) {
                    final normalizedIngredient = ingredient.toLowerCase();
                    final isAvailable = recipeScore.availableIngredients.any((avail) => normalizedIngredient.contains(avail) || avail.contains(normalizedIngredient));
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isAvailable ? Colors.green : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            ingredient.toUpperCase(),
                            style: TextStyle(
                              fontSize: 15,
                              color: isAvailable ? Colors.black87 : Colors.grey.shade600,
                              decoration: isAvailable ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          if (!isAvailable) ...[
                            const Spacer(),
                            Text(
                              'Falta',
                              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                            ),
                          ]
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  Text(
                    'Instrucciones',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      recipeScore.recipe.instructions,
                      style: const TextStyle(height: 1.6, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
