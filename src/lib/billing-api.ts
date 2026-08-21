/**
 * Billing API Utility
 * Handles communication with the billing system API
 */

const API_URL = process.env.BILLING_API_URL || 'https://jpo.jelantik.com/api/v1';
const API_KEY = process.env.BILLING_API_KEY;

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
  status_invoice: 'Lunas' | 'Belum Lunas' | 'Jatuh Tempo' | 'Kadaluarsa' | string;
  tgl_jatuh_tempo: string;
  paid_at?: string;
  tgl_invoice?: string;
  metode_pembayaran?: string;
  payment_link?: string;
  brand?: string;
  nama_pelanggan?: string;
}

export interface CustomerData {
  pelanggan: Pelanggan;
  langganan: Langganan | null;
  invoices: Invoice[];
}

/**
 * Get admin access token for API calls
 */
export async function getAdminToken(): Promise<string> {
  if (!API_KEY) {
    throw new Error('BILLING_API_KEY is not configured');
  }
  return API_KEY;
}

/**
 * Direct Ultra-Fast Single-Query Customer Lookup for Portal (V5 Optimized)
 */
export async function getCustomerDirectLookup(identifier: string): Promise<CustomerData | null> {
  try {
    const token = await getAdminToken();

    const response = await fetch(`${API_URL}/portal/customer/lookup?identifier=${encodeURIComponent(identifier)}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-API-Key': token,
        'Content-Type': 'application/json',
      },
      cache: 'no-store',
    });

    if (!response.ok) {
      return null;
    }

    const result = await response.json();
    if (result && result.data && result.data.pelanggan) {
      return {
        pelanggan: result.data.pelanggan,
        langganan: result.data.langganan || null,
        invoices: result.data.invoices || [],
      };
    }
    return null;
  } catch (error) {
    console.error('Error in direct customer lookup:', error);
    return null;
  }
}

/**
 * Search pelanggan by query using API search endpoint
 */
async function searchPelanggan(query: string): Promise<Pelanggan[]> {
  const token = await getAdminToken();

  const response = await fetch(`${API_URL}/pelanggan?search=${encodeURIComponent(query)}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-API-Key': token,
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
    // Try fast direct lookup first
    const directData = await getCustomerDirectLookup(email);
    if (directData) return directData;

    const results = await searchPelanggan(email);
    const pelanggan = results.find((p: Pelanggan) => p.email.toLowerCase() === email.toLowerCase());

    if (!pelanggan) {
      return null;
    }

    // Fetch related data
    const [langganan, invoices] = await Promise.all([
      getLanggananByPelangganId(pelanggan.id),
      getInvoicesByPelangganId(pelanggan.id, pelanggan.nama),
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
    // Try fast direct lookup first
    const directData = await getCustomerDirectLookup(phone);
    if (directData) return directData;

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
      getInvoicesByPelangganId(pelanggan.id, pelanggan.nama),
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
    const response = await fetch(`${API_URL}/langganan?pelanggan_id=${pelangganId}&_t=${timestamp}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-API-Key': token,
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
      const matchedLangganan = langgananData.find((l: any) => {
        const itemPelangganId = l.pelanggan_id || l.id_pelanggan;
        return String(itemPelangganId) == String(pelangganId);
      });
      return matchedLangganan || null;
    }
    return langgananData;
  } catch (error) {
    console.error('Error fetching langganan:', error);
    return null;
  }
}

/**
 * Fetch invoices by customer ID with multiple fallback strategies
 */
export async function getInvoicesByPelangganId(pelangganId: number, customerName?: string): Promise<Invoice[]> {
  try {
    const token = await getAdminToken();
    const timestamp = Date.now();
    
    const endpoints = ['/invoices'];
    let rawInvoices: any[] = [];
    
    for (const endpoint of endpoints) {
      const searchParams = new URLSearchParams({
        pelanggan_id: String(pelangganId),
        limit: '100',
        _t: String(timestamp)
      });

      const response = await fetch(`${API_URL}${endpoint}?${searchParams.toString()}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-API-Key': token,
          'Content-Type': 'application/json',
        },
        cache: 'no-store',
      });

      if (response.ok) {
        const data = await response.json();
        const foundArray = extractArray(data);
        if (foundArray.length > 0) {
          rawInvoices = foundArray;
          break;
        }
      }
    }

    function extractArray(data: any): any[] {
      if (Array.isArray(data)) return data;
      if (data.data && Array.isArray(data.data)) return data.data;
      if (data.invoices && Array.isArray(data.invoices)) return data.invoices;
      if (data.tagihan && Array.isArray(data.tagihan)) return data.tagihan;
      if (typeof data === 'object' && data !== null) {
        const possibleArray = Object.values(data).find(val => Array.isArray(val));
        return Array.isArray(possibleArray) ? possibleArray : [];
      }
      return [];
    }

    return rawInvoices.filter((inv: any) => {
      const invPelangganId = inv.pelanggan_id || inv.id_pelanggan || inv.customer_id;
      if (invPelangganId && String(invPelangganId) == String(pelangganId)) return true;
      if (customerName) {
        const invName = inv.nama_pelanggan || inv.pelanggan?.nama || inv.customer_name || inv.nama;
        if (invName && String(invName).toLowerCase().includes(customerName.toLowerCase())) return true;
      }
      return false;
    });
  } catch (error) {
    console.error('Error fetching invoices:', error);
    return [];
  }
}

/**
 * Verify customer credentials (email or phone)
 */
export async function verifyCustomer(identifier: string): Promise<CustomerData | null> {
  // Try direct ultra-fast lookup first
  const directData = await getCustomerDirectLookup(identifier);
  if (directData) {
    return directData;
  }

  const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);

  if (isEmail) {
    return getCustomerByEmail(identifier);
  } else {
    return getCustomerByPhone(identifier);
  }
}
