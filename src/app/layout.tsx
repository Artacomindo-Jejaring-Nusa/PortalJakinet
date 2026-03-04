import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import './portal.css';
import './portal-mobile.css';
import './portal-nav.css';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

export const metadata: Metadata = {
  title: 'Portal Jakinet - Customer Area',
  description: 'Kelola tagihan internet Anda dengan mudah dalam satu portal. Portal Pelanggan Jakinet by PT. Artacomindo Jejaring Nusa.',
  keywords: ['portal', 'jakinet', 'customer', 'billing', 'internet', 'ISP'],
  robots: 'noindex, nofollow',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id" className={inter.variable}>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
        <link rel="icon" href="/favicon.png" />
      </head>
      <body className={inter.className}>
        <div className="min-h-screen bg-[#F8FAFC]">
          {children}
        </div>
      </body>
    </html>
  );
}
