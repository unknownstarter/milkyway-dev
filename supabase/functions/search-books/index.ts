// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

console.log("Hello from Functions!")

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { query } = await req.json()
    
    // 첫 번째 요청으로 전체 결과 수 확인
    const initialResponse = await fetch(
      `https://openapi.naver.com/v1/search/book.json?query=${encodeURIComponent(query)}&display=10&start=1`,
      {
        headers: {
          'X-Naver-Client-Id': Deno.env.get('NAVER_CLIENT_ID') || '',
          'X-Naver-Client-Secret': Deno.env.get('NAVER_CLIENT_SECRET') || '',
        },
      }
    ).then(res => res.json());

    console.log('Initial response:', {
      total: initialResponse.total,
      display: initialResponse.display,
      start: initialResponse.start,
      itemsLength: initialResponse.items?.length
    });

    const totalResults = Math.min(initialResponse.total, 100);
    const numberOfRequests = Math.ceil(totalResults / 10);
    console.log(`Total results: ${initialResponse.total}, Fetching: ${totalResults}, Requests needed: ${numberOfRequests}`);

    // 첫 번째 요청의 결과를 포함
    const allItems = [...initialResponse.items];
    console.log('After initial items:', allItems.length);

    // 2번째 요청부터 준비 (start=11부터)
    const requests = Array.from({ length: numberOfRequests - 1 }, (_, i) => {
      const start = (i + 1) * 10 + 1; // 11, 21, 31, ...
      console.log(`Preparing request with start=${start}`);
      return fetch(
        `https://openapi.naver.com/v1/search/book.json?query=${encodeURIComponent(query)}&display=10&start=${start}`,
        {
          headers: {
            'X-Naver-Client-Id': Deno.env.get('NAVER_CLIENT_ID') || '',
            'X-Naver-Client-Secret': Deno.env.get('NAVER_CLIENT_SECRET') || '',
          },
        }
      ).then(async res => {
        const data = await res.json();
        console.log(`Response for start=${start}:`, {
          itemsLength: data.items?.length,
          start: data.start,
          display: data.display
        });
        return data;
      });
    });

    if (requests.length > 0) {
      console.log(`Executing ${requests.length} additional requests...`);
      const results = await Promise.all(requests);
      const newItems = results.flatMap(result => result.items || []);
      console.log(`Got ${newItems.length} new items from additional requests`);
      allItems.push(...newItems);
    }

    console.log(`Final count: ${allItems.length} items for query "${query}"`);

    return new Response(JSON.stringify({ 
      items: allItems.slice(0, 100),
      total: initialResponse.total
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error: unknown) {
    console.error('Error:', error instanceof Error ? error.message : error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/search-books' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
