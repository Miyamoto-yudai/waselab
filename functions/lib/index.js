"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendTestNotification = exports.removeFCMToken = exports.updateUserFCMToken = exports.sendExperimentCompletedNotification = exports.sendCancellationNotification = exports.sendReservationNotification = exports.sendMessageNotification = exports.sendEvaluationNotification = exports.onNotificationCreated = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
async function sendPushNotification(token, title, body, data) {
    try {
        const message = {
            notification: {
                title,
                body,
            },
            data: data || {},
            token,
            apns: {
                payload: {
                    aps: {
                        badge: 1,
                        sound: "default",
                    },
                },
            },
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    priority: "high",
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
        };
        const response = await messaging.send(message);
        console.log("Successfully sent push notification:", response);
        return response;
    }
    catch (error) {
        console.error("Error sending push notification:", error);
        throw error;
    }
}
exports.onNotificationCreated = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    try {
        const userDoc = await db.collection("users").doc(notification.userId).get();
        if (!userDoc.exists) {
            console.log(`User ${notification.userId} not found`);
            return null;
        }
        const userData = userDoc.data();
        if (!userData.fcmToken) {
            console.log(`User ${notification.userId} has no FCM token`);
            return null;
        }
        const notificationData = {
            notificationId: context.params.notificationId,
            type: notification.type,
            createdAt: notification.createdAt.toDate().toISOString(),
        };
        if (notification.data) {
            Object.keys(notification.data).forEach((key) => {
                notificationData[key] = String(notification.data[key]);
            });
        }
        await sendPushNotification(userData.fcmToken, notification.title, notification.message, notificationData);
        console.log(`Push notification sent to user ${notification.userId}`);
        return null;
    }
    catch (error) {
        console.error("Error in onNotificationCreated:", error);
        return null;
    }
});
exports.sendEvaluationNotification = functions.firestore
    .document("evaluations/{evaluationId}")
    .onCreate(async (snapshot, context) => {
    var _a;
    const evaluation = snapshot.data();
    try {
        const experimentDoc = await db
            .collection("experiments")
            .doc(evaluation.experimentId)
            .get();
        if (!experimentDoc.exists) {
            console.log(`Experiment ${evaluation.experimentId} not found`);
            return null;
        }
        const experiment = experimentDoc.data();
        const targetUserId = experiment === null || experiment === void 0 ? void 0 : experiment.creatorId;
        if (!targetUserId) {
            console.log("No creator ID found for experiment");
            return null;
        }
        const evaluatorDoc = await db
            .collection("users")
            .doc(evaluation.evaluatorId)
            .get();
        const evaluatorName = evaluatorDoc.exists
            ? ((_a = evaluatorDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || "参加者"
            : "参加者";
        const pointsAwarded = evaluation.isGood ? (evaluation.pointsAwarded || 1) : 0;
        const message = evaluation.isGood
            ? `${evaluatorName}さんから「${experiment.title}」に対してGood評価を受けました${pointsAwarded > 0 ? ` +${pointsAwarded} ポイント獲得` : ""}`
            : `${evaluatorName}さんから「${experiment.title}」に対してBad評価を受けました`;
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
            userId: targetUserId,
            type: "evaluation",
            title: evaluation.isGood
                ? `評価が届きました${pointsAwarded > 0 ? `（+${pointsAwarded} P）` : ""}`
                : "評価が届きました",
            message,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            data: {
                experimentId: evaluation.experimentId,
                evaluatorName,
                isGood: evaluation.isGood,
                pointsAwarded,
            },
        });
        console.log(`Evaluation notification created for user ${targetUserId}`);
        return null;
    }
    catch (error) {
        console.error("Error in sendEvaluationNotification:", error);
        return null;
    }
});
exports.sendMessageNotification = functions.firestore
    .document("conversations/{conversationId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
    var _a;
    const message = snapshot.data();
    const conversationId = context.params.conversationId;
    try {
        const conversationDoc = await db
            .collection("conversations")
            .doc(conversationId)
            .get();
        if (!conversationDoc.exists) {
            console.log(`Conversation ${conversationId} not found`);
            return null;
        }
        const conversation = conversationDoc.data();
        const participants = (conversation === null || conversation === void 0 ? void 0 : conversation.participants) || [];
        const targetUserId = participants.find((id) => id !== message.senderId);
        if (!targetUserId) {
            console.log("No recipient found for message");
            return null;
        }
        const senderDoc = await db.collection("users").doc(message.senderId).get();
        const senderName = senderDoc.exists
            ? ((_a = senderDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || "ユーザー"
            : "ユーザー";
        const messagePreview = message.text.length > 50
            ? message.text.substring(0, 50) + "..."
            : message.text;
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
            userId: targetUserId,
            type: "message",
            title: "新しいメッセージ",
            message: `${senderName}さん: ${messagePreview}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            data: {
                conversationId,
                senderName,
            },
        });
        console.log(`Message notification created for user ${targetUserId}`);
        return null;
    }
    catch (error) {
        console.error("Error in sendMessageNotification:", error);
        return null;
    }
});
exports.sendReservationNotification = functions.firestore
    .document("reservations/{reservationId}")
    .onCreate(async (snapshot, context) => {
    var _a;
    const reservation = snapshot.data();
    try {
        const experimentDoc = await db
            .collection("experiments")
            .doc(reservation.experimentId)
            .get();
        if (!experimentDoc.exists) {
            console.log(`Experiment ${reservation.experimentId} not found`);
            return null;
        }
        const experiment = experimentDoc.data();
        const creatorId = experiment === null || experiment === void 0 ? void 0 : experiment.creatorId;
        if (!creatorId) {
            console.log("No creator ID found for experiment");
            return null;
        }
        const participantDoc = await db
            .collection("users")
            .doc(reservation.userId)
            .get();
        const participantName = participantDoc.exists
            ? ((_a = participantDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || "参加者"
            : "参加者";
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
            userId: creatorId,
            type: "experiment_joined",
            title: "実験に参加者が加わりました",
            message: `${participantName}さんが「${experiment.title}」に参加しました`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            data: {
                experimentId: reservation.experimentId,
                participantName,
            },
        });
        console.log(`Reservation notification created for user ${creatorId}`);
        return null;
    }
    catch (error) {
        console.error("Error in sendReservationNotification:", error);
        return null;
    }
});
exports.sendCancellationNotification = functions.firestore
    .document("reservations/{reservationId}")
    .onDelete(async (snapshot, context) => {
    var _a;
    const reservation = snapshot.data();
    try {
        const experimentDoc = await db
            .collection("experiments")
            .doc(reservation.experimentId)
            .get();
        if (!experimentDoc.exists) {
            console.log(`Experiment ${reservation.experimentId} not found`);
            return null;
        }
        const experiment = experimentDoc.data();
        const creatorId = experiment === null || experiment === void 0 ? void 0 : experiment.creatorId;
        if (!creatorId) {
            console.log("No creator ID found for experiment");
            return null;
        }
        const participantDoc = await db
            .collection("users")
            .doc(reservation.userId)
            .get();
        const participantName = participantDoc.exists
            ? ((_a = participantDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || "参加者"
            : "参加者";
        const message = reservation.cancellationReason
            ? `${participantName}さんが「${experiment.title}」の予約をキャンセルしました。理由: ${reservation.cancellationReason}`
            : `${participantName}さんが「${experiment.title}」の予約をキャンセルしました`;
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
            userId: creatorId,
            type: "experiment_cancelled",
            title: "予約がキャンセルされました",
            message,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            data: {
                experimentId: reservation.experimentId,
                participantName,
                reason: reservation.cancellationReason,
            },
        });
        console.log(`Cancellation notification created for user ${creatorId}`);
        return null;
    }
    catch (error) {
        console.error("Error in sendCancellationNotification:", error);
        return null;
    }
});
exports.sendExperimentCompletedNotification = functions.firestore
    .document("experiments/{experimentId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== "completed" && after.status === "completed") {
        try {
            const creatorId = after.creatorId;
            const notificationRef = db.collection("notifications").doc();
            await notificationRef.set({
                userId: creatorId,
                type: "experiment_completed",
                title: "実験が終了しました",
                message: `「${after.title}」が終了しました。参加者の評価をお願いします`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                data: {
                    experimentId: context.params.experimentId,
                },
            });
            console.log(`Experiment completed notification created for user ${creatorId}`);
            return null;
        }
        catch (error) {
            console.error("Error in sendExperimentCompletedNotification:", error);
            return null;
        }
    }
    return null;
});
exports.updateUserFCMToken = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = context.auth.uid;
    const { token } = data;
    if (!token) {
        throw new functions.https.HttpsError("invalid-argument", "FCM token is required");
    }
    try {
        await db.collection("users").doc(userId).update({
            fcmToken: token,
            fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`FCM token updated for user ${userId}`);
        return { success: true };
    }
    catch (error) {
        console.error("Error updating FCM token:", error);
        throw new functions.https.HttpsError("internal", "Failed to update FCM token");
    }
});
exports.removeFCMToken = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = context.auth.uid;
    try {
        await db.collection("users").doc(userId).update({
            fcmToken: admin.firestore.FieldValue.delete(),
            fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`FCM token removed for user ${userId}`);
        return { success: true };
    }
    catch (error) {
        console.error("Error removing FCM token:", error);
        throw new functions.https.HttpsError("internal", "Failed to remove FCM token");
    }
});
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = context.auth.uid;
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User not found");
        }
        const userData = userDoc.data();
        if (!userData.fcmToken) {
            throw new functions.https.HttpsError("failed-precondition", "No FCM token found for user");
        }
        await sendPushNotification(userData.fcmToken, "テスト通知", "プッシュ通知が正常に動作しています！", {
            type: "test",
            timestamp: new Date().toISOString(),
        });
        return { success: true, message: "Test notification sent successfully" };
    }
    catch (error) {
        console.error("Error sending test notification:", error);
        throw new functions.https.HttpsError("internal", "Failed to send test notification");
    }
});
//# sourceMappingURL=index.js.map