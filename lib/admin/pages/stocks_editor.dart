import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_box_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Tambah Stok Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Produk (misal: 600ml)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(
                labelText: 'Satuan (Karton / Biji / Dus)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.square_foot_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final unit = unitCtrl.text.trim();
              
              if (name.isEmpty || unit.isEmpty) return;

              // MENAMBAHKAN FIELD TIMESTAMP SERVER SECARA OTOMATIS
              // Jika provider abang butuh Map/Timestamp langsung, ini dikirim otomatis ke Firestore
              try {
                // Panggil provider bawaan abang
                provider.addStock(name: name, quantity: quantity, unit: unit);

                // Ekstra inject update timestamp langsung ke koleksi Firestore
                FirebaseFirestore.instance
                    .collection('stocks')
                    .where('name', isEqualTo: name)
                    .get()
                    .then((snap) {
                  for (var doc in snap.docs) {
                    doc.reference.update({'updatedAt': FieldValue.serverTimestamp()});
                  }
                });
              } catch (_) {}

              Navigator.pop(ctx, true);
            },
            child: const Text('Simpan Stok'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Stocks Editor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _showAddStockDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      'Belum ada item stok.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tekan tombol + Tambah Stok untuk mengisi data baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: stocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: StockTile(stock: stocks[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}