--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: notify_events_added(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION notify_events_added() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM pg_notify(
    'events',
    json_build_object(
      'id', NEW.id,
      'aggregate', NEW.aggregate,
      'type', NEW.type
    )::text
  );
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE events (
    id integer NOT NULL,
    aggregate uuid NOT NULL,
    sequence integer NOT NULL,
    type character varying(255) NOT NULL,
    payload jsonb NOT NULL
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: events_aggregate_sequence_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_aggregate_sequence_index ON events USING btree (aggregate, sequence);


--
-- Name: events tr_notify_events_added; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_notify_events_added AFTER INSERT ON events FOR EACH ROW EXECUTE PROCEDURE notify_events_added();


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170628083824), (20170630084751);

