import {onRequest, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
admin.initializeApp();
const db = admin.firestore();

const payhereSecret = defineSecret("PAYHERE_MERCHANT_SECRET");
const payhereMerchantId = defineSecret("PAYHERE_MERCHANT_ID");
const geminiApiKey = defineSecret("GEMINI_API_KEY");

const weatherApiKey = defineSecret("OPENWEATHER_API_KEY");

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
      logger.error("Signature mismatch", {
        local: localMd5sig,
        remote: md5sig,
      });
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

/*
  SECURE PROXY FUNCTIONS
  ----------------------
  These functions keep API keys on the server and use defineSecret.
*/

// 1. Gemini AI Proxy
export const getGeminiResponse = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    if (!request.auth) throw new Error("Unauthorized");

    const {prompt, history, systemInstruction} = request.data;
    const apiKey = geminiApiKey.value();

    logger.info("Gemini Request:", {prompt, historyCount: history?.length});

    try {
      const candidateModels = [
        "gemini-2.5-flash",
        "gemini-2.0-flash-001",
        "gemini-flash-latest",
      ];
      let lastErrorText = "No model attempts were made.";
      let lastStatus = -1;

      for (const model of candidateModels) {
        const url = "https://generativelanguage.googleapis.com/v1beta/models/" +
          `${model}:generateContent?key=${apiKey}`;

        const response = await fetch(url, {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify({
            contents: [
              ...(history || []),
              {role: "user", parts: [{text: prompt}]},
            ],
            system_instruction: systemInstruction ?
              {parts: [{text: systemInstruction}]} : undefined,
          }),
        });

        if (response.ok) {
          const data = await response.json();
          logger.info("Gemini Response received successfully", {model});
          return data;
        }

        const errorText = await response.text();
        lastErrorText = errorText;
        lastStatus = response.status;
        logger.error("Gemini API Error Response:", {
          model,
          status: response.status,
          error: errorText,
        });
      }

      throw new Error(`Gemini API returned ${lastStatus}: ${lastErrorText}`);
    } catch (error) {
      logger.error("Gemini Proxy Error:", error);
      throw new Error("Failed to get AI response");
    }
  });

// 2. OpenWeather Proxy
export const getWeatherData = onCall(
  {secrets: [weatherApiKey]},
  async (request) => {
    if (!request.auth) throw new Error("Unauthorized");

    const {lat, lon, mode} = request.data; // mode: 'weather' or 'forecast'
    const apiKey = weatherApiKey.value();
    const endpoint = mode === "forecast" ? "forecast" : "weather";

    try {
      const url = `https://api.openweathermap.org/data/2.5/${endpoint}?` +
        `lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
      const response = await fetch(url);
      const data = await response.json();
      return data;
    } catch (error) {
      logger.error("Weather Proxy Error:", error);
      throw new Error("Failed to get weather data");
    }
  });

// 3. PayHere Hash Generator
export const getPayhereHash = onCall(
  {secrets: [payhereSecret, payhereMerchantId]},
  async (request) => {
    if (!request.auth) throw new Error("Unauthorized");

    const {orderId, amount, currency} = request.data;
    const merchantId = payhereMerchantId.value();
    const merchantSecret = payhereSecret.value();

    // Format amount to 2 decimal places as required by PayHere
    const formattedAmount = parseFloat(amount).toFixed(2);

    // Formula: md5(merchant_id + order_id + amount + currency + md5(secret))
    const hashedSecret = crypto.createHash("md5")
      .update(merchantSecret)
      .digest("hex")
      .toUpperCase();

    const hashString = `${merchantId}${orderId}${formattedAmount}` +
      `${currency}${hashedSecret}`;

    const hash = crypto.createHash("md5")
      .update(hashString)
      .digest("hex")
      .toUpperCase();

    return {
      merchantId,
      hash,
      amount: formattedAmount,
    };
  });

