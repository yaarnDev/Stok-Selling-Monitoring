import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// Paket universal HTML bawaan Flutter untuk handle download file di browser PC
import 'dart:html' as html; 
import '../providers/admin_provider.dart';
import 'stocks_editor.dart';
import 'stores_manager.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _hasStartedListening = false;
  
  // Kunci utama untuk menangkap area widget rekap agar bisa difoto jadi gambar
  final GlobalKey _boundaryKey = GlobalKey();

  // Menandai jenis rekap yang sedang aktif (HARIAN / BULANAN)
  String _jenisReportAktif = 'HARIAN';

  final List<String> listSales = ['SYAKUR', 'FAISOL', 'MULYADI', 'LUAY', 'INSTANSI', 'SHOPEE'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedListening) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Provider.of<AdminProvider>(context, listen: false).startListening();
        _hasStartedListening = true;
      }
    }
  }

  Future<void> _seedSampleStocks(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('stocks').limit(1).get();
    if (snap.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample stocks already exist')));
      return;
    }
    final samples = [
      {'name': 'GLS (Gelas)', 'quantity': 1240, 'unit': 'Dus'},
      {'name': 'BT (330ml)', 'quantity': 850, 'unit': 'Dus'},
      {'name': 'BB (600ml)', 'quantity': 2100, 'unit': 'Dus'},
    ];
    for (var s in samples) {
      await db.collection('stocks').add(s);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample stocks seeded')));
  }

  // ==================== ENGINE DOWNLOAD GAMBAR + DIRECT WA WEB ====================
  Future<void> _generateAndShareReportImage({required String jenisReport}) async {
    setState(() {
      _jenisReportAktif = jenisReport;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (mounted) Navigator.pop(context); // Tutup Loading screen

      // --- LOGIK DOWNLOAD OTOMATIS DI BROWSER ---
      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "REKAP_${jenisReport}_${DateFormat('yyyyMMdd').format(DateTime.now())}.png")
        ..click();
      html.Url.revokeObjectUrl(url); // Bersihkan memory url cache

      // Buka tab baru langsung ke WA Web
      html.window.open('https://web.whatsapp.com/', '_blank');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Gambar sukses ter-download! Silakan attach dari folder Downloads ke WhatsApp Web.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat gambar rekap: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AdminLoginPage();
    }

    final prov = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/admin');
              }
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Stack(
        children: [
          
          // LAYOUT 1: HALAMAN DASHBOARD UTAMA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, Admin', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Stocks loaded: ${prov.stocks.length}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Stores loaded: ${prov.stores.length}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                
                const Text('Fitur Cetak & Rekapitulasi:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _generateAndShareReportImage(jenisReport: 'HARIAN'),
                        icon: const Icon(Icons.download_for_offline_rounded),
                        label: const Text('Download Rekap Harian'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _generateAndShareReportImage(jenisReport: 'BULANAN'),
                        icon: const Icon(Icons.cloud_download_rounded),
                        label: const Text('Download Rekap Bulanan'),
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                      ),
                      onPressed: () async {
                        final konfirmasi = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Reset Rutinitas Harian?'),
                              ],
                            ),
                            content: const Text(
                              'Tindakan ini akan mengosongkan semua muatan barang toko dan menghapus toko yang sudah TERKIRIM untuk persiapan besok hari.\n\nData nama-nama toko TIDAK akan dihapus.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Ya, Reset Sekarang', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (konfirmasi == true && context.mounted) {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            await Provider.of<AdminProvider>(context, listen: false).resetHarianSemuaToko();

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sistem berhasil direset! Semua toko siap menerima muatan baru.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal mereset data: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset Harian'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StocksEditorPage())),
                      icon: const Icon(Icons.storage),
                      label: const Text('Edit Stocks'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoresManagerPage())),
                      icon: const Icon(Icons.store),
                      label: const Text('Manage Stores'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _seedSampleStocks(context),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Seed Sample Stocks'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (prov.stocks.isEmpty)
                  Card(
                    color: Colors.yellow.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Belum ada data stok.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Klik "Seed Sample Stocks" untuk menambahkan data awal, atau gunakan "Edit Stocks" untuk menambah manual.'),
                        ],
                      ),
                    ),
                  ),
                if (prov.stocks.isNotEmpty) ...[
                  const Text('Recent stocks:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: prov.stocks.length,
                      key: const PageStorageKey('recent_stocks_list'),
                      itemBuilder: (context, index) {
                        final stock = prov.stocks[index];
                        return ListTile(
                          title: Text(stock.name),
                          subtitle: Text('${stock.quantity} ${stock.unit}'),
                        );
                      },
                    ),
                  ),
                ]
              ],
            ),
          ),

          // LAYOUT 2: WIDGET REKAP YANG DI-RENDER KHUSUS UNTUK DIPOTRET
          Transform.translate(
            offset: const Offset(-3000, -3000), 
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _jenisReportAktif == 'HARIAN' ? Colors.blue.shade800 : Colors.green.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REKAP PENJUALAN $_jenisReportAktif', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text('Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())} WIB', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            const Icon(Icons.summarize_rounded, color: Colors.white, size: 32),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1, borderRadius: BorderRadius.circular(4)),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(10), 
                                child: Text('NAMA SALES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))
                              ),
                              Padding(
                                padding: EdgeInsets.all(10), 
                                child: Text('TOTAL OMSET (KRT)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))
                              ),
                            ],
                          ),
                          ...listSales.map((sales) {
                            int totalKarton = 0;

                            if (_jenisReportAktif == 'HARIAN') {
                              // KUNCI EMAS EDITAN: Hanya menyaring toko berstatus 'TERKIRIM' (Pending & OTW otomatis dibuang/0)
                              final tokoSalesTerkirim = prov.stores.where((store) {
                                return store.sales.toUpperCase() == sales.toUpperCase() && 
                                       store.status.toUpperCase() == 'TERKIRIM' &&
                                       store.muatan.isNotEmpty;
                              }).toList();

                              for (var store in tokoSalesTerkirim) {
                                for (var item in store.muatan) {
                                  final int qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0;
                                  totalKarton += qty;
                                }
                              }
                            } else {
                              // Filter bulanan: Tetap mengonsumsi fungsi akumulasi bulanan murni (murni status terkirim)
                              totalKarton = prov.getSalesMonthlyAchieved(sales);
                            }

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12), 
                                  child: Text(sales, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12), 
                                  child: Text(
                                    '$totalKarton', 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 14, 
                                      color: _jenisReportAktif == 'HARIAN' ? Colors.blue.shade900 : Colors.green.shade900, 
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          '-- Dokumen Otomatis Sistem Selling & Stok Monitoring --',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade900,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text(
          'RESET BULANAN', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Reset Rekap Bulanan?'),
                ],
              ),
              content: const Text(
                'Tindakan ini bersifat PERMANEN.\n\nSemua riwayat pengiriman bulan ini akan dihapus total dari database, dan semua akumulasi TARGET SALES bulanan para sales akan kembali menjadi 0.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await Provider.of<AdminProvider>(context, listen: false).resetBulananSemuaPenjualan();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Berhasil mereset data bulanan! Akumulasi target kembali ke 0.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal melakukan reset bulanan: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Ya, Hapus Total', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}