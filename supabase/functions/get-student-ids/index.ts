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
    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 401
      });
    }
    // Check if the user is a teacher by looking for teacher_id
    const { data: teacherCheck, error: teacherError } = await supabaseClient.from('teachers').select('teacher_id') // Check for teacher_id
    .eq('teacher_id', user.id).single();

    if (teacherError || !teacherCheck) {
      return new Response(JSON.stringify({
        error: 'User is not a teacher'
      }), {
        status: 403
      });
    }

    // Query to get student IDs associated with the teacher
    const { data: studentIds, error: studentError } = await supabaseClient.from('students').select('student_id') // Select "student_id"
    .eq('teacher_id', user.id);

    if (studentError) {
      throw studentError;
    }

    return new Response(JSON.stringify(studentIds), {
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
      status: 400
    });
  }
});
