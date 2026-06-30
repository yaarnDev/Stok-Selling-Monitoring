Functions deployment

1) From project root install functions dependencies:

```bash
cd functions
npm install
```

2) Deploy functions to Firebase:

```bash
firebase deploy --only functions
```

This Cloud Function listens for updates on `stocks/{stockId}` and writes an entry to `stock_logs` recording the diff, timestamps, and (if present) `lastUpdatedBy` uid.
