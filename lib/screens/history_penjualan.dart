import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../admin/providers/admin_provider.dart';

class AllSalesHistoryPage extends StatefulWidget {
  const AllSalesHistoryPage({super.key});

  @override
  State<AllSalesHistoryPage> createState() => _AllSalesHistoryPageState();
}

class _AllSalesHistoryPageState extends State<AllSalesHistoryPage> {
  String _historySearchQuery = "";
  String _selectedSalesFilter = "SEMUA";

  // Set untuk menyimpan key unik item yang DICENTANG (DITANDAI UNTUK DIHAPUS)
  final Set<String> _selectedDeleteItemKeys = {};

  final List<String> _salesList = [
    'SEMUA',
    'SYAKUR',
    'FAISOL',
    'MULYADI',
    'LUAY',
    'INSTANSI',
    'SHOPEE'
  ];

  // Helper pembuat key unik per transaksi
  String _getItemUniqueKey(Map<String, dynamic> item) {
    return "${item['source']}_${item['docId']}";
  }

  // ==================== ENGINE CETAK REKAP DALAM BENTUK PDF ====================
  Future<void> _generateAndDownloadPdf(List<Map<String, dynamic>> dataList) async {
    final pdf = pw.Document();

    // Mengelompokkan data berdasarkan Sales jika filter "SEMUA"
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in dataList) {
      String salesName = item['sales'].toString().toUpperCase();
      groupedData.putIfAbsent(salesName, () => []).add(item);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal800,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN REKAP HISTORY PENJUALAN (${_selectedSalesFilter})',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Tanggal Cetak: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())} WIB',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                    ),
                  ],
                ),
                pw.Text(
                  'Hal ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '-- Dokumen Otomatis Sistem Selling & Stok Monitoring --',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          groupedData.forEach((salesName, items) {
            // Header Nama Sales
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: PdfColors.teal200, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SALES: $salesName',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                    pw.Text(
                      'Total: ${items.length} Toko',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                  ],
                ),
              ),
            );

            // Tabel Data Toko untuk Sales Ini
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5), // Nama Toko
                  1: pw.FlexColumnWidth(4.5), // Detail Muatan
                  2: pw.FlexColumnWidth(1.8), // Tanggal
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('NAMA TOKO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('DETAIL MUATAN BARANG', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('TANGGAL TERKIRIM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                      ),
                    ],
                  ),
                  ...items.map((item) {
                    final List<dynamic> muatan = item['muatan'] ?? [];
                    String detail = muatan.map((m) => "${m['qty']} ${m['unit'] ?? 'Krt'} ${m['name']}").join(", ");
                    DateTime ts = item['timestamp'] as DateTime;
                    String tglStr = DateFormat('dd/MM/yy HH:mm').format(ts);

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(item['name'] ?? '', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(detail, style: const pw.TextStyle(fontSize: 8.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(tglStr, style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 10));
          });

          return widgets;
        },
      ),
    );

    final String namaFile = 'REKAP_HISTORY_${_selectedSalesFilter}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    // Trigger preview & download/print PDF universal
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: namaFile,
    );
  }

  // ==================== DIALOG HAPUS HISTORY (SUPER CEPAT DENGAN FIRESTORE BATCH) ====================
  void _showDeleteHistoryDialog(BuildContext context, List<Map<String, dynamic>> currentFilteredList) {
    if (currentFilteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data riwayat untuk dihapus!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final passwordController = TextEditingController();
    int deleteCount = currentFilteredList.where((item) => _selectedDeleteItemKeys.contains(_getItemUniqueKey(item))).length;

    if (deleteCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih/centang minimal 1 toko yang mau dihapus!'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Filter: $_selectedSalesFilter',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              Text('• Jumlah Toko Dicentang: $deleteCount Toko', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Toko yang dicentang akan dihapus permanen dari riwayat!',
                style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Admin',
                  hintText: 'Masukkan password admin...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                if (passwordController.text.trim() == "admin123") {
                  Navigator.pop(ctx);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // GUANAKAN BATCH UNTUK EKSEKUSI MASSAL DALAM 1 REQUEST
                    final batch = FirebaseFirestore.instance.batch();
                    int deletedItemsCount = 0;

                    for (var item in currentFilteredList) {
                      String itemKey = _getItemUniqueKey(item);

                      if (_selectedDeleteItemKeys.contains(itemKey)) {
                        String docId = item['docId'] ?? '';
                        String source = item['source'] ?? '';

                        if (docId.isNotEmpty) {
                          if (source == 'history_penjualan') {
                            final ref = FirebaseFirestore.instance.collection('history_penjualan').doc(docId);
                            batch.delete(ref);
                          } else if (source == 'stores') {
                            final ref = FirebaseFirestore.instance.collection('stores').doc(docId);
                            batch.update(ref, {
                              'status': 'PENDING',
                              'muatan': [],
                            });
                          }
                          deletedItemsCount++;
                        }
                      }
                    }

                    // KIRIM SEMUA PERINTAH HAPUS SEKALIGUS
                    if (deletedItemsCount > 0) {
                      await batch.commit();
                    }

                    setState(() {
                      _selectedDeleteItemKeys.clear();
                    });

                    if (context.mounted) {
                      Navigator.pop(context); // Tutup loading dialog
                      Provider.of<AdminProvider>(context, listen: false).startListening();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⚡ Berhasil menghapus $deletedItemsCount riwayat sekaligus!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menghapus history: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Akses Ditolak! Password Admin Salah.'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Proses Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==================== DIALOG CETAK PDF WITH ADMIN AUTH ====================
  void _showPrintPdfDialog(BuildContext context, List<Map<String, dynamic>> currentFilteredList) {
    if (currentFilteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data riwayat untuk dicetak!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('Cetak Rekap PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Sales: $_selectedSalesFilter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
              const SizedBox(height: 4),
              Text('Total Data: ${currentFilteredList.length} Toko'),
              const SizedBox(height: 12),
              const Text('Format PDF mendukung auto-halaman untuk data sebanyak apapun.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Admin',
                  hintText: 'Masukkan password admin...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                if (passwordController.text.trim() == "admin123") {
                  Navigator.pop(ctx);
                  _generateAndDownloadPdf(currentFilteredList);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Akses Ditolak! Password Admin Salah.'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Cetak & Unduh PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==================== DIALOG TRANSFER / PINDAH SALES ====================
  void _showTransferSalesDialog(BuildContext context, Map<String, dynamic> item) {
    final passwordController = TextEditingController();
    String currentSales = item['sales'].toString().toUpperCase();
    String targetSales = currentSales;

    final List<String> availableSalesList = [
      'SYAKUR',
      'FAISOL',
      'MULYADI',
      'LUAY',
      'INSTANSI',
      'SHOPEE'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Pindah / Rolling Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toko: ${item['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Sales Saat Ini: $currentSales', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: availableSalesList.contains(targetSales) ? targetSales : availableSalesList.first,
                      decoration: InputDecoration(
                        labelText: 'Pindah ke Sales',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      items: availableSalesList.map((sales) {
                        return DropdownMenuItem(
                          value: sales,
                          child: Text(sales, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            targetSales = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password Admin',
                        hintText: 'Masukkan password admin...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (passwordController.text.trim() == "admin123") {
                      if (targetSales == currentSales) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Pilih nama sales yang berbeda!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      final String docId = item['docId'] ?? '';
                      final String source = item['source'] ?? '';

                      if (docId.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Gagal! ID Dokumen tidak ditemukan.'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await FirebaseFirestore.instance.collection(source).doc(docId).update({
                          'sales': targetSales,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Penjualan "${item['name']}" berhasil dipindah ke $targetSales!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal memindahkan sales: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Akses Ditolak! Password Admin Salah.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final sekarang = DateTime.now();
    
    List<Map<String, dynamic>> gabunganHistory = [];

    for (var record in provider.history) {
      if (record.timestamp.month == sekarang.month && record.timestamp.year == sekarang.year) {
        gabunganHistory.add({
          'docId': record.id,
          'source': 'history_penjualan',
          'name': record.storeName,
          'sales': record.sales,
          'muatan': record.muatan,
          'timestamp': record.timestamp,
          'address': 'Riwayat Terbuku (Selesai)',
        });
      }
    }

    for (var store in provider.stores) {
      if (store.status.toUpperCase() == 'TERKIRIM') {
        DateTime waktuToko = store.createdAt ?? sekarang;
        if (waktuToko.month == sekarang.month && waktuToko.year == sekarang.year) {
          gabunganHistory.add({
            'docId': store.id,
            'source': 'stores',
            'name': store.name,
            'sales': store.sales,
            'muatan': store.muatan,
            'timestamp': waktuToko,
            'address': store.address,
          });
        }
      }
    }

    final filteredList = gabunganHistory.where((item) {
      final String storeName = item['name'].toString().toLowerCase();
      final String address = item['address'].toString().toLowerCase();
      final String salesName = item['sales'].toString().toUpperCase();

      final matchesSearch = storeName.contains(_historySearchQuery) || address.contains(_historySearchQuery);
      final matchesSales = _selectedSalesFilter == 'SEMUA' || salesName == _selectedSalesFilter;

      return matchesSearch && matchesSales;
    }).toList();

    filteredList.sort((a, b) {
      final DateTime timeA = a['timestamp'] as DateTime;
      final DateTime timeB = b['timestamp'] as DateTime;
      return timeB.compareTo(timeA);
    });

    bool isAllCurrentSelected = filteredList.isNotEmpty &&
        filteredList.every((item) => _selectedDeleteItemKeys.contains(_getItemUniqueKey(item)));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'History Semua Penjualan',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.3),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Pencarian & Dropdown
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                      ],
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      onChanged: (value) {
                        setState(() {
                          _historySearchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama toko atau resi...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSalesFilter,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: _salesList.map((sales) {
                        return DropdownMenuItem(
                          value: sales,
                          child: Text(sales, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSalesFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BARIS CONTROL FITUR: RESPONSIF MOBILE (ANTI OVERFLOW)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Baris 1: Checkbox Centang Semua
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isAllCurrentSelected) {
                          for (var item in filteredList) {
                            _selectedDeleteItemKeys.remove(_getItemUniqueKey(item));
                          }
                        } else {
                          for (var item in filteredList) {
                            _selectedDeleteItemKeys.add(_getItemUniqueKey(item));
                          }
                        }
                      });
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: isAllCurrentSelected,
                            activeColor: Colors.red,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  for (var item in filteredList) {
                                    _selectedDeleteItemKeys.add(_getItemUniqueKey(item));
                                  }
                                } else {
                                  for (var item in filteredList) {
                                    _selectedDeleteItemKeys.remove(_getItemUniqueKey(item));
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Centang Semua (Hapus)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Baris 2: Tombol Cetak PDF & Hapus (Bagi 2 Rata Kanan Kiri)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => _showPrintPdfDialog(context, filteredList),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                          label: const Text('Cetak PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => _showDeleteHistoryDialog(context, filteredList),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
                          label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada riwayat penjualan pada periode berjalan.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final String itemKey = _getItemUniqueKey(item);
                        final bool isSelectedForDelete = _selectedDeleteItemKeys.contains(itemKey);

                        final String storeName = item['name'] ?? '';
                        final String address = item['address'] ?? '';
                        final String sales = item['sales'] ?? '-';
                        final List<dynamic> muatan = item['muatan'] ?? [];
                        final DateTime timestamp = item['timestamp'] as DateTime;

                        String formattedFullDate = DateFormat('EEEE, dd MMM yyyy HH:mm', 'id').format(timestamp);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelectedForDelete ? Colors.red.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelectedForDelete ? Colors.red.shade400 : const Color(0xFFE2E8F0),
                              width: isSelectedForDelete ? 2.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Checkbox(
                                      value: isSelectedForDelete,
                                      activeColor: Colors.red,
                                      onChanged: (bool? checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedDeleteItemKeys.add(itemKey);
                                          } else {
                                            _selectedDeleteItemKeys.remove(itemKey);
                                          }
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        storeName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: isSelectedForDelete ? Colors.red.shade900 : const Color(0xFF0F172A),
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _showTransferSalesDialog(context, item),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: const Text(
                                            'TERKIRIM',
                                            style: TextStyle(color: Color(0xFF047857), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (address.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    address,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),
                                const Text('Detail Muatan Barang:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                ...muatan.map((m) {
                                  final int qty = (m['qty'] is int) ? m['qty'] as int : int.tryParse('${m['qty']}') ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$qty ${m['unit'] ?? 'Krt'}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 12),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${m['name'] ?? '-'}',
                                            style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('Sales: $sales', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                                    ),
                                    Text(
                                      formattedFullDate,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ],
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
    );
  }
}