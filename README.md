# Portal Jakinet - Customer Portal

Portal Pelanggan Jakinet — Standalone customer portal application for PT. Artacomindo Jejaring Nusa (AJNUSA).

## Tech Stack

- **Framework**: Next.js 16 (React 19)
- **Styling**: Vanilla CSS + Tailwind CSS
- **Language**: TypeScript
- **Authentication**: Custom session-based (encrypted cookies)
- **API**: Billing system API integration

## Getting Started

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Required variables:

- `BILLING_API_URL` — Billing system API URL
- `BILLING_API_USERNAME` — API admin username
- `BILLING_API_PASSWORD` — API admin password
- `NEXTAUTH_SECRET` — Secret key for session encryption (generate with `openssl rand -base64 32`)
- `NEXTAUTH_URL` — Application URL

### 3. Run development server

```bash
npm run dev
```

The portal will be available at [http://localhost:3001](http://localhost:3001)

## Project Structure

```
portal-jakinet/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   │   ├── login/route.ts    # Login API
│   │   │   │   └── logout/route.ts   # Logout API
│   │   │   └── invoice/
│   │   │       └── [id]/pdf/route.ts # Invoice PDF generation
│   │   ├── login/
│   │   │   └── page.tsx              # Login page
│   │   ├── layout.tsx                # Root layout
│   │   ├── page.tsx                  # Dashboard (protected)
│   │   ├── portal-client.tsx         # Dashboard client component
│   │   ├── portal.css                # Desktop portal styles
│   │   ├── portal-mobile.css         # Mobile content styles
│   │   ├── portal-nav.css            # Mobile nav & component styles
│   │   └── globals.css               # Global styles
│   └── lib/
│       ├── billing-api.ts            # Billing API integration
│       └── session.ts                # Session management
├── public/
│   └── images/icons/jakinet.png      # Logo
├── .env.example                      # Environment template
├── ecosystem.config.js               # PM2 config for deployment
├── next.config.ts                    # Next.js config (standalone output)
└── package.json
```

## Deployment (CPanel)

### Build for production

```bash
npm run build
```

### Using PM2

```bash
pm2 start ecosystem.config.js
```

### Notes

- The `next.config.ts` is configured with `output: "standalone"` for optimized deployment
- Port defaults to `3001` to avoid conflicts
- Make sure to set a secure `NEXTAUTH_SECRET` in production
