import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import path from 'path';

let firebaseApp: App | null = null;

export function getFirebaseAdmin(): App {
  if (firebaseApp) return firebaseApp;

  const apps = getApps();
  if (apps.length > 0) {
    firebaseApp = apps[0]!;
    return firebaseApp;
  }

  try {
    const keyPath = path.resolve(process.cwd(), 'portal-ajnusa-firebase-adminsdk-fbsvc-07b0313b9c.json');
    firebaseApp = initializeApp({
      credential: cert(keyPath),
    });
    console.log('[FirebaseAdmin] Initialized successfully with service account cert.');
  } catch (err: any) {
    console.warn('[FirebaseAdmin] Failed with cert file, trying default application credentials:', err?.message);
    firebaseApp = initializeApp();
  }

  return firebaseApp;
}

export async function sendFCMToTokens(
  tokens: string[],
  payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }
) {
  if (!tokens || tokens.length === 0) return { success: 0, failure: 0 };

  const app = getFirebaseAdmin();
  const messaging = getMessaging(app);

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: payload.data || {},
    android: {
      priority: 'high',
      notification: {
        channelId: payload.data?.type === 'chat' ? 'portal_chat_channel' : 'portal_invoice_channel',
        sound: payload.data?.type === 'chat' ? 'chat_notif' : 'default',
        priority: 'max',
      },
    },
  });

  console.log(`[FCM] Sent notifications: success=${response.successCount}, failure=${response.failureCount}`);
  return {
    success: response.successCount,
    failure: response.failureCount,
  };
}

