'use client';

/**
 * Customer Portal Login Page
 * Powered by PT Artacomindo Jejaring Nusa
 */

import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [identifier, setIdentifier] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [imgSrc, setImgSrc] = useState('/images/artacom.png');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ identifier }),
      });

      const data = await response.json();

      if (!response.ok) {
        setError(data.error || 'Login gagal. Silakan periksa kembali data Anda.');
        setLoading(false);
        return;
      }

      // Successful login
      setIsSuccess(true);
      router.push('/');
      router.refresh();
    } catch (err) {
      setError('Terjadi kesalahan jaringan. Silakan coba lagi.');
      setLoading(false);
    }
  };

  return (
    <div className="portal-login-page">
      {/* Full screen loading/redirecting overlay */}
      {(loading || isSuccess) && (
        <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-slate-900/40 backdrop-blur-md animate-in fade-in duration-300">
          <div className="relative mb-6">
            <div className="w-20 h-20 rounded-3xl bg-white text-blue-600 shadow-2xl flex items-center justify-center p-3 animate-bounce border border-slate-100">
              {/* Fallback & primary image rendering */}
              <img
                src={imgSrc}
                alt="Artacom Logo"
                className="w-full h-full object-contain"
                onError={() => setImgSrc('https://www.ajnusa.com/Images/artacom.png')}
              />
            </div>
            <div className="absolute -inset-3 border-2 border-blue-500 rounded-[2.2rem] animate-ping opacity-30"></div>
          </div>
          <div className="flex items-center gap-3 bg-white/90 backdrop-blur-md px-6 py-3 rounded-full shadow-lg border border-slate-100">
            <svg className="w-5 h-5 text-blue-600 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span className="text-base font-bold text-slate-900 tracking-tight">
              {isSuccess ? 'Mempersiapkan Portal...' : 'Memverifikasi Data...'}
            </span>
          </div>
          {isSuccess && <p className="mt-3 text-slate-600 font-semibold animate-pulse bg-white/80 px-4 py-1.5 rounded-full text-xs shadow-sm">Menuju Dashboard Pelanggan</p>}
        </div>
      )}

      {/* Ambient Lighting & Background Circles */}
      <div className="portal-login-bg">
        <div className="portal-login-bg-circle portal-login-bg-circle-1"></div>
        <div className="portal-login-bg-circle portal-login-bg-circle-2"></div>
        <div className="portal-login-bg-circle portal-login-bg-circle-3"></div>
      </div>

      <div className="portal-login-container">
        {/* Brand Bar */}
        <div className="portal-login-topbar">
          <div className="portal-login-brand">
            <div className="portal-login-logo-box">
              <img
                src={imgSrc}
                alt="Artacom Logo"
                className="portal-login-logo-img"
                onError={() => setImgSrc('https://www.ajnusa.com/Images/artacom.png')}
              />
            </div>
            <div className="portal-login-brand-info">
              <span className="portal-login-brand-text">Portal Pelanggan</span>
              <span className="portal-login-brand-powered">Powered by Artacomindo</span>
            </div>
          </div>
        </div>

        {/* Login Card */}
        <div className="portal-login-card">
          <div className="portal-login-card-inner">
            {/* Header / Hero Branding */}
            <div className="portal-login-header">
              <div className="portal-login-hero-logo">
                <img
                  src={imgSrc}
                  alt="Artacom Logo"
                  className="portal-login-hero-img"
                  onError={() => setImgSrc('https://www.ajnusa.com/Images/artacom.png')}
                />
              </div>
              <h1 className="portal-login-title">Selamat Datang</h1>
              <p className="portal-login-subtitle">
                Kelola tagihan &amp; layanan internet Anda dengan mudah dalam satu portal.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="portal-login-form" autoComplete="on" suppressHydrationWarning={true}>
              <div className="portal-login-field">
                <label htmlFor="identifier" className="portal-login-label">
                  Email atau Nomor Telepon
                </label>
                <div className="portal-login-input-wrap">
                  <div className="portal-login-input-icon">
                    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <input
                    id="identifier"
                    type="text"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="nama@email.com atau 08123456789"
                    className="portal-login-input"
                    disabled={loading || isSuccess}
                    autoComplete="username"
                    suppressHydrationWarning={true}
                    required
                  />
                </div>
                <p className="portal-login-hint">
                  Masukkan data yang terdaftar saat pemasangan layanan.
                </p>
              </div>

              {error && (
                <div className="portal-login-error">
                  <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <p>{error}</p>
                </div>
              )}

              <button
                type="submit"
                disabled={loading || isSuccess}
                className="portal-login-btn"
                suppressHydrationWarning={true}
              >
                {isSuccess ? (
                  <span className="portal-login-btn-loading">
                    <svg className="portal-login-spinner" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Berhasil...
                  </span>
                ) : loading ? (
                  <span className="portal-login-btn-loading">
                    <svg className="portal-login-spinner" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Memverifikasi...
                  </span>
                ) : (
                  'Masuk ke Portal'
                )}
              </button>
            </form>
          </div>
        </div>

        {/* Footer info & Powered by */}
        <div className="portal-login-footer">
          <p>© {new Date().getFullYear()} Portal Pelanggan. All rights reserved.</p>
          <p className="portal-login-footer-powered">
            Powered by <strong>PT Artacomindo Jejaring Nusa</strong>
          </p>
        </div>
      </div>
    </div>
  );
}

