const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const TOPIC = "pengumuman-kampus";

exports.notifyAllOnAnnouncementCreated = onDocumentCreated(
  {
    document: "announcements/{announcementId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const announcement = snapshot.data() || {};

    // Draft tidak dikirim. Trigger ini khusus dokumen baru yang langsung published.
    if (announcement.isPublished === false) {
      logger.info("Announcement baru masih draft; push dilewati.", {
        announcementId: event.params.announcementId,
      });
      return;
    }

    const announcementId = event.params.announcementId;
    const title = String(announcement.title || "Pengumuman Kampus").slice(0, 100);
    const content = String(announcement.content || announcement.body || "");
    const body = content.length > 180 ? `${content.slice(0, 177)}...` : content;

    const message = {
      topic: TOPIC,
      notification: {
        title,
        body: body || "Ada pengumuman baru. Ketuk untuk melihat detail.",
      },
      data: {
        type: "announcement_created",
        id: announcementId,
        route: `/pengumuman/${announcementId}`,
        title,
        body: body || "Ada pengumuman baru.",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "pengumuman_bell_small_v3",
          sound: "bell_small",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "bell_small.wav",
          },
        },
      },
    };

    const messageId = await admin.messaging().send(message);
    logger.info("Push pengumuman terkirim ke topik.", {
      announcementId,
      messageId,
    });
  }
);
