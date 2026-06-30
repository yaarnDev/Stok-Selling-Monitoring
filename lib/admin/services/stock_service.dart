import 'dart:async';

// Placeholder service for stock operations. Replace with Firestore calls.
class StockService {
  Future<void> updateStock(String stockId, int newQty) async {
    // simulate network / db latency
    await Future.delayed(const Duration(milliseconds: 300));
    // In real implementation, update Firestore document here
  }
}
