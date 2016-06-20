--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: directories_id_seq; Type: SEQUENCE; Schema: public; Owner: fijisearch
--

CREATE SEQUENCE directories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directories_id_seq OWNER TO fijisearch;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: directories; Type: TABLE; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE TABLE directories (
    host character varying(64),
    brick character varying(16),
    path character varying(1024),
    searched boolean DEFAULT false NOT NULL,
    searching boolean DEFAULT false NOT NULL,
    id integer DEFAULT nextval('directories_id_seq'::regclass) NOT NULL
);


ALTER TABLE public.directories OWNER TO fijisearch;

--
-- Name: found_files; Type: TABLE; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE TABLE found_files (
    id integer NOT NULL,
    asset_id bigint DEFAULT 0 NOT NULL,
    pub_id bigint DEFAULT 0 NOT NULL,
    host character varying(64) NOT NULL,
    brick character varying(16) NOT NULL,
    path character varying(1024) NOT NULL,
    gfs_size bigint DEFAULT 0 NOT NULL,
    source_id character varying(512),
    target_id character varying(512),
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    verified_at timestamp without time zone,
    status character varying(32),
    size character varying(1024),
    mtime character varying(1024),
    message character varying(1024)
);


ALTER TABLE public.found_files OWNER TO fijisearch;

--
-- Name: found_files_id_seq; Type: SEQUENCE; Schema: public; Owner: fijisearch
--

CREATE SEQUENCE found_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.found_files_id_seq OWNER TO fijisearch;

--
-- Name: found_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: fijisearch
--

ALTER SEQUENCE found_files_id_seq OWNED BY found_files.id;


--
-- Name: missing_files; Type: TABLE; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE TABLE missing_files (
    id integer NOT NULL,
    asset_id bigint DEFAULT 0 NOT NULL,
    pub_id bigint DEFAULT 0 NOT NULL,
    bcfs_key character varying(1024) NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    found boolean DEFAULT false NOT NULL
);


ALTER TABLE public.missing_files OWNER TO fijisearch;

--
-- Name: missing_files_id_seq; Type: SEQUENCE; Schema: public; Owner: fijisearch
--

CREATE SEQUENCE missing_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.missing_files_id_seq OWNER TO fijisearch;

--
-- Name: missing_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: fijisearch
--

ALTER SEQUENCE missing_files_id_seq OWNED BY missing_files.id;


--
-- Name: publishers; Type: TABLE; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE TABLE publishers (
    pub_id bigint NOT NULL,
    pub_name character varying(64)
);


ALTER TABLE public.publishers OWNER TO fijisearch;

--
-- Name: sync_status; Type: TABLE; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE TABLE sync_status (
    source_id character varying(512) NOT NULL,
    target_id character varying(512),
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    verified_at timestamp without time zone,
    status character varying(32) DEFAULT 'Error'::character varying NOT NULL,
    size character varying(1024),
    mtime character varying(1024),
    message character varying(1024)
);


ALTER TABLE public.sync_status OWNER TO fijisearch;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: fijisearch
--

ALTER TABLE ONLY found_files ALTER COLUMN id SET DEFAULT nextval('found_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: fijisearch
--

ALTER TABLE ONLY missing_files ALTER COLUMN id SET DEFAULT nextval('missing_files_id_seq'::regclass);


--
-- Name: sync_status_pkey; Type: CONSTRAINT; Schema: public; Owner: fijisearch; Tablespace: 
--

ALTER TABLE ONLY sync_status
    ADD CONSTRAINT sync_status_pkey PRIMARY KEY (source_id);


--
-- Name: directories_host_brick_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX directories_host_brick_idx ON directories USING btree (host, brick);


--
-- Name: directories_path_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX directories_path_idx ON directories USING btree (path);


--
-- Name: found_files_asset_by_pub_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_asset_by_pub_idx ON found_files USING btree (asset_id, pub_id);


--
-- Name: found_files_asset_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_asset_id_idx ON found_files USING btree (asset_id);


--
-- Name: found_files_host_brick_size_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_host_brick_size_idx ON found_files USING btree (host, brick, gfs_size);


--
-- Name: found_files_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_id_idx ON found_files USING btree (id);


--
-- Name: found_files_path_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_path_idx ON found_files USING btree (path);


--
-- Name: found_files_pub_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_pub_id_idx ON found_files USING btree (pub_id);


--
-- Name: found_files_source_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX found_files_source_id_idx ON found_files USING btree (source_id);


--
-- Name: missing_files_asset_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX missing_files_asset_id_idx ON missing_files USING btree (asset_id);


--
-- Name: missing_files_asset_id_pub_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX missing_files_asset_id_pub_id_idx ON missing_files USING btree (asset_id, pub_id);


--
-- Name: missing_files_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX missing_files_id_idx ON missing_files USING btree (id);


--
-- Name: missing_files_path_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX missing_files_path_idx ON missing_files USING btree (bcfs_key);


--
-- Name: missing_files_pub_id_idx; Type: INDEX; Schema: public; Owner: fijisearch; Tablespace: 
--

CREATE INDEX missing_files_pub_id_idx ON missing_files USING btree (pub_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: fijisearch
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM fijisearch;
GRANT ALL ON SCHEMA public TO fijisearch;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

