const admin = require("firebase-admin");
const fs = require("fs");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function exportData() {
  const allData = {};

  const collections = await db.listCollections();
  for (const collection of collections) {
    const collectionName = collection.id;
    allData[collectionName] = [];

    const snapshot = await collection.get();
    for (const doc of snapshot.docs) {
      const docData = { id: doc.id, ...doc.data(), subcollections: {} };

      const subcollections = await doc.ref.listCollections();
      for (const subcol of subcollections) {
        const subcolSnapshot = await subcol.get();
        docData.subcollections[subcol.id] = [];

        subcolSnapshot.forEach(subdoc => {
          docData.subcollections[subcol.id].push({
            id: subdoc.id,
            ...subdoc.data()
          });
        });
      }

      allData[collectionName].push(docData);
    }
  }

  fs.writeFileSync("firestore-with-subcollections.json", JSON.stringify(allData, null, 2));
  console.log("Export complete: firestore-with-subcollections.json");
}

exportData();
