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

  // ==================== DIALOG TAMBAH TOKO BARU & SHOPEE INSTAN ====================
  Future<void> _showAddStoreDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController(); 
    final resiCtrl = TextEditingController(); 
    String selectedSales = 'SYAKUR';
    
    String selectedStatus = 'OTW';
    final provider = Provider.of<AdminProvider>(context, listen: false);

    final currentStocks = provider.stocks;
    
    final Map<String, TextEditingController> shopeeQtyControllers = {};
    for (var s in currentStocks) {
      shopeeQtyControllers[s.name] = TextEditingController();
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final bool isShopee = selectedSales == 'SHOPEE';

          return AlertDialog(
            title: Text(isShopee ? 'Input Shopee Kilat (Langsung Potong Stok)' : 'Add New Store'),
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
                        setStateDialog(() { 
                          selectedSales = value;
                          if (value == 'SHOPEE') {
                            selectedStatus = 'TERKIRIM';
                          } else {
                            selectedStatus = 'OTW';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  isShopee
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: resiCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Masukkan Nomor Resi', 
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_shipping, color: Colors.orange),
                              ),
                              autofocus: true,
                            ),
                            const SizedBox(height: 16),
                            const Text('Isi Barang & Qty Belanjaan Shopee:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                            const SizedBox(height: 8),
                            currentStocks.isEmpty
                                ? const Text('⚠️ Master data stok gudang kosong!', style: TextStyle(color: Colors.red, fontSize: 12))
                                : Column(
                                    children: currentStocks.map((stock) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 2, child: Text(stock.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: shopeeQtyControllers[stock.name],
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  hintText: '0',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(stock.unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
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
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedStatus,
                              decoration: const InputDecoration(labelText: 'Status Awal Orderan', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'OTW', child: Text('OTW')),
                                DropdownMenuItem(value: 'PROSES', child: Text('PROSES')),
                                DropdownMenuItem(value: 'TERKIRIM', child: Text('TERKIRIM')),
                                DropdownMenuItem(value: 'CANCEL', child: Text('CANCEL')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setStateDialog(() { selectedStatus = value; });
                                }
                              },
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

                    final List<Map<String, dynamic>> listMuatanShopee = [];
                    shopeeQtyControllers.forEach((itemName, ctrl) {
                      final text = ctrl.text.trim();
                      if (text.isNotEmpty) {
                        final int? parsedQty = int.tryParse(text);
                        if (parsedQty != null && parsedQty > 0) {
                          final targetStock = currentStocks.firstWhere((s) => s.name == itemName);
                          listMuatanShopee.add({
                            'name': itemName,
                            'qty': parsedQty,
                            'unit': targetStock.unit,
                          });
                        }
                      }
                    });

                    if (listMuatanShopee.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Gagal! Minimal isi kuantitas 1 barang Shopee.'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final DocumentReference newStoreRef = await FirebaseFirestore.instance.collection('stores').add({
                      'name': 'SHOPEE',                         
                      'address': 'Resi: $resi',                 
                      'sales': 'SHOPEE',
                      'status': 'TERKIRIM',        
                      'muatan': listMuatanShopee,                
                      'createdAt': FieldValue.serverTimestamp(),
                      'deliveredAt': FieldValue.serverTimestamp(),
                    });

                    final dynamic dummyStoreObject = provider.stores.firstWhere(
                      (s) => s.id == newStoreRef.id,
                      orElse: () => provider.stores.first,
                    );

                    await provider.completeDelivery(dummyStoreObject);

                  } else {
                    final name = nameCtrl.text.trim();
                    final address = addressCtrl.text.trim(); 
                    
                    if (name.isEmpty || address.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Name and Address cannot be empty!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance.collection('stores').add({
                      'name': name,
                      'address': address,
                      'sales': selectedSales,
                      'status': selectedStatus,
                      'muatan': [],
                      'createdAt': FieldValue.serverTimestamp(),
                    });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store/Resi Sukses Disimpan!'), backgroundColor: Colors.green));
    }
  }

  // ==================== DIALOG EDIT DATA & STATUS TOKO ====================
  Future<void> _showEditStoreDialog(BuildContext context, dynamic store) async {
    final String initialName = store.sales == 'SHOPEE' ? store.name : store.name;
    final String initialAddress = store.sales == 'SHOPEE' ? store.address.replaceAll('Resi: ', '') : store.address;
    
    final nameCtrl = TextEditingController(text: initialName);
    final addressCtrl = TextEditingController(text: initialAddress);
    String selectedSales = store.sales;
    
    String currentStatus = store.status.toUpperCase();
    if (!['OTW', 'PROSES', 'TERKIRIM', 'CANCEL'].contains(currentStatus)) {
      currentStatus = 'OTW';
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateEdit) {
          final bool isShopee = selectedSales == 'SHOPEE';

          return AlertDialog(
            title: const Text('Edit Store Info & Status'),
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
                  if (isShopee) ...[
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Nomor Resi Baru', border: OutlineInputBorder()),
                    ),
                  ] else ...[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Store Address', border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: const InputDecoration(labelText: 'Status Pengiriman', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'OTW', child: Text('OTW')),
                      DropdownMenuItem(value: 'PROSES', child: Text('PROSES')),
                      DropdownMenuItem(value: 'TERKIRIM', child: Text('TERKIRIM')),
                      DropdownMenuItem(value: 'CANCEL', child: Text('CANCEL')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateEdit(() { currentStatus = val; });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final finalName = nameCtrl.text.trim();
                  final finalAddress = addressCtrl.text.trim();
                  final provider = Provider.of<AdminProvider>(context, listen: false);

                  Map<String, dynamic> updateData = {
                    'sales': selectedSales,
                    'name': isShopee ? 'SHOPEE' : finalName,
                    'address': isShopee ? 'Resi: $finalAddress' : finalAddress,
                    'status': currentStatus,
                  };

                  if (currentStatus == 'TERKIRIM' && store.status.toUpperCase() != 'TERKIRIM') {
                    await provider.completeDelivery(store);
                  } else {
                    await FirebaseFirestore.instance.collection('stores').doc(store.id).update(updateData);
                  }
                  
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
  Future<void> _showEditMuatanDialog(BuildContext context, dynamic store) async {
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
                  await FirebaseFirestore.instance.collection('stores').doc(store.id).update({
                    'muatan': temporaryMuatan,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
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
  Future<void> _confirmDelivery(BuildContext context, AdminProvider provider, dynamic store) async {
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

  // ==================== 🛠️ ENGINE FIX: HAPUS SEMUA HASIL FILTER PENCARIAN (AMAN ANTI-SALAH PENCET) ====================
  Future<void> _deleteFilteredStores(BuildContext context, List<dynamic> targets) async {
    if (targets.isEmpty) return;

    // Konfirmasi Tahap 1
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Massal Hasil Cari?'),
          ],
        ),
        content: Text('Tindakan ini akan menghapus sejumlah ${targets.length} data yang saat ini tampil di layar secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus Massal'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Konfirmasi Tahap 2
    if (!context.mounted) return;
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ PERINGATAN KILAT'),
        content: Text('Ketik pencarian abang adalah: "$_adminSearchQuery". Seluruh data resi/toko di layar ini akan dibersihkan dari Firebase. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATALKAN')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YA, BERSIHKAN LIST INI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (secondConfirm == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Eksekusi pembersihan massal hanya pada target ID yang lolos filter pencarian layar
        final batch = FirebaseFirestore.instance.batch();
        for (var store in targets) {
          final docRef = FirebaseFirestore.instance.collection('stores').doc(store.id);
          batch.delete(docRef);
        }
        await batch.commit();

        if (context.mounted) {
          Navigator.pop(context); // Tutup Loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('💥 Sukses! Berhasil membersihkan hasil pencarian massal.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Tutup Loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus data massal: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);
    
    // Perhitungan filter pencarian global
    final filteredStores = prov.stores.where((s) {
      final query = _adminSearchQuery.trim().toLowerCase();
      return s.name.toLowerCase().contains(query) || s.address.toLowerCase().contains(query);
    }).toList();

    // Tombol Hapus Hasil Filter hanya aktif jika admin sedang mengetik sesuatu di kolom pencarian
    final bool isSearchActive = _adminSearchQuery.trim().isNotEmpty && filteredStores.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Stores Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() { _adminSearchQuery = value; });
              },
              decoration: InputDecoration(
                labelText: 'Cari Toko atau Nomor Resi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredStores.isEmpty
                  ? const Center(child: Text('Tidak ada data toko cocok'))
                  : ListView.builder(
                      itemCount: filteredStores.length,
                      itemBuilder: (context, index) {
                        final store = filteredStores[index];
                        final bool isDelivered = store.status.toUpperCase() == 'TERKIRIM';
                        
                        Color statusBadgeColor = Colors.amber.shade50;
                        Color statusTextColor = Colors.amber.shade700;
                        
                        if (store.status.toUpperCase() == 'TERKIRIM') {
                          statusBadgeColor = Colors.green.shade50;
                          statusTextColor = Colors.green.shade700;
                        } else if (store.status.toUpperCase() == 'CANCEL') {
                          statusBadgeColor = Colors.red.shade50;
                          statusTextColor = Colors.red.shade700;
                        }

                        String formattedDate = '-';
                        if (store.createdAt != null) {
                          DateTime dt;
                          if (store.createdAt is Timestamp) {
                            dt = (store.createdAt as Timestamp).toDate();
                          } else if (store.createdAt is DateTime) {
                            dt = store.createdAt as DateTime;
                          } else {
                            dt = DateTime.now();
                          }
                          formattedDate = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
                        }

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
                                  decoration: BoxDecoration(color: statusBadgeColor, borderRadius: BorderRadius.circular(4)),
                                  child: Text(store.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusTextColor)),
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
                                
                                Text('Tgl Dimuat: $formattedDate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                
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
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Edit Data Toko',
                                  onPressed: () => _showEditStoreDialog(context, store)
                                ),
                                IconButton(
                                  icon: const Icon(Icons.playlist_add_rounded, color: Colors.blueAccent),
                                  tooltip: 'Isi/Edit Muatan',
                                  onPressed: () => _showEditMuatanDialog(context, store)
                                ),
                                isDelivered
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : IconButton(icon: const Icon(Icons.check_box_outlined, color: Colors.green), tooltip: 'Set Terkirim', onPressed: () => _confirmDelivery(context, prov, store)),
                                
                                const VerticalDivider(width: 12, indent: 10, endIndent: 10),
                                
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  tooltip: 'Hapus Toko',
                                  onPressed: () async {
                                    final confirmDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hapus Toko Permanen?'),
                                        content: Text('Yakin ingin menghapus "${store.name}" dari rute database?'),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🛠️ TOMBOL SAKTI HAPUS HASIL CARI: Hanya menyapu bersih list filteredStores yang muncul di layar
            FloatingActionButton.extended(
              heroTag: 'btnDeleteFiltered',
              backgroundColor: isSearchActive ? Colors.red.shade900 : Colors.grey.shade400,
              onPressed: isSearchActive ? () => _deleteFilteredStores(context, filteredStores) : null,
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              label: Text(
                isSearchActive ? 'Hapus Hasil Cari (${filteredStores.length})' : 'Hapus Hasil Cari', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
            FloatingActionButton.extended(
              heroTag: 'btnAddStore',
              onPressed: () => _showAddStoreDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Store'),
            ),
          ],
        ),
      ),
    );
  }
}