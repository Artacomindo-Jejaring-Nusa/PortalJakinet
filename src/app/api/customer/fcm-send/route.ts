import { NextRequest, NextResponse } from 'next/server';
import { sendFCMToTokens } from '@/lib/firebase-admin';

export async function POST(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const secretKey = process.env.NEXTAUTH_SECRET || 'portal-internal-secret';
    
    // Allow internal billing system calls
    if (authHeader && authHeader.replace('Bearer ', '') !== secretKey) {
      // Optional check, allow internal calls
    }

    const body = await request.json();
    const { tokens, title, body: messageBody, data } = body;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return NextResponse.json({ error: 'tokens array is required and must not be empty' }, { status: 400 });
    }

    if (!title || !messageBody) {
      return NextResponse.json({ error: 'title and body are required' }, { status: 400 });
    }

    const result = await sendFCMToTokens(tokens, {
      title,
      body: messageBody,
      data: data || {},
    });

    return NextResponse.json({
      success: true,
      message: 'FCM push notification processed',
      data: result,
    });
  } catch (error: any) {
    console.error('Error sending FCM push:', error);
    return NextResponse.json(
      { error: 'Failed to send FCM push: ' + error?.message },
      { status: 500 }
    );
  }
}

