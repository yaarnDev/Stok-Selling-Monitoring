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
import 'history_penjualan.dart'; // Pastikan import file history baru abang ke sini

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
          elevation: 10,
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
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: -0.3),
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
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: const Color(0xFF38BDF8), width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  salesName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              title: Text('Edit Foto $salesName', style: const TextStyle(fontWeight: FontWeight.w800)),
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
                          border: Border.all(color: const Color(0xFF2563EB), width: 2.5),
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
          // HEADER PREMIUM DENGAN GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1E1B4B)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))
              ]
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
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
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12)
                                ),
                                child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Monitoring & Selling', 
                                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                                  ),
                                  Text(
                                    'Realtime Business Operations', 
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
                                  child: const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 20),
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
                                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 20),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08), 
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12)
                            ),
                            child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'DailySale & StokMonitoring', 
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)
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
                          constraints: const BoxConstraints(maxWidth: 420),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08), 
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
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
                          IconButton(
                            tooltip: 'History Penjualan Semua Toko',
                            icon: const Icon(Icons.history_rounded, color: Colors.white70, size: 24),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AllSalesHistoryPage()),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Admin Panel',
                            onPressed: () => Navigator.pushNamed(context, '/admin'),
                            icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 24),
                          ),
                        ],
                      )
                    ],
                  ),
            ),
          ),
          
          // TAB BAR DENGAN PILL SLEEK DESIGN
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: TabBar(
                controller: _tabController, 
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
                  ]
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: salesCategories.map((tab) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.warehouse_rounded, size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                const Text('Sisa Stok Gudang Pusat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_getFormattedDate(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
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
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0, vertical: 16.0), 
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
            bool isLow = item.quantity < 50;

            return Container(
              width: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(18), 
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 4))
                ],
                border: Border.all(color: isLow ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0), width: 1.5)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name, 
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLow ? Colors.red : const Color(0xFF10B981),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.quantity}', style: TextStyle(color: isLow ? Colors.red.shade900 : const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3.0), 
                        child: Text(item.unit, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
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
          height: 102,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(18), 
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showWAProfilePreviewDialog(context, _currentTabSalesName, avatarBase64), 
                child: Tooltip(
                  message: 'Lihat / Ubah Foto Profil',
                  child: Container(
                    width: isMobile ? 100 : 120, 
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2563EB).withOpacity(0.08), const Color(0xFF2563EB).withOpacity(0.01)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (context) {
                            if (upperName == 'INSTANSI') {
                              return const CircleAvatar(radius: 20, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 20));
                            } else if (upperName == 'SHOPEE') {
                              return const CircleAvatar(radius: 20, backgroundColor: Color(0xFFFFF7ED), child: Icon(Icons.shopping_bag_rounded, color: Colors.orange, size: 20));
                            } else {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE2E8F0),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                                  ]
                                ),
                                child: ClipOval(
                                  child: decodedBytes != null
                                      ? Image.memory(
                                          decodedBytes,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(initial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
                                        ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(upperName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))), 
                        Text(bulanSekarang, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)), 
                      ],
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
                        const Text('TOTAL PENJUALAN', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('$achieved Karton', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF2563EB), letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        const Text('Periode berjalan bulan ini', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
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
                            const Text('CAPAIAN TARGET', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            Text('${(persen * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: persen >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$achieved / $target Krt', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: persen, 
                            minHeight: 7, 
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$qty $unit', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 12)),
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                const SizedBox(width: 8),
                Flexible(child: Text(name, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                    Text('Tgl Dimuat: $tanggalInfo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
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
                                ExpandableDeliveryColumn(title: '🚚 ANTRIAN AKTIF', subtitle: '(${activeCards.length} Toko)', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: activeCards),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.12),
                        blurRadius: 20,
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -2))
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 20)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Antrian', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 0.3)), 
                    const SizedBox(height: 2), 
                    Text('$pendingCount Krt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFD97706), letterSpacing: -0.5))
                  ]
                ),
              ],
            )
          ),
          Container(width: 1.5, height: 38, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Color(0xFFD1FAE5), child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Terkirim', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 0.3)), 
                    const SizedBox(height: 2), 
                    Text('$deliveredCount Krt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: -0.5))
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
        border: Border.all(color: widget.headerColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.headerColor.withOpacity(0.04),
            blurRadius: 12,
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
              Container(width: 4, height: 18, decoration: BoxDecoration(color: widget.headerColor, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 10),
              Text(
                widget.title, 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: widget.headerColor, letterSpacing: -0.2),
              ),
              const SizedBox(width: 6),
              Text(
                widget.subtitle,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.headerColor.withOpacity(0.7)),
              )
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.headerColor.withOpacity(0.08),
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
                        style: TextStyle(color: widget.headerColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(shopName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
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