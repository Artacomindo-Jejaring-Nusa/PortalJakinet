/**
 * Session Management Utility
 * Handles customer session using encrypted cookies
 */

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import crypto from 'crypto';

const SESSION_COOKIE_NAME = 'portal_session';
const SESSION_DURATION = 24 * 60 * 60 * 1000; // 24 hours

export interface SessionData {
  customerId: number;
  customerEmail: string;
  customerPhone: string;
  customerName: string;
  expiresAt: number;
}

/**
 * Encrypt session data
 */
function encrypt(data: string): string {
  const secret = process.env.NEXTAUTH_SECRET || 'fallback-secret-change-this';
  const key = crypto.createHash('sha256').update(secret).digest(); // Always 32 bytes
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);

  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  return iv.toString('hex') + ':' + encrypted;
}

/**
 * Decrypt session data
 */
function decrypt(encryptedData: string): string | null {
  try {
    const secret = process.env.NEXTAUTH_SECRET || 'fallback-secret-change-this';
    const key = crypto.createHash('sha256').update(secret).digest(); // Always 32 bytes
    const parts = encryptedData.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = parts[1];

    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);

    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  } catch {
    return null;
  }
}

/**
 * Create a customer session
 */
export async function createSession(data: Omit<SessionData, 'expiresAt'>): Promise<void> {
  const cookieStore = await cookies();

  const sessionData: SessionData = {
    ...data,
    expiresAt: Date.now() + SESSION_DURATION,
  };

  const encrypted = encrypt(JSON.stringify(sessionData));

  cookieStore.set(SESSION_COOKIE_NAME, encrypted, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: SESSION_DURATION / 1000,
    path: '/',
  });
}

/**
 * Get current customer session
 */
export async function getSession(): Promise<SessionData | null> {
  const cookieStore = await cookies();
  const sessionCookie = cookieStore.get(SESSION_COOKIE_NAME);

  if (!sessionCookie) {
    return null;
  }

  const decrypted = decrypt(sessionCookie.value);
  if (!decrypted) {
    return null;
  }

  const session: SessionData = JSON.parse(decrypted);

  // Check if session has expired
  if (session.expiresAt < Date.now()) {
    await clearSession();
    return null;
  }

  return session;
}

/**
 * Clear customer session
 */
export async function clearSession(): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.delete(SESSION_COOKIE_NAME);
}

/**
 * Verify if customer is authenticated
 */
export async function isAuthenticated(): Promise<boolean> {
  const session = await getSession();
  return session !== null;
}

/**
 * Require authentication - redirects to login if not authenticated
 */
export async function requireAuth(): Promise<SessionData> {
  const session = await getSession();

  if (!session) {
    redirect('/login');
  }

  return session;
}
