drop policy "Teacher can view their students' progress" on "public"."user_completed_lessons";

drop policy "User can update their own progress" on "public"."user_completed_lessons";

drop policy "User can view their own progress" on "public"."user_completed_lessons";

revoke delete on table "public"."user_assigned_lesson" from "anon";

revoke insert on table "public"."user_assigned_lesson" from "anon";

revoke references on table "public"."user_assigned_lesson" from "anon";

revoke select on table "public"."user_assigned_lesson" from "anon";

revoke trigger on table "public"."user_assigned_lesson" from "anon";

revoke truncate on table "public"."user_assigned_lesson" from "anon";

revoke update on table "public"."user_assigned_lesson" from "anon";

revoke delete on table "public"."user_assigned_lesson" from "authenticated";

revoke insert on table "public"."user_assigned_lesson" from "authenticated";

revoke references on table "public"."user_assigned_lesson" from "authenticated";

revoke select on table "public"."user_assigned_lesson" from "authenticated";

revoke trigger on table "public"."user_assigned_lesson" from "authenticated";

revoke truncate on table "public"."user_assigned_lesson" from "authenticated";

revoke update on table "public"."user_assigned_lesson" from "authenticated";

revoke delete on table "public"."user_assigned_lesson" from "service_role";

revoke insert on table "public"."user_assigned_lesson" from "service_role";

revoke references on table "public"."user_assigned_lesson" from "service_role";

revoke select on table "public"."user_assigned_lesson" from "service_role";

revoke trigger on table "public"."user_assigned_lesson" from "service_role";

revoke truncate on table "public"."user_assigned_lesson" from "service_role";

revoke update on table "public"."user_assigned_lesson" from "service_role";

revoke delete on table "public"."user_completed_lessons" from "anon";

revoke insert on table "public"."user_completed_lessons" from "anon";

revoke references on table "public"."user_completed_lessons" from "anon";

revoke select on table "public"."user_completed_lessons" from "anon";

revoke trigger on table "public"."user_completed_lessons" from "anon";

revoke truncate on table "public"."user_completed_lessons" from "anon";

revoke update on table "public"."user_completed_lessons" from "anon";

revoke delete on table "public"."user_completed_lessons" from "authenticated";

revoke insert on table "public"."user_completed_lessons" from "authenticated";

revoke references on table "public"."user_completed_lessons" from "authenticated";

revoke select on table "public"."user_completed_lessons" from "authenticated";

revoke trigger on table "public"."user_completed_lessons" from "authenticated";

revoke truncate on table "public"."user_completed_lessons" from "authenticated";

revoke update on table "public"."user_completed_lessons" from "authenticated";

revoke delete on table "public"."user_completed_lessons" from "service_role";

revoke insert on table "public"."user_completed_lessons" from "service_role";

revoke references on table "public"."user_completed_lessons" from "service_role";

revoke select on table "public"."user_completed_lessons" from "service_role";

revoke trigger on table "public"."user_completed_lessons" from "service_role";

revoke truncate on table "public"."user_completed_lessons" from "service_role";

revoke update on table "public"."user_completed_lessons" from "service_role";

alter table "public"."user_assigned_lesson" drop constraint "user_assigned_lesson_lesson_id_fkey";

alter table "public"."user_assigned_lesson" drop constraint "user_assigned_lesson_user_id_fkey";

alter table "public"."user_completed_lessons" drop constraint "user_completed_lessons_lesson_id_fkey";

alter table "public"."user_completed_lessons" drop constraint "user_progress_user_id_fkey";

alter table "public"."user_assigned_lesson" drop constraint "user_assigned_lesson_pkey";

alter table "public"."user_completed_lessons" drop constraint "user_completed_lessons_pkey";

drop index if exists "public"."user_assigned_lesson_pkey";

drop index if exists "public"."user_completed_lessons_pkey";

drop table "public"."user_assigned_lesson";

drop table "public"."user_completed_lessons";

create table "public"."student_assigned_lesson" (
    "student_id" uuid not null,
    "lesson_id" bigint not null,
    "id" uuid not null default gen_random_uuid()
);


alter table "public"."student_assigned_lesson" enable row level security;

create table "public"."student_completed_lessons" (
    "student_id" uuid not null,
    "lesson_id" bigint,
    "id" uuid not null default gen_random_uuid()
);


CREATE UNIQUE INDEX user_assigned_lesson_pkey ON public.student_assigned_lesson USING btree (id);

CREATE UNIQUE INDEX user_completed_lessons_pkey ON public.student_completed_lessons USING btree (id);

alter table "public"."student_assigned_lesson" add constraint "user_assigned_lesson_pkey" PRIMARY KEY using index "user_assigned_lesson_pkey";

alter table "public"."student_completed_lessons" add constraint "user_completed_lessons_pkey" PRIMARY KEY using index "user_completed_lessons_pkey";

alter table "public"."student_assigned_lesson" add constraint "student_assigned_lesson_student_id_fkey" FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE not valid;

alter table "public"."student_assigned_lesson" validate constraint "student_assigned_lesson_student_id_fkey";

alter table "public"."student_assigned_lesson" add constraint "user_assigned_lesson_lesson_id_fkey" FOREIGN KEY (lesson_id) REFERENCES lesson(id) not valid;

alter table "public"."student_assigned_lesson" validate constraint "user_assigned_lesson_lesson_id_fkey";

alter table "public"."student_assigned_lesson" add constraint "user_assigned_lesson_user_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE not valid;

alter table "public"."student_assigned_lesson" validate constraint "user_assigned_lesson_user_id_fkey";

alter table "public"."student_completed_lessons" add constraint "student_completed_lessons_student_id_fkey" FOREIGN KEY (student_id) REFERENCES students(student_id) not valid;

alter table "public"."student_completed_lessons" validate constraint "student_completed_lessons_student_id_fkey";

alter table "public"."student_completed_lessons" add constraint "user_completed_lessons_lesson_id_fkey" FOREIGN KEY (lesson_id) REFERENCES lesson(id) not valid;

alter table "public"."student_completed_lessons" validate constraint "user_completed_lessons_lesson_id_fkey";

alter table "public"."student_completed_lessons" add constraint "user_progress_user_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE not valid;

alter table "public"."student_completed_lessons" validate constraint "user_progress_user_id_fkey";

grant delete on table "public"."student_assigned_lesson" to "anon";

grant insert on table "public"."student_assigned_lesson" to "anon";

grant references on table "public"."student_assigned_lesson" to "anon";

grant select on table "public"."student_assigned_lesson" to "anon";

grant trigger on table "public"."student_assigned_lesson" to "anon";

grant truncate on table "public"."student_assigned_lesson" to "anon";

grant update on table "public"."student_assigned_lesson" to "anon";

grant delete on table "public"."student_assigned_lesson" to "authenticated";

grant insert on table "public"."student_assigned_lesson" to "authenticated";

grant references on table "public"."student_assigned_lesson" to "authenticated";

grant select on table "public"."student_assigned_lesson" to "authenticated";

grant trigger on table "public"."student_assigned_lesson" to "authenticated";

grant truncate on table "public"."student_assigned_lesson" to "authenticated";

grant update on table "public"."student_assigned_lesson" to "authenticated";

grant delete on table "public"."student_assigned_lesson" to "service_role";

grant insert on table "public"."student_assigned_lesson" to "service_role";

grant references on table "public"."student_assigned_lesson" to "service_role";

grant select on table "public"."student_assigned_lesson" to "service_role";

grant trigger on table "public"."student_assigned_lesson" to "service_role";

grant truncate on table "public"."student_assigned_lesson" to "service_role";

grant update on table "public"."student_assigned_lesson" to "service_role";

grant delete on table "public"."student_completed_lessons" to "anon";

grant insert on table "public"."student_completed_lessons" to "anon";

grant references on table "public"."student_completed_lessons" to "anon";

grant select on table "public"."student_completed_lessons" to "anon";

grant trigger on table "public"."student_completed_lessons" to "anon";

grant truncate on table "public"."student_completed_lessons" to "anon";

grant update on table "public"."student_completed_lessons" to "anon";

grant delete on table "public"."student_completed_lessons" to "authenticated";

grant insert on table "public"."student_completed_lessons" to "authenticated";

grant references on table "public"."student_completed_lessons" to "authenticated";

grant select on table "public"."student_completed_lessons" to "authenticated";

grant trigger on table "public"."student_completed_lessons" to "authenticated";

grant truncate on table "public"."student_completed_lessons" to "authenticated";

grant update on table "public"."student_completed_lessons" to "authenticated";

grant delete on table "public"."student_completed_lessons" to "service_role";

grant insert on table "public"."student_completed_lessons" to "service_role";

grant references on table "public"."student_completed_lessons" to "service_role";

grant select on table "public"."student_completed_lessons" to "service_role";

grant trigger on table "public"."student_completed_lessons" to "service_role";

grant truncate on table "public"."student_completed_lessons" to "service_role";

grant update on table "public"."student_completed_lessons" to "service_role";

create policy "Teacher can view their students' progress"
on "public"."student_completed_lessons"
as permissive
for select
to public
using ((auth.uid() IN ( SELECT students.teacher_id
   FROM students
  WHERE (students.student_id = student_completed_lessons.student_id))));


create policy "User can update their own progress"
on "public"."student_completed_lessons"
as permissive
for update
to public
using ((auth.uid() = student_id));


create policy "User can view their own progress"
on "public"."student_completed_lessons"
as permissive
for select
to public
using ((auth.uid() = student_id));



