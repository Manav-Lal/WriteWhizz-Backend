import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import SupabaseClient from "../_shared/supabaseClient.ts";
import {corsHeaders} from "../_shared/cors.ts";
/**
 * HTTP endpoint to fetch student IDs associated with an authenticated teacher.
 *
 * This function:
 * - Handles CORS preflight (`OPTIONS`) requests.
 * - Authenticates the incoming request using a Supabase Bearer token.
 * - Checks if the authenticated user exists in the `teachers` table.
 * - If the user is a teacher, queries all `students` that have a matching `teacher_id`.
 * - Returns a list of `student_id`s as a JSON array.
 *
 * @param {Request} req - Incoming HTTP request.
 *   - Must include an `Authorization: Bearer <token>` header.
 *
 * @returns {Promise<Response>} JSON response:
 * - `200 OK`: An array of student IDs, e.g. `[{ "student_id": "abc123" }, ...]`
 * - `401 Unauthorized`: If user authentication fails.
 * - `403 Forbidden`: If the user is not found in the `teachers` table.
 * - `400 Bad Request`: On any other error.
 */
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  try {
    const supabaseClient = SupabaseClient(req)
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
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: 200,

    });

  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: 400
    });
  }
});
