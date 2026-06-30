import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== APPBAR PREMIUM GRADIENT ====================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 12),
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
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13), // 🛠️ FIX: white45 diganti opacity
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
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13), // 🛠️ FIX: white45 diganti opacity
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
          
          // ==================== NAVIGATION TABS AREA (PILL DESIGN) ====================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
          
          // ==================== CONTENT UTAMA RESPONSIVE ====================
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
                                Text('📦', style: TextStyle(fontSize: 16)),
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
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0, vertical: 12.0), 
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
                  BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1)
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
                        padding: const EdgeInsets.only(bottom: 3.0), // 🛠️ FIX: const EdgeInsets.bottom dihapus const-nya dari padding induk
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

    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 95 : 115, 
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E88E5).withOpacity(0.08), const Color(0xFF1E88E5).withOpacity(0.01)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
            ),
            child: Column(
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
                        radius: 18, backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=${_currentTabSalesName.toLowerCase()}'),
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                Text(upperName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(bulanSekarang, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ],
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
                    Text('$achieved Karton', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E88E5), letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    const Text('Periode berjalan bulan ini', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Navigator.canPop(context) ? const SizedBox.shrink() : const SizedBox.shrink(), // Dummy check safe rule
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
                    Text('$achieved / $target Krt', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF1F5F9))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$qty $unit', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.orange, fontSize: 12)),
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

        final pendingStores = storeList.where((s) => s.status.toUpperCase() != 'TERKIRIM').toList();
        final deliveredStores = storeList.where((s) => s.status.toUpperCase() == 'TERKIRIM').toList();

        final int totalPendingKarton = _calculateTotalItems(pendingStores);
        final int totalDeliveredKarton = _calculateTotalItems(deliveredStores);

        final pendingCards = pendingStores.map((store) {
          String tanggalInfo = "-";
          Widget agingWidget = const SizedBox.shrink();

          if (store.createdAt != null) {
            tanggalInfo = DateFormat('d MMM yyyy', 'id').format(store.createdAt!);
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
            shopName: store.name, address: store.address, 
            details: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMuatanDetails(store.muatan),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('Tgl Order: $tanggalInfo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    agingWidget,
                  ],
                ),
              ],
            ), 
            isOtw: true,
          );
        }).toList();

        final deliveredCards = deliveredStores.map((store) {
          return DeliveryCard(shopName: store.name, address: store.address, details: _buildMuatanDetails(store.muatan), isOtw: false);
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
                                _buildColumn(title: '🚚 PENDING / OTW', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: pendingCards),
                                const SizedBox(height: 20),
                                _buildColumn(title: '✅ BERHASIL TERKIRIM', headerColor: const Color(0xFF047857), bgColor: const Color(0xFFF0FDF4), items: deliveredCards),
                              ],
                            )
                          : Column( 
                              children: [
                                Row( 
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildColumn(title: '🚚 PENDING / OTW', headerColor: const Color(0xFFB45309), bgColor: const Color(0xFFFFFBEB), items: pendingCards)),
                                    const SizedBox(width: 20),
                                    Expanded(child: _buildColumn(title: '✅ BERHASIL TERKIRIM', headerColor: const Color(0xFF047857), bgColor: const Color(0xFFF0FDF4), items: deliveredCards)),
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
                        color: const Color(0xFF0F172A).withOpacity(0.15),
                        blurRadius: 15,
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

  Widget _buildColumn({required String title, required Color headerColor, required Color bgColor, required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(18), 
        border: Border.all(color: headerColor.withOpacity(0.15), width: 1.5)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: headerColor, letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 14),
          items.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Text('Tidak ada rute pipeline', style: TextStyle(color: headerColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: items.length, 
                  separatorBuilder: (_, __) => const SizedBox(height: 10), 
                  itemBuilder: (ctx, idx) => items[idx],
                ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard({required int pendingCount, required int deliveredCount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 16)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Pending', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.3)), 
                    const SizedBox(height: 2), 
                    Text('$pendingCount Krt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFD97706), letterSpacing: -0.5))
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
                const CircleAvatar(radius: 16, backgroundColor: Color(0xFFD1FAE5), child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Total Terkirim', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.3)), 
                    const SizedBox(height: 2), 
                    Text('$deliveredCount Krt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: -0.5))
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

class DeliveryCard extends StatelessWidget {
  final String shopName; final String address; final Widget details; final bool isOtw;
  const DeliveryCard({super.key, required this.shopName, required this.address, required this.details, required this.isOtw});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(14), 
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.015), blurRadius: 8, offset: const Offset(0, 2))
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF94A3B8)),
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
            decoration: BoxDecoration(
              color: isOtw ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5), 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isOtw ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0), width: 1)
            ), 
            child: Text(
              isOtw ? 'OTW' : 'TERKIRIM', 
              style: TextStyle(color: isOtw ? const Color(0xFFB45309) : const Color(0xFF047857), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
            )
          ),
        ],
      ),
    );
  }
}