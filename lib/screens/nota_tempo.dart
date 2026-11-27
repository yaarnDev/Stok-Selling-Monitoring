import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotaTempoPage extends StatefulWidget {
  const NotaTempoPage({super.key});

  @override
  State<NotaTempoPage> createState() => _NotaTempoPageState();
}

class _NotaTempoPageState extends State<NotaTempoPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'SEMUA';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _notaTempoStream;

  final List<String> _salesList = [
    'SYAKUR',
    'FAISOL',
    'MULYADI',
    'LUAY',
    'INSTANSI',
    'SHOPEE',
  ];

  @override
  void initState() {
    super.initState();
    _notaTempoStream =
        FirebaseFirestore.instance.collection('nota_tempo').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _dateFromDynamic(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  bool _isPaid(Map<String, dynamic> data) =>
      data['paid'] == true || data['status'] == 'LUNAS';

  bool _isOverdue(Map<String, dynamic> data) {
    if (_isPaid(data)) return false;
    return _dateFromDynamic(data['dueDate'])
        .isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  Future<void> _openForm(
      {String? documentId, Map<String, dynamic>? data}) async {
    final formKey = GlobalKey<FormState>();
    final customerController =
        TextEditingController(text: data?['customerName']?.toString() ?? '');
    final addressController = TextEditingController(
        text: data?['address']?.toString() ??
            data?['noteNumber']?.toString() ??
            '');
    final amountController = TextEditingController(
      text: data?['amount'] == null ? '' : '${data!['amount']}',
    );
    final noteController =
        TextEditingController(text: data?['note']?.toString() ?? '');
    String sales = data?['sales']?.toString() ?? 'SYAKUR';
    if (!_salesList.contains(sales)) sales = 'SYAKUR';
    DateTime issuedDate =
        data == null ? DateTime.now() : _dateFromDynamic(data['issuedDate']);
    DateTime dueDate = data == null
        ? DateTime.now().add(const Duration(days: 30))
        : _dateFromDynamic(data['dueDate']);
    bool paid = data == null ? false : _isPaid(data);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate(bool isIssued) async {
              final selected = await showDatePicker(
                context: context,
                initialDate: isIssued ? issuedDate : dueDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (selected != null) {
                setDialogState(() {
                  if (isIssued) {
                    issuedDate = selected;
                  } else {
                    dueDate = selected;
                  }
                });
              }
            }

            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                documentId == null ? 'Tambah Nota Tempo' : 'Edit Nota Tempo',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: customerController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            'Nama toko / pelanggan',
                            Icons.storefront_outlined,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Nama pelanggan wajib diisi'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: addressController,
                                decoration: _inputDecoration(
                                  'Alamat toko',
                                  Icons.location_on_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: sales,
                                decoration: _inputDecoration(
                                  'Sales',
                                  Icons.person_outline,
                                ),
                                items: _salesList
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() => sales = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Nominal (Rp)',
                            Icons.payments_outlined,
                          ),
                          validator: (value) {
                            final amount = int.tryParse(
                                value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Nominal harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickDate(true),
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: Text(
                                  'Nota: ${DateFormat('dd MMM yyyy').format(issuedDate)}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickDate(false),
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  'Tempo: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            'Keterangan',
                            Icons.notes_outlined,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Sudah lunas',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          value: paid,
                          activeColor: const Color(0xFF059669),
                          onChanged: (value) =>
                              setDialogState(() => paid = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = int.parse(
                      amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    );
                    final payload = {
                      'customerName': customerController.text.trim(),
                      'address': addressController.text.trim(),
                      'sales': sales,
                      'amount': amount,
                      'issuedDate': Timestamp.fromDate(issuedDate),
                      'dueDate': Timestamp.fromDate(dueDate),
                      'note': noteController.text.trim(),
                      'paid': paid,
                      'status': paid ? 'LUNAS' : 'BELUM LUNAS',
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    final collection =
                        FirebaseFirestore.instance.collection('nota_tempo');
                    if (documentId == null) {
                      await collection.add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await collection.doc(documentId).update(payload);
                    }
                    if (mounted) Navigator.pop(dialogContext);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAdmin({required VoidCallback onConfirmed}) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Validasi Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              content: TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password Admin',
                  hintText: 'Masukkan password admin',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) {
                  Navigator.pop(dialogContext,
                      passwordController.text.trim() == 'admin123');
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      passwordController.text.trim() == 'admin123',
                    );
                  },
                  child: const Text('Lanjutkan'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    if (confirmed == true) {
      onConfirmed();
    } else if (confirmed == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak. Password admin salah.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
  }

  Future<void> _togglePaid(String documentId, bool paid) async {
    await FirebaseFirestore.instance
        .collection('nota_tempo')
        .doc(documentId)
        .update({
      'paid': !paid,
      'status': !paid ? 'LUNAS' : 'BELUM LUNAS',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteItem(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Nota Tempo?'),
        content: const Text('Data nota tempo ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('nota_tempo')
          .doc(documentId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Pencatatan Nota Tempo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tambah Nota Tempo',
            onPressed: () => _confirmAdmin(onConfirmed: () {
              _openForm();
            }),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notaTempoStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data?.docs ?? [];
          final records = items.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['_id'] = doc.id;
            return data;
          }).toList();

          records.sort((a, b) => _dateFromDynamic(b['dueDate'])
              .compareTo(_dateFromDynamic(a['dueDate'])));

          final filtered = records.where((data) {
            final text =
                '${data['customerName'] ?? ''} ${data['address'] ?? data['noteNumber'] ?? ''} ${data['sales'] ?? ''}'
                    .toLowerCase();
            final matchesSearch =
                _searchQuery.isEmpty || text.contains(_searchQuery);
            final matchesStatus = _statusFilter == 'SEMUA' ||
                (_statusFilter == 'LUNAS' && _isPaid(data)) ||
                (_statusFilter == 'BELUM LUNAS' && !_isPaid(data)) ||
                (_statusFilter == 'JATUH TEMPO' && _isOverdue(data));
            return matchesSearch && matchesStatus;
          }).toList();

          int outstandingCount = 0;
          int overdueCount = 0;
          int outstandingAmount = 0;
          int paidCount = 0;
          int totalPaidAmount = 0;
          for (final data in filtered) {
            final amount = data['amount'] is int
                ? data['amount'] as int
                : int.tryParse('${data['amount']}') ?? 0;
            if (_isPaid(data)) {
              paidCount++;
              totalPaidAmount += amount;
            } else {
              outstandingCount++;
              outstandingAmount += amount;
              if (_isOverdue(data)) overdueCount++;
            }
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final horizontalPadding = isMobile ? 24.0 : 48.0;
          final halfCardWidth = (screenWidth - horizontalPadding - 10) / 2;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: isMobile ? 92 : 105,
                      child: _summaryCard(
                        'Piutang Aktif',
                        '$outstandingCount nota',
                        currency.format(outstandingAmount),
                        const Color(0xFFD97706),
                        Icons.pending_actions_rounded,
                        mobile: isMobile,
                        width: screenWidth - horizontalPadding,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: isMobile ? 92 : 105,
                      child: Row(
                        children: [
                          _summaryCard(
                            'Jatuh Tempo',
                            '$overdueCount nota',
                            'Perlu ditindaklanjuti',
                            const Color(0xFFDC2626),
                            Icons.warning_amber_rounded,
                            mobile: isMobile,
                            width: halfCardWidth,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            'Sudah Lunas',
                            '$paidCount nota',
                            currency.format(totalPaidAmount),
                            const Color(0xFF059669),
                            Icons.check_circle_outline_rounded,
                            mobile: isMobile,
                            width: halfCardWidth,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari nama toko, alamat, atau sales...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          items: const [
                            DropdownMenuItem(
                              value: 'SEMUA',
                              child: Text('Semua'),
                            ),
                            DropdownMenuItem(
                              value: 'BELUM LUNAS',
                              child: Text('Belum Lunas'),
                            ),
                            DropdownMenuItem(
                              value: 'JATUH TEMPO',
                              child: Text('Jatuh Tempo'),
                            ),
                            DropdownMenuItem(
                              value: 'LUNAS',
                              child: Text('Lunas'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _statusFilter = value ?? 'SEMUA'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Belum ada nota tempo',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final data = filtered[index];
                            final paid = _isPaid(data);
                            final overdue = _isOverdue(data);
                            final amount = data['amount'] is int
                                ? data['amount'] as int
                                : int.tryParse('${data['amount']}') ?? 0;
                            final dueDate = _dateFromDynamic(data['dueDate']);

                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: overdue
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: paid
                                            ? const Color(0xFFD1FAE5)
                                            : overdue
                                                ? const Color(0xFFFEE2E2)
                                                : const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        paid
                                            ? Icons.check_rounded
                                            : overdue
                                                ? Icons.priority_high_rounded
                                                : Icons.receipt_long_rounded,
                                        color: paid
                                            ? const Color(0xFF059669)
                                            : overdue
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFFD97706),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['customerName']?.toString() ??
                                                '-',
                                            style: TextStyle(
                                              fontWeight: isMobile
                                                  ? FontWeight.w700
                                                  : FontWeight.w900,
                                              fontSize: isMobile ? 13 : 14,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${data['address']?.toString().isNotEmpty == true ? data['address'] : data['noteNumber']?.toString().isNotEmpty == true ? data['noteNumber'] : 'Alamat belum diisi'}  |  ${data['sales'] ?? '-'}',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            currency.format(amount),
                                            style: TextStyle(
                                              color: paid
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFF0F172A),
                                              fontWeight: isMobile
                                                  ? FontWeight.w700
                                                  : FontWeight.w900,
                                              fontSize: isMobile ? 13 : 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${overdue ? 'JATUH TEMPO: ' : 'Tempo: '}${DateFormat('dd MMM yyyy').format(dueDate)}',
                                            style: TextStyle(
                                              color: overdue
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF64748B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if ((data['note']?.toString() ?? '')
                                              .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                data['note'].toString(),
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        _confirmAdmin(onConfirmed: () {
                                          if (value == 'paid') {
                                            _togglePaid(data['_id'], paid);
                                          } else if (value == 'edit') {
                                            _openForm(
                                              documentId: data['_id'],
                                              data: data,
                                            );
                                          } else if (value == 'delete') {
                                            _deleteItem(data['_id']);
                                          }
                                        });
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'paid',
                                          child: Text(
                                            paid
                                                ? 'Batalkan Lunas'
                                                : 'Tandai Lunas',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Hapus',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
          );
        },
      ),
    );
  }

  Widget _summaryCard(
      String title, String subtitle, String value, Color color, IconData icon,
      {required bool mobile, double? width}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? (mobile ? (screenWidth - 24 - 10) / 2 : 148.0);
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(mobile ? 9 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(mobile ? 12 : 16),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 5 : 7,
              vertical: mobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: mobile ? 14 : 13, color: color),
                SizedBox(width: mobile ? 4 : 5),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: mobile ? 10 : 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: mobile ? 11 : 9,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
