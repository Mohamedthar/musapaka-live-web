import { getClientIp, jsonResponse } from '@/lib/api-utils';

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  const ip = getClientIp(request);

  const result: Record<string, unknown> = {
    ip,
    ipLength: ip?.length,
    isLocal: ip === '127.0.0.1' || ip === '::1' || ip === 'unknown',
  };

  if (ip && ip !== 'unknown' && ip !== '127.0.0.1' && ip !== '::1') {
    try {
      const ctrl = new AbortController();
      const timeout = setTimeout(() => ctrl.abort(), 3000);
      const geoRes = await fetch(
        `https://ip-api.com/json/${ip}?fields=status,message,city,regionName,lat,lon`,
        { signal: ctrl.signal }
      );
      clearTimeout(timeout);

      if (geoRes.ok) {
        const geo = await geoRes.json();
        result.geoRaw = geo;
        result.geoStatus = geo.status;
        result.hasCoords = geo.lat != null && geo.lon != null;
      } else {
        result.geoHttpError = geoRes.status;
      }
    } catch (e: unknown) {
      result.geoError = e instanceof Error ? e.message : 'unknown';
    }
  }

  return jsonResponse(result, 200, origin, 0);
}
