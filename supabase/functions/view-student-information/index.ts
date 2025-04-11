import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import SupabaseClient from "../_shared/supabaseClient.ts";
import {corsHeaders} from "../_shared/cors.ts";
/**
 * HTTP handler for retrieving student data (and their lesson progress) for a specific teacher.
 *
 * This endpoint:
 * - Handles CORS preflight requests (`OPTIONS`).
 * - Authenticates the request via a Bearer token from the `Authorization` header.
 * - Accepts a `student_id` query parameter to specify which student to look up.
 * - Verifies the authenticated user is the teacher assigned to the student.
 * - Retrieves the student record and their associated lesson progress from the database.
 * - Returns the full student object, including nested `lesson_progress`.
 *
 * @param {Request} req - Incoming HTTP request. Should include:
 *   - `Authorization` header with a Supabase Bearer token.
 *   - Query param `student_id` representing the student to retrieve.
 *
 * @returns {Promise<Response>} JSON response:
 * - `200 OK` with the student object and lesson progress.
 * - `401 Unauthorized` if authentication fails or user is missing.
 * - `400+` for database or unexpected errors.
 */
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
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
        status: 401,
        headers:corsHeaders
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
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: 200
    });

  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: error.status
    });
  }
});
