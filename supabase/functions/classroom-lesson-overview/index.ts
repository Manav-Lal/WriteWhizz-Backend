import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import {corsHeaders} from "../_shared/cors.ts";
import SupabaseClient from "../_shared/supabaseClient.ts";
/**
 * An HTTP server handler using Deno that responds with detailed statistics for a given lesson.
 *
 * The response includes:
 * - Lesson details from the `lesson` table
 * - Aggregated student tracing performance via a stored procedure `aggregate_tracing_scores`
 *
 * ### Authorization
 * - Requires a valid Supabase Bearer token in the `Authorization` header.
 * - User must be a teacher (validated via Supabase user lookup).
 *
 * ### Request
 * - Method: `POST`
 * - Required query param: `lesson_id` (number)
 *
 * ### Supabase RPC
 * - Calls `aggregate_tracing_scores(lessonid, teacherid)` to get:
 *   - average_tracing_score
 *   - total_successful_traces
 *   - total_failed_traces
 *
 * ### Response
 * - 200 OK: Merged lesson data + aggregated tracing data
 * - 401 Unauthorized: Missing or invalid user token
 * - 500 Server Error: If lesson or aggregation fails
 *
 * @param {Request} req - The incoming HTTP request
 * @returns {Promise<Response>} JSON response containing lesson stats or error info
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  try{
    const supabase = await SupabaseClient(req)

    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    const { data: { user },userError } = await supabase.auth.getUser(token)
    // Check if there's an error or no user found
    if (userError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 401,
        headers:corsHeaders
      });
    }

    const url = new URL(req.url);
    const lesson_id:number = url.searchParams.get("lesson_id");

    // To return
    // Lesson Details
    // Average Tracing score for that lesson
    // Total successful traces
    // Total failed traces

    // Grab lesson
    const {data:lessonData, error:lessonError} = await supabase.from("lesson").select("*").eq("id", lesson_id).single();

    if (lessonError || !lessonData){
      throw lessonError
    }
    const {data:studentAggData, error:studentError} = await supabase.rpc('aggregate_tracing_scores', {lessonid : lesson_id, teacherid:user.id}).single()
    if (studentError || !studentAggData){
      throw studentError
    }
    let merged = {...lessonData, ...studentAggData}


    console.log(merged)
    return new Response(JSON.stringify(merged), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: 200,

    });
  }catch (error){
    return new Response(JSON.stringify({
      error: error
    }), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status:500
    });
  }

})

