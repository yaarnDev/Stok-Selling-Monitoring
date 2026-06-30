import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoresManagerPage extends StatefulWidget {
  const StoresManagerPage({super.key});

  @override
  State<StoresManagerPage> createState() => _StoresManagerPageState();
}

class _StoresManagerPageState extends State<StoresManagerPage> {
  String _adminSearchQuery = ""; // Menyimpan filter input pencarian admin

  // ==================== DIALOG TAMBAH TOKO BARU ====================
  Future<void> _showAddStoreDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController(); 
    final resiCtrl = TextEditingController(); 
    String selectedSales = 'SYAKUR';
    final provider = Provider.of<AdminProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final bool isShopee = selectedSales == 'SHOPEE';

          return AlertDialog(
            title: Text(isShopee ? 'Input Resi Shopee' : 'Add New Store'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSales,
                    decoration: const InputDecoration(labelText: 'Sales', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'SYAKUR', child: Text('SYAKUR')),
                      DropdownMenuItem(value: 'FAISOL', child: Text('FAISOL')),
                      DropdownMenuItem(value: 'MULYADI', child: Text('MULYADI')),
                      DropdownMenuItem(value: 'LUAY', child: Text('LUAY')),
                      DropdownMenuItem(value: 'INSTANSI', child: Text('INSTANSI')),
                      DropdownMenuItem(value: 'SHOPEE', child: Text('SHOPEE')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() { selectedSales = value; });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  isShopee
                      ? TextField(
                          controller: resiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Masukkan Nomor Resi', 
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_shipping, color: Colors.orange),
                          ),
                          autofocus: true,
                        )
                      : Column(
                          children: [
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder()),
                              autofocus: true,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: addressCtrl,
                              decoration: const InputDecoration(labelText: 'Store Address', border: OutlineInputBorder()),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedSales == 'SHOPEE') {
                    final resi = resiCtrl.text.trim();
                    if (resi.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Nomor Resi tidak boleh kosong!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance.collection('stores').add({
                      'name': 'Resi: $resi',       
                      'address': 'Shopee Order',   
                      'sales': 'SHOPEE',
                      'status': 'TERKIRIM',        
                      'muatan': [],                
                      'createdAt': FieldValue.serverTimestamp(),
                      'deliveredAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    final name = nameCtrl.text.trim();
                    final address = addressCtrl.text.trim(); 
                    
                    if (name.isEmpty || address.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Name and Address cannot be empty!'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    await provider.addStore(name: name, address: address, sales: selectedSales);
                  }

                  Navigator.pop(ctx, true);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store added successfully')));
    }
  }

  // ==================== BARU: DIALOG EDIT DATA TOKO ====================
  Future<void> _showEditStoreDialog(BuildContext context, Store store) async {
    // Jika data shopee, hilangkan awalan teks "Resi: " saat dimasukkan ke textfield biar rapi
    final String initialName = store.sales == 'SHOPEE' ? store.name.replaceAll('Resi: ', '') : store.name;
    
    final nameCtrl = TextEditingController(text: initialName);
    final addressCtrl = TextEditingController(text: store.address);
    String selectedSales = store.sales;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateEdit) {
          final bool isShopee = selectedSales == 'SHOPEE';

          return AlertDialog(
            title: const Text('Edit Store Info'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSales,
                    decoration: const InputDecoration(labelText: 'Sales / Channel', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'SYAKUR', child: Text('SYAKUR')),
                      DropdownMenuItem(value: 'FAISOL', child: Text('FAISOL')),
                      DropdownMenuItem(value: 'MULYADI', child: Text('MULYADI')),
                      DropdownMenuItem(value: 'LUAY', child: Text('LUAY')),
                      DropdownMenuItem(value: 'INSTANSI', child: Text('INSTANSI')),
                      DropdownMenuItem(value: 'SHOPEE', child: Text('SHOPEE')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateEdit(() { selectedSales = value; });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: isShopee ? 'Nomor Resi Baru' : 'Store Name', 
                      border: const OutlineInputBorder()
                    ),
                  ),
                  if (!isShopee) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Store Address', border: OutlineInputBorder()),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final finalName = nameCtrl.text.trim();
                  final finalAddress = addressCtrl.text.trim();

                  if (finalName.isEmpty) return;

                  Map<String, dynamic> updateData = {
                    'sales': selectedSales,
                    'name': isShopee ? 'Resi: $finalName' : finalName,
                    'address': isShopee ? 'Shopee Order' : finalAddress,
                  };

                  // Jika dipindah ke Shopee, otomatis paksa status TERKIRIM
                  if (selectedSales == 'SHOPEE') {
                    updateData['status'] = 'TERKIRIM';
                    updateData['deliveredAt'] = FieldValue.serverTimestamp();
                  }

                  await FirebaseFirestore.instance.collection('stores').doc(store.id).update(updateData);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated successfully')));
                  }
                },
                child: const Text('Update'),
              )
            ],
          );
        },
      ),
    );
  }

  // ==================== DIALOG EDIT ISI MUATAN BARANG ====================
  Future<void> _showEditMuatanDialog(BuildContext context, Store store) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final listBarangTersedia = provider.stocks.map((s) => s.name).toList();
    
    if (listBarangTersedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi master data stok gudang terlebih dahulu!'), backgroundColor: Colors.red),
      );
      return;
    }

    List<Map<String, dynamic>> temporaryMuatan = List<Map<String, dynamic>>.from(
      store.muatan.map((m) => {'name': m['name'], 'qty': m['qty'], 'unit': m['unit']})
    );

    String selectedBarang = listBarangTersedia.first;
    final qtyCtrl = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateMuatan) {
          return AlertDialog(
            title: Text('Edit Muatan: ${store.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedBarang,
                          decoration: const InputDecoration(labelText: 'Barang', isDense: true),
                          items: listBarangTersedia.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) { if (val != null) selectedBarang = val; },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () {
                          final int inputQty = int.tryParse(qtyCtrl.text) ?? 0;
                          if (inputQty <= 0) return;
                          final stockMaster = provider.stocks.firstWhere((s) => s.name == selectedBarang);

                          setStateMuatan(() {
                            final existingIndex = temporaryMuatan.indexWhere((m) => m['name'] == selectedBarang);
                            if (existingIndex >= 0) {
                              temporaryMuatan[existingIndex]['qty'] += inputQty;
                            } else {
                              temporaryMuatan.add({'name': selectedBarang, 'qty': inputQty, 'unit': stockMaster.unit});
                            }
                            qtyCtrl.text = '1';
                          });
                        },
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  const Align(alignment: Alignment.centerLeft, child: Text('Daftar Muatan Saat Ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(height: 8),
                  Flexible(
                    child: temporaryMuatan.isEmpty
                        ? const Padding(padding: EdgeInsets.all(8.0), child: Text('Belum ada muatan rute.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: temporaryMuatan.length,
                            itemBuilder: (context, idx) {
                              final item = temporaryMuatan[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('${item['name']}'),
                                subtitle: Text('${item['qty']} ${item['unit']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () { setStateMuatan(() { temporaryMuatan.removeAt(idx); }); },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('stores').doc(store.id).update({'muatan': temporaryMuatan});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Simpan Muatan'),
              )
            ],
          );
        },
      ),
    );
  }

  // ==================== KONFIRMASI PENYELESAIAN RUTE TOKO ====================
  Future<void> _confirmDelivery(BuildContext context, AdminProvider provider, Store store) async {
    if (store.muatan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal! Muatan barang masih kosong.'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Pengiriman?'),
        content: Text('Toko "${store.name}" akan diset TERKIRIM & memotong sisa stok gudang pusat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Terkirim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        await provider.completeDelivery(store);
        if (context.mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sukses! Pengiriman "${store.name}" selesai.')));
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStoreDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Store'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() { _adminSearchQuery = value.trim().toLowerCase(); });
              },
              decoration: InputDecoration(
                labelText: 'Cari Toko...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, prov, _) {
                  var stores = prov.stores;

                  if (_adminSearchQuery.isNotEmpty) {
                    stores = stores.where((s) => s.name.toLowerCase().contains(_adminSearchQuery)).toList();
                  }

                  if (stores.isEmpty) {
                    return const Center(child: Text('Tidak ada data toko cocok'));
                  }

                  return ListView.builder(
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      final bool isDelivered = store.status.toUpperCase() == 'TERKIRIM';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(Icons.store, color: isDelivered ? Colors.green : Colors.blue),
                          title: Row(
                            children: [
                              Expanded(child: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: isDelivered ? Colors.green.shade50 : Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(store.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDelivered ? Colors.green.shade700 : Colors.amber.shade700)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              if (store.address.isNotEmpty)
                                Text(store.address, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text('Sales: ${store.sales}'),
                              if (store.muatan.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Muatan: ' + store.muatan.map((m) => '${m['qty']} ${m['unit']} ${m['name']}').join(', '),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                const Text('Muatan: Kosong ⚠️', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
                              ]
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. TOMBOL EDIT INFO TOKO (Icon Pensil Biru)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue), 
                                tooltip: 'Edit Data Toko', 
                                onPressed: () => _showEditStoreDialog(context, store)
                              ),
                              // 2. TOMBOL ISI MUATAN (Icon Rilis)
                              IconButton(
                                icon: const Icon(Icons.playlist_add_rounded, color: Colors.blueAccent), 
                                tooltip: 'Isi/Edit Muatan', 
                                onPressed: () => _showEditMuatanDialog(context, store)
                              ),
                              // 3. TOMBOL STATUS SET TERKIRIM (Icon Centang)
                              isDelivered
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : IconButton(icon: const Icon(Icons.check_box_outlined, color: Colors.green), tooltip: 'Set Terkirim', onPressed: () => _confirmDelivery(context, prov, store)),
                              
                              const VerticalDivider(width: 12, indent: 10, endIndent: 10),
                              
                              // 4. BARU: TOMBOL HAPUS TOKO PERMANEN (Icon Sampah Merah)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: 'Hapus Toko',
                                onPressed: () async {
                                  final confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus Toko Permanen?'),
                                      content: Text('Yakin ingin menghapus "${store.name}" dari rute database?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Hapus Toko', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    await prov.deleteStore(store.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toko berhasil dihapus.')));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}