import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import SupabaseClient from "../_shared/supabaseClient.ts";
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      status: 200
    });
  }
  try {
    const supabaseClient = SupabaseClient(req)

    // grab url and the query params: the student_id to lookup
    const url = new URL(req.url);
    const student_id = url.searchParams.get("student_id");

    // Retrieve calling user's auth and role for checking
    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 401
      });
    }

    // Query to get student info associated with the teacher
    const { data: studentData, error: studentError } = await supabaseClient.from('students').select("*," +
        " lesson_progress(*)") // Select
    // "student_id"
        .eq('student_id', student_id).eq('teacher_id', user.id).single();
    if (studentError) {
      throw studentError;
    }

    // return the student personal data
    return new Response(JSON.stringify(studentData), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 200
    });

  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: error.status
    });
  }
});
