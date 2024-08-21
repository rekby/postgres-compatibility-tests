--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7 (Debian 14.7-1.pgdg110+1)
-- Dumped by pg_dump version 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
-- SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- SET default_tablespace = '';

-- SET default_table_access_method = heap;

--
-- Name: alert; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert (
    id SERIAL NOT NULL,
    version int NOT NULL,
    dashboard_id int NOT NULL,
    panel_id int NOT NULL,
    org_id int NOT NULL,
    name character varying(255) NOT NULL,
    message text NOT NULL,
    state character varying(190) NOT NULL,
    settings text NOT NULL,
    frequency int NOT NULL,
    handler int NOT NULL,
    severity text NOT NULL,
    silenced boolean NOT NULL,
    execution_error text NOT NULL,
    eval_data text,
    eval_date timestamp without time zone,
    new_state_date timestamp without time zone NOT NULL,
    state_changes integer NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    "for" bigint,
    PRIMARY KEY(id)
);


--

--
-- Name: alert_configuration; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_configuration (
    id SERIAL NOT NULL,
    alertmanager_configuration text NOT NULL,
    configuration_version character varying(3) NOT NULL,
    created_at integer NOT NULL,
    "default" boolean DEFAULT false NOT NULL,
    org_id int DEFAULT 0 NOT NULL,
    configuration_hash character varying(32) DEFAULT 'not-yet-calculated'::character varying NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: alert_configuration_history; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_configuration_history (
    id SERIAL NOT NULL,
    org_id int DEFAULT 0 NOT NULL,
    alertmanager_configuration text NOT NULL,
    configuration_hash character varying(32) DEFAULT 'not-yet-calculated'::character varying NOT NULL,
    configuration_version character varying(3) NOT NULL,
    created_at integer NOT NULL,
    "default" boolean DEFAULT false NOT NULL,
    last_applied integer DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: alert_image; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_image (
    id SERIAL NOT NULL,
    token character varying(190) NOT NULL,
    path character varying(190) NOT NULL,
    url character varying(2048) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);



--
-- Name: alert_instance; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_instance (
    rule_org_id int NOT NULL,
    rule_uid character varying(40) DEFAULT '0' NOT NULL,
    labels text NOT NULL,
    labels_hash character varying(190) NOT NULL,
    current_state character varying(190) NOT NULL,
    current_state_since int NOT NULL,
    last_eval_time int NOT NULL,
    current_state_end int DEFAULT 0 NOT NULL,
    current_reason character varying(190),
    result_fingerprint character varying(16),
    __pg_stub_id BIGSERIAL PRIMARY KEY
);


--

--
-- Name: alert_notification; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_notification (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    name character varying(190) NOT NULL,
    type character varying(255) NOT NULL,
    settings text NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    frequency bigint,
    send_reminder boolean DEFAULT false,
    disable_resolve_message boolean DEFAULT false NOT NULL,
    uid character varying(40),
    secure_settings text,
    PRIMARY KEY(id)
);


--
-- Name: alert_notification_state; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_notification_state (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    alert_id int NOT NULL,
    notifier_id int NOT NULL,
    state character varying(50) NOT NULL,
    version int NOT NULL,
    updated_at int NOT NULL,
    alert_rule_state_updated_version int NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: alert_rule; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_rule (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    title character varying(190) NOT NULL,
    condition character varying(190) NOT NULL,
    data text NOT NULL,
    updated timestamp without time zone NOT NULL,
    interval_seconds int DEFAULT 60 NOT NULL,
    version integer DEFAULT 0 NOT NULL,
    uid character varying(40) DEFAULT '0' NOT NULL,
    namespace_uid character varying(40) NOT NULL,
    rule_group character varying(190) NOT NULL,
    no_data_state character varying(15) DEFAULT 'NoData'::character varying NOT NULL,
    exec_err_state character varying(15) DEFAULT 'Alerting'::character varying NOT NULL,
    "for" int DEFAULT 0 NOT NULL,
    annotations text,
    labels text,
    dashboard_uid character varying(40),
    panel_id bigint,
    rule_group_idx integer DEFAULT 1 NOT NULL,
    is_paused boolean DEFAULT false NOT NULL,
    notification_settings text,
    PRIMARY KEY(id)
);


--
-- Name: alert_rule_tag; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_rule_tag (
    id SERIAL NOT NULL,
    alert_id int NOT NULL,
    tag_id int NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: alert_rule_version; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE alert_rule_version (
    id SERIAL NOT NULL,
    rule_org_id int NOT NULL,
    rule_uid character varying(40) DEFAULT '0' NOT NULL,
    rule_namespace_uid character varying(40) NOT NULL,
    rule_group character varying(190) NOT NULL,
    parent_version integer NOT NULL,
    restored_from integer NOT NULL,
    version integer NOT NULL,
    created timestamp without time zone NOT NULL,
    title character varying(190) NOT NULL,
    condition character varying(190) NOT NULL,
    data text NOT NULL,
    interval_seconds int NOT NULL,
    no_data_state character varying(15) DEFAULT 'NoData'::character varying NOT NULL,
    exec_err_state character varying(15) DEFAULT 'Alerting'::character varying NOT NULL,
    "for" int DEFAULT 0 NOT NULL,
    annotations text,
    labels text,
    rule_group_idx integer DEFAULT 1 NOT NULL,
    is_paused boolean DEFAULT false NOT NULL,
    notification_settings text,
    PRIMARY KEY(id)
);

--
-- Name: annotation; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE annotation (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    alert_id bigint,
    user_id bigint,
    dashboard_id bigint,
    panel_id bigint,
    category_id bigint,
    type character varying(25) NOT NULL,
    title text NOT NULL,
    text text NOT NULL,
    metric character varying(255),
    prev_state character varying(25) NOT NULL,
    new_state character varying(25) NOT NULL,
    data text NOT NULL,
    epoch int NOT NULL,
    region_id int DEFAULT 0,
    tags character varying(4096),
    created int DEFAULT 0,
    updated int DEFAULT 0,
    epoch_end int DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);

--
-- Name: annotation_tag; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE annotation_tag (
    id SERIAL NOT NULL,
    annotation_id int NOT NULL,
    tag_id int NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: anon_device; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE anon_device (
    id SERIAL NOT NULL,
    client_ip character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    device_id character varying(127) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_agent character varying(255) NOT NULL,
    PRIMARY KEY(id)
);


--


--

--
-- Name: anon_device_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: api_key; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE api_key (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    name character varying(190) NOT NULL,
    key character varying(190) NOT NULL,
    role character varying(255) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    expires bigint,
    service_account_id bigint,
    last_used_at timestamp without time zone,
    is_revoked boolean DEFAULT false,
    PRIMARY KEY(id)
);


--

--

--
-- Name: api_key_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: builtin_role; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE builtin_role (
    id SERIAL NOT NULL,
    role character varying(190) NOT NULL,
    role_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    org_id int DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);


--

--

--
-- Name: builtin_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: cache_data; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE cache_data (
    cache_key character varying(168) NOT NULL,
    data bytea NOT NULL,
    expires integer NOT NULL,
    created_at integer NOT NULL,
    PRIMARY KEY(cache_key)
);


--

--
-- Name: correlation; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE correlation (
    uid character varying(40) NOT NULL,
    org_id int DEFAULT 0 NOT NULL,
    source_uid character varying(40) NOT NULL,
    target_uid character varying(40),
    label text NOT NULL,
    description text NOT NULL,
    config text,
    provisioned boolean DEFAULT false NOT NULL,
    __pg_stub_id BIGSERIAL PRIMARY KEY
);


--

--
-- Name: dashboard; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard (
    id SERIAL NOT NULL,
    version integer NOT NULL,
    slug character varying(189) NOT NULL,
    title character varying(189) NOT NULL,
    data text NOT NULL,
    org_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    updated_by integer,
    created_by integer,
    gnet_id bigint,
    plugin_id character varying(189),
    folder_id int DEFAULT 0 NOT NULL,
    is_folder boolean DEFAULT false NOT NULL,
    has_acl boolean DEFAULT false NOT NULL,
    uid character varying(40),
    is_public boolean DEFAULT false NOT NULL,
    folder_uid character varying(40),
    PRIMARY KEY(id)
);


--

--
-- Name: dashboard_acl; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard_acl (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    dashboard_id int NOT NULL,
    user_id bigint,
    team_id bigint,
    permission int DEFAULT 4 NOT NULL,
    role character varying(20),
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: dashboard_provisioning; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard_provisioning (
    id SERIAL NOT NULL,
    dashboard_id bigint,
    name character varying(150) NOT NULL,
    external_id text NOT NULL,
    updated integer DEFAULT 0 NOT NULL,
    check_sum character varying(32),
    PRIMARY KEY(id)
);


--
-- Name: dashboard_public; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard_public (
    uid character varying(40) NOT NULL,
    dashboard_uid character varying(40) NOT NULL,
    org_id int NOT NULL,
    time_settings text,
    template_variables text,
    access_token character varying(32) NOT NULL,
    created_by integer NOT NULL,
    updated_by integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    is_enabled boolean DEFAULT false NOT NULL,
    annotations_enabled boolean DEFAULT false NOT NULL,
    time_selection_enabled boolean DEFAULT false NOT NULL,
    share character varying(64) DEFAULT 'public'::character varying NOT NULL,
    PRIMARY KEY(uid)
);


--

--
-- Name: dashboard_snapshot; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard_snapshot (
    id SERIAL NOT NULL,
    name character varying(255) NOT NULL,
    key character varying(190) NOT NULL,
    delete_key character varying(190) NOT NULL,
    org_id int NOT NULL,
    user_id int NOT NULL,
    external boolean NOT NULL,
    external_url character varying(255) NOT NULL,
    dashboard text NOT NULL,
    expires timestamp without time zone NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    external_delete_url character varying(255),
    dashboard_encrypted bytea,
    PRIMARY KEY(id)
);



--
-- Name: dashboard_tag; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard_tag (
    id SERIAL NOT NULL,
    dashboard_id int NOT NULL,
    term character varying(50) NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: dashboard_version; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE dashboard_version (
    id SERIAL NOT NULL,
    dashboard_id int NOT NULL,
    parent_version integer NOT NULL,
    restored_from integer NOT NULL,
    version integer NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by int NOT NULL,
    message text NOT NULL,
    data text NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: data_keys; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE data_keys (
    name character varying(100) NOT NULL,
    active boolean NOT NULL,
    scope character varying(30) NOT NULL,
    provider character varying(50) NOT NULL,
    encrypted_data bytea NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    label character varying(100) DEFAULT ''::character varying NOT NULL,
    PRIMARY KEY(name)
);


--

--
-- Name: data_source; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE data_source (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    version integer NOT NULL,
    type character varying(255) NOT NULL,
    name character varying(190) NOT NULL,
    access character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    password character varying(255),
    "user" character varying(255),
    database character varying(255),
    basic_auth boolean NOT NULL,
    basic_auth_user character varying(255),
    basic_auth_password character varying(255),
    is_default boolean NOT NULL,
    json_data text,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    with_credentials boolean DEFAULT false NOT NULL,
    secure_json_data text,
    read_only boolean,
    uid character varying(40) DEFAULT '0' NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: data_source_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: entity_event; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE entity_event (
    id SERIAL NOT NULL,
    entity_id character varying(1024) NOT NULL,
    event_type character varying(8) NOT NULL,
    created int NOT NULL,
    PRIMARY KEY(id)
);

--
-- Name: file; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE file (
    path character varying(1024) NOT NULL COLLATE pg_catalog."C",
    path_hash character varying(64) NOT NULL,
    parent_folder_path_hash character varying(64) NOT NULL,
    contents bytea NOT NULL,
    etag character varying(32) NOT NULL,
    cache_control character varying(128) NOT NULL,
    content_disposition character varying(128) NOT NULL,
    updated timestamp without time zone NOT NULL,
    created timestamp without time zone NOT NULL,
    size int NOT NULL,
    mime_type character varying(255) NOT NULL,
    __pg_stub_id BIGSERIAL PRIMARY KEY
);


--

--
-- Name: file_meta; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE file_meta (
    path_hash character varying(64) NOT NULL,
    key character varying(191) NOT NULL,
    value character varying(1024) NOT NULL,
    __pg_stub_id BIGSERIAL PRIMARY KEY
);


--

--
-- Name: folder; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE folder (
    id SERIAL NOT NULL,
    uid character varying(40) NOT NULL,
    org_id int NOT NULL,
    title character varying(189) NOT NULL,
    description character varying(255),
    parent_uid character varying(40),
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: kv_store; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE kv_store (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    namespace character varying(190) NOT NULL,
    key character varying(190) NOT NULL,
    value text NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: library_element; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE library_element (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    folder_id int NOT NULL,
    uid character varying(40) NOT NULL,
    name character varying(150) NOT NULL,
    kind int NOT NULL,
    type character varying(40) NOT NULL,
    description character varying(2048) NOT NULL,
    model text NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by int NOT NULL,
    updated timestamp without time zone NOT NULL,
    updated_by int NOT NULL,
    version int NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: library_element_connection; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE library_element_connection (
    id SERIAL NOT NULL,
    element_id int NOT NULL,
    kind int NOT NULL,
    connection_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by int NOT NULL,
    PRIMARY KEY(id)
);


--
-- Name: login_attempt; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE login_attempt (
    id SERIAL NOT NULL,
    username character varying(190) NOT NULL,
    ip_address character varying(30) NOT NULL,
    created integer DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);

--
-- Name: migration_log; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE migration_log (
    id SERIAL NOT NULL,
    migration_id character varying(255) NOT NULL,
    sql text NOT NULL,
    success boolean NOT NULL,
    error text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);

--
-- Name: ngalert_configuration; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE ngalert_configuration (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    alertmanagers text,
    created_at integer NOT NULL,
    updated_at integer NOT NULL,
    send_alerts_to int DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);



--
-- Name: org; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE org (
    id SERIAL NOT NULL,
    version integer NOT NULL,
    name character varying(190) NOT NULL,
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip_code character varying(50),
    country character varying(255),
    billing_email character varying(255),
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: org_user; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE org_user (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    user_id int NOT NULL,
    role character varying(20) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--


--
-- Name: permission; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE permission (
    id SERIAL NOT NULL,
    role_id int NOT NULL,
    action character varying(190) NOT NULL,
    scope character varying(190) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    kind character varying(40) DEFAULT ''::character varying NOT NULL,
    attribute character varying(40) DEFAULT ''::character varying NOT NULL,
    identifier character varying(40) DEFAULT ''::character varying NOT NULL,
    PRIMARY KEY(id)
);


--


--
-- Name: playlist; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE playlist (
    id SERIAL NOT NULL,
    name character varying(255) NOT NULL,
    "interval" character varying(255) NOT NULL,
    org_id int NOT NULL,
    created_at int DEFAULT 0 NOT NULL,
    updated_at int DEFAULT 0 NOT NULL,
    uid character varying(80) DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);


--


--
-- Name: playlist_item; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE playlist_item (
    id SERIAL NOT NULL,
    playlist_id int NOT NULL,
    type character varying(255) NOT NULL,
    value text NOT NULL,
    title text NOT NULL,
    "order" integer NOT NULL,
    PRIMARY KEY(id)
);


--


--
-- Name: plugin_setting; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE plugin_setting (
    id SERIAL NOT NULL,
    org_id bigint,
    plugin_id character varying(190) NOT NULL,
    enabled boolean NOT NULL,
    pinned boolean NOT NULL,
    json_data text,
    secure_json_data text,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    plugin_version character varying(50),
    PRIMARY KEY(id)
);


--

--
-- Name: preferences; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE preferences (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    user_id int NOT NULL,
    version integer NOT NULL,
    home_dashboard_id int NOT NULL,
    timezone character varying(50) NOT NULL,
    theme character varying(20) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    team_id bigint,
    week_start character varying(10),
    json_data text,
    PRIMARY KEY(id)
);


--


--
-- Name: provenance_type; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE provenance_type (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    record_key character varying(190) NOT NULL,
    record_type character varying(190) NOT NULL,
    provenance character varying(190) NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: query_history; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE query_history (
    id SERIAL NOT NULL,
    uid character varying(40) NOT NULL,
    org_id int NOT NULL,
    datasource_uid character varying(40) NOT NULL,
    created_by int NOT NULL,
    created_at integer NOT NULL,
    comment text NOT NULL,
    queries text NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: query_history_star; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE query_history_star (
    id SERIAL NOT NULL,
    query_uid character varying(40) NOT NULL,
    user_id int NOT NULL,
    org_id int DEFAULT 1 NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: quota; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE quota (
    id SERIAL NOT NULL,
    org_id bigint,
    user_id bigint,
    target character varying(190) NOT NULL,
    "limit" int NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);



--
-- Name: role; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE role (
    id SERIAL NOT NULL,
    name character varying(190) NOT NULL,
    description text,
    version int NOT NULL,
    org_id int NOT NULL,
    uid character varying(40) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    display_name character varying(190),
    group_name character varying(190),
    hidden boolean DEFAULT false NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: secrets; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE secrets (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    namespace character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    value text,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--


--
-- Name: seed_assignment; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE seed_assignment (
    builtin_role character varying(190) NOT NULL,
    role_name character varying(190),
    action character varying(190),
    scope character varying(190),
    id SERIAL NOT NULL,
    origin character varying(190),
    PRIMARY KEY(id)
);



--
-- Name: server_lock; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE server_lock (
    id SERIAL NOT NULL,
    operation_uid character varying(100) NOT NULL,
    version int NOT NULL,
    last_execution int NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: session; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE session (
    key character(16) NOT NULL,
    data bytea NOT NULL,
    expiry integer NOT NULL,
    PRIMARY KEY(key)
);


--

--
-- Name: short_url; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE short_url (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    uid character varying(40) NOT NULL,
    path text NOT NULL,
    created_by int NOT NULL,
    created_at integer NOT NULL,
    last_seen_at integer,
    PRIMARY KEY(id)
);


--


--
-- Name: signing_key; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE signing_key (
    id SERIAL NOT NULL,
    key_id character varying(255) NOT NULL,
    private_key text NOT NULL,
    added_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone,
    alg character varying(255) NOT NULL,
    PRIMARY KEY(id)
);


--


--
-- Name: sso_setting; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE sso_setting (
    id character varying(40) NOT NULL,
    provider character varying(255) NOT NULL,
    settings text NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: star; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE star (
    id SERIAL NOT NULL,
    user_id int NOT NULL,
    dashboard_id int NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: tag; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE tag (
    id SERIAL NOT NULL,
    key character varying(100) NOT NULL,
    value character varying(100) NOT NULL,
    PRIMARY KEY(id)
);

--

--
-- Name: tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: team; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE team (
    id SERIAL NOT NULL,
    name character varying(190) NOT NULL,
    org_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    uid character varying(40),
    email character varying(190),
    PRIMARY KEY(id)
);


--

--

--
-- Name: team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: team_member; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE team_member (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    team_id int NOT NULL,
    user_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    external boolean,
    permission smallint,
    PRIMARY KEY(id)
);


--


--

--
-- Name: team_member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: team_role; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE team_role (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    team_id int NOT NULL,
    role_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);



--

--
-- Name: team_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: temp_user; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE temp_user (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    version integer NOT NULL,
    email character varying(190) NOT NULL,
    name character varying(255),
    role character varying(20),
    code character varying(190) NOT NULL,
    status character varying(20) NOT NULL,
    invited_by_user_id bigint,
    email_sent boolean NOT NULL,
    email_sent_on timestamp without time zone,
    remote_addr character varying(255),
    created integer DEFAULT 0 NOT NULL,
    updated integer DEFAULT 0 NOT NULL,
    PRIMARY KEY(id)
);


--

--
-- Name: temp_user_id_seq1; Type: SEQUENCE; Schema: public; Owner: root
--
--
-- Name: temp_user_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: test_data; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE test_data (
    id SERIAL NOT NULL,
    metric1 character varying(20),
    metric2 character varying(150),
    value_big_int bigint,
    value_double double precision,
    value_float real,
    value_int integer,
    time_epoch int NOT NULL,
    time_date_time timestamp without time zone NOT NULL,
    time_time_stamp timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);

--

--
-- Name: test_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: user; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE "user" (
    id SERIAL NOT NULL,
    version integer NOT NULL,
    login character varying(190) NOT NULL,
    email character varying(190) NOT NULL,
    name character varying(255),
    password character varying(255),
    salt character varying(50),
    rands character varying(50),
    company character varying(255),
    org_id int NOT NULL,
    is_admin boolean NOT NULL,
    email_verified boolean,
    theme character varying(255),
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    help_flags1 int DEFAULT 0 NOT NULL,
    last_seen_at timestamp without time zone,
    is_disabled boolean DEFAULT false NOT NULL,
    is_service_account boolean DEFAULT false,
    uid character varying(40),
    PRIMARY KEY(id)
);


--

--
-- Name: user_auth; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE user_auth (
    id SERIAL NOT NULL,
    user_id int NOT NULL,
    auth_module character varying(190) NOT NULL,
    auth_id character varying(190) NOT NULL,
    created timestamp without time zone NOT NULL,
    o_auth_access_token text,
    o_auth_refresh_token text,
    o_auth_token_type text,
    o_auth_expiry timestamp without time zone,
    o_auth_id_token text,
    PRIMARY KEY(id)
);


--



--

--
-- Name: user_auth_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: user_auth_token; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE user_auth_token (
    id SERIAL NOT NULL,
    user_id int NOT NULL,
    auth_token character varying(100) NOT NULL,
    prev_auth_token character varying(100) NOT NULL,
    user_agent character varying(255) NOT NULL,
    client_ip character varying(255) NOT NULL,
    auth_token_seen boolean NOT NULL,
    seen_at integer,
    rotated_at integer NOT NULL,
    created_at integer NOT NULL,
    updated_at integer NOT NULL,
    revoked_at integer,
    PRIMARY KEY(id)
);


--

--

--
-- Name: user_auth_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--



--

--
-- Name: user_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: user_role; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE user_role (
    id SERIAL NOT NULL,
    org_id int NOT NULL,
    user_id int NOT NULL,
    role_id int NOT NULL,
    created timestamp without time zone NOT NULL,
    PRIMARY KEY(id)
);


--

--

--
-- Name: user_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--




--
-- Name: alert id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_configuration id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_configuration_history id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_image id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_notification id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_notification_state id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_rule id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_rule_tag id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_rule_version id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: annotation id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: annotation_tag id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: anon_device id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: api_key id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: builtin_role id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: dashboard id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: dashboard_acl id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: dashboard_provisioning id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: dashboard_snapshot id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: dashboard_tag id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: dashboard_version id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: data_source id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: entity_event id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: folder id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: kv_store id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: library_element id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: library_element_connection id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: login_attempt id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: migration_log id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: ngalert_configuration id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: org id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: org_user id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: permission id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: playlist id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: playlist_item id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: plugin_setting id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: preferences id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: provenance_type id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: query_history id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: query_history_star id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: quota id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: role id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: secrets id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: seed_assignment id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: server_lock id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: short_url id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: signing_key id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: star id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: tag id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: team id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: team_member id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: team_role id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: temp_user id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: test_data id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: user_auth id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: user_auth_token id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: user_role id; Type: DEFAULT; Schema: public; Owner: root
--




--
-- Name: alert_configuration_history alert_configuration_history_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_configuration_history_pkey PRIMARY KEY (id);


--
-- Name: alert_configuration alert_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_configuration_pkey PRIMARY KEY (id);


--
-- Name: alert_image alert_image_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_image_pkey PRIMARY KEY (id);


--
-- Name: alert_instance alert_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_instance_pkey PRIMARY KEY (rule_org_id, rule_uid, labels_hash);


--
-- Name: alert_notification alert_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_notification_pkey PRIMARY KEY (id);


--
-- Name: alert_notification_state alert_notification_state_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_notification_state_pkey PRIMARY KEY (id);


--
-- Name: alert alert_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_pkey PRIMARY KEY (id);


--
-- Name: alert_rule alert_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_rule_pkey PRIMARY KEY (id);


--
-- Name: alert_rule_tag alert_rule_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_rule_tag_pkey PRIMARY KEY (id);


--
-- Name: alert_rule_version alert_rule_version_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT alert_rule_version_pkey PRIMARY KEY (id);


--
-- Name: annotation annotation_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT annotation_pkey PRIMARY KEY (id);


--
-- Name: annotation_tag annotation_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT annotation_tag_pkey PRIMARY KEY (id);


--
-- Name: anon_device anon_device_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT anon_device_pkey PRIMARY KEY (id);


--
-- Name: api_key api_key_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT api_key_pkey1 PRIMARY KEY (id);


--
-- Name: builtin_role builtin_role_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT builtin_role_pkey PRIMARY KEY (id);


--
-- Name: cache_data cache_data_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT cache_data_pkey PRIMARY KEY (cache_key);


--
-- Name: correlation correlation_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT correlation_pkey1 PRIMARY KEY (uid, org_id, source_uid);


--
-- Name: dashboard_acl dashboard_acl_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_acl_pkey PRIMARY KEY (id);


--
-- Name: dashboard dashboard_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_pkey1 PRIMARY KEY (id);


--
-- Name: dashboard_provisioning dashboard_provisioning_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_provisioning_pkey1 PRIMARY KEY (id);


--
-- Name: dashboard_public dashboard_public_config_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_public_config_pkey PRIMARY KEY (uid);


--
-- Name: dashboard_snapshot dashboard_snapshot_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_snapshot_pkey PRIMARY KEY (id);


--
-- Name: dashboard_tag dashboard_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_tag_pkey PRIMARY KEY (id);


--
-- Name: dashboard_version dashboard_version_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT dashboard_version_pkey PRIMARY KEY (id);


--
-- Name: data_keys data_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT data_keys_pkey PRIMARY KEY (name);


--
-- Name: data_source data_source_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT data_source_pkey1 PRIMARY KEY (id);


--
-- Name: entity_event entity_event_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT entity_event_pkey PRIMARY KEY (id);


--
-- Name: folder folder_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT folder_pkey PRIMARY KEY (id);


--
-- Name: kv_store kv_store_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT kv_store_pkey PRIMARY KEY (id);


--
-- Name: library_element_connection library_element_connection_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT library_element_connection_pkey PRIMARY KEY (id);


--
-- Name: library_element library_element_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT library_element_pkey PRIMARY KEY (id);


--
-- Name: login_attempt login_attempt_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT login_attempt_pkey1 PRIMARY KEY (id);


--
-- Name: migration_log migration_log_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT migration_log_pkey PRIMARY KEY (id);


--
-- Name: ngalert_configuration ngalert_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT ngalert_configuration_pkey PRIMARY KEY (id);


--
-- Name: org org_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT org_pkey PRIMARY KEY (id);


--
-- Name: org_user org_user_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT org_user_pkey PRIMARY KEY (id);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT permission_pkey PRIMARY KEY (id);


--
-- Name: playlist_item playlist_item_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT playlist_item_pkey PRIMARY KEY (id);


--
-- Name: playlist playlist_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT playlist_pkey PRIMARY KEY (id);


--
-- Name: plugin_setting plugin_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT plugin_setting_pkey PRIMARY KEY (id);


--
-- Name: preferences preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT preferences_pkey PRIMARY KEY (id);


--
-- Name: provenance_type provenance_type_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT provenance_type_pkey PRIMARY KEY (id);


--
-- Name: query_history query_history_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT query_history_pkey PRIMARY KEY (id);


--
-- Name: query_history_star query_history_star_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT query_history_star_pkey PRIMARY KEY (id);


--
-- Name: quota quota_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT quota_pkey PRIMARY KEY (id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: secrets secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT secrets_pkey PRIMARY KEY (id);


--
-- Name: seed_assignment seed_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT seed_assignment_pkey PRIMARY KEY (id);


--
-- Name: server_lock server_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT server_lock_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT session_pkey PRIMARY KEY (key);


--
-- Name: short_url short_url_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT short_url_pkey PRIMARY KEY (id);


--
-- Name: signing_key signing_key_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT signing_key_pkey PRIMARY KEY (id);


--
-- Name: sso_setting sso_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT sso_setting_pkey PRIMARY KEY (id);


--
-- Name: star star_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT star_pkey PRIMARY KEY (id);


--
-- Name: tag tag_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT tag_pkey PRIMARY KEY (id);


--
-- Name: team_member team_member_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT team_member_pkey PRIMARY KEY (id);


--
-- Name: team team_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT team_pkey PRIMARY KEY (id);


--
-- Name: team_role team_role_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT team_role_pkey PRIMARY KEY (id);


--
-- Name: temp_user temp_user_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT temp_user_pkey1 PRIMARY KEY (id);


--
-- Name: test_data test_data_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT test_data_pkey PRIMARY KEY (id);


--
-- Name: user_auth user_auth_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT user_auth_pkey PRIMARY KEY (id);


--
-- Name: user_auth_token user_auth_token_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT user_auth_token_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey1; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT user_pkey1 PRIMARY KEY (id);


--
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--
--     ADD CONSTRAINT user_role_pkey PRIMARY KEY (id);


--
-- Name: IDX_alert_dashboard_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_dashboard_id" ON alert USING btree (dashboard_id);


--
-- Name: IDX_alert_instance_rule_org_id_current_state; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_instance_rule_org_id_current_state" ON alert_instance USING btree (rule_org_id, current_state);


--
-- Name: IDX_alert_instance_rule_org_id_rule_uid_current_state; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_instance_rule_org_id_rule_uid_current_state" ON alert_instance USING btree (rule_org_id, rule_uid, current_state);


--
-- Name: IDX_alert_notification_state_alert_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_notification_state_alert_id" ON alert_notification_state USING btree (alert_id);


--
-- Name: IDX_alert_org_id_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_org_id_id" ON alert USING btree (org_id, id);


--
-- Name: IDX_alert_rule_org_id_dashboard_uid_panel_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_rule_org_id_dashboard_uid_panel_id" ON alert_rule USING btree (org_id, dashboard_uid, panel_id);


--
-- Name: IDX_alert_rule_org_id_namespace_uid_rule_group; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_rule_org_id_namespace_uid_rule_group" ON alert_rule USING btree (org_id, namespace_uid, rule_group);


--
-- Name: IDX_alert_rule_tag_alert_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_rule_tag_alert_id" ON alert_rule_tag USING btree (alert_id);


--
-- Name: IDX_alert_rule_version_rule_org_id_rule_namespace_uid_rule_grou; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_rule_version_rule_org_id_rule_namespace_uid_rule_grou" ON alert_rule_version USING btree (rule_org_id, rule_namespace_uid, rule_group);


--
-- Name: IDX_alert_state; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_alert_state" ON alert USING btree (state);


--
-- Name: IDX_annotation_alert_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_alert_id" ON annotation USING btree (alert_id);


--
-- Name: IDX_annotation_org_id_alert_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_org_id_alert_id" ON annotation USING btree (org_id, alert_id);


--
-- Name: IDX_annotation_org_id_created; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_org_id_created" ON annotation USING btree (org_id, created);


--
-- Name: IDX_annotation_org_id_dashboard_id_epoch_end_epoch; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_org_id_dashboard_id_epoch_end_epoch" ON annotation USING btree (org_id, dashboard_id, epoch_end, epoch);


--
-- Name: IDX_annotation_org_id_epoch_end_epoch; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_org_id_epoch_end_epoch" ON annotation USING btree (org_id, epoch_end, epoch);


--
-- Name: IDX_annotation_org_id_type; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_org_id_type" ON annotation USING btree (org_id, type);


--
-- Name: IDX_annotation_org_id_updated; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_annotation_org_id_updated" ON annotation USING btree (org_id, updated);


--
-- Name: IDX_anon_device_updated_at; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_anon_device_updated_at" ON anon_device USING btree (updated_at);


--
-- Name: IDX_api_key_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_api_key_org_id" ON api_key USING btree (org_id);


--
-- Name: IDX_builtin_role_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_builtin_role_org_id" ON builtin_role USING btree (org_id);


--
-- Name: IDX_builtin_role_role; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_builtin_role_role" ON builtin_role USING btree (role);


--
-- Name: IDX_builtin_role_role_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_builtin_role_role_id" ON builtin_role USING btree (role_id);


--
-- Name: IDX_correlation_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_correlation_org_id" ON correlation USING btree (org_id);


--
-- Name: IDX_correlation_source_uid; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_correlation_source_uid" ON correlation USING btree (source_uid);


--
-- Name: IDX_correlation_uid; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_correlation_uid" ON correlation USING btree (uid);


--
-- Name: IDX_dashboard_acl_dashboard_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_acl_dashboard_id" ON dashboard_acl USING btree (dashboard_id);


--
-- Name: IDX_dashboard_acl_org_id_role; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_acl_org_id_role" ON dashboard_acl USING btree (org_id, role);


--
-- Name: IDX_dashboard_acl_permission; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_acl_permission" ON dashboard_acl USING btree (permission);


--
-- Name: IDX_dashboard_acl_team_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_acl_team_id" ON dashboard_acl USING btree (team_id);


--
-- Name: IDX_dashboard_acl_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_acl_user_id" ON dashboard_acl USING btree (user_id);


--
-- Name: IDX_dashboard_gnet_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_gnet_id" ON dashboard USING btree (gnet_id);


--
-- Name: IDX_dashboard_is_folder; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_is_folder" ON dashboard USING btree (is_folder);


--
-- Name: IDX_dashboard_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_org_id" ON dashboard USING btree (org_id);


--
-- Name: IDX_dashboard_org_id_folder_id_title; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_org_id_folder_id_title" ON dashboard USING btree (org_id, folder_id, title);


--
-- Name: IDX_dashboard_org_id_plugin_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_org_id_plugin_id" ON dashboard USING btree (org_id, plugin_id);


--
-- Name: IDX_dashboard_provisioning_dashboard_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_provisioning_dashboard_id" ON dashboard_provisioning USING btree (dashboard_id);


--
-- Name: IDX_dashboard_provisioning_dashboard_id_name; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_provisioning_dashboard_id_name" ON dashboard_provisioning USING btree (dashboard_id, name);


--
-- Name: IDX_dashboard_public_config_org_id_dashboard_uid; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_public_config_org_id_dashboard_uid" ON dashboard_public USING btree (org_id, dashboard_uid);


--
-- Name: IDX_dashboard_snapshot_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_snapshot_user_id" ON dashboard_snapshot USING btree (user_id);


--
-- Name: IDX_dashboard_tag_dashboard_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_tag_dashboard_id" ON dashboard_tag USING btree (dashboard_id);


--
-- Name: IDX_dashboard_title; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_title" ON dashboard USING btree (title);


--
-- Name: IDX_dashboard_version_dashboard_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_dashboard_version_dashboard_id" ON dashboard_version USING btree (dashboard_id);


--
-- Name: IDX_data_source_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_data_source_org_id" ON data_source USING btree (org_id);


--
-- Name: IDX_data_source_org_id_is_default; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_data_source_org_id_is_default" ON data_source USING btree (org_id, is_default);


--
-- Name: IDX_file_parent_folder_path_hash; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_file_parent_folder_path_hash" ON file USING btree (parent_folder_path_hash);


--
-- Name: IDX_login_attempt_username; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_login_attempt_username" ON login_attempt USING btree (username);


--
-- Name: IDX_org_user_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_org_user_org_id" ON org_user USING btree (org_id);


--
-- Name: IDX_org_user_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_org_user_user_id" ON org_user USING btree (user_id);


--
-- Name: IDX_permission_identifier; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_permission_identifier" ON permission USING btree (identifier);


--
-- Name: IDX_permission_role_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_permission_role_id" ON permission USING btree (role_id);


--
-- Name: IDX_preferences_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_preferences_org_id" ON preferences USING btree (org_id);


--
-- Name: IDX_preferences_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_preferences_user_id" ON preferences USING btree (user_id);


--
-- Name: IDX_query_history_org_id_created_by_datasource_uid; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_query_history_org_id_created_by_datasource_uid" ON query_history USING btree (org_id, created_by, datasource_uid);


--
-- Name: IDX_role_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_role_org_id" ON role USING btree (org_id);


--
-- Name: IDX_team_member_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_team_member_org_id" ON team_member USING btree (org_id);


--
-- Name: IDX_team_member_team_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_team_member_team_id" ON team_member USING btree (team_id);


--
-- Name: IDX_team_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_team_org_id" ON team USING btree (org_id);


--
-- Name: IDX_team_role_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_team_role_org_id" ON team_role USING btree (org_id);


--
-- Name: IDX_team_role_team_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_team_role_team_id" ON team_role USING btree (team_id);


--
-- Name: IDX_temp_user_code; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_temp_user_code" ON temp_user USING btree (code);


--
-- Name: IDX_temp_user_email; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_temp_user_email" ON temp_user USING btree (email);


--
-- Name: IDX_temp_user_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_temp_user_org_id" ON temp_user USING btree (org_id);


--
-- Name: IDX_temp_user_status; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_temp_user_status" ON temp_user USING btree (status);


--
-- Name: IDX_user_auth_auth_module_auth_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_auth_auth_module_auth_id" ON user_auth USING btree (auth_module, auth_id);


--
-- Name: IDX_user_auth_token_revoked_at; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_auth_token_revoked_at" ON user_auth_token USING btree (revoked_at);


--
-- Name: IDX_user_auth_token_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_auth_token_user_id" ON user_auth_token USING btree (user_id);


--
-- Name: IDX_user_auth_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_auth_user_id" ON user_auth USING btree (user_id);


--
-- Name: IDX_user_login_email; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_login_email" ON "user" USING btree (login, email);


--
-- Name: IDX_user_role_org_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_role_org_id" ON user_role USING btree (org_id);


--
-- Name: IDX_user_role_user_id; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX "IDX_user_role_user_id" ON user_role USING btree (user_id);
