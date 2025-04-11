import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import SupabaseClient from "../_shared/supabaseClient.ts";
import {corsHeaders} from "../_shared/cors.ts";

/**
 * API endpoint that retrieves lesson progress data for students under a specific teacher.
 *
 * This function performs the following steps:
 * 1. Authenticates the teacher using the Supabase token from the Authorization header.
 * 2. Retrieves all students associated with the authenticated teacher.
 * 3. For each student:
 *    - Retrieves attempted lesson progress.
 *    - Retrieves assigned lessons.
 *    - Merges both, preferring the lesson with the earlier assigned date if both exist.
 *    - Defaults `completed_activities` to 0 for assigned lessons with no progress.
 *    - Removes internal date fields from the final result.
 * 4. Returns a map of student IDs to their corresponding list of lessons with progress.
 *
 * @param {Request} req - The incoming HTTP request, expected to include an Authorization header with a Bearer token.
 * @returns {Promise<Response>} A JSON response with student lesson progress or an error message.
 *
 * Response format:
 * - Success (200): JSON array of entries in the format [student_id,completed_activities, lessons[]]
 * - Unauthorized (401): `{ error: "Unauthorized" }`
 * - Internal error or Supabase error: `{ error: error.message }`
 *
 * Notes:
 * - Lessons include`lesson(activity_amt)`.
 * - Both `assigned_date` and `created_at` are stripped before returning.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  try {
    const supabaseClient = SupabaseClient(req)

    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    const { data: { user },userError } = await supabaseClient.auth.getUser(token)

// Check if there's an error or no user found
    if (userError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 401,
        headers:corsHeaders
      });
    }

    // make a map of data to return for each student
    const studentMap = new Map();

    const { data: stu, error } = await supabaseClient
        .from('students')
        .select("student_id, teacher_id")
        .eq('teacher_id', user.id);

// Check for error fetching students
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: error.status });
    }

// Aggregate all student attempted lessons into a table where lesson id and progress are stored.
    for (const student of stu) {
      try {
        const { data: attempted, error: lessonError } = await supabaseClient
            .from('lesson_progress')
            .select("lesson_id, lesson(activity_amt),completed_activities, created_at")
            .eq("user_id", student.student_id)
        // Store the lesson progress in the student map, with the key being an array of student_id and username
        const map = new Map();
        // Add attempted
        attempted?.forEach(item => {
          map.set(item.lesson_id, item);
        });

        // grab the assigned lessons too and only add if not in attempted
        const { data: assigned, error: assignedError } = await supabaseClient
            .from('student_assigned_lesson')
            .select("lesson_id, lesson(activity_amt), assigned_date")
            .eq("student_id", student.student_id)

        // Add assignedWithZero if not already present
        assigned?.forEach(item => {
          const existing = map.get(item.lesson_id);
          if (!existing) {
            map.set(item.lesson_id, { ...item, completed_activities: 0 });
          } else {
            // Compare dates: replace only if assigned_date < created_at
            const assignedDate = new Date(item.assigned_date);
            const createdAt = new Date(existing.created_at);
            if (assignedDate > createdAt) {
              map.set(item.lesson_id, { ...item, completed_activities: 0 });
            }
          }
        });
        // Store in studentMap
        const cleanedValues = Array.from(map.values()).map(({ created_at, assigned_date, ...rest }) => rest);

        studentMap.set(student.student_id, cleanedValues);

      } catch (err) {
        console.error(`Error processing student ${student.student_id}:`, err);
      }
    }

    // process this data and combine into one list where the only info is progress out of 100
    return new Response(JSON.stringify([...studentMap]), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      status: 200
    });
  }catch(error){
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
})

