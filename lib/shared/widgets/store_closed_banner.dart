import 'package:flutter/material.dart';

class StoreClosedBanner extends StatelessWidget {
  const StoreClosedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.orange[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Loja fechada no momento. Pedidos serão processados no próximo horário de funcionamento.',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
