/**
 * Login API Route
 * Handles customer authentication via email or phone
 */

import { NextRequest, NextResponse } from 'next/server';
import { verifyCustomer } from '@/lib/billing-api';
import { createSession } from '@/lib/session';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { identifier } = body;

    if (!identifier || typeof identifier !== 'string') {
      return NextResponse.json(
        { error: 'Email atau nomor telepon harus diisi' },
        { status: 400 }
      );
    }

    // Validate identifier format
    const cleanIdentifier = identifier.replace(/[-\s]/g, '');
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
    const isPhone = /^(\+62|62|0|8)[0-9]{8,15}$/.test(cleanIdentifier);

    if (!isEmail && !isPhone) {
      return NextResponse.json(
        { error: 'Format email atau nomor telepon tidak valid' },
        { status: 400 }
      );
    }

    // Verify customer with billing API
    const customerData = await verifyCustomer(identifier);

    if (!customerData) {
      return NextResponse.json(
        { error: 'Data tidak ditemukan. Pastikan email atau nomor telepon terdaftar.' },
        { status: 404 }
      );
    }

    // Create session
    await createSession({
      customerId: customerData.pelanggan.id,
      customerEmail: customerData.pelanggan.email,
      customerPhone: customerData.pelanggan.no_telp,
      customerName: customerData.pelanggan.nama,
    });

    return NextResponse.json({
      success: true,
      message: 'Login berhasil',
      redirect: '/',
    });
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'Terjadi kesalahan saat login. Silakan coba lagi.' },
      { status: 500 }
    );
  }
}
