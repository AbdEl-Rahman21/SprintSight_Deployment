CREATE OR REPLACE FUNCTION extract_sprint_input(p_sprint_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_start_date date;
    v_end_date   date;
    v_cutoff     timestamptz;
    v_result     jsonb;
BEGIN
    SELECT s.start_date, s.end_date INTO v_start_date, v_end_date
      FROM sprints s WHERE s.id = p_sprint_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'sprint % not found', p_sprint_id;
    END IF;
    v_cutoff := COALESCE(v_start_date::timestamptz, now());

    WITH scope AS (
        SELECT si.issue_id FROM sprint_issues si
         WHERE si.sprint_id = p_sprint_id
           AND si.added_at <= v_cutoff
           AND (si.removed_at IS NULL OR si.removed_at > v_cutoff)
    ),
    issue AS (
        SELECT
            i.id,
            (SELECT count(*) FROM issue_components ic WHERE ic.issue_id = i.id) AS no_component,
            (SELECT count(*) FROM comments c WHERE c.issue_id = i.id AND c.created_at <= v_cutoff) AS no_comments,
            (SELECT count(*) FROM issue_events e WHERE e.issue_id=i.id AND e.changed_at<v_cutoff AND e.field_name='DESCRIPTION') AS chg_desc,
            (SELECT count(*) FROM issue_events e WHERE e.issue_id=i.id AND e.changed_at<v_cutoff AND e.field_name='PRIORITY')    AS chg_prio,
            (SELECT count(*) FROM issue_events e WHERE e.issue_id=i.id AND e.changed_at<v_cutoff AND e.field_name='FIX_VERSION') AS chg_fix,
            tc.name AS type_name,
            pc.name AS prio_name,
            trim(coalesce(i.title,'')||' '||coalesce(i.description,'')) AS text
          FROM issues i
          JOIN scope sc ON sc.issue_id = i.id
          LEFT JOIN issue_type_configs     tc ON tc.id = i.type_id
          LEFT JOIN issue_priority_configs pc ON pc.id = i.priority_id
    ),
    dev_action AS (
        SELECT e.changed_by AS uid, e.issue_id, e.field_name AS action
          FROM issue_events e JOIN scope sc ON sc.issue_id = e.issue_id
         WHERE e.changed_at < v_cutoff AND e.changed_by IS NOT NULL
        UNION ALL
        SELECT c.user_id, c.issue_id, 'COMMENT' FROM comments c JOIN scope sc ON sc.issue_id=c.issue_id
         WHERE c.created_at <= v_cutoff AND c.user_id IS NOT NULL
        UNION ALL
        SELECT i.created_by, i.id, 'CREATE' FROM issues i JOIN scope sc ON sc.issue_id=i.id
         WHERE i.created_by IS NOT NULL AND i.created_at < v_cutoff
    ),
    dev AS (
        SELECT uid, count(DISTINCT action) AS no_distinct_action, count(DISTINCT issue_id) AS activeness
          FROM dev_action GROUP BY uid
    ),
    dev_pref AS (
        SELECT DISTINCT ON (da.uid) da.uid, tc.name AS type_name
          FROM dev_action da
          JOIN issues i ON i.id = da.issue_id
          LEFT JOIN issue_type_configs tc ON tc.id = i.type_id
         GROUP BY da.uid, tc.name
         ORDER BY da.uid, count(*) DESC, tc.name
    )
    SELECT jsonb_build_object(
        'plan_duration_hours', GREATEST(COALESCE((v_end_date - v_start_date)*24, 0), 0),
        'no_issues',           (SELECT count(*) FROM scope),
        'no_team_members',     GREATEST((SELECT count(*) FROM dev), 1),
        'no_components',       COALESCE((SELECT sum(no_component) FROM issue), 0),
        'no_comments',         COALESCE((SELECT sum(no_comments) FROM issue), 0),
        'no_description_changes', COALESCE((SELECT sum(chg_desc) FROM issue), 0),
        'no_priority_changes',    COALESCE((SELECT sum(chg_prio) FROM issue), 0),
        'no_fix_version_changes', COALESCE((SELECT sum(chg_fix)  FROM issue), 0),
        'type_bug_count',             (SELECT count(*) FROM issue WHERE type_name='Bug'),
        'type_suggestion_count',      (SELECT count(*) FROM issue WHERE type_name='Suggestion'),
        'type_support_request_count', (SELECT count(*) FROM issue WHERE type_name='Support Request'),
        'priority_blocker_count',  (SELECT count(*) FROM issue WHERE prio_name='Blocker'),
        'priority_critical_count', (SELECT count(*) FROM issue WHERE prio_name='Critical'),
        'priority_high_count',     (SELECT count(*) FROM issue WHERE prio_name='High'),
        'priority_highest_count',  (SELECT count(*) FROM issue WHERE prio_name='Highest'),
        'priority_low_count',      (SELECT count(*) FROM issue WHERE prio_name='Low'),
        'priority_major_count',    (SELECT count(*) FROM issue WHERE prio_name='Major'),
        'priority_medium_count',   (SELECT count(*) FROM issue WHERE prio_name='Medium'),
        'priority_minor_count',    (SELECT count(*) FROM issue WHERE prio_name='Minor'),
        'priority_trivial_count',  (SELECT count(*) FROM issue WHERE prio_name='Trivial'),
        'no_distinct_actions',  COALESCE((SELECT sum(no_distinct_action) FROM dev), 0),
        'developer_activeness', COALESCE((SELECT round(avg(activeness),4) FROM dev), 0),
        'dev_prefer_bug_count',        (SELECT count(*) FROM dev_pref WHERE type_name='Bug'),
        'dev_prefer_na_count',         (SELECT count(*) FROM dev_pref WHERE type_name IS NULL),
        'dev_prefer_subtask_count',   (SELECT count(*) FROM dev_pref WHERE type_name='Sub-task'),
        'dev_prefer_suggestion_count', (SELECT count(*) FROM dev_pref WHERE type_name='Suggestion'),
        'sprint_text', COALESCE(NULLIF(trim((SELECT string_agg(text, ' ') FROM issue)), ''), '[EMPTY]')
    ) INTO v_result;

    RETURN v_result;
END;
$$;

