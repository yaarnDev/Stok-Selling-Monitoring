import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import Wajib Image Picker
import '../admin/providers/admin_provider.dart';

class AudienceHomeScreen extends StatefulWidget {
  const AudienceHomeScreen({super.key});

  @override
  State<AudienceHomeScreen> createState() => _AudienceHomeScreenState();
}

class _AudienceHomeScreenState extends State<AudienceHomeScreen> with SingleTickerProviderStateMixin {
  bool _hasStartedListening = false;
  String _searchQuery = "";
  
  late TabController _tabController;
  String _currentTabSalesName = "SYAKUR"; 

  final List<Map<String, dynamic>> salesCategories = [
    {'name': 'SYAKUR', 'icon': Icons.badge, 'avatar': 'SY'},
    {'name': 'FAISOL', 'icon': Icons.badge, 'avatar': 'FA'},
    {'name': 'MULYADI', 'icon': Icons.badge, 'avatar': 'MU'},
    {'name': 'LUAY', 'icon': Icons.badge, 'avatar': 'LU'},
    {'name': 'INSTANSI', 'icon': Icons.business, 'avatar': 'IN'},
    {'name': 'SHOPEE', 'icon': Icons.shopping_bag, 'avatar': 'SH'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: salesCategories.length, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabSalesName = salesCategories[_tabController.index]['name'] as String;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedListening) {
      Provider.of<AdminProvider>(context, listen: false).startListening();
      _hasStartedListening = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    initializeDateFormatting('id', null);
    return DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now());
  }

  void _showEditAvatarDialog(BuildContext context, String salesName) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final passwordController = TextEditingController();
    File? selectedLocalFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ubah Foto Profil $salesName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Masukkan password admin untuk memvalidasi identitas hak akses.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password Admin',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (selectedLocalFile != null)
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 12), // FIX: EdgeInsets.only
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: FileImage(selectedLocalFile!), 
                            fit: BoxFit.cover // FIX: BoxFit.cover
                          )
                        ),
                      ),
                    
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(selectedLocalFile == null ? 'Pilih Foto dari Galeri' : 'Ganti Foto Pilihan'),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedLocalFile = File(pickedFile.path); 
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (passwordController.text.trim() == "admin123") {
                      if (selectedLocalFile != null) {
                        Navigator.pop(context);
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await provider.uploadAndUpdateSalesAvatar(salesName, selectedLocalFile!);
                          
                          if (context.mounted) Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Foto profil $salesName sukses diunggah dari memori lokal!'), behavior: SnackBarBehavior.floating),
                          );
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal mengunggah file: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Silakan pilih file gambar terlebih dahulu!'), backgroundColor: Colors.orange),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Akses Ditolak! Password Admin Salah.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Mulai Upload'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 14),
            child: SafeArea(
              bottom: false,
              child: isMobile 
                ? Column( 
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Monitoring & Selling', 
                                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.5)
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Admin Panel',
                                onPressed: () => Navigator.pushNamed(context, '/admin'),
                                icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 24),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 1.5)
                                ),
                                child: const CircleAvatar(radius: 14, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white, size: 18)),
                              )
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08), 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (value) {
                            setState(() { _searchQuery = value.trim().toLowerCase(); });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama toko secara instan...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13), 
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row( 
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 28),
                          SizedBox(width: 12),
                          Text(
                            'DailySale & StokMonitoring', 
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08), 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            onChanged: (value) {
                              setState(() { _searchQuery = value.trim().toLowerCase(); });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nama toko secara instan...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13), 
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, color: Colors.white70, size: 24),
                          const SizedBox(width: 20),
                          const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 24),
                          const SizedBox(width: 16),
                          IconButton(
                            tooltip: 'Admin Panel',
                            onPressed: () => Navigator.pushNamed(context, '/admin'),
                            icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 24),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1.5)
                            ),
                            child: const CircleAvatar(radius: 16, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white, size: 20))
                          )
                        ],
                      )
                    ],
                  ),
            ),
          ),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TabBar(
                controller: _tabController, 
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: const Color(0xFFEFF6FF), 
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF1E40AF),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: salesCategories.map((tab) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab['icon'] as IconData, size: 16), 
                        const SizedBox(width: 8), 
                        Text(tab['name'] as String)
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController, 
              children: salesCategories.map((tab) {
                return SalesDeliveryPipeline(
                  salesName: tab['name'] as String, 
                  query: _searchQuery,
                  headerWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: isMobile ? 16.0 : 24.0, top: 20.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warehouse_rounded, size: 18, color: Color(0xFF0F172A)),
                                SizedBox(width: 8),
                                Text('Sisa Stok Gudang Pusat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_getFormattedDate(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0),
                        child: isMobile 
                          ? Column(
                              children: [
                                _buildStockGrid(context),
                                const SizedBox(height: 12),
                                _buildEnhancedDynamicSalesTarget(context, isMobile),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(width: screenWidth * 0.54, child: _buildStockGrid(context)),
                                SizedBox(width: screenWidth * 0.40, child: _buildEnhancedDynamicSalesTarget(context, isMobile)),
                              ],
                            ),
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0, vertical: 14.0), 
                        child: const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0))
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockGrid(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final stocks = provider.stocks;

    if (stocks.isEmpty) {
      return Container(
        height: 110, 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No stock data available', style: TextStyle(color: Color(0xFF94A3B8))))
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 115,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: stocks.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            var item = stocks[index];
            return Container(
              width: 145,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))
                ],
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name, 
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.quantity}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3.0), 
                        child: Text(item.unit, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildEnhancedDynamicSalesTarget(BuildContext context, bool isMobile) {
    final provider = Provider.of<AdminProvider>(context);
    final String upperName = _currentTabSalesName.trim().toUpperCase();
    
    final int target = provider.salesTargets[upperName] ?? 0;
    final int achieved = provider.getSalesMonthlyAchieved(upperName);
    final bool isNonTarget = upperName == 'INSTANSI' || upperName == 'SHOPEE';
    
    double persen = target > 0 ? (achieved / target) : 0.0;
    if (persen > 1.0) persen = 1.0;

    String bulanSekarang = DateFormat('MMMM yyyy', 'id').format(DateTime.now());

    void _downloadDetailPenjualan() {
      final sekarang = DateTime.now();
      final Map<String, List<Map<String, dynamic>>> rekapPerToko = {};

      try {
        final dynamic providerDyn = provider;
        
        if (providerDyn.runtimeType.toString() != '') {
          for (var record in providerDyn.history) {
            final SalesHistory historyItem = record as SalesHistory; 
            
            if (historyItem.sales.trim().toUpperCase() == upperName) {
              if (historyItem.timestamp.month == sekarang.month && historyItem.timestamp.year == sekarang.year) {
                
                if (providerDyn._waktuResetBulananTerakhir != null && 
                    historyItem.timestamp.isBefore(providerDyn._waktuResetBulananTerakhir!)) {
                  continue;
                }

                final String namaToko = historyItem.storeName;
                final String tglText = DateFormat('dd MMM yyyy', 'id').format(historyItem.timestamp); 
                final String keyToko = "$namaToko ($tglText)";

                if (!rekapPerToko.containsKey(keyToko)) {
                  rekapPerToko[keyToko] = [];
                }
                
                for (var item in historyItem.muatan) {
                  rekapPerToko[keyToko]!.add({
                    'name': item['name'] ?? '-',
                    'qty': (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0,
                    'unit': item['unit'] ?? 'Krt',
                  });
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Akses history error: $e');
      }

      for (var store in provider.stores) {
        if (store.sales.trim().toUpperCase() == upperName && store.status.toUpperCase() == 'TERKIRIM') { 
          
          try {
            final dynamic providerDyn = provider;
            if (providerDyn._waktuResetBulananTerakhir != null && 
                store.createdAt != null && 
                store.createdAt!.isBefore(providerDyn._waktuResetBulananTerakhir!)) {
              continue;
            }
          } catch (_) {}

          final String tglText = store.createdAt != null 
              ? DateFormat('dd MMM yyyy', 'id').format(store.createdAt!) 
              : 'Hari ini';
          final String keyToko = "${store.name} ($tglText - Baru)";

          if (!rekapPerToko.containsKey(keyToko)) {
            rekapPerToko[keyToko] = [];
          }

          for (var item in store.muatan) {
            rekapPerToko[keyToko]!.add({
              'name': item['name'] ?? '-',
              'qty': (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0,
              'unit': item['unit'] ?? 'Krt',
            });
          }
        }
      }

      if (rekapPerToko.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Rekap Penjualan $upperName'),
            content: Text('Belum ada riwayat transaksi penjualan berstatus TERKIRIM pada periode bulan $bulanSekarang.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        return;
      }

      StringBuffer detailSummary = StringBuffer();
      detailSummary.writeln('===================================');
      detailSummary.writeln('LAPORAN ASAL PENCAPAIAN BULANAN');
      detailSummary.writeln('Sales    : $upperName');
      detailSummary.writeln('Periode  : $bulanSekarang');
      detailSummary.writeln('===================================\n');

      int grandTotalKarton = 0;
      rekapPerToko.forEach((toko, listMuatan) {
        detailSummary.writeln('📍 $toko');
        int subtotalToko = 0;
        for (var item in listMuatan) {
          detailSummary.writeln('   • ${item['qty']} ${item['unit']} - ${item['name']}');
          subtotalToko += item['qty'] as int;
        }
        grandTotalKarton += subtotalToko;
        detailSummary.writeln('   Subtotal Toko: $subtotalToko Karton\n');
      });

      detailSummary.writeln('-----------------------------------');
      detailSummary.writeln('🎉 TOTAL HISTORY REALISASI: $grandTotalKarton Karton');
      detailSummary.writeln('-----------------------------------');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RINCIAN ASAL PENJUALAN BULANAN', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    Text('Menampilkan rincian dari history hari sebelumnya & transaksi hari ini ($achieved Krt)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const Divider(height: 20),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Text(
                              detailSummary.toString(), 
                              style: const TextStyle(fontFamily: 'Courier', fontSize: 12, height: 1.4, color: Color(0xFF334155))
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showEditAvatarDialog(context, _currentTabSalesName), 
            child: Tooltip(
              message: 'Ubah Foto Profil (Khusus Admin)',
              child: Container(
                width: isMobile ? 95 : 115, 
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E88E5).withOpacity(0.08), const Color(0xFF1E88E5).withOpacity(0.01)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: provider.streamSalesProfile(upperName), 
                  builder: (context, snapshot) {
                    String? customAvatarUrl;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      customAvatarUrl = data['avatarUrl']?.toString();
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (context) {
                            if (upperName == 'INSTANSI') {
                              return const CircleAvatar(radius: 18, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.business_rounded, color: Color(0xFF1E88E5), size: 18));
                            } else if (upperName == 'SHOPEE') {
                              return const CircleAvatar(radius: 18, backgroundColor: Color(0xFFFFF7ED), child: Icon(Icons.shopping_bag_rounded, color: Colors.orange, size: 18));
                            } else {
                              return CircleAvatar(
                                radius: 18, 
                                backgroundColor: const Color(0xFFF1F5F9),
                                backgroundImage: customAvatarUrl != null && customAvatarUrl.isNotEmpty
                                    ? NetworkImage(customAvatarUrl)
                                    : NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=${_currentTabSalesName.toLowerCase()}'), 
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(upperName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))), 
                        Text(bulanSekarang, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)), 
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
          
          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: isNonTarget 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('TOTAL PENJUALAN', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$achieved Karton', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E88E5), letterSpacing: -0.5)),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF1E88E5)),
                            tooltip: 'Unduh Detail Penjualan',
                            onPressed: _downloadDetailPenjualan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Periode berjalan bulan ini', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Navigator.canPop(context) ? const SizedBox.shrink() : const SizedBox.shrink(), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('CAPAIAN TARGET', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        Text('${(persen * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: persen >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$achieved / $target Krt', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.download_rounded, size: 16, color: persen >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                            tooltip: 'Unduh Detail Penjualan',
                            onPressed: _downloadDetailPenjualan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: persen, 
                        minHeight: 6, 
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(persen >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class SalesDeliveryPipeline extends StatelessWidget {
  final String salesName;
  final String query;
  final Widget headerWidget; 
  
  const SalesDeliveryPipeline({
    super.key, 
    required this.salesName, 
    required this.query,
    required this.headerWidget,
  });

  Widget _buildMuatanDetails(List<dynamic>? muatan) {
    if (muatan == null || muatan.isEmpty) {
      return const Text('Muatan: Kosong', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: muatan.map((item) {
        final String name = item['name'] ?? '-';
        final int qty = item['qty'] ?? 0;
        final String unit = item['unit'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$qty $unit', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 12)),
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                const SizedBox(width: 8),
                Flexible(child: Text(name, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  int _calculateTotalItems(List<Store> stores) {
    int total = 0;
    for (var store in stores) {
      for (var item in store.muatan) {
        final int qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0;
        total += qty;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final bool isMobile = MediaQuery.of(context).size.width < 650;

    return StreamBuilder<List<Store>>(
      stream: provider.streamStoresBySales(salesName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final listMasterToko = snapshot.data ?? [];
        var storeList = List<Store>.from(listMasterToko);
        storeList = storeList.where((store) => store.muatan.isNotEmpty).toList();

        if (query.isNotEmpty) {
          storeList = storeList.where((store) => store.name.toLowerCase().contains(query)).toList();
        }

        final activeStores = storeList.where((s) {
          final stat = s.status.toUpperCase();
          return stat != 'TERKIRIM' && stat != 'CANCEL';
        }).toList();

        final finalStores = storeList.where((s) {
          final stat = s.status.toUpperCase();
          return stat == 'TERKIRIM' || stat == 'CANCEL';
        }).toList();

        final int totalPendingKarton = _calculateTotalItems(activeStores);
        final int totalDeliveredKarton = _calculateTotalItems(finalStores);

        final activeCards = activeStores.map((store) {
          String tanggalInfo = "-";
          Widget agingWidget = const SizedBox.shrink();

          if (store.createdAt != null) {
            tanggalInfo = DateFormat('d MMM yyyy HH:mm', 'id').format(store.createdAt!);
            final tanggalHariIni = DateTime.now();
            final hanyaTanggalOrder = DateTime(store.createdAt!.year, store.createdAt!.month, store.createdAt!.day);
            final hanyaTanggalHariIni = DateTime(tanggalHariIni.year, tanggalHariIni.month, tanggalHariIni.day);
            final selisihHari = hanyaTanggalHariIni.difference(hanyaTanggalOrder).inDays;

            if (selisihHari >= 3) {
              agingWidget = Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                child: Text('⚠️ PENDING $selisihHari HARI', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.w800)),
              );
            }
          }

          return DeliveryCard(
            shopName: store.name, 
            address: store.address, 
            details: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMuatanDetails(store.muatan),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('Tgl Dimuat: $tanggalInfo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    agingWidget,
                  ],
                ),
              ],
            ), 
            status: store.status.toUpperCase(), 
          );
        }).toList();

        final finalCards = finalStores.map((store) {
          String tanggalInfo = "-";
          if (store.createdAt != null) {
            tanggalInfo = DateFormat('d MMM yyyy HH:mm', 'id').format(store.createdAt!);
          }

          return DeliveryCard(
            shopName: store.name, 
            address: store.address, 
            details: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMuatanDetails(store.muatan),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('Tgl Dimuat: $tanggalInfo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ), 
            status: store.status.toUpperCase(), 
          );
        }).toList();

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 75.0 : 0.0), 
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerWidget, 
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0),
                        child: isMobile 
                          ? Column(
                              children: [
                                ExpandableDeliveryColumn(title: '🚚 ANTRIAN AKT', subtitle: '(${activeCards.length} Toko)', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: activeCards),
                                const SizedBox(height: 20),
                                ExpandableDeliveryColumn(title: '✅ RUTE SELESAI', subtitle: '(${finalCards.length} Toko)', headerColor: const Color(0xFF047857), bgColor: const Color(0xFFF0FDF4), items: finalCards),
                              ],
                            )
                          : Column( 
                              children: [
                                Row( 
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: ExpandableDeliveryColumn(title: '🚚 ANTRIAN AKTIF', subtitle: '(${activeCards.length} Toko)', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: activeCards)),
                                    const SizedBox(width: 20),
                                    Expanded(child: ExpandableDeliveryColumn(title: '✅ RUTE SELESAI', subtitle: '(${finalCards.length} Toko)', headerColor: const Color(0xFF047857), bgColor: const Color(0xFFF0FDF4), items: finalCards)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildTotalsCard(pendingCount: totalPendingKarton, deliveredCount: totalDeliveredKarton),
                              ],
                            ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            
            if (isMobile)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.12),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _buildTotalsCard(pendingCount: totalPendingKarton, deliveredCount: totalDeliveredKarton),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTotalsCard({required int pendingCount, required int deliveredCount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 14, offset: const Offset(0, -2))
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 18)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Antrian', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.3)), 
                    const SizedBox(height: 2), 
                    Text('$pendingCount Krt', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFD97706), letterSpacing: -0.5))
                  ]
                ),
              ],
            )
          ),
          Container(width: 1.5, height: 36, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD1FAE5), child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Terkirim', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.3)), 
                    const SizedBox(height: 2), 
                    Text('$deliveredCount Krt', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: -0.5))
                  ]
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}

class ExpandableDeliveryColumn extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color headerColor;
  final Color bgColor;
  final List<Widget> items;

  const ExpandableDeliveryColumn({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerColor,
    required this.bgColor,
    required this.items,
  });

  @override
  State<ExpandableDeliveryColumn> createState() => _ExpandableDeliveryColumnState();
}

class _ExpandableDeliveryColumnState extends State<ExpandableDeliveryColumn> {
  bool _isExpanded = true; 

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: widget.headerColor.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.headerColor.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          title: Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: widget.headerColor, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 10),
              Text(
                widget.title, 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: widget.headerColor, letterSpacing: -0.2),
              ),
              const SizedBox(width: 6),
              Text(
                widget.subtitle,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.headerColor.withOpacity(0.6)),
              )
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.headerColor.withOpacity(0.06),
              shape: BoxShape.circle
            ),
            child: Icon(
              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: widget.headerColor,
              size: 20,
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            widget.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36), 
                      child: Text(
                        'Tidak ada rute pipeline', 
                        style: TextStyle(color: widget.headerColor.withOpacity(0.45), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: widget.items.length, 
                    separatorBuilder: (_, __) => const SizedBox(height: 10), 
                    itemBuilder: (ctx, idx) => widget.items[idx],
                  ),
          ],
        ),
      ),
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final String shopName; 
  final String address; 
  final Widget details; 
  final String status; 

  const DeliveryCard({
    super.key, 
    required this.shopName, 
    required this.address, 
    required this.details, 
    required this.status
  });
  
  @override
  Widget build(BuildContext context) {
    Color badgeBgColor = const Color(0xFFFEF3C7);
    Color badgeBorderColor = const Color(0xFFFDE68A);
    Color badgeTextColor = const Color(0xFFB45309);
    String labelText = status;

    switch (status) {
      case 'OTW':
        badgeBgColor = const Color(0xFFFEF3C7);
        badgeBorderColor = const Color(0xFFFDE68A);
        badgeTextColor = const Color(0xFFB45309);
        break;
      case 'PROSES':
        badgeBgColor = const Color(0xFFE0F2FE);
        badgeBorderColor = const Color(0xFFBAE6FD);
        badgeTextColor = const Color(0xFF0369A1);
        break;
      case 'TERKIRIM':
        badgeBgColor = const Color(0xFFD1FAE5);
        badgeBorderColor = const Color(0xFFA7F3D0);
        badgeTextColor = const Color(0xFF047857);
        labelText = 'TERKIRIM';
        break;
      case 'CANCEL':
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeBorderColor = const Color(0xFFFECACA);
        badgeTextColor = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 3))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(shopName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
                const SizedBox(height: 4), 
                details,
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
            decoration: BoxDecoration(
              color: badgeBgColor, 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeBorderColor, width: 1)
            ), 
            child: Text(
              labelText, 
              style: TextStyle(color: badgeTextColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
            )
          ),
        ],
      ),
    );
  }
}