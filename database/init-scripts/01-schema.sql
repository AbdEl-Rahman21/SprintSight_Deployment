BEGIN;


CREATE TABLE IF NOT EXISTS public.comments
(
    id uuid NOT NULL,
    content text COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    user_id uuid NOT NULL,
    issue_id uuid NOT NULL,
    CONSTRAINT comments_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.components
(
    id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    description character varying(500) COLLATE pg_catalog."default",
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    project_id uuid NOT NULL,
    CONSTRAINT components_pkey PRIMARY KEY (id),
    CONSTRAINT components_project_name_key UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS public.issue_components
(
    issue_id uuid NOT NULL,
    component_id uuid NOT NULL,
    CONSTRAINT issue_components_pkey PRIMARY KEY (issue_id, component_id)
);

CREATE TABLE IF NOT EXISTS public.issue_events
(
    id uuid NOT NULL,
    changed_at timestamp(6) with time zone NOT NULL,
    field_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    new_value text COLLATE pg_catalog."default",
    old_value text COLLATE pg_catalog."default",
    changed_by uuid NOT NULL,
    issue_id uuid NOT NULL,
    CONSTRAINT issue_events_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.issue_priority_configs
(
    id uuid NOT NULL,
    is_default boolean NOT NULL,
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    order_index integer NOT NULL,
    project_id uuid NOT NULL,
    CONSTRAINT issue_priority_configs_pkey PRIMARY KEY (id),
    CONSTRAINT issue_priority_project_name_key UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS public.issue_status_configs
(
    id uuid NOT NULL,
    is_completed boolean NOT NULL,
    is_default boolean NOT NULL,
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    order_index integer NOT NULL,
    project_id uuid NOT NULL,
    CONSTRAINT issue_status_configs_pkey PRIMARY KEY (id),
    CONSTRAINT issue_status_project_name_key UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS public.issue_type_configs
(
    id uuid NOT NULL,
    is_default boolean NOT NULL,
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    project_id uuid NOT NULL,
    CONSTRAINT issue_type_configs_pkey PRIMARY KEY (id),
    CONSTRAINT issue_type_project_name_key UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS public.issues
(
    id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    description text COLLATE pg_catalog."default",
    fix_version character varying(50) COLLATE pg_catalog."default",
    story_points integer,
    title character varying(255) COLLATE pg_catalog."default" NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    assigned_to uuid,
    created_by uuid,
    priority_id uuid NOT NULL,
    project_id uuid NOT NULL,
    status_id uuid NOT NULL,
    type_id uuid NOT NULL,
    CONSTRAINT issues_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.project_invitations
(
    id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    intended_role character varying(255) COLLATE pg_catalog."default" NOT NULL,
    responded_at timestamp(6) with time zone,
    status character varying(255) COLLATE pg_catalog."default" NOT NULL,
    project_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    CONSTRAINT project_invitations_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.project_members
(
    joined_at timestamp(6) with time zone NOT NULL,
    project_role character varying(255) COLLATE pg_catalog."default" NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT project_members_pkey PRIMARY KEY (project_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.projects
(
    id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    description text COLLATE pg_catalog."default",
    image_url character varying(512) COLLATE pg_catalog."default",
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    created_by uuid NOT NULL,
    CONSTRAINT projects_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.refresh_tokens
(
    id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    expiry_date timestamp(6) with time zone NOT NULL,
    token character varying(255) COLLATE pg_catalog."default" NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id),
    CONSTRAINT ukghpmfn23vmxfu3spu3lfg4r2d UNIQUE (token)
);

CREATE TABLE IF NOT EXISTS public.sprint_issues
(
    id uuid NOT NULL,
    added_at timestamp(6) with time zone NOT NULL,
    removed_at timestamp(6) with time zone,
    issue_id uuid NOT NULL,
    sprint_id uuid NOT NULL,
    status_at_closure_id uuid,
    CONSTRAINT sprint_issues_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.sprints
(
    id uuid NOT NULL,
    completed_at timestamp(6) with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    end_date date,
    goal text COLLATE pg_catalog."default",
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    start_date date,
    status character varying(255) COLLATE pg_catalog."default" NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    project_id uuid NOT NULL,
    CONSTRAINT sprints_pkey PRIMARY KEY (id),
    CONSTRAINT sprints_project_name_key UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS public.users
(
    id uuid NOT NULL,
    bio character varying(500) COLLATE pg_catalog."default",
    created_at timestamp(6) with time zone NOT NULL,
    email character varying(255) COLLATE pg_catalog."default" NOT NULL,
    enabled boolean NOT NULL,
    full_name character varying(100) COLLATE pg_catalog."default",
    password character varying(255) COLLATE pg_catalog."default" NOT NULL,
    profile_picture_url character varying(512) COLLATE pg_catalog."default",
    updated_at timestamp(6) with time zone NOT NULL,
    user_role character varying(255) COLLATE pg_catalog."default" NOT NULL,
    username character varying(50) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT users_username_key UNIQUE (username)
);

ALTER TABLE IF EXISTS public.comments
    ADD CONSTRAINT fk287j1dpionjmfs2yycfjmy5j2 FOREIGN KEY (issue_id)
    REFERENCES public.issues (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS comments_issue_idx
    ON public.comments(issue_id);


ALTER TABLE IF EXISTS public.comments
    ADD CONSTRAINT fk8omq0tc18jd43bu5tjh6jvraq FOREIGN KEY (user_id)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS comments_user_idx
    ON public.comments(user_id);


ALTER TABLE IF EXISTS public.components
    ADD CONSTRAINT fkqn9vdp8971uqbjh5n0xce52kn FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS components_project_idx
    ON public.components(project_id);


ALTER TABLE IF EXISTS public.issue_components
    ADD CONSTRAINT fkb0pfv68uovj9bmt6i7upqhco3 FOREIGN KEY (component_id)
    REFERENCES public.components (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.issue_components
    ADD CONSTRAINT fkmk6i25qxqxwor0nnx3rvktv6o FOREIGN KEY (issue_id)
    REFERENCES public.issues (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.issue_events
    ADD CONSTRAINT fkj5g0gvsb8brgsf6573gckw39a FOREIGN KEY (issue_id)
    REFERENCES public.issues (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS issue_events_issue_idx
    ON public.issue_events(issue_id);


ALTER TABLE IF EXISTS public.issue_events
    ADD CONSTRAINT fkr69dstnvdpi4w70iqsht0bewq FOREIGN KEY (changed_by)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS issue_events_changed_by_idx
    ON public.issue_events(changed_by);


ALTER TABLE IF EXISTS public.issue_priority_configs
    ADD CONSTRAINT fk2vwj7xha5g4928e084ms2pa10 FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS issue_priority_project_idx
    ON public.issue_priority_configs(project_id);


ALTER TABLE IF EXISTS public.issue_status_configs
    ADD CONSTRAINT fk419l9523i7qcw7lalbnglvftl FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS issue_status_project_idx
    ON public.issue_status_configs(project_id);


ALTER TABLE IF EXISTS public.issue_type_configs
    ADD CONSTRAINT fkgr74qxlw1njyqq85fy0dpx1f6 FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS issue_type_project_idx
    ON public.issue_type_configs(project_id);


ALTER TABLE IF EXISTS public.issues
    ADD CONSTRAINT fk4j2x3reshuu7qj5svh6eacnpt FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS issues_project_idx
    ON public.issues(project_id);


ALTER TABLE IF EXISTS public.issues
    ADD CONSTRAINT fk5bf1viph0f0wa99esuvbc0895 FOREIGN KEY (assigned_to)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS issues_assignee_idx
    ON public.issues(assigned_to);


ALTER TABLE IF EXISTS public.issues
    ADD CONSTRAINT fkeytvklidnnq8cnpeybixvy9rv FOREIGN KEY (created_by)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE SET NULL;


ALTER TABLE IF EXISTS public.issues
    ADD CONSTRAINT fkj77fqcqs2okpcmi7w3gyc71vu FOREIGN KEY (status_id)
    REFERENCES public.issue_status_configs (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;


ALTER TABLE IF EXISTS public.issues
    ADD CONSTRAINT fkkuo8b50414rpymf5t8kvaddbe FOREIGN KEY (type_id)
    REFERENCES public.issue_type_configs (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;


ALTER TABLE IF EXISTS public.issues
    ADD CONSTRAINT fku33gccrw8lpwtioavi3406qm FOREIGN KEY (priority_id)
    REFERENCES public.issue_priority_configs (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;


ALTER TABLE IF EXISTS public.project_invitations
    ADD CONSTRAINT fkhk66j7po8n11yhiagqfvtpn0l FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS invitations_project_idx
    ON public.project_invitations(project_id);


ALTER TABLE IF EXISTS public.project_invitations
    ADD CONSTRAINT fkm829hbibox67n9pliqkvnbjl7 FOREIGN KEY (sender_id)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.project_invitations
    ADD CONSTRAINT fkn1bbgcc7wdp0n47uxpe1bfi93 FOREIGN KEY (receiver_id)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.project_members
    ADD CONSTRAINT fkdki1sp2homqsdcvqm9yrix31g FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
CREATE INDEX IF NOT EXISTS project_members_project_idx
    ON public.project_members(project_id);


ALTER TABLE IF EXISTS public.project_members
    ADD CONSTRAINT fkgul2el0qjk5lsvig3wgajwm77 FOREIGN KEY (user_id)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.projects
    ADD CONSTRAINT fkf1ph00os6khfle3ub9b50x594 FOREIGN KEY (created_by)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.refresh_tokens
    ADD CONSTRAINT fk1lih5y2npsf8u5o3vhdb9y0os FOREIGN KEY (user_id)
    REFERENCES public.users (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.sprint_issues
    ADD CONSTRAINT fk7y1nftwc1xfgi8sf5d3hb89v3 FOREIGN KEY (sprint_id)
    REFERENCES public.sprints (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS sprint_issues_sprint_idx
    ON public.sprint_issues(sprint_id);


ALTER TABLE IF EXISTS public.sprint_issues
    ADD CONSTRAINT fkkgp74v731k8b55vblu1d3cqkl FOREIGN KEY (status_at_closure_id)
    REFERENCES public.issue_status_configs (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE SET NULL;


ALTER TABLE IF EXISTS public.sprint_issues
    ADD CONSTRAINT fks2cg7g8g57iufd98918x3fnd2 FOREIGN KEY (issue_id)
    REFERENCES public.issues (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS sprint_issues_issue_idx
    ON public.sprint_issues(issue_id);


ALTER TABLE IF EXISTS public.sprints
    ADD CONSTRAINT fkke5a9e380ibc0xugykeqaktp4 FOREIGN KEY (project_id)
    REFERENCES public.projects (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS sprints_project_idx
    ON public.sprints(project_id);


CREATE INDEX IF NOT EXISTS users_username_lower_pattern_idx
    ON users (LOWER(username) text_pattern_ops);

END;

