import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class StockTile extends StatelessWidget {
  final Stock stock;

  const StockTile({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    // Memastikan jika nama produk mengandung '220', satuannya dipaksa jadi 'Karton'
    final String displayUnit = stock.name.toLowerCase().contains('220') 
        ? 'Karton' 
        : stock.unit;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stock.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              // Menampilkan quantity dengan satuan yang sudah difilter
              Text('${stock.quantity} $displayUnit', style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final controller = TextEditingController(text: stock.quantity.toString());
              final result = await showDialog<int?>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Edit Quantity'),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        final v = int.tryParse(controller.text) ?? stock.quantity;
                        Navigator.pop(ctx, v);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );

              if (result != null) {
                provider.updateStockQuantity(stock.id, result);
              }
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}