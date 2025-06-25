const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

admin.initializeApp();
const app = express();
app.use(express.json());

app.use(cors({
    origin: 'https://alvynstane.github.io',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type'],
}));

app.post('/create-user', async (req, res) => {
    console.log("Request Body:", req.body);

    const {
        email,
        password = "User123",
        no,
        name,
        nik,
        gender,
        dob,
        pob,
        position,
        address,
        joinDate,
        phone,
        isEditing,
        uid: existingUid
    } = req.body;

    if (!email) {
        return res.status(400).send({ error: 'Email is required.' });
    }
    try {
        let uid;

        if (isEditing && existingUid) {
            uid = existingUid;
        } else {
            const userRecord = await admin.auth().createUser({
                email,
                password,
                emailVerified: true,
            });
            uid = userRecord.uid;

            await admin.firestore().collection("users").doc(uid).set({
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        const profileData = {
            uid,
            no,
            name,
            nik,
            email,
            gender,
            dob,
            pob,
            position,
            address,
            joinDate,
            phone,
        };

        await admin.firestore()
            .collection("users")
            .doc(uid)
            .collection("profile")
            .doc(uid)
            .set(profileData, { merge: true });

        res.status(200).send({ uid });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});

app.post('/delete-user', async (req, res) => {
    const { uid } = req.body;

    if (!uid) {
        return res.status(400).send({ error: 'UID is required.' });
    }

    try {
        const userDocRef = admin.firestore().collection("users").doc(uid);

        const profileSnapshot = await userDocRef.collection("profile").get();
        const deletePromises = profileSnapshot.docs.map(doc => doc.ref.delete());
        await Promise.all(deletePromises);

        await userDocRef.delete();

        await admin.auth().deleteUser(uid);

        res.status(200).send({ message: `User ${uid} and Firestore data deleted successfully.` });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});

app.post('/edit-user', async (req, res) => {
    const { uid, newEmail } = req.body;

    if (!uid || !newEmail) {
        return res.status(400).send({ error: 'UID and new email are required.' });
    }

    try {
        await admin.auth().updateUser(uid, {
            email: newEmail,
        });

        const profileRef = admin.firestore().collection("users").doc(uid).collection("profile").doc(uid);
        await profileRef.set({ email: newEmail }, { merge: true });

        res.status(200).send({ message: `Email updated successfully for user ${uid}.` });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});

exports.api = functions.https.onRequest(app);

exports.onLeaveRequestUpdate = onDocumentUpdated('users/{userId}/leave_requests/{requestId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const { userId, requestId } = event.params;

    console.log(`Leave request update detected for user: ${userId}, request: ${requestId}`);
    console.log(`Before status: ${before.status}, After status: ${after.status}`);
    console.log(`attendanceGenerated: ${after.attendanceGenerated}`);

    if (after.leaveType !== "Attendance Request") {
        console.log("Not an Attendance Request. Skipping...");
        return
    };

    const attendanceRef = admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('attendance');

    if (before.status !== "Approved" && after.status === "Approved" && !after.attendanceGenerated) {
        console.log("Generating attendance records...");
        const startDateUTC = after.startDate.toDate();
        const endDateUTC = after.endDate.toDate();

        const start = new Date(startDateUTC.getTime() + 7 * 60 * 60 * 1000);
        const end = new Date(endDateUTC.getTime() + 7 * 60 * 60 * 1000);

        start.setHours(0, 0, 0, 0);
        end.setHours(0, 0, 0, 0);
        console.log(`Start date raw: ${start}`);
        console.log(`End date raw: ${end}`);

        let userEmail = after.userEmail;
        if (!userEmail) {
            const profileSnap = await admin.firestore()
                .collection("users")
                .doc(userId)
                .collection("profile")
                .doc(userId)
                .get();

            const profileData = profileSnap.data();
            userEmail = profileData?.email || "unknown";
        }

        const batch = admin.firestore().batch();

        while (start <= end) {
            const clockIn = new Date(Date.UTC(start.getFullYear(), start.getMonth(), start.getDate(), 2));
            const clockOut = new Date(Date.UTC(start.getFullYear(), start.getMonth(), start.getDate(), 10));

            console.log(`Adding attendance for ${start.toDateString()} | Clock In: ${clockIn} | Clock Out: ${clockOut}`);

            batch.set(attendanceRef.doc(), {
                activityType: 'Clock In',
                uploadedAt: admin.firestore.Timestamp.fromDate(clockIn),
                userEmail,
                url: "",
                late: false,
                noDaily: false,
                autoGenerated: true,
                requestId,
            });

            batch.set(attendanceRef.doc(), {
                activityType: 'Clock Out',
                uploadedAt: admin.firestore.Timestamp.fromDate(clockOut),
                userEmail,
                url: "",
                late: false,
                noDaily: false,
                autoGenerated: true,
                requestId,
            });

            start.setDate(start.getDate() + 1);
        }

        await batch.commit();
        console.log("Attendance records committed.");

        await event.data.after.ref.update({ attendanceGenerated: true });
        console.log(`Marked attendanceGenerated: true for request ${requestId}`);
    }

    if (before.status === "Approved" && after.status === "Rejected" && after.attendanceGenerated) {
        console.log("Deleting auto-generated attendance due to rejection...");

        const snapshot = await attendanceRef.where("requestId", "==", requestId).get();

        if (snapshot.empty) {
            console.log(`No attendance found for requestId: ${requestId}`);
        } else {
            const deleteBatch = admin.firestore().batch();
            snapshot.forEach(doc => {
                console.log(`Deleting attendance doc: ${doc.id}`);
                deleteBatch.delete(doc.ref);
            });

            await deleteBatch.commit();
            console.log("Attendance documents deleted.");
        }

        await event.data.after.ref.update({ attendanceGenerated: false });
        console.log("Marked attendanceGenerated: false");
    }
});

