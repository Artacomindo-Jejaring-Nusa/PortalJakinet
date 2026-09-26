const admin = require('firebase-admin');

const serviceAccount = require('./portal-ajnusa-firebase-adminsdk-fbsvc-07b0313b9c.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const fcmToken = process.argv[2];

if (!fcmToken) {
  console.log('Usage: node send_fcm.js <FCM_DEVICE_TOKEN>');
  process.exit(1);
}

const message = {
  notification: {
    title: '📄 Terbit Invoice Baru!',
    body: 'Invoice #JELANTIKNAGRAK/ftth/AHMADRI... senilai Rp 150.000 telah diterbitkan.'
  },
  data: {
    invoice_number: 'JELANTIKNAGRAK/ftth/AHMADRI',
    total: '150000',
    type: 'invoice_issued'
  },
  android: {
    priority: 'high',
    notification: {
      channelId: 'portal_invoice_channel',
      sound: 'default'
    }
  },
  token: fcmToken
};

admin.messaging().send(message)
  .then(response => {
    console.log('✅ SUCCESS: Sent FCM notification message ID:', response);
  })
  .catch(error => {
    console.error('❌ Error sending FCM notification:', error);
  });
