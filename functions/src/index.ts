/**
 * 封神アプリ — Cloud Functions (v2)
 *
 * Firestore の notifications コレクションに新しいドキュメントが作成されると、
 * 対象ユーザーの FCM トークンを取得してプッシュ通知を送信する。
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();
setGlobalOptions({region: "asia-northeast1"});

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * notifications コレクションへの新規ドキュメント作成をトリガーに
 * プッシュ通知を送信する Cloud Function
 */
export const sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No snapshot data");
      return;
    }
    const data = snap.data();
    if (!data) {
      logger.warn("No data in notification document");
      return;
    }

    const toUid: string = data.toUid;
    const title: string = data.title || "封神";
    const body: string = data.body || "";
    const payload: Record<string, string> = {};

    // payload の値を全て string に変換（FCM の data は string のみ受け付ける）
    if (data.payload && typeof data.payload === "object") {
      for (const [key, value] of Object.entries(data.payload)) {
        payload[key] = String(value);
      }
    }
    payload["notificationType"] = data.type || "";

    // 送信先ユーザーの FCM トークンを取得
    const userDoc = await db.collection("users").doc(toUid).get();
    if (!userDoc.exists) {
      logger.warn(`User ${toUid} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken: string | undefined = userData?.fcmToken;

    if (!fcmToken) {
      logger.info(
        `User ${toUid} has no FCM token, skipping push notification`
      );
      return;
    }

    // プッシュ通知を送信
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: payload,
      android: {
        priority: "high",
        notification: {
          channelId: "fujin_notifications",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await messaging.send(message);
      logger.info(
        `Push notification sent to ${toUid}: ${response}`
      );
    } catch (error: unknown) {
      if (
        error instanceof Error &&
        "code" in error &&
        ((error as {code: string}).code ===
          "messaging/registration-token-not-registered" ||
          (error as {code: string}).code ===
            "messaging/invalid-registration-token")
      ) {
        // トークンが無効 → Firestore から削除
        logger.warn(
          `Invalid FCM token for user ${toUid}, removing token`
        );
        await db.collection("users").doc(toUid).update({
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
        });
      } else {
        logger.error(
          `Failed to send push notification to ${toUid}:`,
          error
        );
      }
    }
  });
