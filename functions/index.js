const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Audit log: whenever a stock document is updated, write a log entry
exports.onStockUpdate = functions.firestore
  .document('stocks/{stockId}')
  .onUpdate(async (change, context) => {
    const stockId = context.params.stockId;
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    // Prepare a friendly diff
    const diff = {};
    Object.keys(after).forEach((k) => {
      if (JSON.stringify(before[k]) !== JSON.stringify(after[k])) {
        diff[k] = { before: before[k], after: after[k] };
      }
    });

    const log = {
      stockId,
      changedAt: admin.firestore.FieldValue.serverTimestamp(),
      changedBy: after.lastUpdatedBy || null,
      diff,
      beforeSnapshot: before,
      afterSnapshot: after,
    };

    await db.collection('stock_logs').add(log);
    return null;
  });
