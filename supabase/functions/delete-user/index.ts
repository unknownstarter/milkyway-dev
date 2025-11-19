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
    const user_id = body.user_id;
    if (!user_id) {
      return new Response(JSON.stringify({ error: "user_id가 제공되지 않았습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // 프로필 이미지 삭제
    try {
      const { data: files } = await supabase.storage.from('profile_images').list(user_id);
      if (files && files.length > 0) {
        await supabase.storage
          .from('profile_images')
          .remove(files.map((file: { name: string }) => `${user_id}/${file.name}`));
      }
    } catch (e) {
      console.error('프로필 이미지 삭제 실패:', (e as Error).message);
    }

    // 테이블 데이터 삭제 (순서 중요: 외래키 제약조건 때문에)
    await supabase.from('memos').delete().eq('user_id', user_id);
    await supabase.from('user_books').delete().eq('user_id', user_id);
    await supabase.from('statistics').delete().eq('user_id', user_id);
    await supabase.from('users').delete().eq('id', user_id);

    // auth.users에서 사용자 삭제
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false } });
    await adminClient.auth.admin.deleteUser(user_id);

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
