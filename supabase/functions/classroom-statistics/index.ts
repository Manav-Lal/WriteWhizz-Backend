import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import SupabaseClient from "../_shared/supabaseClient.ts";


Deno.serve(async (req) => {
  try {
    const supabaseClient = SupabaseClient(req)

    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    const { data: { user },userError } = await supabaseClient.auth.getUser(token)

// Check if there's an error or no user found
    if (userError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 401
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
        console.log(student.student_id)
        const { data: attempted, error: lessonError } = await supabaseClient
            .from('lesson_progress')
            .select("lesson_id, lesson(activity_amt),completed_activities")
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
            .select("lesson_id, lesson(activity_amt)")
            .eq("student_id", student.student_id)

        // Add assignedWithZero if not already present
        assigned?.forEach(item => {
          if (!map.has(item.lesson_id)) {
            map.set(item.lesson_id, {...item, completed_activities: 0});
          }
        });
        // Store in studentMap
        studentMap.set(student.student_id, Array.from(map.values()));

      } catch (err) {
        console.error(`Error processing student ${student.student_id}:`, err);
      }
    }

    console.log(studentMap); // You can print or process the studentMap as needed

    // process this data and combine into one list where the only info is progress out of 100
    return new Response(JSON.stringify([...studentMap]), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 200
    });
  }catch(error){
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: error.status
    });
  }
})

