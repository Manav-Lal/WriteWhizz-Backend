import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import SupabaseClient from "../_shared/supabaseClient.ts";

/**
 * This method returns all the assigned lessons for all students associated with a teacher.
 */
Deno.serve(async (req) => {
  const supabaseClient = SupabaseClient(req)

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

  const { data: profile_data, error: profileError } = await supabaseClient
          .from('students')
          .select(`
            student_id,
            student_assigned_lessons(id,lesson_id)
        `)
          .eq('teacher_id', user.id); // Filter based on the teacher_id in students
  if (profileError) {
    return new Response(JSON.stringify({
      error: profileError.message,
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 400
    });
  }
  return new Response(
    JSON.stringify(profile_data),
    { headers: { "Content-Type": "application/json" } },
  )
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/view-all-students-assigned-lessons' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
