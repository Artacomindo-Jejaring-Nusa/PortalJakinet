'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import type { CustomerData } from '@/lib/billing-api';

interface Props {
  customerData: CustomerData;
}

export default function PortalDashboardClient({ customerData }: Props) {
  const router = useRouter();
  const [logoutLoading, setLogoutLoading] = useState(false);
  const [invoiceFilter, setInvoiceFilter] = useState<'all' | 'unpaid' | 'paid'>('all');
  const [mobileTab, setMobileTab] = useState<'home' | 'history' | 'pesan' | 'settings'>('home');

  const handleLogout = async () => {
    setLogoutLoading(true);
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      router.push('/login');
      router.refresh();
    } catch (err) {
      console.error('Logout error:', err);
    } finally {
      setLogoutLoading(false);
    }
  };

  const filteredInvoices = customerData.invoices.filter((invoice) => {
    if (invoiceFilter === 'all') return true;
    if (invoiceFilter === 'unpaid') return invoice.status_invoice !== 'Lunas';
    if (invoiceFilter === 'paid') return invoice.status_invoice === 'Lunas';
    return true;
  });

  const totalUnpaid = customerData.invoices
    .filter((inv) => inv.status_invoice !== 'Lunas')
    .reduce((sum, inv) => sum + (inv.total_harga || 0), 0);

  const unpaidCount = customerData.invoices.filter((inv) => inv.status_invoice !== 'Lunas').length;

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatDateShort = (dateString: string) => {
    const d = new Date(dateString);
    return {
      day: d.getDate(),
      month: d.toLocaleDateString('id-ID', { month: 'long' }),
      year: d.getFullYear(),
    };
  };

  const calculateSubscriptionStatus = () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const overdueInvoice = customerData.invoices.find((invoice) => {
      const status = invoice.status_invoice?.toLowerCase() || '';
      if (status === 'lunas') return false;
      
      // If API explicitly says it's expired or overdue, it's suspended
      if (status === 'kadaluarsa' || status === 'tunggakan' || status === 'macet') return true;
      
      const dueDate = new Date(invoice.tgl_jatuh_tempo);
      dueDate.setHours(0, 0, 0, 0);
      return dueDate < today;
    });

    if (overdueInvoice) return 'Suspended';
    
    const status = customerData.langganan?.status || 'Aktif';
    if (status.toLowerCase().includes('suspend')) return 'Suspended';
    if (status.toLowerCase().includes('non-aktif') || status.toLowerCase() === 'non aktif') return 'Non-Aktif';
    
    return status;
  };

  const actualSubscriptionStatus = calculateSubscriptionStatus();
  const isActive = actualSubscriptionStatus.toLowerCase() === 'aktif';

  // Find the nearest due date for mobile display
  const nextDueInvoice = customerData.invoices
    .filter((inv) => inv.status_invoice !== 'Lunas')
    .sort((a, b) => new Date(a.tgl_jatuh_tempo).getTime() - new Date(b.tgl_jatuh_tempo).getTime())[0];

  const nextDue = nextDueInvoice ? formatDateShort(nextDueInvoice.tgl_jatuh_tempo) : null;

  // Extract speed from layanan name
  const layananName = customerData.pelanggan.layanan || 'Internet 10 Mbps';
  const speedMatch = layananName.match(/(\d+)\s*Mbps/i);
  const speed = speedMatch ? speedMatch[1] : '10';

  // Get customer ID display
  const customerId = customerData.pelanggan.id.toString().padStart(10, '0');

  return (
    <div className="portal-root">
      {/* ==================== DESKTOP LAYOUT ==================== */}
      <div className="portal-desktop">
        {/* --- ELITE HEADER --- */}
        <header className="portal-header">
          <div className="portal-header-inner">
            <div className="portal-header-row">
              {/* Logo Section */}
              <div className="portal-header-left">
                <a href="/" className="portal-logo-link">
                  <div className="portal-logo-img-wrap">
                    <Image
                      src="/images/icons/jakinet.png"
                      alt="Logo"
                      fill
                      className="portal-logo-img"
                    />
                  </div>
                  <div className="portal-logo-text-wrap">
                    <h1 className="portal-logo-title">Portal Jakinet</h1>
                    <span className="portal-logo-subtitle">Customer Area</span>
                  </div>
                </a>
              </div>

              {/* Actions */}
              <div className="portal-header-right">
                <a href="https://ajnusa.com" target="_blank" rel="noopener noreferrer" className="portal-header-link">
                  Website Utama
                </a>
                <div className="portal-header-divider"></div>
                <button
                  onClick={handleLogout}
                  disabled={logoutLoading}
                  className="portal-logout-btn"
                >
                  {logoutLoading ? (
                    <span className="portal-logout-loading">
                      <svg className="portal-spin" width="16" height="16" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Keluar...
                    </span>
                  ) : (
                    <>
                      <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                      </svg>
                      <span>Keluar</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        </header>

        <main className="portal-main">
          {/* --- GREETING SECTION --- */}
          <div className="portal-greeting">
            <div>
              <h2 className="portal-greeting-name">Halo, {customerData.pelanggan.nama}!</h2>
              <p className="portal-greeting-desc">Selamat datang kembali di pusat kendali layanan internet Anda.</p>
            </div>
            <div className="portal-greeting-status-wrap">
              <div className="portal-status-badge">
                <div className={`portal-status-dot ${isActive ? 'portal-status-dot--active' : 'portal-status-dot--suspended'}`}></div>
                <span className="portal-status-text">Status Layanan: {actualSubscriptionStatus}</span>
              </div>
            </div>
          </div>

          {/* --- STATS GRID --- */}
          <div className="portal-stats-grid">
            {/* Unpaid Card */}
            <div className="portal-stat-card">
              <div className="portal-stat-card-top">
                <div className="portal-stat-icon portal-stat-icon--red">
                  <svg width="32" height="32" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <span className="portal-stat-label-tag">Tunggakan</span>
              </div>
              <p className="portal-stat-desc">Tagihan Belum Lunas</p>
              <h3 className="portal-stat-value">{formatCurrency(totalUnpaid)}</h3>
            </div>

            {/* Count Card */}
            <div className="portal-stat-card">
              <div className="portal-stat-card-top">
                <div className="portal-stat-icon portal-stat-icon--orange">
                  <svg width="32" height="32" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <span className="portal-stat-label-tag">Dokumen</span>
              </div>
              <p className="portal-stat-desc">Invoice Perlu Dibayar</p>
              <div className="portal-stat-value-row">
                <h3 className="portal-stat-value">{unpaidCount}</h3>
                <span className="portal-stat-unit">Lembar</span>
              </div>
            </div>

            {/* Subscription Card */}
            <div className="portal-stat-card portal-stat-card--blue">
              <div className="portal-stat-card--blue-glow"></div>
              <div className="portal-stat-card--blue-content">
                <div className="portal-stat-card-top">
                  <div className="portal-stat-icon portal-stat-icon--white">
                    <svg width="32" height="32" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                  <span className="portal-stat-label-tag portal-stat-label-tag--blue">Layanan</span>
                </div>
                <p className="portal-stat-desc portal-stat-desc--blue">Paket Langganan</p>
                <h3 className="portal-stat-value portal-stat-value--white">{layananName}</h3>
                <div className="portal-stat-badge-row">
                  <span className="portal-stat-badge--fiber">Fiber Optic 100%</span>
                </div>
              </div>
            </div>
          </div>

          {/* --- MAIN CONTENT GRID --- */}
          <div className="portal-content-grid">
            {/* LEFT: INVOICES */}
            <div className="portal-content-left">
              <div className="portal-invoices-card">
                <div className="portal-invoices-inner">
                  <div className="portal-invoices-header">
                    <div>
                      <h3 className="portal-invoices-title">Riwayat Transaksi</h3>
                      <p className="portal-invoices-desc">Daftar lengkap penagihan dan status pembayaran Anda.</p>
                    </div>
                    <div className="portal-invoices-filters">
                      {(['all', 'unpaid', 'paid'] as const).map((filter) => (
                        <button
                          key={filter}
                          onClick={() => setInvoiceFilter(filter)}
                          className={`portal-filter-btn ${invoiceFilter === filter ? 'portal-filter-btn--active' : ''}`}
                        >
                          {filter === 'all' ? 'Semua Data' : filter === 'unpaid' ? 'Belum Lunas' : 'Sudah Lunas'}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Invoice List */}
                  {filteredInvoices.length === 0 ? (
                    <div className="portal-invoices-empty">
                      <div className="portal-invoices-empty-icon">
                        <svg width="40" height="40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                      </div>
                      <p>Tidak ada invoice ditemukan.</p>
                    </div>
                  ) : (
                    <div className="portal-invoices-list">
                      {filteredInvoices.map((invoice) => (
                        <div key={invoice.id} className="portal-invoice-item">
                          <div className="portal-invoice-left">
                            <div className={`portal-invoice-icon ${invoice.status_invoice === 'Lunas' ? 'portal-invoice-icon--paid' : 'portal-invoice-icon--unpaid'}`}>
                              <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a1 1 0 01-1-1V5a1 1 0 011-1h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a1 1 0 01-1 1z" />
                              </svg>
                            </div>
                            <div>
                              <h4 className="portal-invoice-num">{invoice.invoice_number}</h4>
                              <div className="portal-invoice-meta">
                                <span className="portal-invoice-meta-label">Jatuh Tempo</span>
                                <p className="portal-invoice-meta-date">{formatDate(invoice.tgl_jatuh_tempo)}</p>
                              </div>
                            </div>
                          </div>

                          <div className="portal-invoice-right">
                            <div className="portal-invoice-amount-wrap">
                              <span className="portal-invoice-amount">{formatCurrency(invoice.total_harga)}</span>
                              <div className="portal-invoice-status-row">
                                <div className={`portal-invoice-status-dot ${invoice.status_invoice === 'Lunas' ? 'portal-invoice-status-dot--paid' : 'portal-invoice-status-dot--unpaid'}`}></div>
                                <span className={`portal-invoice-status-text ${invoice.status_invoice === 'Lunas' ? 'portal-invoice-status-text--paid' : 'portal-invoice-status-text--unpaid'}`}>
                                  {invoice.status_invoice === 'Lunas' ? 'Sudah Bayar' : 'Belum Bayar'}
                                </span>
                              </div>
                            </div>

                            <div className="portal-invoice-actions">
                              <button
                                onClick={() => window.open(`/api/invoice/${invoice.id}/pdf`, '_blank')}
                                className="portal-invoice-pdf-btn"
                                title="Download PDF"
                              >
                                <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                              </button>

                              {invoice.status_invoice !== 'Lunas' && invoice.payment_link && (
                                <a
                                  href={invoice.payment_link}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="portal-invoice-pay-btn"
                                >
                                  Bayar Sekarang
                                </a>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* RIGHT: PROFILE */}
            <div className="portal-content-right">
              <div className="portal-profile-card">
                <div className="portal-profile-inner">
                  <h3 className="portal-profile-title">Akun Pelanggan</h3>

                  <div className="portal-profile-fields">
                    <div className="portal-profile-field">
                      <div className="portal-profile-field-icon">
                        <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                      </div>
                      <div>
                        <p className="portal-profile-field-label">Nama Lengkap</p>
                        <p className="portal-profile-field-value">{customerData.pelanggan.nama}</p>
                      </div>
                    </div>

                    <div className="portal-profile-field">
                      <div className="portal-profile-field-icon">
                        <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                      </div>
                      <div>
                        <p className="portal-profile-field-label">Email Aktif</p>
                        <p className="portal-profile-field-value portal-profile-field-value--truncate">{customerData.pelanggan.email}</p>
                      </div>
                    </div>

                    <div className="portal-profile-field">
                      <div className="portal-profile-field-icon">
                        <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                      </div>
                      <div>
                        <p className="portal-profile-field-label">WhatsApp</p>
                        <p className="portal-profile-field-value">{customerData.pelanggan.no_telp}</p>
                      </div>
                    </div>

                    <div className="portal-profile-field">
                      <div className="portal-profile-field-icon">
                        <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                      </div>
                      <div>
                        <p className="portal-profile-field-label">Lokasi Pemasangan</p>
                        <p className="portal-profile-field-value portal-profile-field-value--sm">
                          {customerData.pelanggan.alamat_2 || customerData.pelanggan.alamat}
                          {customerData.pelanggan.blok && (
                            <span className="portal-profile-blok">
                              Blok {customerData.pelanggan.blok}, Unit {customerData.pelanggan.unit}
                            </span>
                          )}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="portal-profile-help">
                    <p className="portal-profile-help-title">Butuh Bantuan?</p>
                    <p className="portal-profile-help-desc">Kami siap membantu kendala koneksi internet Anda kapan saja.</p>
                    <a
                      href="https://wa.me/6281188809633"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="portal-profile-wa-btn"
                    >
                      <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
                      </svg>
                      Chat WhatsApp
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>

        {/* --- DESKTOP FOOTER --- */}
        <footer className="portal-footer-desktop">
          <div className="portal-footer-inner">
            <div className="portal-footer-brand">
              <div className="portal-footer-brand-icon">J</div>
              <div className="portal-footer-brand-text">
                <span className="portal-footer-brand-name">Portal Jakinet</span>
                <span className="portal-footer-brand-sub">Fiber Optic Specialist</span>
              </div>
            </div>
            <p className="portal-footer-copy">
              © {new Date().getFullYear()} PT. Artacomindo Jejaring Nusa.
            </p>
            <div className="portal-footer-links">
              <a href="https://ajnusa.com" target="_blank" rel="noopener noreferrer" className="portal-footer-link">Pusat Bantuan</a>
              <a href="https://ajnusa.com" target="_blank" rel="noopener noreferrer" className="portal-footer-link">Kebijakan Privasi</a>
            </div>
          </div>
        </footer>
      </div>

      {/* ==================== MOBILE LAYOUT ==================== */}
      <div className="portal-mobile">
        {/* Mobile Header Card */}
        <div className="pm-header-card">
          <div className="pm-header-inner">
            <h2 className="pm-header-name">Hi, {customerData.pelanggan.nama}</h2>
            <button className="pm-header-id" onClick={() => navigator.clipboard?.writeText(customerId)}>
              <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ opacity: 0.5 }}>
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
              {customerId}
            </button>
          </div>
        </div>

        {/* Mobile Content - conditionally rendered based on active tab */}
        <div className="pm-content">
          {/* ===== HOME TAB ===== */}
          {mobileTab === 'home' && (
            <div className="pm-home">
              {/* Status Cards Row */}
              <div className="pm-status-row">
                {/* Billing Status Card */}
                <div className={`pm-status-card ${isActive ? 'pm-status-card--active' : 'pm-status-card--suspended'}`}>
                  <span className="pm-status-card-label">{isActive ? 'Tagihan Lunas' : 'Tunggakan'}</span>
                  <span className={`pm-status-card-badge ${isActive ? 'pm-status-card-badge--green' : 'pm-status-card-badge--red'}`}>
                    {isActive ? 'Aktif hingga' : 'Jatuh Tempo'}
                  </span>
                  {nextDue ? (
                    <div className="pm-status-card-date">
                      <span className="pm-status-card-day">{nextDue.day}</span>
                      <span className="pm-status-card-month">{nextDue.month}</span>
                      <span className="pm-status-card-year">{nextDue.year}</span>
                    </div>
                  ) : (
                    <div className="pm-status-card-date">
                      <span className="pm-status-card-month" style={{ fontSize: '0.875rem' }}>Tidak ada tagihan</span>
                    </div>
                  )}
                  {nextDueInvoice && (
                    <span className="pm-status-card-next">
                      Tagihan selanjutnya {formatDate(nextDueInvoice.tgl_jatuh_tempo)}
                    </span>
                  )}
                </div>

                {/* Speed Card */}
                <div className="pm-speed-card">
                  <span className="pm-speed-card-label">{customerData.pelanggan.harga_layanan?.brand || 'Jakinet'}</span>
                  <div className="pm-speed-card-value">
                    <span className="pm-speed-number">{speed}</span>
                    <span className="pm-speed-unit">Mbps</span>
                  </div>
                  <span className="pm-speed-card-ont">ONT : {customerData.pelanggan.id_brand || 'N/A'}</span>
                </div>
              </div>

              {/* Internet Info Bar */}
              <div className="pm-internet-bar">
                <div className="pm-internet-bar-left">
                  <div className="pm-internet-icon">
                    <svg width="28" height="28" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                    </svg>
                  </div>
                  <div>
                    <span className="pm-internet-label">Internet</span>
                    <span className="pm-internet-sublabel">Sampai dengan</span>
                  </div>
                </div>
                <div className="pm-internet-bar-right">
                  <span className="pm-internet-type">Broadband UpTo</span>
                  <span className="pm-internet-speed">{speed} Mbps</span>
                </div>
              </div>

              {/* Quick Actions */}
              <div className="pm-quick-actions">
                <a href={nextDueInvoice?.payment_link || '#'} className="pm-quick-action" target={nextDueInvoice?.payment_link ? '_blank' : undefined}>
                  <div className="pm-quick-action-icon">
                    <svg width="28" height="28" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                    </svg>
                  </div>
                  <span className="pm-quick-action-label">Pembayaran</span>
                </a>
                <a href="https://wa.me/6281188809633" target="_blank" rel="noopener noreferrer" className="pm-quick-action">
                  <div className="pm-quick-action-icon">
                    <svg width="28" height="28" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                    </svg>
                  </div>
                  <span className="pm-quick-action-label">Customer Support</span>
                </a>
                <a href="https://www.speedtest.net/" target="_blank" rel="noopener noreferrer" className="pm-quick-action">
                  <div className="pm-quick-action-icon">
                    <svg width="28" height="28" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                  <span className="pm-quick-action-label">SpeedTest</span>
                </a>
              </div>

              {/* Recent Payments Section */}
              <div className="pm-offers">
                <h3 className="pm-offers-title">Pembayaran Terakhir</h3>
                <div className="pm-offers-header">
                  <span className="pm-offers-link" onClick={() => setMobileTab('history')}>Lihat semua riwayat →</span>
                </div>
                <div className="pm-offers-list">
                  {customerData.invoices.length === 0 ? (
                    <div className="pm-history-empty" style={{ padding: '2rem 0' }}>
                      <svg width="40" height="40" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: '#cbd5e1' }}>
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                      <p>Belum ada riwayat pembayaran</p>
                    </div>
                  ) : (
                    customerData.invoices.slice(0, 3).map((invoice) => (
                      <div key={invoice.id} className="pm-history-item">
                        <div className="pm-history-item-top">
                          <div className={`pm-history-item-dot ${invoice.status_invoice === 'Lunas' ? 'pm-history-item-dot--paid' : 'pm-history-item-dot--unpaid'}`}></div>
                          <span className="pm-history-item-num">{invoice.invoice_number}</span>
                        </div>
                        <div className="pm-history-item-body">
                          <div>
                            <span className="pm-history-item-amount">{formatCurrency(invoice.total_harga)}</span>
                            <span className="pm-history-item-date">{formatDate(invoice.tgl_jatuh_tempo)}</span>
                          </div>
                          <div className="pm-history-item-actions">
                            {invoice.status_invoice !== 'Lunas' && invoice.payment_link && (
                              <a href={invoice.payment_link} target="_blank" rel="noopener noreferrer" className="pm-history-pay-btn">
                                Bayar
                              </a>
                            )}
                            {invoice.status_invoice === 'Lunas' && (
                              <span className="pm-history-paid-badge">Lunas</span>
                            )}
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          )}

          {/* ===== HISTORY TAB ===== */}
          {mobileTab === 'history' && (
            <div className="pm-history">
              <h3 className="pm-section-title">Riwayat Transaksi</h3>
              <div className="pm-history-filters">
                {(['all', 'unpaid', 'paid'] as const).map((filter) => (
                  <button
                    key={filter}
                    onClick={() => setInvoiceFilter(filter)}
                    className={`pm-history-filter-btn ${invoiceFilter === filter ? 'pm-history-filter-btn--active' : ''}`}
                  >
                    {filter === 'all' ? 'Semua' : filter === 'unpaid' ? 'Belum Lunas' : 'Lunas'}
                  </button>
                ))}
              </div>
              {filteredInvoices.length === 0 ? (
                <div className="pm-history-empty">
                  <svg width="48" height="48" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: '#cbd5e1' }}>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  <p>Tidak ada invoice</p>
                </div>
              ) : (
                <div className="pm-history-list">
                  {filteredInvoices.map((invoice) => (
                    <div key={invoice.id} className="pm-history-item">
                      <div className="pm-history-item-top">
                        <div className={`pm-history-item-dot ${invoice.status_invoice === 'Lunas' ? 'pm-history-item-dot--paid' : 'pm-history-item-dot--unpaid'}`}></div>
                        <span className="pm-history-item-num">{invoice.invoice_number}</span>
                      </div>
                      <div className="pm-history-item-body">
                        <div>
                          <span className="pm-history-item-amount">{formatCurrency(invoice.total_harga)}</span>
                          <span className="pm-history-item-date">{formatDate(invoice.tgl_jatuh_tempo)}</span>
                        </div>
                        <div className="pm-history-item-actions">
                          {invoice.status_invoice !== 'Lunas' && invoice.payment_link && (
                            <a href={invoice.payment_link} target="_blank" rel="noopener noreferrer" className="pm-history-pay-btn">
                              Bayar
                            </a>
                          )}
                          <button onClick={() => window.open(`/api/invoice/${invoice.id}/pdf`, '_blank')} className="pm-history-pdf-btn">
                            <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ===== PESAN TAB ===== */}
          {mobileTab === 'pesan' && (
            <div className="pm-pesan">
              <h3 className="pm-section-title">Pesan</h3>
              <div className="pm-pesan-empty">
                <div className="pm-pesan-empty-icon">
                  <svg width="48" height="48" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                </div>
                <p className="pm-pesan-empty-text">Belum ada pesan</p>
                <p className="pm-pesan-empty-sub">Pesan dari Jakinet akan muncul di sini</p>
                <a
                  href="https://wa.me/6281188809633"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="pm-pesan-wa-btn"
                >
                  <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
                  </svg>
                  Hubungi via WhatsApp
                </a>
              </div>
            </div>
          )}

          {/* ===== SETTINGS TAB ===== */}
          {mobileTab === 'settings' && (
            <div className="pm-settings">
              <h3 className="pm-section-title">Pengaturan</h3>

              <div className="pm-settings-profile-card">
                <div className="pm-settings-avatar">
                  <svg width="32" height="32" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <div>
                  <p className="pm-settings-name">{customerData.pelanggan.nama}</p>
                  <p className="pm-settings-email">{customerData.pelanggan.email}</p>
                </div>
              </div>

              <div className="pm-settings-list">
                <div className="pm-settings-item">
                  <div className="pm-settings-item-left">
                    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                    <span>WhatsApp</span>
                  </div>
                  <span className="pm-settings-item-value">{customerData.pelanggan.no_telp}</span>
                </div>
                <div className="pm-settings-item">
                  <div className="pm-settings-item-left">
                    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span>Lokasi</span>
                  </div>
                  <span className="pm-settings-item-value">{customerData.pelanggan.alamat_2 || customerData.pelanggan.alamat}</span>
                </div>
                <div className="pm-settings-item">
                  <div className="pm-settings-item-left">
                    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                    <span>Paket</span>
                  </div>
                  <span className="pm-settings-item-value">{layananName}</span>
                </div>
                <div className="pm-settings-item">
                  <div className="pm-settings-item-left">
                    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span>Status</span>
                  </div>
                  <span className={`pm-settings-status ${isActive ? 'pm-settings-status--active' : 'pm-settings-status--suspended'}`}>
                    {actualSubscriptionStatus}
                  </span>
                </div>
              </div>

              <button
                onClick={handleLogout}
                disabled={logoutLoading}
                className="pm-settings-logout-btn"
              >
                {logoutLoading ? (
                  <span className="pm-settings-logout-loading">
                    <svg className="portal-spin" width="18" height="18" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Keluar...
                  </span>
                ) : (
                  <>
                    <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                    Keluar dari Portal
                  </>
                )}
              </button>
            </div>
          )}
        </div>

        {/* ===== BOTTOM NAVIGATION ===== */}
        <nav className="pm-bottom-nav">
          <button
            className={`pm-nav-item ${mobileTab === 'home' ? 'pm-nav-item--active' : ''}`}
            onClick={() => setMobileTab('home')}
          >
            <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={mobileTab === 'home' ? 2.5 : 1.8} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
            <span>Home</span>
          </button>
          <button
            className={`pm-nav-item ${mobileTab === 'history' ? 'pm-nav-item--active' : ''}`}
            onClick={() => setMobileTab('history')}
          >
            <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={mobileTab === 'history' ? 2.5 : 1.8} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>History</span>
          </button>
          <button
            className={`pm-nav-item ${mobileTab === 'pesan' ? 'pm-nav-item--active' : ''}`}
            onClick={() => setMobileTab('pesan')}
          >
            <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={mobileTab === 'pesan' ? 2.5 : 1.8} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span>Pesan</span>
          </button>
          <button
            className={`pm-nav-item ${mobileTab === 'settings' ? 'pm-nav-item--active' : ''}`}
            onClick={() => setMobileTab('settings')}
          >
            <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={mobileTab === 'settings' ? 2.5 : 1.8} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={mobileTab === 'settings' ? 2.5 : 1.8} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>Settings</span>
          </button>
        </nav>
      </div>
    </div>
  );
}
