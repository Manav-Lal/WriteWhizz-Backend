

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."activity_type" AS ENUM (
    'lowercase',
    'combination',
    'uppercase',
    'numerals',
    'fill in the gap',
    'sentence writing',
    'proper nouns'
);


ALTER TYPE "public"."activity_type" OWNER TO "postgres";


COMMENT ON TYPE "public"."activity_type" IS 'The type of activity that the lesson represent. Each type of activity has a slightly different layout of activities as defined in the App';



CREATE TYPE "public"."role" AS ENUM (
    'student',
    'teacher',
    'parent',
    'child'
);


ALTER TYPE "public"."role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_if_username_exists"("requested_username" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE username_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM profiles WHERE username = requested_username) INTO username_exists;
    RETURN username_exists;
END;$$;


ALTER FUNCTION "public"."check_if_username_exists"("requested_username" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_email_from_username"("requested_username" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE user_email TEXT;
BEGIN
    SELECT email INTO user_email FROM profiles WHERE username = requested_username;
    
    -- If no user found, return NULL
    IF user_email IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN user_email;
END;
$$;


ALTER FUNCTION "public"."get_email_from_username"("requested_username" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."return_assigned"("student_id" "uuid") RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$DECLARE
    result JSON;
BEGIN
    SELECT json_agg(user_assigned_lesson) INTO result
    FROM user_assigned_lesson
    WHERE user_id = student_id;

    RETURN result;
END;$$;


ALTER FUNCTION "public"."return_assigned"("student_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."cities" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "country_id" bigint
);


ALTER TABLE "public"."cities" OWNER TO "postgres";


COMMENT ON TABLE "public"."cities" IS 'A test entry';



ALTER TABLE "public"."cities" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."cities_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."lesson" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "level_id" smallint,
    "activity_letters" "text" DEFAULT ''::"text",
    "activity_type" "public"."activity_type",
    "activity_amt" smallint DEFAULT '0'::smallint NOT NULL,
    CONSTRAINT "lesson_level_id_check" CHECK (("level_id" > 0))
);


ALTER TABLE "public"."lesson" OWNER TO "postgres";


COMMENT ON COLUMN "public"."lesson"."level_id" IS 'The numeric identifyer of the level. This is in order of intended completion';



COMMENT ON COLUMN "public"."lesson"."activity_letters" IS 'The set of letters primarily focused on for this lesson';



COMMENT ON COLUMN "public"."lesson"."activity_type" IS 'The type of activity that is to be loaded inside the App, as each has a slightly different layout';



COMMENT ON COLUMN "public"."lesson"."activity_amt" IS 'How many activites are there in total for this particular lesson? This will match up with the progress the user makes within the App.';



ALTER TABLE "public"."lesson" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."lesson_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."lesson_progress" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "lesson_id" bigint NOT NULL,
    "avg_tracing_score" double precision DEFAULT 0.0,
    "tracing_speed_variance" double precision DEFAULT 0.0,
    "failures" integer DEFAULT 0,
    "successes" integer DEFAULT 0,
    "time_spent" interval DEFAULT '00:00:00'::interval,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "completed_activities" smallint DEFAULT '0'::smallint NOT NULL
);


ALTER TABLE "public"."lesson_progress" OWNER TO "postgres";


COMMENT ON COLUMN "public"."lesson_progress"."completed_activities" IS 'How many activities within this lesson has the user completed';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "username" "text" NOT NULL,
    "email" "text",
    "user_role" "public"."role",
    "first_name" "text",
    "last_name" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."user_role" IS 'Used to determine privileges at a glance';



CREATE TABLE IF NOT EXISTS "public"."students" (
    "student_id" "uuid" NOT NULL,
    "teacher_id" "uuid",
    "classroom_id" "text",
    "national_id" "uuid"
);


ALTER TABLE "public"."students" OWNER TO "postgres";


COMMENT ON COLUMN "public"."students"."classroom_id" IS 'The name of the classroom that the teacher has assigned them. This is plain text, as we will allow teachers to name these classrooms themselves.';



COMMENT ON COLUMN "public"."students"."national_id" IS 'The ID of the student in the government system. Used if we need to link or pull data or allow teachers to export data with this attached to the correct student.';



CREATE TABLE IF NOT EXISTS "public"."teachers" (
    "teacher_id" "uuid" NOT NULL,
    "country" "text",
    "school_name" "text",
    "school_id" "text"
);


ALTER TABLE "public"."teachers" OWNER TO "postgres";


COMMENT ON COLUMN "public"."teachers"."country" IS 'The name of the country they work within. This will be primarliy populated from a FrontEnd Dropdown, so inputs should be uniform';



COMMENT ON COLUMN "public"."teachers"."school_name" IS 'The name of the school that they work at';



COMMENT ON COLUMN "public"."teachers"."school_id" IS 'The national or International ID of the school, if one exists';



CREATE TABLE IF NOT EXISTS "public"."user_assigned_lesson" (
    "user_id" "uuid" NOT NULL,
    "lesson_id" bigint NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "public"."user_assigned_lesson" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_completed_lessons" (
    "user_id" "uuid" NOT NULL,
    "lesson_id" bigint,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "public"."user_completed_lessons" OWNER TO "postgres";


ALTER TABLE ONLY "public"."cities"
    ADD CONSTRAINT "cities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lesson"
    ADD CONSTRAINT "lesson_id_key" UNIQUE ("id");



ALTER TABLE ONLY "public"."lesson"
    ADD CONSTRAINT "lesson_level_id_key" UNIQUE ("level_id");



ALTER TABLE ONLY "public"."lesson"
    ADD CONSTRAINT "lesson_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lesson_progress"
    ADD CONSTRAINT "lesson_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."students"
    ADD CONSTRAINT "students_national_id_key" UNIQUE ("national_id");



ALTER TABLE ONLY "public"."students"
    ADD CONSTRAINT "students_pkey" PRIMARY KEY ("student_id");



ALTER TABLE ONLY "public"."teachers"
    ADD CONSTRAINT "teachers_pkey" PRIMARY KEY ("teacher_id");



ALTER TABLE ONLY "public"."user_assigned_lesson"
    ADD CONSTRAINT "user_assigned_lesson_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_completed_lessons"
    ADD CONSTRAINT "user_completed_lessons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lesson_progress"
    ADD CONSTRAINT "lesson_progress_lesson_id_fkey" FOREIGN KEY ("lesson_id") REFERENCES "public"."lesson"("id");



ALTER TABLE ONLY "public"."lesson_progress"
    ADD CONSTRAINT "lesson_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."students"
    ADD CONSTRAINT "students_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."students"
    ADD CONSTRAINT "students_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."teachers"
    ADD CONSTRAINT "teachers_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_assigned_lesson"
    ADD CONSTRAINT "user_assigned_lesson_lesson_id_fkey" FOREIGN KEY ("lesson_id") REFERENCES "public"."lesson"("id");



ALTER TABLE ONLY "public"."user_assigned_lesson"
    ADD CONSTRAINT "user_assigned_lesson_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_completed_lessons"
    ADD CONSTRAINT "user_completed_lessons_lesson_id_fkey" FOREIGN KEY ("lesson_id") REFERENCES "public"."lesson"("id");



ALTER TABLE ONLY "public"."user_completed_lessons"
    ADD CONSTRAINT "user_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



CREATE POLICY "Enable insert for authenticated users only" ON "public"."cities" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable read access for all users" ON "public"."lesson" FOR SELECT USING (true);



CREATE POLICY "Enable users to view their own data only" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Teacher can view their students' progress" ON "public"."lesson_progress" FOR SELECT USING (("auth"."uid"() = ( SELECT "students"."teacher_id"
   FROM "public"."students"
  WHERE ("students"."student_id" = "lesson_progress"."user_id"))));



CREATE POLICY "Teacher can view their students' progress" ON "public"."user_completed_lessons" FOR SELECT USING (("auth"."uid"() IN ( SELECT "students"."teacher_id"
   FROM "public"."students"
  WHERE ("students"."student_id" = "user_completed_lessons"."user_id"))));



CREATE POLICY "Teachers have CRUD access to their own students." ON "public"."students" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "teacher_id"));



CREATE POLICY "User can update their own progress" ON "public"."lesson_progress" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "User can update their own progress" ON "public"."user_completed_lessons" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "User can view their own progress" ON "public"."lesson_progress" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "User can view their own progress" ON "public"."user_completed_lessons" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own profile" ON "public"."profiles" FOR INSERT WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE USING (("id" = "auth"."uid"()));



ALTER TABLE "public"."cities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."lesson" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_assigned_lesson" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";




















































































































































































GRANT ALL ON FUNCTION "public"."check_if_username_exists"("requested_username" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."check_if_username_exists"("requested_username" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_if_username_exists"("requested_username" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_email_from_username"("requested_username" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_email_from_username"("requested_username" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_email_from_username"("requested_username" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."return_assigned"("student_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."return_assigned"("student_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."return_assigned"("student_id" "uuid") TO "service_role";


















GRANT ALL ON TABLE "public"."cities" TO "anon";
GRANT ALL ON TABLE "public"."cities" TO "authenticated";
GRANT ALL ON TABLE "public"."cities" TO "service_role";



GRANT ALL ON SEQUENCE "public"."cities_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."cities_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."cities_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."lesson" TO "anon";
GRANT ALL ON TABLE "public"."lesson" TO "authenticated";
GRANT ALL ON TABLE "public"."lesson" TO "service_role";



GRANT ALL ON SEQUENCE "public"."lesson_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."lesson_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."lesson_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."lesson_progress" TO "anon";
GRANT ALL ON TABLE "public"."lesson_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."lesson_progress" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."students" TO "anon";
GRANT ALL ON TABLE "public"."students" TO "authenticated";
GRANT ALL ON TABLE "public"."students" TO "service_role";



GRANT ALL ON TABLE "public"."teachers" TO "anon";
GRANT ALL ON TABLE "public"."teachers" TO "authenticated";
GRANT ALL ON TABLE "public"."teachers" TO "service_role";



GRANT ALL ON TABLE "public"."user_assigned_lesson" TO "anon";
GRANT ALL ON TABLE "public"."user_assigned_lesson" TO "authenticated";
GRANT ALL ON TABLE "public"."user_assigned_lesson" TO "service_role";



GRANT ALL ON TABLE "public"."user_completed_lessons" TO "anon";
GRANT ALL ON TABLE "public"."user_completed_lessons" TO "authenticated";
GRANT ALL ON TABLE "public"."user_completed_lessons" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
