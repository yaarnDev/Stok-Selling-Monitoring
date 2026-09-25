import 'dart:io';
import 'dart:convert'; // Wajib untuk base64Decode
import 'package:flutter/foundation.dart'; // Wajib import untuk kIsWeb dan Uint8List
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import Wajib Image Picker
import '../admin/providers/admin_provider.dart';
import 'history_penjualan.dart'; // Pastikan import file history baru ke sini

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
    {'name': 'SYAKUR', 'icon': Icons.badge_outlined, 'avatar': 'SY'},
    {'name': 'FAISOL', 'icon': Icons.badge_outlined, 'avatar': 'FA'},
    {'name': 'MULYADI', 'icon': Icons.badge_outlined, 'avatar': 'MU'},
    {'name': 'LUAY', 'icon': Icons.badge_outlined, 'avatar': 'LU'},
    {'name': 'INSTANSI', 'icon': Icons.business_outlined, 'avatar': 'IN'},
    {'name': 'SHOPEE', 'icon': Icons.shopping_bag_outlined, 'avatar': 'SH'},
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

  // DIALOG MODEL WA: Preview Profil Besar
  void _showWAProfilePreviewDialog(BuildContext context, String salesName, String? base64String) {
    final String initial = salesName.length >= 2 ? salesName.substring(0, 2).toUpperCase() : salesName.toUpperCase();
    Uint8List? decodedBytes;
    
    if (base64String != null && base64String.isNotEmpty) {
      try {
        decodedBytes = base64Decode(base64String);
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 6,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profil $salesName',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: -0.3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                        image: decodedBytes != null
                            ? DecorationImage(
                                image: MemoryImage(decodedBytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: decodedBytes != null
                          ? null
                          : Center(
                              child: Text(
                                initial, 
                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))
                              ),
                            ),
                    ),
                    if (salesName != 'INSTANSI' && salesName != 'SHOPEE')
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); 
                          _showEditAvatarProcess(context, salesName); 
                        },
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  salesName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), // BOLD NAMA SALES
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Hak Akses Terbimbing (Admin)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ALUR PROSES UPLOAD DAN VALIDASI PASSWORD ADMIN
  void _showEditAvatarProcess(BuildContext context, String salesName) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final passwordController = TextEditingController();
    
    XFile? pickedXFile;
    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Foto $salesName', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Masukkan password admin untuk memvalidasi identitas hak akses.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password Admin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (selectedImageBytes != null)
                      Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB), width: 2),
                          image: DecorationImage(
                            image: MemoryImage(selectedImageBytes!), 
                            fit: BoxFit.cover
                          )
                        ),
                      ),
                    
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF2563EB)),
                      label: Text(selectedImageBytes == null ? 'Pilih Gambar Baru' : 'Ganti Gambar Pilihan', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                        
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setDialogState(() {
                            pickedXFile = pickedFile;
                            selectedImageBytes = bytes;
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
                      if (pickedXFile != null && selectedImageBytes != null) {
                        Navigator.pop(context); 
                        
                        BuildContext? loadingContext;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext lContext) {
                            loadingContext = lContext;
                            return const Center(child: CircularProgressIndicator());
                          },
                        );

                        try {
                          await provider.uploadAndUpdateSalesAvatarCrossPlatform(
                            salesName, 
                            pickedXFile!, 
                            selectedImageBytes!
                          );
                          
                          if (loadingContext != null && Navigator.canPop(loadingContext!)) {
                            Navigator.pop(loadingContext!);
                          }
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Foto profil $salesName sukses diperbarui!'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          if (loadingContext != null && Navigator.canPop(loadingContext!)) {
                            Navigator.pop(loadingContext!);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                            );
                          }
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
                  child: const Text('Mulai Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF1F5F9), 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER MODERN VIBRANT SLATE BLUE
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 16),
            child: SafeArea(
              bottom: false,
              child: isMobile 
                ? Column( 
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3))
                                ),
                                child: const Icon(Icons.insights_rounded, color: Color(0xFF60A5FA), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Monitoring & Selling', 
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)
                                  ),
                                  Text(
                                    'Realtime Operations Dashboard', 
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'History Penjualan Semua Toko',
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.history_rounded, color: Color(0xFF60A5FA), size: 18),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AllSalesHistoryPage()),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Admin Panel',
                                onPressed: () => Navigator.pushNamed(context, '/admin'),
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF60A5FA), size: 18),
                                ),
                              ),
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
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          onChanged: (value) {
                            setState(() { _searchQuery = value.trim().toLowerCase(); });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama toko secara instan...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13), 
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF60A5FA), size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row( 
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3))
                            ),
                            child: const Icon(Icons.insights_rounded, color: Color(0xFF60A5FA), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'DailySale & StokMonitoring', 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)
                              ),
                              Text(
                                'Executive Operations & Analytics Dashboard', 
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 380),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08), 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (value) {
                              setState(() { _searchQuery = value.trim().toLowerCase(); });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nama toko secara instan...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13), 
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF60A5FA), size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'History Penjualan Semua Toko',
                            icon: const Icon(Icons.history_rounded, color: Colors.white70, size: 22),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AllSalesHistoryPage()),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Admin Panel',
                            onPressed: () => Navigator.pushNamed(context, '/admin'),
                            icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF60A5FA), size: 22),
                          ),
                        ],
                      )
                    ],
                  ),
            ),
          ),
          
          // TAB BAR CLEAN BLUE ACCENT
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
              ]
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TabBar(
                controller: _tabController, 
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFF2563EB),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))
                  ]
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12), // BOLD NAMA SALES DI TAB
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: salesCategories.map((tab) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab['icon'] as IconData, size: 15), 
                        const SizedBox(width: 6), 
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
                        padding: EdgeInsets.only(left: isMobile ? 16.0 : 24.0, top: 16.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(width: 8),
                                const Text('Sisa Stok Gudang Pusat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_getFormattedDate(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
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

  /// BUILDER CARD STOK BERVARIAN (DINAMIS HIJAU / MERAH)
  Widget _buildStockGrid(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final stocks = List.from(provider.stocks);

    if (stocks.isEmpty) {
      return Container(
        height: 105, 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: Text('No stock data available', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)))
      );
    }

    final List<String> customOrder = [
      '220ml',
      '330ml',
      '600ml',
      '1500ml',
      '19 liter',
      'galon',
    ];

    stocks.sort((a, b) {
      String nameA = a.name.toString().toLowerCase();
      String nameB = b.name.toString().toLowerCase();

      int indexA = customOrder.indexWhere((key) => nameA.contains(key));
      int indexB = customOrder.indexWhere((key) => nameB.contains(key));

      if (indexA == -1) indexA = 99;
      if (indexB == -1) indexB = 99;

      return indexA.compareTo(indexB);
    });

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 105,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: stocks.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            var item = stocks[index];
            bool isLow = item.quantity < 50;

            // Skema Warna Dinamis berdasarkan Status (Merah jika LOW, Hijau jika SAFE)
            final Color accentColor = isLow ? const Color(0xFFEF4444) : const Color(0xFF10B981);
            final Color headerBgColor = isLow ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
            final Color headerTextColor = isLow ? const Color(0xFF991B1B) : const Color(0xFF065F46);
            final Color badgeBgColor = isLow ? const Color(0xFFEF4444) : const Color(0xFF10B981);
            final Color badgeBorderColor = isLow ? const Color(0xFFB91C1C) : const Color(0xFF059669);

            return Container(
              width: 148,
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.08), 
                    blurRadius: 10, 
                    offset: const Offset(0, 3)
                  )
                ],
                // GARIS SAMPING / BORDER IKUT HIJAU BILA SAFE, MERAH BILA LOW
                border: Border.all(
                  color: accentColor.withOpacity(0.4), 
                  width: 1.5
                )
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    // TOP BAR HEADER
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: headerBgColor, 
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name, 
                              style: TextStyle(
                                color: headerTextColor, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w800
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBgColor, 
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: badgeBorderColor, 
                                width: 0.8
                              )
                            ),
                            child: Text(
                              isLow ? 'LOW' : 'SAFE', 
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 8, 
                                fontWeight: FontWeight.w900
                              )
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    // BODY QUANTITY
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${item.quantity}', 
                              style: TextStyle(
                                color: isLow ? const Color(0xFF991B1B) : const Color(0xFF0F172A), 
                                fontSize: 22, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: -0.5
                              )
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.unit, 
                              style: TextStyle(
                                color: accentColor, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w700
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
    final String initial = upperName.length >= 2 ? upperName.substring(0, 2).toUpperCase() : upperName.toUpperCase();

    return StreamBuilder<DocumentSnapshot>(
      stream: provider.streamSalesProfile(upperName),
      builder: (context, snapshot) {
        String? avatarBase64;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          avatarBase64 = data['avatarBase64']?.toString();
        }

        Uint8List? decodedBytes;
        if (avatarBase64 != null && avatarBase64.isNotEmpty) {
          try {
            decodedBytes = base64Decode(avatarBase64);
          } catch (_) {}
        }

        return Container(
          height: 97,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showWAProfilePreviewDialog(context, _currentTabSalesName, avatarBase64), 
                child: Tooltip(
                  message: 'Lihat / Ubah Foto Profil',
                  child: Container(
                    width: isMobile ? 100 : 115, 
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.04),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (context) {
                            if (upperName == 'INSTANSI') {
                              return const CircleAvatar(radius: 18, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 18));
                            } else if (upperName == 'SHOPEE') {
                              return const CircleAvatar(radius: 18, backgroundColor: Color(0xFFFFF7ED), child: Icon(Icons.shopping_bag_rounded, color: Colors.orange, size: 18));
                            } else {
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE2E8F0),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: decodedBytes != null
                                      ? Image.memory(
                                          decodedBytes,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                                        ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upperName, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)) // BOLD NAMA SALES
                        ), 
                        Text(bulanSekarang, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500)), 
                      ],
                    ),
                  ),
                ),
              ),
              
              Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  child: isNonTarget 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('TOTAL PENJUALAN', style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text('$achieved Karton', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF2563EB), letterSpacing: -0.5)),
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
                            const Text('CAPAIAN TARGET', style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            Text('${(persen * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: persen >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFD97706))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('$achieved / $target Krt', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
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
      return const Text('Muatan: Kosong', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: muatan.map((item) {
        final String name = item['name'] ?? '-';
        final int qty = item['qty'] ?? 0;
        final String unit = item['unit'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$qty $unit', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706), fontSize: 11)),
                const SizedBox(width: 6),
                const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                const SizedBox(width: 6),
                Flexible(child: Text(name, style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                child: Text('⚠️ PENDING $selisihHari HARI', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.w700)),
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
                const SizedBox(height: 6),
                // WRAP RESPONSIF: MENJAGA BADGE PENDING DARI OVERFLOW DI DISPLAY HP SEMPIT
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text('Tgl Dimuat: $tanggalInfo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
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
                const SizedBox(height: 6),
              ],
            ), 
            status: store.status.toUpperCase(), 
          );
        }).toList();

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 70.0 : 0.0), 
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
                                ExpandableDeliveryColumn(title: 'ANTRIAN AKTIF', subtitle: '(${activeCards.length} Toko)', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: activeCards),
                                const SizedBox(height: 16),
                                ExpandableDeliveryColumn(title: 'RUTE SELESAI', subtitle: '(${finalCards.length} Toko)', headerColor: const Color(0xFF047857), bgColor: const Color(0xFFF0FDF4), items: finalCards),
                              ],
                            )
                          : Column( 
                              children: [
                                Row( 
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: ExpandableDeliveryColumn(title: 'ANTRIAN AKTIF', subtitle: '(${activeCards.length} Toko)', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: activeCards)),
                                    const SizedBox(width: 16),
                                    Expanded(child: ExpandableDeliveryColumn(title: 'RUTE SELESAI', subtitle: '(${finalCards.length} Toko)', headerColor: const Color(0xFF047857), bgColor: const Color(0xFFF0FDF4), items: finalCards)),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.08),
                        blurRadius: 12,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Antrian', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w700)), 
                    const SizedBox(height: 1), 
                    Text('$pendingCount Krt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFD97706), letterSpacing: -0.3))
                  ]
                ),
              ],
            )
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Terkirim', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w700)), 
                    const SizedBox(height: 1), 
                    Text('$deliveredCount Krt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF059669), letterSpacing: -0.3))
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
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: widget.headerColor.withOpacity(0.2), width: 1.2),
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
              Container(width: 3.5, height: 16, decoration: BoxDecoration(color: widget.headerColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                widget.title, 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: widget.headerColor, letterSpacing: 0.2),
              ),
              const SizedBox(width: 6),
              Text(
                widget.subtitle,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.headerColor.withOpacity(0.8)),
              )
            ],
          ),
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: widget.headerColor,
            size: 20,
          ),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 14),
          expandedAlignment: Alignment.topLeft,
          children: [
            widget.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28), 
                      child: Text(
                        'Tidak ada rute pipeline', 
                        style: TextStyle(color: widget.headerColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: widget.items.length, 
                    separatorBuilder: (_, __) => const SizedBox(height: 8), 
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
      case 'RAID 2':
        badgeBgColor = const Color(0xFFFFF7ED);
        badgeBorderColor = const Color(0xFFFFEDD5);
        badgeTextColor = const Color(0xFFC2410C);
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
      case 'PENDING':
        badgeBgColor = const Color(0xFFFEF3C7);
        badgeBorderColor = const Color(0xFFFDE68A);
        badgeTextColor = const Color(0xFFB45309);
        labelText = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  shopName, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A), letterSpacing: -0.2), // BOLD NAMA TOKO
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          address, 
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4), 
                details,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
            decoration: BoxDecoration(
              color: badgeBgColor, 
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeBorderColor, width: 1)
            ), 
            child: Text(
              labelText, 
              style: TextStyle(color: badgeTextColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)
            )
          ),
        ],
      ),
    );
  }
}