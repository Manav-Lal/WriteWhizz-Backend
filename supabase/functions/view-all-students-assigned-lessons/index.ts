import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import SupabaseClient from "../_shared/supabaseClient.ts";
import {corsHeaders} from "../_shared/cors.ts";

/**
 * HTTP endpoint to retrieve a list of students and their assigned lessons for the authenticated teacher.
 *
 * This function:
 * - Handles CORS preflight (`OPTIONS`) requests.
 * - Authenticates the request using a Supabase Bearer token from the `Authorization` header.
 * - Retrieves all students linked to the authenticated teacher (`teacher_id = user.id`).
 * - For each student, includes any `student_assigned_lessons` with `id` and `lesson_id`.
 * - Returns the result as a JSON array.
 *
 * @param {Request} req - Incoming HTTP request.
 *   - Must include the `Authorization: Bearer <token>` header.
 *
 * @returns {Promise<Response>} JSON response:
 * - `200 OK` with an array of student objects and their assigned lessons.
 * - `401 Unauthorized` if authentication fails or user is not found.
 * - `400 Bad Request` if the Supabase query fails.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  const supabaseClient = SupabaseClient(req)

  // Retrieve calling user's auth and role for checking
  const token = req.headers.get('Authorization')?.replace('Bearer ', '');
  const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
  if (userError || !user) {
    return new Response(JSON.stringify({
      error: 'Unauthorized'
    }), {
      status: 401,
      headers:corsHeaders
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
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: 400
    });
  }
  return new Response(
    JSON.stringify(profile_data),
    { headers: { "Content-Type": "application/json",
      ...corsHeaders} },
  )
})

