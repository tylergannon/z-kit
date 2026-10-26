export async function POST({ request, url }) {
  return new Response(await request.arrayBuffer(), {
    status: 207,
    headers: {
      'content-type': 'application/octet-stream',
      'x-request-method': request.method,
      'x-request-target': url.pathname + url.search,
      'x-request-header': request.headers.get('x-proxy-check'),
      'set-cookie': 'proof=one; Path=/'
    }
  });
}
export const PATCH = POST;
export function GET() {
  return new Response(new ReadableStream({
    start(controller) {
      controller.enqueue(new TextEncoder().encode('first chunk\n'));
      setTimeout(() => { controller.enqueue(new TextEncoder().encode('last chunk\n')); controller.close(); }, 50);
    }
  }), { headers: { 'content-type': 'text/plain' } });
}
