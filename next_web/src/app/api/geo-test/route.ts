import { getClientIp, jsonResponse } from '@/lib/api-utils';

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  const ip = getClientIp(request);

  return jsonResponse({
    ip,
    city: request.headers.get('x-vercel-ip-city') || null,
    region: request.headers.get('x-vercel-ip-country-region') || null,
    latitude: request.headers.get('x-vercel-ip-latitude') || null,
    longitude: request.headers.get('x-vercel-ip-longitude') || null,
    country: request.headers.get('x-vercel-ip-country') || null,
  }, 200, origin, 0);
}
