import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:freshbox_app/core/utils/currency_formatter.dart';
import '../../domain/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPromo = product.hasPromo;
    final bool hasImage = product.images.card != null && product.images.card!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () => context.push('/products/${product.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem do produto
            Expanded(
              child: _buildImage(hasImage),
            ),
            // Info do produto
            _buildInfo(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool hasImage) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: _buildImageChild(),
        ),
        if (product.hasPromo)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PROMO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (product.isFeatured && !product.hasPromo)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DESTAQUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageChild() {
    final bool hasImage = product.images.card != null && product.images.card!.isNotEmpty;
    if (hasImage) {
      return CachedNetworkImage(
        imageUrl: product.images.card!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      );
    } else {
      return Container(
        color: Colors.green[50],
        child: const Icon(
          Icons.local_grocery_store,
          size: 48,
          color: Colors.green,
        ),
      );
    }
  }

  Widget _buildInfo(ThemeData theme) {
    final hasPromo = product.hasPromo;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.hasPromo) ...[
                      Text(
                        'De ${product.price.formatted}/${product.unitLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Por ${product.effectivePrice.formatted}/${product.unitLabel}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '${product.effectivePrice.formatted}/${product.unitLabel}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}