// Script to create an admin user and set custom claim 'admin': true
// Usage: node create_admin.js <serviceAccountKey.json> <email> <password>

const admin = require('firebase-admin');

if (process.argv.length < 5) {
  console.error('Usage: node create_admin.js <serviceAccountKey.json> <email> <password>');
  process.exit(1);
}

const keyPath = process.argv[2];
const email = process.argv[3];
const password = process.argv[4];

const serviceAccount = require(require('path').resolve(keyPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function run() {
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
    });
    console.log('Created user:', userRecord.uid);
    await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
    console.log('Set custom claim admin=true');
  } catch (e) {
    console.error('Error:', e);
  }
}

run();
