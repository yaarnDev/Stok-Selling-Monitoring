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
    // 🛠️ DETEKSI LEBAR LAYAR GADGET (HP / LAPTOP)
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== APPBAR RESPONSIVE ====================
          Container(
            color: const Color(0xFF1E88E5), 
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: isMobile 
                ? Column( // Tampilan Atas khusus HP (Susun Vertikal agar tidak sumpek)
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.analytics, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text('Monitoring & Selling', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Admin',
                                onPressed: () => Navigator.pushNamed(context, '/admin'),
                                icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                              ),
                              const CircleAvatar(radius: 14, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 18))
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (value) {
                            setState(() { _searchQuery = value.trim().toLowerCase(); });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Cari nama toko...',
                            hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row( // Tampilan Atas khusus Laptop/Tablet (Menyamping)
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.analytics, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text('Selling & Stok Monitoring', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            onChanged: (value) {
                              setState(() { _searchQuery = value.trim().toLowerCase(); });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Cari nama toko...',
                              hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                              prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.mail_outline, color: Colors.white, size: 22),
                          const SizedBox(width: 18),
                          const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                          const SizedBox(width: 14),
                          IconButton(
                            tooltip: 'Admin',
                            onPressed: () => Navigator.pushNamed(context, '/admin'),
                            icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 6),
                          const CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 20))
                        ],
                      )
                    ],
                  ),
            ),
          ),
          
          // ==================== NAVIGATION TABS AREA ====================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
            child: Center(
              child: TabBar(
                controller: _tabController, 
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorColor: const Color(0xFF1E88E5),
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: const Color(0xFF64748B),
                tabs: salesCategories.map((tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(tab['icon'] as IconData, size: 16), const SizedBox(width: 6), Text(tab['name'] as String)],
                  ),
                )).toList(),
              ),
            ),
          ),
          
          // ==================== CONTENT UTAMA RESPONSIVE ====================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: isMobile ? 16.0 : 24.0, top: 16.0, bottom: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📦 Sisa Stok Gudang Pusat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(_getFormattedDate(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      ],
                    ),
                  ),
                  
                  // 🛠️ PERBAIKAN STRUKTUR: Jika di HP maka tumpuk vertikal, jika di laptop maka horizontal menyamping
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 14.0 : 22.0),
                    child: isMobile 
                      ? Column(
                          children: [
                            _buildStockGrid(context),
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
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0), 
                    child: const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0))
                  ),
                  
                  // RUTE JALUR LAYOUT PENCARIAN SALES
                  SizedBox(
                    height: 600, 
                    child: TabBarView(
                      controller: _tabController, 
                      children: salesCategories.map((tab) => SalesDeliveryPipeline(salesName: tab['name'] as String, query: _searchQuery)).toList(),
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

  Widget _buildStockGrid(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final stocks = provider.stocks;

    if (stocks.isEmpty) {
      return const SizedBox(height: 110, child: Center(child: Text('No stock data')));
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          scrollDirection: Axis.horizontal,
          itemCount: stocks.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            var item = stocks[index];
            return Container(
              width: 135,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.name, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.quantity}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(item.unit, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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

    String bulanSekarang = DateFormat('MMM yyyy', 'id').format(DateTime.now());

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 12),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 85 : 100, // Menyesuaikan lebar profil di HP
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E88E5).withOpacity(0.06), const Color(0xFF1E88E5).withOpacity(0.01)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      if (upperName == 'INSTANSI') {
                        return const CircleAvatar(radius: 16, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.business, color: Color(0xFF1E88E5), size: 16));
                      } else if (upperName == 'SHOPEE') {
                        return const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFFF7ED), child: Icon(Icons.shopping_bag, color: Colors.orange, size: 16));
                      } else {
                        return CircleAvatar(
                          radius: 16, backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=${_currentTabSalesName.toLowerCase()}'),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(upperName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  Text(bulanSekarang, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            
            Container(width: 1, height: 50, color: const Color(0xFFF1F5F9)),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: isNonTarget 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Total Penjualan', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 1),
                      Text('$achieved Karton', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E88E5), letterSpacing: -0.5)),
                      const SizedBox(height: 1),
                      const Text('Periode berjalan bulan ini', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('Capaian Target', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          Text('${(persen * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: persen >= 1.0 ? Colors.green : const Color(0xFFF59E0B))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('$achieved / $target Krt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: persen, minHeight: 4, backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(persen >= 1.0 ? Colors.green : const Color(0xFFF59E0B)),
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesDeliveryPipeline extends StatelessWidget {
  final String salesName;
  final String query;
  const SalesDeliveryPipeline({super.key, required this.salesName, required this.query});

  Widget _buildMuatanDetails(List<dynamic>? muatan) {
    if (muatan == null || muatan.isEmpty) {
      return const Text('Muatan: Kosong', style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: muatan.map((item) {
        final String name = item['name'] ?? '-';
        final int qty = item['qty'] ?? 0;
        final String unit = item['unit'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$qty $unit', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
              const SizedBox(width: 6),
              const Text('|', style: TextStyle(color: Colors.black26, fontSize: 12)),
              const SizedBox(width: 6),
              Flexible(child: Text(name, style: const TextStyle(color: Color(0xFF475569), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text('⚠️ PENDING $selisihHari HARI', style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
              );
            }
          }

          return DeliveryCard(
            shopName: store.name, address: store.address, 
            details: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMuatanDetails(store.muatan),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('Tgl Order: $tanggalInfo', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: isMobile 
                  ? SingleChildScrollView( // 🛠️ RESPONSIVE HP: Bisa di-scroll turun ke bawah jika data penuh
                      child: Column(
                        children: [
                          _buildColumn(title: '🚚 PENDING / OTW ($salesName)', headerColor: const Color(0xFFD97706), bgColor: const Color(0xFFFFFDF5), items: pendingCards),
                          const SizedBox(height: 16),
                          _buildColumn(title: '✅ BERHASIL TERKIRIM', headerColor: const Color(0xFF059669), bgColor: const Color(0xFFF0FDF4), items: deliveredCards),
                        ],
                      ),
                    )
                  : Row( // RESPONSIVE LAPTOP: Berjejer menyamping
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumn(title: '🚚 PENDING / OTW ($salesName)', headerColor: const Color(0xFFD97706), bgColor: const Color(0xFFFFFDF5), items: pendingCards)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildColumn(title: '✅ BERHASIL TERKIRIM', headerColor: const Color(0xFF059669), bgColor: const Color(0xFFF0FDF4), items: deliveredCards)),
                      ],
                    ),
              ),
              const SizedBox(height: 12),
              _buildTotalsCard(pendingCount: totalPendingKarton, deliveredCount: totalDeliveredKarton),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumn({required String title, required Color headerColor, required Color bgColor, required List<Widget> items}) {
    return Container(
      height: 320, // Menetapkan tinggi tetap rute biar tidak overflow di HP
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: headerColor)),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('Tidak ada rute', style: TextStyle(color: Colors.grey[400], fontSize: 12)))
                : ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (ctx, idx) => items[idx]),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard({required int pendingCount, required int deliveredCount}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Pending', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))), const SizedBox(height: 4), Text('$pendingCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Terkirim', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))), const SizedBox(height: 4), Text('$deliveredCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF059669)))])),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
                const SizedBox(height: 4), 
                details,
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: isOtw ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(4)), child: Text(isOtw ? 'OTW' : 'TERKIRIM', style: TextStyle(color: isOtw ? const Color(0xFFB45309) : const Color(0xFF047857), fontSize: 9, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}