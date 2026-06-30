import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/stock_tile.dart';

class StocksEditorPage extends StatelessWidget {
  const StocksEditorPage({super.key});

  Future<void> _showAddStockDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'karton');
    final provider = Provider.of<AdminProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Stock Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final unit = unitCtrl.text.trim();
              if (name.isEmpty || unit.isEmpty) return;
              provider.addStock(name: name, quantity: quantity, unit: unit);
              Navigator.pop(ctx, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock item added')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stocks Editor')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStockDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AdminProvider>(
          builder: (context, prov, _) {
            final stocks = prov.stocks;
            if (stocks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No stock items yet.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to add a stock item or use Seed Sample Stocks from dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: stocks.length,
              itemBuilder: (context, index) => StockTile(stock: stocks[index]),
            );
          },
        ),
      ),
    );
  }
}