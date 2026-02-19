/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Only export the functions you actually want to deploy.
// If helloWorld is not needed, you can remove it.

/*
  PAYHERE NOTIFICATION HANDLER
  ----------------------------
  This function handles the server-to-server POST request from PayHere
  when a payment is completed.
*/
export const payhereNotify = onRequest(async (req, res) => {
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
  // TODO: Replace with your actual Merchant Secret from PayHere Dashboard
  // IMPORTANT: This should be the 'Merchant Secret' from your account, NOT
  // the 'App Secret'.
  const merchantSecret = "Mjg1MTk3NzYxMjM5MTE0NTU4MTYxMTM4MDY1NzYwOTE3MzE2Mzgy";

  // Generate the local signature
  // Formula: strtoupper(md5(merchant_id + order_id + payhere_amount +
  // payhere_currency + status_code + strtoupper(md5(merchant_secret))))
  const hashedSecret = crypto.createHash("md5")
    .update(merchantSecret)
    .digest("hex")
    .toUpperCase();

  const amountFormatted = payhereAmount; // PayHere sends amount like '1000.00'

  const validationString = `${merchantId}${orderId}${amountFormatted}` +
        `${payhereCurrency}${statusCode}${hashedSecret}`;

  const localMd5sig = crypto.createHash("md5")
    .update(validationString)
    .digest("hex")
    .toUpperCase();

  if (localMd5sig !== md5sig) {
    logger.error("Signature mismatch", {local: localMd5sig, remote: md5sig});
    // Respond with 200 to stop PayHere from retrying (since it's an
    // invalid request anyway)
    // or 400 if you want them to know it failed.
    res.status(400).send("Signature verification failed");
    return;
  }

  // 4. Update Database
  try {
    // Status Code 2 means "Success"
    if (parseInt(statusCode) === 2) {
      logger.info(`Payment Success for Order: ${orderId}`);

      // Update Firestore
      // Assumption: You have a 'payments' collection where 'order_id' is
      // the document ID
      // You might need to adjust this path based on your data model.
      await db.collection("payments").doc(orderId).set({
        status: "PAID",
        amount: payhereAmount,
        currency: payhereCurrency,
        method: data.method, // e.g., 'VISA'
        card_holder: data.card_holder_name,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        raw_response: data,
      }, {merge: true});
    } else {
      logger.warn(
        `Payment Failed/Cancelled for Order: ${orderId}, Status: ${statusCode}`
      );
      await db.collection("payments").doc(orderId).set({
        status: "FAILED",
        statusCode: statusCode,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    }

    // 5. Respond to PayHere
    res.status(200).send("OK");
  } catch (error) {
    logger.error("Error updating database", error);
    res.status(500).send("Internal Server Error");
  }
});
