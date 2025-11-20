import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: "POST 요청만 허용됩니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 405,
      });
    }

    const body = await req.json();
    const nickname = body.nickname;
    const currentUserId = body.user_id; // 현재 사용자 ID (선택적)

    if (!nickname || typeof nickname !== 'string') {
      return new Response(JSON.stringify({ error: "nickname이 제공되지 않았습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // Service Role Key를 사용하므로 RLS 정책을 우회하여 모든 사용자 조회 가능
    const { data, error } = await supabase
      .from('users')
      .select('id, nickname')
      .eq('nickname', nickname)
      .maybeSingle();

    if (error) {
      console.error('닉네임 중복 체크 실패:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    // 결과가 없으면 사용 가능
    if (data === null) {
      return new Response(JSON.stringify({ available: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 현재 사용자의 닉네임과 동일하면 사용 가능
    if (currentUserId && data.id === currentUserId) {
      return new Response(JSON.stringify({ available: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 다른 사용자가 사용 중이면 사용 불가
    return new Response(JSON.stringify({ available: false }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error('닉네임 중복 체크 오류:', e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

