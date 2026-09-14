/**
 * Generate Invoice PDF API Route
 * GET /api/invoice/[id]/pdf
 */

import { NextRequest, NextResponse } from 'next/server';
import { getCustomerByEmail, getCustomerByPhone } from '@/lib/billing-api';
import { getSession } from '@/lib/session';
import fs from 'fs';
import path from 'path';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const invoiceId = parseInt(id);

    if (isNaN(invoiceId)) {
      return NextResponse.json({ error: 'Invalid invoice ID' }, { status: 400 });
    }

    // Get session to identify customer
    const session = await getSession();
    let customerPhone = session?.customerPhone;
    let customerEmail = session?.customerEmail;

    if (!session) {
      // Fallback: Check query parameters for authentication
      const queryPhone = request.nextUrl.searchParams.get('phone');
      const queryEmail = request.nextUrl.searchParams.get('email');
      if (queryPhone) {
        customerPhone = queryPhone;
      }
      if (queryEmail) {
        customerEmail = queryEmail;
      }
      
      if (!customerPhone && !customerEmail) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
      }
    }

    // Get customer data
    let customerData = null;
    if (customerEmail) {
      customerData = await getCustomerByEmail(customerEmail);
    }
    if (!customerData && customerPhone) {
      customerData = await getCustomerByPhone(customerPhone);
    }

    if (!customerData) {
      return NextResponse.json({ error: 'Customer not found' }, { status: 404 });
    }

    // Find the invoice
    const invoice = customerData.invoices.find((inv) => inv.id === invoiceId);

    if (!invoice) {
      return NextResponse.json({ error: 'Invoice not found' }, { status: 404 });
    }

    // Read logo image and convert to base64 for embedding in HTML
    let logoBase64 = '';
    try {
      const brandName = customerData.pelanggan.harga_layanan?.brand?.toUpperCase() || '';
      const brandId = customerData.pelanggan.id_brand?.toLowerCase() || '';
      const isJelantik = brandName.includes('JELANTIK') || brandId === 'ajn-02' || brandId === 'ajn-03';
      const logoFilename = isJelantik ? 'jelantik.webp' : 'jakinet.png';
      const logoMime = isJelantik ? 'image/webp' : 'image/png';

      const logoPath = path.join(process.cwd(), 'public', 'images', 'icons', logoFilename);
      const logoBuffer = fs.readFileSync(logoPath);
      logoBase64 = `data:${logoMime};base64,${logoBuffer.toString('base64')}`;
    } catch (err) {
      console.error('Could not read logo file:', err);
    }

    // Generate HTML for the invoice
    const html = generateInvoiceHTML(invoice, customerData, logoBase64);

    // Return HTML as response (browser will handle PDF generation via print)
    return new NextResponse(html, {
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Content-Disposition': `inline; filename="invoice-${invoice.invoice_number}.html"`,
      },
    });
  } catch (error) {
    console.error('Error generating invoice PDF:', error);
    return NextResponse.json({ error: 'Failed to generate invoice' }, { status: 500 });
  }
}

function generateInvoiceHTML(invoice: any, customerData: any, logoBase64: string): string {
  const pelanggan = customerData.pelanggan;

  const brandName = pelanggan.harga_layanan?.brand?.toUpperCase() || '';
  const brandId = pelanggan.id_brand?.toLowerCase() || '';
  const isJelantik = brandName.includes('JELANTIK') || brandId === 'ajn-02' || brandId === 'ajn-03';

  const compName = isJelantik ? 'JELANTIK' : 'JAKINET';
  const compInitials = isJelantik ? 'JL' : 'JK';

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('id-ID', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatMonthYear = (dateString: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('id-ID', {
      year: 'numeric',
      month: 'long'
    });
  };

  const taxRate = pelanggan.harga_layanan?.pajak || 0;
  const total = invoice.total_harga;
  const subtotal = taxRate > 0 ? total / (1 + taxRate/100) : total;
  const taxAmount = total - subtotal;

  const isLunas = invoice.status_invoice === 'Lunas';
  const statusColor = isLunas ? '#10b981' : '#f59e0b';

  return `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice - ${invoice.invoice_number}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }

    body {
      background: #f8fafc;
      padding: 24px 16px;
      color: #1e293b;
      line-height: 1.5;
    }

    .top-action-bar {
      max-width: 800px;
      margin: 0 auto 16px auto;
    }

    .top-bar-content {
      display: flex;
      gap: 12px;
      align-items: center;
      justify-content: flex-end;
    }

    .top-bar-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 18px;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
      text-decoration: none;
      border: none;
      transition: all 0.2s ease;
    }

    .top-bar-btn.print-btn {
      background: #2563eb;
      color: white;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
    }
    .top-bar-btn.print-btn:hover {
      background: #1d4ed8;
    }

    .top-bar-btn.pay-btn {
      background: #16a34a;
      color: white;
      box-shadow: 0 2px 8px rgba(22, 163, 74, 0.25);
    }
    .top-bar-btn.pay-btn:hover {
      background: #15803d;
    }

    .invoice-container {
      max-width: 800px;
      margin: 0 auto;
      background: white;
      padding: 36px 40px;
      border-radius: 12px;
      border: 1px solid #e2e8f0;
      box-shadow: 0 4px 20px rgba(0,0,0,0.05);
      position: relative;
      overflow: hidden;
    }

    .invoice-container::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 6px;
      background: #dc2626;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 24px;
      gap: 16px;
    }

    .brand-section {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .logo-box {
      width: 52px;
      height: 52px;
      border-radius: 10px;
      overflow: hidden;
      flex-shrink: 0;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      color: #dc2626;
    }

    .logo-box img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }

    .company-info h1 {
      font-size: 22px;
      font-weight: 800;
      color: #b91c1c;
      letter-spacing: -0.02em;
      margin-bottom: 2px;
    }

    .company-info p {
      color: #64748b;
      font-size: 13px;
      font-weight: 500;
    }

    .secondary-logo {
      text-align: right;
    }

    .hr-divider {
      border: none;
      border-top: 1px solid #e2e8f0;
      margin: 20px 0;
    }

    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 24px;
    }

    .info-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      padding: 18px;
    }

    .info-card h3 {
      font-size: 11px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #ef4444;
      margin-bottom: 12px;
      padding-bottom: 6px;
      border-bottom: 2px solid #ef4444;
      display: inline-block;
    }

    .info-row {
      display: flex;
      margin-bottom: 8px;
      font-size: 13px;
      line-height: 1.4;
    }

    .info-row:last-child {
      margin-bottom: 0;
    }

    .info-label {
      flex: 0 0 105px;
      color: #64748b;
      font-weight: 500;
    }

    .info-value {
      flex: 1;
      font-weight: 700;
      color: #1e293b;
      word-break: break-word;
    }

    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
    }

    .items-table th {
      text-align: left;
      background: #f8fafc;
      padding: 12px 16px;
      font-size: 11px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #475569;
      border-top: 1px solid #e2e8f0;
      border-bottom: 2px solid #e2e8f0;
    }

    .items-table td {
      padding: 14px 16px;
      font-size: 14px;
      border-bottom: 1px solid #f1f5f9;
    }

    .items-table .text-right {
      text-align: right;
    }

    .summary-section {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      gap: 8px;
      margin-bottom: 24px;
    }

    .summary-row {
      display: flex;
      width: 250px;
      justify-content: space-between;
      font-size: 14px;
      color: #64748b;
    }

    .summary-row.total {
      margin-top: 4px;
      padding-top: 10px;
      border-top: 2px solid #e2e8f0;
      color: #1e293b;
      font-size: 18px;
      font-weight: 800;
    }

    .notes-box {
      background: #fffbeb;
      border: 1px solid #fef3c7;
      border-radius: 8px;
      padding: 15px;
      margin-bottom: 20px;
    }

    .notes-box strong {
      display: block;
      font-size: 13px;
      color: #92400e;
      margin-bottom: 4px;
    }

    .notes-box p {
      font-size: 13px;
      color: #b45309;
    }

    .payment-status-overlay {
      position: absolute;
      top: 90px;
      right: 24px;
      transform: rotate(-10deg);
      border: 4px solid ${statusColor};
      color: ${statusColor};
      padding: 6px 18px;
      font-size: 24px;
      font-weight: 900;
      text-transform: uppercase;
      opacity: 0.2;
      pointer-events: none;
      border-radius: 10px;
      letter-spacing: 3px;
      z-index: 1;
    }

    .footer {
      text-align: center;
      margin-top: 30px;
      color: #64748b;
      font-size: 12px;
    }

    .footer p {
      margin-bottom: 4px;
    }

    .footer strong {
      color: #dc2626;
    }

    .payment-button {
      display: block;
      width: 100%;
      text-align: center;
      background: #dc2626;
      color: white;
      text-decoration: none;
      padding: 14px;
      border-radius: 8px;
      font-weight: 700;
      font-size: 15px;
      margin-bottom: 15px;
    }

    /* ================= RESPONSIVE DESIGN (MOBILE & TABLET) ================= */
    @media (max-width: 640px) {
      body {
        padding: 10px 8px;
      }
      .top-action-bar {
        margin-bottom: 10px;
      }
      .top-bar-content {
        justify-content: center;
        width: 100%;
      }
      .top-bar-btn {
        flex: 1;
        justify-content: center;
        padding: 10px 12px;
        font-size: 13px;
      }
      .invoice-container {
        padding: 20px 14px;
        border-radius: 10px;
      }
      .header {
        flex-direction: column;
        align-items: flex-start;
        gap: 10px;
      }
      .secondary-logo {
        display: none;
      }
      .company-info h1 {
        font-size: 19px;
      }
      .company-info p {
        font-size: 12px;
      }
      .info-grid {
        grid-template-columns: 1fr;
        gap: 12px;
      }
      .info-card {
        padding: 14px 12px;
      }
      .info-row {
        font-size: 12px;
      }
      .info-label {
        flex: 0 0 95px;
      }
      .payment-status-overlay {
        top: 50px;
        right: 12px;
        font-size: 16px;
        padding: 4px 10px;
        border-width: 3px;
        letter-spacing: 2px;
      }
      .items-table th, .items-table td {
        padding: 10px 8px;
        font-size: 12px;
      }
      .summary-row {
        width: 100%;
        max-width: 260px;
        font-size: 13px;
      }
      .summary-row.total {
        font-size: 16px;
      }
    }

    @media print {
      @page {
        size: A4;
        margin: 10mm;
      }
      body {
        background: white;
        padding: 0;
        margin: 0;
      }
      .invoice-container {
        box-shadow: none;
        padding: 0;
        margin: 0 auto;
        width: 100%;
        max-width: none;
        border-radius: 0;
        border: none;
      }
      .invoice-container::before {
        display: none;
      }
      .no-print {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="top-action-bar no-print">
    <div class="top-bar-content">
      <button class="top-bar-btn print-btn" onclick="window.print()">
        <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
        </svg>
        <span>Cetak / Simpan PDF</span>
      </button>
      ${!isLunas && invoice.payment_link ? `
      <a href="${invoice.payment_link}" target="_blank" class="top-bar-btn pay-btn">
        <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
        <span>Bayar Sekarang</span>
      </a>
      ` : ''}
    </div>
  </div>

  <div class="invoice-container">
    <div class="payment-status-overlay">${invoice.status_invoice}</div>

    <div class="header">
      <div class="brand-section">
        <div class="logo-box">${logoBase64 ? `<img src="${logoBase64}" alt="${compName} Logo" />` : compInitials}</div>
        <div class="company-info">
          <h1>${compName}</h1>
          <p>Internet Service Provider</p>
          <p>Telp: 082223616884</p>
        </div>
      </div>
      <div class="secondary-logo">
        <div style="font-weight: 800; font-size: 20px; color: #cbd5e1;">INVOICE</div>
      </div>
    </div>

    <hr class="hr-divider" />

    <div class="info-grid">
      <div class="info-card">
        <h3>INFORMASI PELANGGAN</h3>
        <div class="info-row">
          <div class="info-label">ID Pelanggan:</div>
          <div class="info-value">#${pelanggan.id}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Nama:</div>
          <div class="info-value">${pelanggan.nama}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Alamat:</div>
          <div class="info-value">${pelanggan.alamat}${pelanggan.blok ? `, Blok ${pelanggan.blok}, Unit ${pelanggan.unit}` : ''}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Telepon:</div>
          <div class="info-value">${pelanggan.no_telp}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Paket:</div>
          <div class="info-value">${pelanggan.layanan}</div>
        </div>
      </div>

      <div class="info-card">
        <h3>INFORMASI TAGIHAN</h3>
        <div class="info-row">
          <div class="info-label">ID Invoice:</div>
          <div class="info-value">${invoice.invoice_number}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Periode:</div>
          <div class="info-value">${formatMonthYear(invoice.tgl_invoice || invoice.tgl_jatuh_tempo)}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Terbit:</div>
          <div class="info-value">${formatDate(invoice.tgl_invoice || invoice.tgl_jatuh_tempo)}</div>
        </div>
        <div class="info-row">
          <div class="info-label">Jatuh Tempo:</div>
          <div class="info-value">${formatDate(invoice.tgl_jatuh_tempo)}</div>
        </div>
      </div>
    </div>

    <table class="items-table">
      <thead>
        <tr>
          <th>Deskripsi</th>
          <th class="text-right">Jumlah</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>
            <div style="font-weight: 700;">Biaya Langganan (${pelanggan.layanan})</div>
            <div style="font-size: 13px; color: #64748b; margin-top: 4px;">Periode layanan internet ${formatMonthYear(invoice.tgl_invoice || invoice.tgl_jatuh_tempo)}</div>
          </td>
          <td class="text-right" style="font-weight: 600;">${formatCurrency(subtotal)}</td>
        </tr>
      </tbody>
    </table>

    <div class="summary-section">
      <div class="summary-row">
        <span>Harga</span>
        <span>${formatCurrency(subtotal)}</span>
      </div>
      <div class="summary-row">
        <span>PPN (${taxRate}%)</span>
        <span>${formatCurrency(taxAmount)}</span>
      </div>
      <div class="summary-row total">
        <span>Total</span>
        <span>${formatCurrency(total)}</span>
      </div>
    </div>

    ${!isLunas ? `
    <div class="notes-box">
      <strong>Catatan:</strong>
      <p>Tagihan ini belum dibayar. Silakan lakukan pembayaran sebelum tanggal jatuh tempo melalui link pembayaran di bawah ini.</p>
    </div>

    ${invoice.payment_link ? `
      <a href="${invoice.payment_link}" target="_blank" class="payment-button no-print">BAYAR SEKARANG</a>
    ` : ''}
    ` : `
    <div class="notes-box" style="background: #f0fdf4; border-color: #dcfce7;">
      <strong style="color: #166534;">Catatan:</strong>
      <p style="color: #15803d;">Terima kasih! Tagihan ini telah dibayar lunas pada ${invoice.paid_at ? formatDate(invoice.paid_at) : 'waktu yang ditentukan'}.</p>
    </div>
    `}

    <div class="footer">
      <p>Terima kasih atas kepercayaan Anda menggunakan layanan <strong>${compName}</strong></p>
      <p>Untuk pertanyaan, hubungi: 082223616884 | sales@ajnusa.com</p>
    </div>
  </div>
</body>
</html>`;
}
