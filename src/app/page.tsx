/**
 * Portal Dashboard - Main Page
 * Displays customer profile and invoices
 */

import { redirect } from 'next/navigation';
import { requireAuth } from '@/lib/session';
import { getCustomerByEmail, getCustomerByPhone, type CustomerData } from '@/lib/billing-api';
import PortalDashboardClient from './portal-client';

export default async function PortalPage() {
  // Verify authentication
  const session = await requireAuth();

  // Fetch customer data
  let customerData: CustomerData | null = null;

  // Try to fetch by email first, then phone
  customerData = await getCustomerByEmail(session.customerEmail);
  if (!customerData) {
    customerData = await getCustomerByPhone(session.customerPhone);
  }

  if (!customerData) {
    // Session exists but customer not found - clear session and redirect
    redirect('/login');
  }

  return <PortalDashboardClient customerData={customerData} />;
}
