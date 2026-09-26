import { NextRequest, NextResponse } from 'next/server';
import { verifyCustomer, registerFCMToken } from '@/lib/billing-api';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { identifier, fcm_token, device_type } = body;

    if (!identifier || !fcm_token) {
      return NextResponse.json(
        { error: 'Identifier and fcm_token are required' },
        { status: 400 }
      );
    }

    const customer = await verifyCustomer(identifier);
    if (!customer) {
      return NextResponse.json(
        { error: 'Customer not found' },
        { status: 404 }
      );
    }

    const result = await registerFCMToken(
      customer.pelanggan.id,
      fcm_token,
      device_type || 'android'
    );

    return NextResponse.json({
      success: true,
      message: 'FCM Token registered successfully',
      data: result,
    });
  } catch (error: any) {
    console.error('Error registering FCM token:', error);
    return NextResponse.json(
      { error: 'Failed to register FCM token' },
      { status: 500 }
    );
  }
}
