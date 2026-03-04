/**
 * Billing API Utility
 * Handles communication with the billing system API
 */

const API_URL = process.env.BILLING_API_URL || 'https://billingftth.my.id/api';
const API_USERNAME = process.env.BILLING_API_USERNAME || 'ahmad@ajnusa.com';
const API_PASSWORD = process.env.BILLING_API_PASSWORD || 'password';

// Token cache for admin authentication
let adminToken: string | null = null;
let tokenExpiry: number = 0;

export interface Pelanggan {
  id: number;
  no_ktp: string;
  nama: string;
  alamat: string;
  alamat_2: string;
  tgl_instalasi: string;
  blok: string;
  unit: string;
  no_telp: string;
  email: string;
  id_brand: string;
  layanan: string;
  harga_layanan: {
    id_brand: string;
    brand: string;
    pajak: number;
    xendit_key_name: string;
  };
  created_at: string;
  updated_at: string;
}

export interface Langganan {
  id: number;
  pelanggan_id: number;
  paket: string;
  harga: number;
  status: string;
  tanggal_mulai: string;
}

export interface Invoice {
  id: number;
  pelanggan_id: number;
  invoice_number: string;
  total_harga: number;
  status_invoice: 'Lunas' | 'Belum Lunas' | 'Jatuh Tempo';
  tgl_jatuh_tempo: string;
  paid_at?: string;
  tgl_invoice?: string;
  metode_pembayaran?: string;
  payment_link?: string;
  brand?: string;
}

export interface CustomerData {
  pelanggan: Pelanggan;
  langganan: Langganan | null;
  invoices: Invoice[];
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

/**
 * Get admin access token for API calls
 * Uses token caching to avoid unnecessary login requests
 */
export async function getAdminToken(): Promise<string> {
  const now = Date.now();

  // Return cached token if still valid (with 5min buffer)
  if (adminToken && tokenExpiry > now + 300000) {
    return adminToken;
  }

  try {
    const formData = new URLSearchParams();
    formData.append('username', API_USERNAME);
    formData.append('password', API_PASSWORD!);

    const response = await fetch(`${API_URL}/auth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData.toString(),
      cache: 'no-store',
    });

    if (!response.ok) {
      throw new Error(`Authentication failed: ${response.status}`);
    }

    const data: AuthResponse = await response.json();

    // Cache the token
    adminToken = data.access_token;
    tokenExpiry = now + (data.expires_in * 1000);

    return data.access_token;
  } catch (error) {
    console.error('Error getting admin token:', error);
    throw error;
  }
}

/**
 * Search pelanggan by query using API search endpoint
 */
async function searchPelanggan(query: string): Promise<Pelanggan[]> {
  const token = await getAdminToken();

  const response = await fetch(`${API_URL}/pelanggan/?search=${encodeURIComponent(query)}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    cache: 'no-store',
  });

  if (!response.ok) {
    return [];
  }

  const result = await response.json();
  return result.data || [];
}

/**
 * Fetch customer data by email
 */
export async function getCustomerByEmail(email: string): Promise<CustomerData | null> {
  try {
    const results = await searchPelanggan(email);
    const pelanggan = results.find((p: Pelanggan) => p.email.toLowerCase() === email.toLowerCase());

    if (!pelanggan) {
      return null;
    }

    // Fetch related data
    const [langganan, invoices] = await Promise.all([
      getLanggananByPelangganId(pelanggan.id),
      getInvoicesByPelangganId(pelanggan.id),
    ]);

    return {
      pelanggan,
      langganan,
      invoices,
    };
  } catch (error) {
    console.error('Error fetching customer by email:', error);
    throw error;
  }
}

/**
 * Fetch customer data by phone number
 */
export async function getCustomerByPhone(phone: string): Promise<CustomerData | null> {
  try {
    // Extract the core phone number (removing +62, 62, 0) for searching
    let corePhone = phone.replace(/[-\s]/g, '');
    if (corePhone.startsWith('+62')) corePhone = corePhone.substring(3);
    else if (corePhone.startsWith('62')) corePhone = corePhone.substring(2);
    else if (corePhone.startsWith('0')) corePhone = corePhone.substring(1);

    // Search using the core phone number to get matches regardless of prefix
    const results = await searchPelanggan(corePhone);

    // Normalize both input and database numbers to standard '08...' format for comparison
    const normalizePhone = (num: string) => {
      let cleaned = num.replace(/[-\s]/g, '');
      if (cleaned.startsWith('+62')) cleaned = '0' + cleaned.substring(3);
      else if (cleaned.startsWith('62')) cleaned = '0' + cleaned.substring(2);
      else if (cleaned.startsWith('8')) cleaned = '0' + cleaned;
      return cleaned;
    };

    const normalizedTarget = normalizePhone(phone);

    const pelanggan = results.find((p: Pelanggan) => {
      if (!p.no_telp) return false;
      return normalizePhone(p.no_telp) === normalizedTarget;
    });

    if (!pelanggan) {
      return null;
    }

    const [langganan, invoices] = await Promise.all([
      getLanggananByPelangganId(pelanggan.id),
      getInvoicesByPelangganId(pelanggan.id),
    ]);

    return {
      pelanggan,
      langganan,
      invoices,
    };
  } catch (error) {
    console.error('Error fetching customer by phone:', error);
    throw error;
  }
}

/**
 * Fetch subscription data by customer ID
 */
export async function getLanggananByPelangganId(pelangganId: number): Promise<Langganan | null> {
  try {
    const token = await getAdminToken();

    const timestamp = Date.now();
    const response = await fetch(`${API_URL}/langganan/?pelanggan_id=${pelangganId}&_t=${timestamp}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      cache: 'no-store',
    });

    if (!response.ok) {
      console.error('API Response not OK:', response.status, response.statusText);
      return null;
    }

    const data = await response.json();
    const langgananData = data.data || data;
    if (Array.isArray(langgananData)) {
      const matchedLangganan = langgananData.find((l: Langganan) => l.pelanggan_id === pelangganId);
      return matchedLangganan || null;
    }
    return langgananData;
  } catch (error) {
    console.error('Error fetching langganan:', error);
    return null;
  }
}

/**
 * Fetch invoices by customer ID
 */
export async function getInvoicesByPelangganId(pelangganId: number): Promise<Invoice[]> {
  try {
    const token = await getAdminToken();

    const response = await fetch(`${API_URL}/invoices?pelanggan_id=${pelangganId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      cache: 'no-store',
    });

    if (!response.ok) {
      return [];
    }

    const data = await response.json();
    const invoicesData = data.data || data;
    const allInvoices = Array.isArray(invoicesData) ? invoicesData : [];

    return allInvoices.filter((inv: Invoice) => inv.pelanggan_id === pelangganId);
  } catch (error) {
    console.error('Error fetching invoices:', error);
    return [];
  }
}

/**
 * Verify customer credentials (email or phone)
 */
export async function verifyCustomer(identifier: string): Promise<CustomerData | null> {
  const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);

  if (isEmail) {
    return getCustomerByEmail(identifier);
  } else {
    return getCustomerByPhone(identifier);
  }
}
