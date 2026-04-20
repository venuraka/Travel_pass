import {onRequest, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
admin.initializeApp();
const db = admin.firestore();

const payhereSecret = defineSecret("PAYHERE_MERCHANT_SECRET");

/*
  SCHEDULED MONTHLY PAYMENT REMINDERS
  ---------------------------------
  Runs every 24 hours to alert passengers whose payment day has arrived.
*/
export const scheduleMonthlyPaymentReminders = onSchedule("0 8 * * *",
  async () => {
    logger.info("Running monthly payment reminder task...");
    const today = new Date();
    const currentDay = today.getDate();

    try {
      const passengersSnap = await db.collection("passenger")
        .where("paymentType", "==", "Monthly")
        .get();

      if (passengersSnap.empty) {
        logger.info("No monthly passengers found.");
        return;
      }

      const reminderPromises = passengersSnap.docs.map(async (doc) => {
        const passenger = doc.data();
        const driverId = passenger.driverId;
        const fcmToken = passenger.fcmToken;

        if (!driverId || !fcmToken) return;

        const driverDoc = await db.collection("driver").doc(driverId).get();
        if (!driverDoc.exists) return;

        const driverData = driverDoc.data();
        // Convert Firestore Timestamp to Date
        const paymentDate = driverData?.paymentDate?.toDate();

        if (paymentDate && paymentDate.getDate() === currentDay) {
          // Match! Send notification
          const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
              title: "Monthly Payment Due",
              body: `Your travel payment for ${_getMonthName()} ` +
                   "is due today. Tap to pay.",
            },
            data: {
              screen: "payment",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "high_importance_channel",
              },
            },
          };

          await admin.messaging().send(message);
          logger.info(`Reminder sent to passenger: ${doc.id}`);
        }
      });

      await Promise.all(reminderPromises);
      logger.info("Schedule task completed.");
    } catch (error) {
      logger.error("Error in schedule task:", error);
    }
  });

/**
 * Returns the name of the current month.
 * @return {string} Month name.
 */
function _getMonthName() {
  const months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];
  return months[new Date().getMonth()];
}

/*
  SEND NOTIFICATION (CALLABLE)
  ---------------------------
  Sends a push notification to a list of device tokens.
  Optimized for high-priority delivery even on locked screens.
*/
export const sendNotification = onCall(async (request) => {
  // 1. Verify Authentication
  if (!request.auth) {
    throw new Error("The function must be called while authenticated.");
  }

  const {tokens, title, body, data} = request.data;

  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    logger.warn("No tokens provided for notification.");
    return {success: false, message: "No tokens provided"};
  }

  // 2. Construct Message
  // Using sendEachForMulticast (FCM v1 compatible)
  const message: admin.messaging.MulticastMessage = {
    notification: {
      title: title,
      body: body,
    },
    data: data || {},
    tokens: tokens,
    android: {
      priority: "high",
      notification: {
        sound: "default",
        priority: "high",
        channelId: "high_importance_channel", // Ensure this exists on device
      },
    },
    apns: {
      payload: {
        aps: {
          "content-available": 1,
          "mutable-content": 1,
          "sound": "default",
        },
      },
      headers: {
        "apns-priority": "10", // High priority for iOS
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Successfully sent ${response.successCount} notifications.`);

    const errors: {
      token: string,
      errorCode: string | undefined,
      message: string | undefined
    }[] = [];

    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const error = resp.error as admin.FirebaseError;
          logger.error(`Notification failed for token at index ${idx}:`, {
            token: tokens[idx],
            code: error?.code,
            message: error?.message,
          });

          errors.push({
            token: tokens[idx],
            errorCode: error?.code,
            message: error?.message,
          });
        }
      });
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      errors: errors,
    };
  } catch (error) {
    logger.error("Error sending notification:", error);
    throw new Error("Failed to send notification.");
  }
});

// Only export the functions you actually want to deploy.
// If helloWorld is not needed, you can remove it.

/*
  PAYHERE NOTIFICATION HANDLER
  ----------------------------
  This function handles the server-to-server POST request from PayHere
  when a payment is completed.
*/
export const payhereNotify = onRequest({secrets: [payhereSecret]},
  async (req, res) => {
    // 1. Verify Request Method
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // 2. Extract Data from Form Body
    const data = req.body;
    const merchantId = data.merchant_id;
    const orderId = data.order_id;
    const payhereAmount = data.payhere_amount;
    const payhereCurrency = data.payhere_currency;
    const statusCode = data.status_code;
    const md5sig = data.md5sig;

    // 3. Security Verification (MD5 Signature)
    const merchantSecret = payhereSecret.value();

    // Generate the local signature
    // Formula: strtoupper(md5(merchant_id + order_id + payhere_amount +
    // payhere_currency + status_code + strtoupper(md5(merchant_secret))))
    const hashedSecret = crypto.createHash("md5")
      .update(merchantSecret)
      .digest("hex")
      .toUpperCase();

    const amountFormatted = payhereAmount; // Example: '1000.00'

    const validationString = `${merchantId}${orderId}${amountFormatted}` +
    `${payhereCurrency}${statusCode}${hashedSecret}`;

    const localMd5sig = crypto.createHash("md5")
      .update(validationString)
      .digest("hex")
      .toUpperCase();

    if (localMd5sig !== md5sig) {
      logger.error("Signature mismatch", {local: localMd5sig, remote: md5sig});
      // Respond with 200 to stop PayHere from retrying
      res.status(400).send("Signature verification failed");
      return;
    }

    // 4. Update Database
    try {
      // Status Code 2 means "Success"
      if (parseInt(statusCode) === 2) {
        logger.info(`Payment Success for Order: ${orderId}`);

        // Extract passenger ID from order_id
        // (format: PAY-{passengerId}-{timestamp})
        const orderParts = orderId.split("-");
        const passengerId = orderParts[1] || "unknown";

        // Get passenger data
        const passengerDoc = await db.collection("passenger")
          .doc(passengerId).get();
        const passengerData = passengerDoc.data();

        // Get driver data
        let driverData = null;
        if (passengerData?.driverId) {
          const driverDoc = await db.collection("driver")
            .doc(passengerData.driverId).get();
          driverData = driverDoc.data();
        }

        // Save to payments collection with all details
        await db.collection("payments").doc(orderId).set({
          passengerId: passengerId,
          passengerName: passengerData?.name || "Unknown",
          driverId: passengerData?.driverId || "unknown",
          driverName: driverData?.name || "Unknown",
          orderId: orderId,
          status: "collected",
          paymentNo: data.payment_id,
          amount: payhereAmount,
          currency: payhereCurrency,
          method: data.method || "UNKNOWN",
          cardHolder: data.card_holder_name || "Unknown",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          date: new Date().toISOString(),
        });

        logger.info(`Payment recorded for passenger: ${passengerId}`);
      } else {
        logger.warn(
          `Payment Failed for Order: ${orderId}, Status: ${statusCode}`
        );
        await db.collection("payments").doc(orderId).set({
          orderId: orderId,
          status: "payment_failed",
          statusCode: statusCode,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // 5. Respond to PayHere
      res.status(200).send("OK");
    } catch (error) {
      logger.error("Error updating database", error);
      res.status(500).send("Internal Server Error");
    }
  });
