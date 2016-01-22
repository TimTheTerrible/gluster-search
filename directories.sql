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
    path character varying(1024),
    searched boolean DEFAULT false NOT NULL,
    searching boolean DEFAULT false NOT NULL,
    id integer DEFAULT nextval('directories_id_seq'::regclass) NOT NULL
);


ALTER TABLE public.directories OWNER TO fijisearch;
