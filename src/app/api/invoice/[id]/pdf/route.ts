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
      background: #f1f5f9;
      padding: 40px 20px;
      color: #1e293b;
      line-height: 1.5;
    }

    .invoice-container {
      max-width: 800px;
      margin: 0 auto;
      background: white;
      padding: 40px;
      border-radius: 4px;
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
      margin-bottom: 30px;
    }

    .brand-section {
      display: flex;
      align-items: center;
      gap: 15px;
    }

    .logo-box {
      width: 56px;
      height: 56px;
      border-radius: 8px;
      overflow: hidden;
      flex-shrink: 0;
    }

    .logo-box img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .company-info h1 {
      font-size: 24px;
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
      margin-bottom: 30px;
    }

    .info-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 20px;
    }

    .info-card h3 {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #ef4444;
      margin-bottom: 15px;
      padding-bottom: 8px;
      border-bottom: 2px solid #ef4444;
      display: inline-block;
    }

    .info-row {
      display: flex;
      margin-bottom: 8px;
      font-size: 13px;
    }

    .info-label {
      flex: 0 0 100px;
      color: #64748b;
      font-weight: 500;
    }

    .info-value {
      flex: 1;
      font-weight: 700;
      color: #1e293b;
    }

    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 25px;
    }

    .items-table th {
      text-align: left;
      background: #f8fafc;
      padding: 10px 15px;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #475569;
      border-top: 1px solid #e2e8f0;
      border-bottom: 2px solid #e2e8f0;
    }

    .items-table td {
      padding: 15px;
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
      margin-bottom: 30px;
    }

    .summary-row {
      display: flex;
      width: 250px;
      justify-content: space-between;
      font-size: 14px;
      color: #64748b;
    }

    .summary-row.total {
      margin-top: 5px;
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
      margin-bottom: 25px;
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
      top: 120px;
      right: 40px;
      transform: rotate(-15deg);
      border: 5px solid ${statusColor};
      color: ${statusColor};
      padding: 8px 24px;
      font-size: 30px;
      font-weight: 900;
      text-transform: uppercase;
      opacity: 0.15;
      pointer-events: none;
      border-radius: 12px;
      letter-spacing: 4px;
    }

    .footer {
      text-align: center;
      margin-top: 40px;
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
      }
      .invoice-container::before {
        display: none;
      }
      .no-print {
        display: none;
      }
    }
  </style>
</head>
<body>
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

  <script>
    window.onload = function() {
      if (!window.location.search.includes('noprint')) {
        setTimeout(function() {
          window.print();
        }, 800);
      }
    };
  </script>
</body>
</html>`;
}
