--
-- PostgreSQL database dump
--

\restrict 6kdCfDYx6TCJayLuejtPwscHyp7ZoXfpMzpYrsPtllKrmAfe6WbQagCKMfj3OyC

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: _time_trial_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public._time_trial_type AS (
	a_time numeric
);


ALTER TYPE public._time_trial_type OWNER TO postgres;

--
-- Name: _add(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._add(text, integer) RETURNS integer
    LANGUAGE sql
    AS $_$
    SELECT _add($1, $2, '')
$_$;


ALTER FUNCTION public._add(text, integer) OWNER TO postgres;

--
-- Name: _add(text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._add(text, integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE 'INSERT INTO __tcache__ (label, value, note) values (' ||
    quote_literal($1) || ', ' || $2 || ', ' || quote_literal(COALESCE($3, '')) || ')';
    RETURN $2;
END;
$_$;


ALTER FUNCTION public._add(text, integer, text) OWNER TO postgres;

--
-- Name: _alike(boolean, anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._alike(boolean, anyelement, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    result ALIAS FOR $1;
    got    ALIAS FOR $2;
    rx     ALIAS FOR $3;
    descr  ALIAS FOR $4;
    output TEXT;
BEGIN
    output := ok( result, descr );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '                  ' || COALESCE( quote_literal(got), 'NULL' ) ||
       E'\n   doesn''t match: ' || COALESCE( quote_literal(rx), 'NULL' )
    ) END;
END;
$_$;


ALTER FUNCTION public._alike(boolean, anyelement, text, text) OWNER TO postgres;

--
-- Name: _ancestor_of(name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ancestor_of(name, name, integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
    WITH RECURSIVE inheritance_chain AS (
        -- select the ancestor tuple
        SELECT i.inhrelid AS descendent_id, 1 AS inheritance_level
          FROM pg_catalog.pg_inherits i
        WHERE i.inhparent = (
            SELECT c1.oid
              FROM pg_catalog.pg_class c1
              JOIN pg_catalog.pg_namespace n1
                ON c1.relnamespace = n1.oid
             WHERE c1.relname = $1
               AND pg_catalog.pg_table_is_visible( c1.oid )
        )
        UNION
        -- select the descendents
        SELECT i.inhrelid AS descendent_id,
               p.inheritance_level + 1 AS inheritance_level
          FROM pg_catalog.pg_inherits i
          JOIN inheritance_chain p
            ON p.descendent_id = i.inhparent
         WHERE i.inhrelid = (
            SELECT c1.oid
              FROM pg_catalog.pg_class c1
              JOIN pg_catalog.pg_namespace n1
                ON c1.relnamespace = n1.oid
             WHERE c1.relname = $2
               AND pg_catalog.pg_table_is_visible( c1.oid )
        )
    )
    SELECT EXISTS(
        SELECT true
          FROM inheritance_chain
         WHERE inheritance_level = COALESCE($3, inheritance_level)
           AND descendent_id = (
                SELECT c1.oid
                  FROM pg_catalog.pg_class c1
                  JOIN pg_catalog.pg_namespace n1
                    ON c1.relnamespace = n1.oid
                 WHERE c1.relname = $2
                   AND pg_catalog.pg_table_is_visible( c1.oid )
        )
    );
$_$;


ALTER FUNCTION public._ancestor_of(name, name, integer) OWNER TO postgres;

--
-- Name: _ancestor_of(name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ancestor_of(name, name, name, name, integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
    WITH RECURSIVE inheritance_chain AS (
        -- select the ancestor tuple
        SELECT i.inhrelid AS descendent_id, 1 AS inheritance_level
          FROM pg_catalog.pg_inherits i
        WHERE i.inhparent = (
            SELECT c1.oid
              FROM pg_catalog.pg_class c1
              JOIN pg_catalog.pg_namespace n1
                ON c1.relnamespace = n1.oid
             WHERE c1.relname = $2
               AND n1.nspname = $1
        )
        UNION
        -- select the descendents
        SELECT i.inhrelid AS descendent_id,
               p.inheritance_level + 1 AS inheritance_level
          FROM pg_catalog.pg_inherits i
          JOIN inheritance_chain p
            ON p.descendent_id = i.inhparent
         WHERE i.inhrelid = (
            SELECT c1.oid
              FROM pg_catalog.pg_class c1
              JOIN pg_catalog.pg_namespace n1
                ON c1.relnamespace = n1.oid
             WHERE c1.relname = $4
               AND n1.nspname = $3
        )
    )
    SELECT EXISTS(
        SELECT true
          FROM inheritance_chain
         WHERE inheritance_level = COALESCE($5, inheritance_level)
           AND descendent_id = (
                SELECT c1.oid
                  FROM pg_catalog.pg_class c1
                  JOIN pg_catalog.pg_namespace n1
                    ON c1.relnamespace = n1.oid
                 WHERE c1.relname = $4
                   AND n1.nspname = $3
        )
    );
$_$;


ALTER FUNCTION public._ancestor_of(name, name, name, name, integer) OWNER TO postgres;

--
-- Name: _are(text, name[], name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._are(text, name[], name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    what    ALIAS FOR $1;
    extras  ALIAS FOR $2;
    missing ALIAS FOR $3;
    descr   ALIAS FOR $4;
    msg     TEXT    := '';
    res     BOOLEAN := TRUE;
BEGIN
    IF extras[1] IS NOT NULL THEN
        res = FALSE;
        msg := E'\n' || diag(
            '    Extra ' || what || E':\n        '
            ||  _ident_array_to_sorted_string( extras, E'\n        ' )
        );
    END IF;
    IF missing[1] IS NOT NULL THEN
        res = FALSE;
        msg := msg || E'\n' || diag(
            '    Missing ' || what || E':\n        '
            ||  _ident_array_to_sorted_string( missing, E'\n        ' )
        );
    END IF;

    RETURN ok(res, descr) || msg;
END;
$_$;


ALTER FUNCTION public._are(text, name[], name[], text) OWNER TO postgres;

--
-- Name: _areni(text, text[], text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._areni(text, text[], text[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    what    ALIAS FOR $1;
    extras  ALIAS FOR $2;
    missing ALIAS FOR $3;
    descr   ALIAS FOR $4;
    msg     TEXT    := '';
    res     BOOLEAN := TRUE;
BEGIN
    IF extras[1] IS NOT NULL THEN
        res = FALSE;
        msg := E'\n' || diag(
            '    Extra ' || what || E':\n        '
            ||  _array_to_sorted_string( extras, E'\n        ' )
        );
    END IF;
    IF missing[1] IS NOT NULL THEN
        res = FALSE;
        msg := msg || E'\n' || diag(
            '    Missing ' || what || E':\n        '
            ||  _array_to_sorted_string( missing, E'\n        ' )
        );
    END IF;

    RETURN ok(res, descr) || msg;
END;
$_$;


ALTER FUNCTION public._areni(text, text[], text[], text) OWNER TO postgres;

--
-- Name: _array_to_sorted_string(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._array_to_sorted_string(name[], text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT array_to_string(ARRAY(
        SELECT $1[i]
          FROM generate_series(1, array_upper($1, 1)) s(i)
         ORDER BY $1[i]
    ), $2);
$_$;


ALTER FUNCTION public._array_to_sorted_string(name[], text) OWNER TO postgres;

--
-- Name: _assets_are(text, text[], text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._assets_are(text, text[], text[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _areni(
        $1,
        ARRAY(
            SELECT UPPER($2[i]) AS thing
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
             ORDER BY thing
        ),
        ARRAY(
            SELECT $3[i] AS thing
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT UPPER($2[i])
              FROM generate_series(1, array_upper($2, 1)) s(i)
             ORDER BY thing
        ),
        $4
    );
$_$;


ALTER FUNCTION public._assets_are(text, text[], text[], text) OWNER TO postgres;

--
-- Name: _cast_exists(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cast_exists(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
       SELECT TRUE
         FROM pg_catalog.pg_cast c
        WHERE _cmp_types(castsource, $1)
          AND _cmp_types(casttarget, $2)
   );
$_$;


ALTER FUNCTION public._cast_exists(name, name) OWNER TO postgres;

--
-- Name: _cast_exists(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cast_exists(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
       SELECT TRUE
         FROM pg_catalog.pg_cast c
         JOIN pg_catalog.pg_proc p ON c.castfunc = p.oid
        WHERE _cmp_types(castsource, $1)
          AND _cmp_types(casttarget, $2)
          AND p.proname   = $3
   );
$_$;


ALTER FUNCTION public._cast_exists(name, name, name) OWNER TO postgres;

--
-- Name: _cast_exists(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cast_exists(name, name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
       SELECT TRUE
         FROM pg_catalog.pg_cast c
         JOIN pg_catalog.pg_proc p ON c.castfunc = p.oid
         JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
        WHERE _cmp_types(castsource, $1)
          AND _cmp_types(casttarget, $2)
          AND n.nspname   = $3
          AND p.proname   = $4
   );
$_$;


ALTER FUNCTION public._cast_exists(name, name, name, name) OWNER TO postgres;

--
-- Name: _cdi(name, name, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cdi(name, name, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_default_is(
        $1, $2, $3,
        'Column ' || quote_ident($1) || '.' || quote_ident($2) || ' should default to '
        || COALESCE( quote_literal($3), 'NULL')
    );
$_$;


ALTER FUNCTION public._cdi(name, name, anyelement) OWNER TO postgres;

--
-- Name: _cdi(name, name, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cdi(name, name, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT _cexists( $1, $2 ) THEN
        RETURN fail( $4 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist' );
    END IF;

    IF NOT _has_def( $1, $2 ) THEN
        RETURN fail( $4 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || ' has no default' );
    END IF;

    RETURN _def_is(
        pg_catalog.pg_get_expr(d.adbin, d.adrelid),
        pg_catalog.format_type(a.atttypid, a.atttypmod),
        $3, $4
    )
      FROM pg_catalog.pg_class c, pg_catalog.pg_attribute a, pg_catalog.pg_attrdef d
     WHERE c.oid = a.attrelid
       AND pg_table_is_visible(c.oid)
       AND a.atthasdef
       AND a.attrelid = d.adrelid
       AND a.attnum = d.adnum
       AND c.relname = $1
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND a.attname = $2;
END;
$_$;


ALTER FUNCTION public._cdi(name, name, anyelement, text) OWNER TO postgres;

--
-- Name: _cdi(name, name, name, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cdi(name, name, name, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT _cexists( $1, $2, $3 ) THEN
        RETURN fail( $5 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3) || ' does not exist' );
    END IF;

    IF NOT _has_def( $1, $2, $3 ) THEN
        RETURN fail( $5 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3) || ' has no default' );
    END IF;

    RETURN _def_is(
        pg_catalog.pg_get_expr(d.adbin, d.adrelid),
        pg_catalog.format_type(a.atttypid, a.atttypmod),
        $4, $5
    )
      FROM pg_catalog.pg_namespace n, pg_catalog.pg_class c, pg_catalog.pg_attribute a,
           pg_catalog.pg_attrdef d
     WHERE n.oid = c.relnamespace
       AND c.oid = a.attrelid
       AND a.atthasdef
       AND a.attrelid = d.adrelid
       AND a.attnum = d.adnum
       AND n.nspname = $1
       AND c.relname = $2
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND a.attname = $3;
END;
$_$;


ALTER FUNCTION public._cdi(name, name, name, anyelement, text) OWNER TO postgres;

--
-- Name: _cexists(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cexists(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_class c
          JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
         WHERE c.relname = $1
           AND pg_catalog.pg_table_is_visible(c.oid)
           AND a.attnum > 0
           AND NOT a.attisdropped
           AND a.attname = $2
    );
$_$;


ALTER FUNCTION public._cexists(name, name) OWNER TO postgres;

--
-- Name: _cexists(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cexists(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
          JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
         WHERE n.nspname = $1
           AND c.relname = $2
           AND a.attnum > 0
           AND NOT a.attisdropped
           AND a.attname = $3
    );
$_$;


ALTER FUNCTION public._cexists(name, name, name) OWNER TO postgres;

--
-- Name: _ckeys(name, character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ckeys(name, character) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT * FROM _keys($1, $2) LIMIT 1;
$_$;


ALTER FUNCTION public._ckeys(name, character) OWNER TO postgres;

--
-- Name: _ckeys(name, name, character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ckeys(name, name, character) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT * FROM _keys($1, $2, $3) LIMIT 1;
$_$;


ALTER FUNCTION public._ckeys(name, name, character) OWNER TO postgres;

--
-- Name: _cleanup(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cleanup() RETURNS boolean
    LANGUAGE sql
    AS $$
    DROP SEQUENCE __tresults___numb_seq;
    DROP TABLE __tcache__;
    DROP SEQUENCE __tcache___id_seq;
    SELECT TRUE;
$$;


ALTER FUNCTION public._cleanup() OWNER TO postgres;

--
-- Name: _cmp_types(oid, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._cmp_types(oid, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.format_type($1, NULL) = _typename($2);
$_$;


ALTER FUNCTION public._cmp_types(oid, name) OWNER TO postgres;

--
-- Name: _col_is_null(name, name, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._col_is_null(name, name, text, boolean) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    qcol CONSTANT text := quote_ident($1) || '.' || quote_ident($2);
    c_desc CONSTANT text := coalesce(
        $3,
        'Column ' || qcol || ' should '
            || CASE WHEN $4 THEN 'be NOT' ELSE 'allow' END || ' NULL'
    );
BEGIN
    IF NOT _cexists( $1, $2 ) THEN
        RETURN fail( c_desc ) || E'\n'
            || diag ('    Column ' || qcol || ' does not exist' );
    END IF;
    RETURN ok(
        EXISTS(
            SELECT true
              FROM pg_catalog.pg_class c
              JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
             WHERE pg_catalog.pg_table_is_visible(c.oid)
               AND c.relname = $1
               AND a.attnum > 0
               AND NOT a.attisdropped
               AND a.attname    = $2
               AND a.attnotnull = $4
        ), c_desc
    );
END;
$_$;


ALTER FUNCTION public._col_is_null(name, name, text, boolean) OWNER TO postgres;

--
-- Name: _col_is_null(name, name, name, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._col_is_null(name, name, name, text, boolean) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    qcol CONSTANT text := quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3);
    c_desc CONSTANT text := coalesce(
        $4,
        'Column ' || qcol || ' should '
            || CASE WHEN $5 THEN 'be NOT' ELSE 'allow' END || ' NULL'
    );
BEGIN
    IF NOT _cexists( $1, $2, $3 ) THEN
        RETURN fail( c_desc ) || E'\n'
            || diag ('    Column ' || qcol || ' does not exist' );
    END IF;
    RETURN ok(
        EXISTS(
            SELECT true
              FROM pg_catalog.pg_namespace n
              JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
              JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
             WHERE n.nspname = $1
               AND c.relname = $2
               AND a.attnum  > 0
               AND NOT a.attisdropped
               AND a.attname    = $3
               AND a.attnotnull = $5
        ), c_desc
    );
END;
$_$;


ALTER FUNCTION public._col_is_null(name, name, name, text, boolean) OWNER TO postgres;

--
-- Name: _constraint(name, character, name[], text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._constraint(name, character, name[], text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    akey NAME[];
    keys TEXT[] := '{}';
    have TEXT;
BEGIN
    FOR akey IN SELECT * FROM _keys($1, $2) LOOP
        IF akey = $3 THEN RETURN pass($4); END IF;
        keys = keys || akey::text;
    END LOOP;
    IF array_upper(keys, 0) = 1 THEN
        have := 'No ' || $5 || ' constraints';
    ELSE
        have := array_to_string(keys, E'\n              ');
    END IF;

    RETURN fail($4) || E'\n' || diag(
             '        have: ' || have
       || E'\n        want: ' || CASE WHEN $3 IS NULL THEN 'NULL' ELSE $3::text END
    );
END;
$_$;


ALTER FUNCTION public._constraint(name, character, name[], text, text) OWNER TO postgres;

--
-- Name: _constraint(name, name, character, name[], text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._constraint(name, name, character, name[], text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    akey NAME[];
    keys TEXT[] := '{}';
    have TEXT;
BEGIN
    FOR akey IN SELECT * FROM _keys($1, $2, $3) LOOP
        IF akey = $4 THEN RETURN pass($5); END IF;
        keys = keys || akey::text;
    END LOOP;
    IF array_upper(keys, 0) = 1 THEN
        have := 'No ' || $6 || ' constraints';
    ELSE
        have := array_to_string(keys, E'\n              ');
    END IF;

    RETURN fail($5) || E'\n' || diag(
             '        have: ' || have
       || E'\n        want: ' || CASE WHEN $4 IS NULL THEN 'NULL' ELSE $4::text END
    );
END;
$_$;


ALTER FUNCTION public._constraint(name, name, character, name[], text, text) OWNER TO postgres;

--
-- Name: _contract_on(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._contract_on(text) RETURNS "char"
    LANGUAGE sql IMMUTABLE
    AS $_$
   SELECT CASE substring(LOWER($1) FROM 1 FOR 1)
          WHEN 's' THEN '1'::"char"
          WHEN 'u' THEN '2'::"char"
          WHEN 'i' THEN '3'::"char"
          WHEN 'd' THEN '4'::"char"
          ELSE          '0'::"char" END
$_$;


ALTER FUNCTION public._contract_on(text) OWNER TO postgres;

--
-- Name: _currtest(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._currtest() RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN currval('__tresults___numb_seq');
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN RETURN 0;
END;
$$;


ALTER FUNCTION public._currtest() OWNER TO postgres;

--
-- Name: _db_privs(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._db_privs() RETURNS name[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    pgversion INTEGER := pg_version_num();
BEGIN
    IF pgversion < 80200 THEN
        RETURN ARRAY['CREATE', 'TEMPORARY'];
    ELSE
        RETURN ARRAY['CREATE', 'CONNECT', 'TEMPORARY'];
    END IF;
END;
$$;


ALTER FUNCTION public._db_privs() OWNER TO postgres;

--
-- Name: _def_is(text, text, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._def_is(text, text, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    thing text;
BEGIN
    -- Function, cast, or special SQL syntax.
    IF $1 ~ '^[^'']+[(]' OR $1 ~ '[)]::[^'']+$' OR $1 = ANY('{CURRENT_CATALOG,CURRENT_ROLE,CURRENT_SCHEMA,CURRENT_USER,SESSION_USER,USER,CURRENT_DATE,CURRENT_TIME,CURRENT_TIMESTAMP,LOCALTIME,LOCALTIMESTAMP}') THEN
        RETURN is( $1, $3, $4 );
    END IF;

    EXECUTE 'SELECT is('
             || COALESCE($1, 'NULL' || '::' || $2) || '::' || $2 || ', '
             || COALESCE(quote_literal($3), 'NULL') || '::' || $2 || ', '
             || COALESCE(quote_literal($4), 'NULL')
    || ')' INTO thing;
    RETURN thing;
END;
$_$;


ALTER FUNCTION public._def_is(text, text, anyelement, text) OWNER TO postgres;

--
-- Name: _definer(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._definer(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_definer FROM tap_funky WHERE name = $1 AND is_visible;
$_$;


ALTER FUNCTION public._definer(name) OWNER TO postgres;

--
-- Name: _definer(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._definer(name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_definer
      FROM tap_funky
     WHERE name = $1
       AND args = _funkargs($2)
       AND is_visible;
$_$;


ALTER FUNCTION public._definer(name, name[]) OWNER TO postgres;

--
-- Name: _definer(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._definer(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_definer FROM tap_funky WHERE schema = $1 AND name = $2
$_$;


ALTER FUNCTION public._definer(name, name) OWNER TO postgres;

--
-- Name: _definer(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._definer(name, name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_definer
      FROM tap_funky
     WHERE schema = $1
       AND name   = $2
       AND args   = _funkargs($3)
$_$;


ALTER FUNCTION public._definer(name, name, name[]) OWNER TO postgres;

--
-- Name: _dexists(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._dexists(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
   SELECT EXISTS(
       SELECT true
         FROM pg_catalog.pg_type t
        WHERE t.typname = $1
          AND pg_catalog.pg_type_is_visible(t.oid)
   );
$_$;


ALTER FUNCTION public._dexists(name) OWNER TO postgres;

--
-- Name: _dexists(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._dexists(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
   SELECT EXISTS(
       SELECT true
         FROM pg_catalog.pg_namespace n
         JOIN pg_catalog.pg_type t on n.oid = t.typnamespace
        WHERE n.nspname = $1
          AND t.typname = $2
   );
$_$;


ALTER FUNCTION public._dexists(name, name) OWNER TO postgres;

--
-- Name: _do_ne(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._do_ne(text, text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have    ALIAS FOR $1;
    want    ALIAS FOR $2;
    extras  TEXT[]  := '{}';
    missing TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
BEGIN
    BEGIN
        -- Find extra records.
        EXECUTE 'SELECT EXISTS ( '
             || '( SELECT * FROM ' || have || ' EXCEPT ' || $4
             || '  SELECT * FROM ' || want
             || ' ) UNION ( '
             || '  SELECT * FROM ' || want || ' EXCEPT ' || $4
             || '  SELECT * FROM ' || have
             || ' ) LIMIT 1 )' INTO res;

        -- Drop the temporary tables.
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
    EXCEPTION WHEN syntax_error OR datatype_mismatch THEN
        msg := E'\n' || diag(
            E'    Columns differ between queries:\n'
            || '        have: (' || _temptypes(have) || E')\n'
            || '        want: (' || _temptypes(want) || ')'
        );
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
        RETURN ok(FALSE, $3) || msg;
    END;

    -- Return the value from the query.
    RETURN ok(res, $3);
END;
$_$;


ALTER FUNCTION public._do_ne(text, text, text, text) OWNER TO postgres;

--
-- Name: _docomp(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._docomp(text, text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have    ALIAS FOR $1;
    want    ALIAS FOR $2;
    extras  TEXT[]  := '{}';
    missing TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
    rec     RECORD;
BEGIN
    BEGIN
        -- Find extra records.
        FOR rec in EXECUTE 'SELECT * FROM ' || have || ' EXCEPT ' || $4
                        || 'SELECT * FROM ' || want LOOP
            extras := extras || rec::text;
        END LOOP;

        -- Find missing records.
        FOR rec in EXECUTE 'SELECT * FROM ' || want || ' EXCEPT ' || $4
                        || 'SELECT * FROM ' || have LOOP
            missing := missing || rec::text;
        END LOOP;

        -- Drop the temporary tables.
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
    EXCEPTION WHEN syntax_error OR datatype_mismatch THEN
        msg := E'\n' || diag(
            E'    Columns differ between queries:\n'
            || '        have: (' || _temptypes(have) || E')\n'
            || '        want: (' || _temptypes(want) || ')'
        );
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
        RETURN ok(FALSE, $3) || msg;
    END;

    -- What extra records do we have?
    IF extras[1] IS NOT NULL THEN
        res := FALSE;
        msg := E'\n' || diag(
            E'    Extra records:\n        '
            ||  array_to_string( extras, E'\n        ' )
        );
    END IF;

    -- What missing records do we have?
    IF missing[1] IS NOT NULL THEN
        res := FALSE;
        msg := msg || E'\n' || diag(
            E'    Missing records:\n        '
            ||  array_to_string( missing, E'\n        ' )
        );
    END IF;

    RETURN ok(res, $3) || msg;
END;
$_$;


ALTER FUNCTION public._docomp(text, text, text, text) OWNER TO postgres;

--
-- Name: _error_diag(text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._error_diag(text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT COALESCE(
               COALESCE( NULLIF($1, '') || ': ', '' ) || COALESCE( NULLIF($2, ''), '' ),
               'NO ERROR FOUND'
           )
        || COALESCE(E'\n        DETAIL:     ' || nullif($3, ''), '')
        || COALESCE(E'\n        HINT:       ' || nullif($4, ''), '')
        || COALESCE(E'\n        SCHEMA:     ' || nullif($6, ''), '')
        || COALESCE(E'\n        TABLE:      ' || nullif($7, ''), '')
        || COALESCE(E'\n        COLUMN:     ' || nullif($8, ''), '')
        || COALESCE(E'\n        CONSTRAINT: ' || nullif($9, ''), '')
        || COALESCE(E'\n        TYPE:       ' || nullif($10, ''), '')
        -- We need to manually indent all the context lines
        || COALESCE(E'\n        CONTEXT:\n'
               || regexp_replace(NULLIF( $5, ''), '^', '            ', 'gn'
           ), '');
$_$;


ALTER FUNCTION public._error_diag(text, text, text, text, text, text, text, text, text, text) OWNER TO postgres;

--
-- Name: _expand_context(character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._expand_context(character) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
   SELECT CASE $1
          WHEN 'i' THEN 'implicit'
          WHEN 'a' THEN 'assignment'
          WHEN 'e' THEN 'explicit'
          ELSE          'unknown' END
$_$;


ALTER FUNCTION public._expand_context(character) OWNER TO postgres;

--
-- Name: _expand_on(character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._expand_on(character) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
   SELECT CASE $1
          WHEN '1' THEN 'SELECT'
          WHEN '2' THEN 'UPDATE'
          WHEN '3' THEN 'INSERT'
          WHEN '4' THEN 'DELETE'
          ELSE          'UNKNOWN' END
$_$;


ALTER FUNCTION public._expand_on(character) OWNER TO postgres;

--
-- Name: _expand_vol(character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._expand_vol(character) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
   SELECT CASE $1
          WHEN 'i' THEN 'IMMUTABLE'
          WHEN 's' THEN 'STABLE'
          WHEN 'v' THEN 'VOLATILE'
          ELSE          'UNKNOWN' END
$_$;


ALTER FUNCTION public._expand_vol(character) OWNER TO postgres;

--
-- Name: _ext_exists(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ext_exists(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
        SELECT TRUE
          FROM pg_catalog.pg_extension ex
         WHERE ex.extname = $1
    );
$_$;


ALTER FUNCTION public._ext_exists(name) OWNER TO postgres;

--
-- Name: _ext_exists(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ext_exists(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
        SELECT TRUE
          FROM pg_catalog.pg_extension ex
          JOIN pg_catalog.pg_namespace n ON ex.extnamespace = n.oid
         WHERE n.nspname  = $1
           AND ex.extname = $2
    );
$_$;


ALTER FUNCTION public._ext_exists(name, name) OWNER TO postgres;

--
-- Name: _extensions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._extensions() RETURNS SETOF name
    LANGUAGE sql
    AS $$
    SELECT extname FROM pg_catalog.pg_extension
$$;


ALTER FUNCTION public._extensions() OWNER TO postgres;

--
-- Name: _extensions(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._extensions(name) RETURNS SETOF name
    LANGUAGE sql
    AS $_$
    SELECT e.extname
      FROM pg_catalog.pg_namespace n
      JOIN pg_catalog.pg_extension e ON n.oid = e.extnamespace
     WHERE n.nspname = $1
$_$;


ALTER FUNCTION public._extensions(name) OWNER TO postgres;

--
-- Name: _extras(character[], name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._extras(character[], name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT c.relname
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE pg_catalog.pg_table_is_visible(c.oid)
           AND n.nspname <> 'pg_catalog'
           AND c.relkind = ANY($1)
           AND c.relname NOT IN ('__tcache__', 'pg_all_foreign_keys', 'tap_funky', '__tresults___numb_seq', '__tcache___id_seq')
        EXCEPT
        SELECT $2[i]
          FROM generate_series(1, array_upper($2, 1)) s(i)
    );
$_$;


ALTER FUNCTION public._extras(character[], name[]) OWNER TO postgres;

--
-- Name: _extras(character, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._extras(character, name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
SELECT _extras(ARRAY[$1], $2);
$_$;


ALTER FUNCTION public._extras(character, name[]) OWNER TO postgres;

--
-- Name: _extras(character[], name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._extras(character[], name, name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT c.relname
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE c.relkind = ANY($1)
           AND n.nspname = $2
           AND c.relname NOT IN('pg_all_foreign_keys', 'tap_funky', '__tresults___numb_seq', '__tcache___id_seq')
        EXCEPT
        SELECT $3[i]
          FROM generate_series(1, array_upper($3, 1)) s(i)
    );
$_$;


ALTER FUNCTION public._extras(character[], name, name[]) OWNER TO postgres;

--
-- Name: _extras(character, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._extras(character, name, name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT _extras(ARRAY[$1], $2, $3);
$_$;


ALTER FUNCTION public._extras(character, name, name[]) OWNER TO postgres;

--
-- Name: _finish(integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._finish(integer, integer, integer, boolean DEFAULT NULL::boolean) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    curr_test ALIAS FOR $1;
    exp_tests INTEGER := $2;
    num_faild ALIAS FOR $3;
    plural    CHAR;
    raise_ex  ALIAS FOR $4;
BEGIN
    plural    := CASE exp_tests WHEN 1 THEN '' ELSE 's' END;

    IF curr_test IS NULL THEN
        RAISE EXCEPTION '# No tests run!';
    END IF;

    IF exp_tests = 0 OR exp_tests IS NULL THEN
         -- No plan. Output one now.
        exp_tests = curr_test;
        RETURN NEXT '1..' || exp_tests;
    END IF;

    IF curr_test <> exp_tests THEN
        RETURN NEXT diag(
            'Looks like you planned ' || exp_tests || ' test' ||
            plural || ' but ran ' || curr_test
        );
    ELSIF num_faild > 0 THEN
        IF raise_ex THEN
            RAISE EXCEPTION  '% test% failed of %', num_faild, CASE num_faild WHEN 1 THEN '' ELSE 's' END, exp_tests;
        END IF;
        RETURN NEXT diag(
            'Looks like you failed ' || num_faild || ' test' ||
            CASE num_faild WHEN 1 THEN '' ELSE 's' END
            || ' of ' || exp_tests
        );
    ELSE

    END IF;
    RETURN;
END;
$_$;


ALTER FUNCTION public._finish(integer, integer, integer, boolean) OWNER TO postgres;

--
-- Name: _fkexists(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._fkexists(name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT TRUE
           FROM pg_all_foreign_keys
          WHERE quote_ident(fk_table_name)     = quote_ident($1)
            AND pg_catalog.pg_table_is_visible(fk_table_oid)
            AND fk_columns = $2
    );
$_$;


ALTER FUNCTION public._fkexists(name, name[]) OWNER TO postgres;

--
-- Name: _fkexists(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._fkexists(name, name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT TRUE
           FROM pg_all_foreign_keys
          WHERE fk_schema_name    = $1
            AND quote_ident(fk_table_name)     = quote_ident($2)
            AND fk_columns = $3
    );
$_$;


ALTER FUNCTION public._fkexists(name, name, name[]) OWNER TO postgres;

--
-- Name: _fprivs_are(text, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._fprivs_are(text, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_func_privs($2, $1);
BEGIN
    IF grants[1] = 'undefined_function' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Function ' || $1 || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public._fprivs_are(text, name, name[], text) OWNER TO postgres;

--
-- Name: _func_compare(name, name, boolean, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._func_compare(name, name, boolean, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN $3 IS NULL
      THEN ok( FALSE, $4 ) || _nosuch($1, $2, '{}')
      ELSE ok( $3, $4 )
      END;
$_$;


ALTER FUNCTION public._func_compare(name, name, boolean, text) OWNER TO postgres;

--
-- Name: _func_compare(name, name, name[], boolean, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._func_compare(name, name, name[], boolean, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN $4 IS NULL
      THEN ok( FALSE, $5 ) || _nosuch($1, $2, $3)
      ELSE ok( $4, $5 )
      END;
$_$;


ALTER FUNCTION public._func_compare(name, name, name[], boolean, text) OWNER TO postgres;

--
-- Name: _func_compare(name, name, anyelement, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._func_compare(name, name, anyelement, anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN $3 IS NULL
      THEN ok( FALSE, $5 ) || _nosuch($1, $2, '{}')
      ELSE is( $3, $4, $5 )
      END;
$_$;


ALTER FUNCTION public._func_compare(name, name, anyelement, anyelement, text) OWNER TO postgres;

--
-- Name: _func_compare(name, name, name[], anyelement, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._func_compare(name, name, name[], anyelement, anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN $4 IS NULL
      THEN ok( FALSE, $6 ) || _nosuch($1, $2, $3)
      ELSE is( $4, $5, $6 )
      END;
$_$;


ALTER FUNCTION public._func_compare(name, name, name[], anyelement, anyelement, text) OWNER TO postgres;

--
-- Name: _funkargs(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._funkargs(name[]) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN
    RETURN array_to_string($1::regtype[], ',');
EXCEPTION WHEN undefined_object THEN
    RETURN array_to_string($1, ',');
END;
$_$;


ALTER FUNCTION public._funkargs(name[]) OWNER TO postgres;

--
-- Name: _get(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get(text) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
    ret integer;
BEGIN
    EXECUTE 'SELECT value FROM __tcache__ WHERE label = ' || quote_literal($1) || ' LIMIT 1' INTO ret;
    RETURN ret;
END;
$_$;


ALTER FUNCTION public._get(text) OWNER TO postgres;

--
-- Name: _get_ac_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_ac_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
    privs  TEXT[] := ARRAY['INSERT', 'REFERENCES', 'SELECT', 'UPDATE'];
    grants TEXT[] := '{}';
BEGIN
    FOR i IN 1..array_upper(privs, 1) LOOP
        BEGIN
            IF pg_catalog.has_any_column_privilege($1, $2, privs[i]) THEN
                grants := grants || privs[i];
            END IF;
        EXCEPTION WHEN undefined_table THEN
            -- Not a valid table name.
            RETURN '{undefined_table}';
        WHEN undefined_object THEN
            -- Not a valid role.
            RETURN '{undefined_role}';
        WHEN invalid_parameter_value THEN
            -- Not a valid permission on this version of PostgreSQL; ignore;
        END;
    END LOOP;
    RETURN grants;
END;
$_$;


ALTER FUNCTION public._get_ac_privs(name, text) OWNER TO postgres;

--
-- Name: _get_col_ns_type(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_col_ns_type(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    -- Always include the namespace.
    SELECT CASE WHEN pg_catalog.pg_type_is_visible(t.oid)
                THEN quote_ident(tn.nspname) || '.'
                ELSE ''
           END || pg_catalog.format_type(a.atttypid, a.atttypmod)
      FROM pg_catalog.pg_namespace n
      JOIN pg_catalog.pg_class c      ON n.oid = c.relnamespace
      JOIN pg_catalog.pg_attribute a  ON c.oid = a.attrelid
      JOIN pg_catalog.pg_type t       ON a.atttypid = t.oid
      JOIN pg_catalog.pg_namespace tn ON t.typnamespace = tn.oid
     WHERE n.nspname = $1
       AND c.relname = $2
       AND a.attname = $3
       AND attnum    > 0
       AND NOT a.attisdropped
$_$;


ALTER FUNCTION public._get_col_ns_type(name, name, name) OWNER TO postgres;

--
-- Name: _get_col_privs(name, text, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_col_privs(name, text, name) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
    privs  TEXT[] := ARRAY['INSERT', 'REFERENCES', 'SELECT', 'UPDATE'];
    grants TEXT[] := '{}';
BEGIN
    FOR i IN 1..array_upper(privs, 1) LOOP
        IF pg_catalog.has_column_privilege($1, $2, $3, privs[i]) THEN
            grants := grants || privs[i];
        END IF;
    END LOOP;
    RETURN grants;
EXCEPTION
    -- Not a valid column name.
    WHEN undefined_column THEN RETURN '{undefined_column}';
    -- Not a valid table name.
    WHEN undefined_table THEN RETURN '{undefined_table}';
    -- Not a valid role.
    WHEN undefined_object THEN RETURN '{undefined_role}';
END;
$_$;


ALTER FUNCTION public._get_col_privs(name, text, name) OWNER TO postgres;

--
-- Name: _get_col_type(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_col_type(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.format_type(a.atttypid, a.atttypmod)
      FROM pg_catalog.pg_attribute a
      JOIN pg_catalog.pg_class c ON  a.attrelid = c.oid
     WHERE pg_catalog.pg_table_is_visible(c.oid)
       AND c.relname = $1
       AND a.attname = $2
       AND attnum    > 0
       AND NOT a.attisdropped
$_$;


ALTER FUNCTION public._get_col_type(name, name) OWNER TO postgres;

--
-- Name: _get_col_type(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_col_type(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.format_type(a.atttypid, a.atttypmod)
      FROM pg_catalog.pg_namespace n
      JOIN pg_catalog.pg_class c     ON n.oid = c.relnamespace
      JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
     WHERE n.nspname = $1
       AND c.relname = $2
       AND a.attname = $3
       AND attnum    > 0
       AND NOT a.attisdropped
$_$;


ALTER FUNCTION public._get_col_type(name, name, name) OWNER TO postgres;

--
-- Name: _get_context(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_context(name, name) RETURNS "char"
    LANGUAGE sql
    AS $_$
   SELECT c.castcontext
     FROM pg_catalog.pg_cast c
    WHERE _cmp_types(castsource, $1)
      AND _cmp_types(casttarget, $2)
$_$;


ALTER FUNCTION public._get_context(name, name) OWNER TO postgres;

--
-- Name: _get_db_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_db_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(datdba)
      FROM pg_catalog.pg_database
     WHERE datname = $1;
$_$;


ALTER FUNCTION public._get_db_owner(name) OWNER TO postgres;

--
-- Name: _get_db_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_db_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
    privs  TEXT[] := _db_privs();
    grants TEXT[] := '{}';
BEGIN
    FOR i IN 1..array_upper(privs, 1) LOOP
        BEGIN
            IF pg_catalog.has_database_privilege($1, $2, privs[i]) THEN
                grants := grants || privs[i];
            END IF;
        EXCEPTION WHEN invalid_catalog_name THEN
            -- Not a valid db name.
            RETURN '{invalid_catalog_name}';
        WHEN undefined_object THEN
            -- Not a valid role.
            RETURN '{undefined_role}';
        WHEN invalid_parameter_value THEN
            -- Not a valid permission on this version of PostgreSQL; ignore;
        END;
    END LOOP;
    RETURN grants;
END;
$_$;


ALTER FUNCTION public._get_db_privs(name, text) OWNER TO postgres;

--
-- Name: _get_dtype(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_dtype(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.format_type(t.oid, t.typtypmod)
      FROM pg_catalog.pg_type d
      JOIN pg_catalog.pg_type t  ON d.typbasetype  = t.oid
     WHERE d.typisdefined
       AND pg_catalog.pg_type_is_visible(d.oid)
       AND d.typname = LOWER($1)
       AND d.typtype = 'd'
$_$;


ALTER FUNCTION public._get_dtype(name) OWNER TO postgres;

--
-- Name: _get_dtype(name, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_dtype(name, text, boolean) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN $3 AND pg_catalog.pg_type_is_visible(t.oid)
                THEN quote_ident(tn.nspname) || '.'
                ELSE ''
            END || pg_catalog.format_type(t.oid, t.typtypmod)
      FROM pg_catalog.pg_type d
      JOIN pg_catalog.pg_namespace dn ON d.typnamespace = dn.oid
      JOIN pg_catalog.pg_type t       ON d.typbasetype  = t.oid
      JOIN pg_catalog.pg_namespace tn ON t.typnamespace = tn.oid
     WHERE d.typisdefined
       AND dn.nspname = $1
       AND d.typname  = LOWER($2)
       AND d.typtype  = 'd'
$_$;


ALTER FUNCTION public._get_dtype(name, text, boolean) OWNER TO postgres;

--
-- Name: _get_fdw_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_fdw_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF pg_catalog.has_foreign_data_wrapper_privilege($1, $2, 'USAGE') THEN
        RETURN '{USAGE}';
    ELSE
        RETURN '{}';
    END IF;
EXCEPTION WHEN undefined_object THEN
    -- Same error code for unknown user or fdw. So figure out which.
    RETURN CASE WHEN SQLERRM LIKE '%' || $1 || '%' THEN
        '{undefined_role}'
    ELSE
        '{undefined_fdw}'
    END;
END;
$_$;


ALTER FUNCTION public._get_fdw_privs(name, text) OWNER TO postgres;

--
-- Name: _get_func_owner(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_func_owner(name, name[]) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT owner
      FROM tap_funky
     WHERE name = $1
       AND args = _funkargs($2)
       AND is_visible
$_$;


ALTER FUNCTION public._get_func_owner(name, name[]) OWNER TO postgres;

--
-- Name: _get_func_owner(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_func_owner(name, name, name[]) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT owner
      FROM tap_funky
     WHERE schema = $1
       AND name   = $2
       AND args   = _funkargs($3)
$_$;


ALTER FUNCTION public._get_func_owner(name, name, name[]) OWNER TO postgres;

--
-- Name: _get_func_privs(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_func_privs(text, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF pg_catalog.has_function_privilege($1, $2, 'EXECUTE') THEN
        RETURN '{EXECUTE}';
    ELSE
        RETURN '{}';
    END IF;
EXCEPTION
    -- Not a valid func name.
    WHEN undefined_function THEN RETURN '{undefined_function}';
    -- Not a valid role.
    WHEN undefined_object   THEN RETURN '{undefined_role}';
END;
$_$;


ALTER FUNCTION public._get_func_privs(text, text) OWNER TO postgres;

--
-- Name: _get_index_owner(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_index_owner(name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(ci.relowner)
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
     WHERE ct.relname = $1
       AND ci.relname = $2
       AND pg_catalog.pg_table_is_visible(ct.oid);
$_$;


ALTER FUNCTION public._get_index_owner(name, name) OWNER TO postgres;

--
-- Name: _get_index_owner(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_index_owner(name, name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(ci.relowner)
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
     WHERE n.nspname  = $1
       AND ct.relname = $2
       AND ci.relname = $3;
$_$;


ALTER FUNCTION public._get_index_owner(name, name, name) OWNER TO postgres;

--
-- Name: _get_lang_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_lang_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF pg_catalog.has_language_privilege($1, $2, 'USAGE') THEN
        RETURN '{USAGE}';
    ELSE
        RETURN '{}';
    END IF;
EXCEPTION WHEN undefined_object THEN
    -- Same error code for unknown user or language. So figure out which.
    RETURN CASE WHEN SQLERRM LIKE '%' || $1 || '%' THEN
        '{undefined_role}'
    ELSE
        '{undefined_language}'
    END;
END;
$_$;


ALTER FUNCTION public._get_lang_privs(name, text) OWNER TO postgres;

--
-- Name: _get_language_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_language_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(lanowner)
      FROM pg_catalog.pg_language
     WHERE lanname = $1;
$_$;


ALTER FUNCTION public._get_language_owner(name) OWNER TO postgres;

--
-- Name: _get_latest(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_latest(text) RETURNS integer[]
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
    ret integer[];
BEGIN
    EXECUTE 'SELECT ARRAY[id, value] FROM __tcache__ WHERE label = ' ||
    quote_literal($1) || ' AND id = (SELECT MAX(id) FROM __tcache__ WHERE label = ' ||
    quote_literal($1) || ') LIMIT 1' INTO ret;
    RETURN ret;
EXCEPTION WHEN undefined_table THEN
   RAISE EXCEPTION 'You tried to run a test without a plan! Gotta have a plan';
END;
$_$;


ALTER FUNCTION public._get_latest(text) OWNER TO postgres;

--
-- Name: _get_latest(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_latest(text, integer) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
    ret integer;
BEGIN
    EXECUTE 'SELECT MAX(id) FROM __tcache__ WHERE label = ' ||
    quote_literal($1) || ' AND value = ' || $2 INTO ret;
    RETURN ret;
END;
$_$;


ALTER FUNCTION public._get_latest(text, integer) OWNER TO postgres;

--
-- Name: _get_note(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_note(integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
    ret text;
BEGIN
    EXECUTE 'SELECT note FROM __tcache__ WHERE id = ' || $1 || ' LIMIT 1' INTO ret;
    RETURN ret;
END;
$_$;


ALTER FUNCTION public._get_note(integer) OWNER TO postgres;

--
-- Name: _get_note(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_note(text) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
    ret text;
BEGIN
    EXECUTE 'SELECT note FROM __tcache__ WHERE label = ' || quote_literal($1) || ' LIMIT 1' INTO ret;
    RETURN ret;
END;
$_$;


ALTER FUNCTION public._get_note(text) OWNER TO postgres;

--
-- Name: _get_opclass_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_opclass_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(opcowner)
      FROM pg_catalog.pg_opclass
     WHERE opcname = $1
       AND pg_catalog.pg_opclass_is_visible(oid);
$_$;


ALTER FUNCTION public._get_opclass_owner(name) OWNER TO postgres;

--
-- Name: _get_opclass_owner(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_opclass_owner(name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(opcowner)
      FROM pg_catalog.pg_opclass oc
      JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
     WHERE n.nspname = $1
       AND opcname   = $2;
$_$;


ALTER FUNCTION public._get_opclass_owner(name, name) OWNER TO postgres;

--
-- Name: _get_rel_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_rel_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(c.relowner)
      FROM pg_catalog.pg_class c
     WHERE c.relname = $1
       AND pg_catalog.pg_table_is_visible(c.oid)
$_$;


ALTER FUNCTION public._get_rel_owner(name) OWNER TO postgres;

--
-- Name: _get_rel_owner(character[], name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_rel_owner(character[], name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(c.relowner)
      FROM pg_catalog.pg_class c
     WHERE c.relkind = ANY($1)
       AND c.relname = $2
       AND pg_catalog.pg_table_is_visible(c.oid)
$_$;


ALTER FUNCTION public._get_rel_owner(character[], name) OWNER TO postgres;

--
-- Name: _get_rel_owner(character, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_rel_owner(character, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT _get_rel_owner(ARRAY[$1], $2);
$_$;


ALTER FUNCTION public._get_rel_owner(character, name) OWNER TO postgres;

--
-- Name: _get_rel_owner(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_rel_owner(name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(c.relowner)
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = $1
       AND c.relname = $2
$_$;


ALTER FUNCTION public._get_rel_owner(name, name) OWNER TO postgres;

--
-- Name: _get_rel_owner(character[], name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_rel_owner(character[], name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(c.relowner)
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind = ANY($1)
       AND n.nspname = $2
       AND c.relname = $3
$_$;


ALTER FUNCTION public._get_rel_owner(character[], name, name) OWNER TO postgres;

--
-- Name: _get_rel_owner(character, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_rel_owner(character, name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT _get_rel_owner(ARRAY[$1], $2, $3);
$_$;


ALTER FUNCTION public._get_rel_owner(character, name, name) OWNER TO postgres;

--
-- Name: _get_schema_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_schema_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(nspowner)
      FROM pg_catalog.pg_namespace
     WHERE nspname = $1;
$_$;


ALTER FUNCTION public._get_schema_owner(name) OWNER TO postgres;

--
-- Name: _get_schema_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_schema_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
    privs  TEXT[] := ARRAY['CREATE', 'USAGE'];
    grants TEXT[] := '{}';
BEGIN
    FOR i IN 1..array_upper(privs, 1) LOOP
        IF pg_catalog.has_schema_privilege($1, $2, privs[i]) THEN
            grants := grants || privs[i];
        END IF;
    END LOOP;
    RETURN grants;
EXCEPTION
    -- Not a valid schema name.
    WHEN invalid_schema_name THEN RETURN '{invalid_schema_name}';
    -- Not a valid role.
    WHEN undefined_object   THEN RETURN '{undefined_role}';
END;
$_$;


ALTER FUNCTION public._get_schema_privs(name, text) OWNER TO postgres;

--
-- Name: _get_sequence_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_sequence_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
    privs  TEXT[] := ARRAY['SELECT', 'UPDATE', 'USAGE'];
    grants TEXT[] := '{}';
BEGIN
    FOR i IN 1..array_upper(privs, 1) LOOP
        BEGIN
            IF pg_catalog.has_sequence_privilege($1, $2, privs[i]) THEN
                grants := grants || privs[i];
            END IF;
        EXCEPTION WHEN undefined_table THEN
            -- Not a valid sequence name.
            RETURN '{undefined_table}';
        WHEN undefined_object THEN
            -- Not a valid role.
            RETURN '{undefined_role}';
        WHEN invalid_parameter_value THEN
            -- Not a valid permission on this version of PostgreSQL; ignore;
        END;
    END LOOP;
    RETURN grants;
END;
$_$;


ALTER FUNCTION public._get_sequence_privs(name, text) OWNER TO postgres;

--
-- Name: _get_server_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_server_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF pg_catalog.has_server_privilege($1, $2, 'USAGE') THEN
        RETURN '{USAGE}';
    ELSE
        RETURN '{}';
    END IF;
EXCEPTION WHEN undefined_object THEN
    -- Same error code for unknown user or server. So figure out which.
    RETURN CASE WHEN SQLERRM LIKE '%' || $1 || '%' THEN
        '{undefined_role}'
    ELSE
        '{undefined_server}'
    END;
END;
$_$;


ALTER FUNCTION public._get_server_privs(name, text) OWNER TO postgres;

--
-- Name: _get_table_privs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_table_privs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
    privs  TEXT[] := _table_privs();
    grants TEXT[] := '{}';
BEGIN
    FOR i IN 1..array_upper(privs, 1) LOOP
        BEGIN
            IF pg_catalog.has_table_privilege($1, $2, privs[i]) THEN
                grants := grants || privs[i];
            END IF;
        EXCEPTION WHEN undefined_table THEN
            -- Not a valid table name.
            RETURN '{undefined_table}';
        WHEN undefined_object THEN
            -- Not a valid role.
            RETURN '{undefined_role}';
        WHEN invalid_parameter_value THEN
            -- Not a valid permission on this version of PostgreSQL; ignore;
        END;
    END LOOP;
    RETURN grants;
END;
$_$;


ALTER FUNCTION public._get_table_privs(name, text) OWNER TO postgres;

--
-- Name: _get_tablespace_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_tablespace_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(spcowner)
      FROM pg_catalog.pg_tablespace
     WHERE spcname = $1;
$_$;


ALTER FUNCTION public._get_tablespace_owner(name) OWNER TO postgres;

--
-- Name: _get_tablespaceprivs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_tablespaceprivs(name, text) RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF pg_catalog.has_tablespace_privilege($1, $2, 'CREATE') THEN
        RETURN '{CREATE}';
    ELSE
        RETURN '{}';
    END IF;
EXCEPTION WHEN undefined_object THEN
    -- Same error code for unknown user or tablespace. So figure out which.
    RETURN CASE WHEN SQLERRM LIKE '%' || $1 || '%' THEN
        '{undefined_role}'
    ELSE
        '{undefined_tablespace}'
    END;
END;
$_$;


ALTER FUNCTION public._get_tablespaceprivs(name, text) OWNER TO postgres;

--
-- Name: _get_type_owner(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_type_owner(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(typowner)
      FROM pg_catalog.pg_type
     WHERE typname = $1
       AND pg_catalog.pg_type_is_visible(oid)
$_$;


ALTER FUNCTION public._get_type_owner(name) OWNER TO postgres;

--
-- Name: _get_type_owner(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._get_type_owner(name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT pg_catalog.pg_get_userbyid(t.typowner)
      FROM pg_catalog.pg_type t
      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
     WHERE n.nspname = $1
       AND t.typname = $2
$_$;


ALTER FUNCTION public._get_type_owner(name, name) OWNER TO postgres;

--
-- Name: _got_func(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._got_func(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS( SELECT TRUE FROM tap_funky WHERE name = $1 AND is_visible);
$_$;


ALTER FUNCTION public._got_func(name) OWNER TO postgres;

--
-- Name: _got_func(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._got_func(name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT TRUE
          FROM tap_funky
         WHERE name = $1
           AND args = _funkargs($2)
           AND is_visible
    );
$_$;


ALTER FUNCTION public._got_func(name, name[]) OWNER TO postgres;

--
-- Name: _got_func(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._got_func(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS( SELECT TRUE FROM tap_funky WHERE schema = $1 AND name = $2 );
$_$;


ALTER FUNCTION public._got_func(name, name) OWNER TO postgres;

--
-- Name: _got_func(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._got_func(name, name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT TRUE
          FROM tap_funky
         WHERE schema = $1
           AND name   = $2
           AND args = _funkargs($3)
    );
$_$;


ALTER FUNCTION public._got_func(name, name, name[]) OWNER TO postgres;

--
-- Name: _grolist(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._grolist(name) RETURNS oid[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT member
          FROM pg_catalog.pg_auth_members m
          JOIN pg_catalog.pg_roles r ON m.roleid = r.oid
         WHERE r.rolname =  $1
    );
$_$;


ALTER FUNCTION public._grolist(name) OWNER TO postgres;

--
-- Name: _has_def(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_def(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT a.atthasdef
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
     WHERE c.relname = $1
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND a.attname = $2
       AND pg_catalog.pg_table_is_visible(c.oid)
$_$;


ALTER FUNCTION public._has_def(name, name) OWNER TO postgres;

--
-- Name: _has_def(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_def(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT a.atthasdef
      FROM pg_catalog.pg_namespace n
      JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
      JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
     WHERE n.nspname = $1
       AND c.relname = $2
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND a.attname = $3
$_$;


ALTER FUNCTION public._has_def(name, name, name) OWNER TO postgres;

--
-- Name: _has_group(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_group(name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_group
         WHERE groname = $1
    );
$_$;


ALTER FUNCTION public._has_group(name) OWNER TO postgres;

--
-- Name: _has_role(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_role(name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_roles
         WHERE rolname = $1
    );
$_$;


ALTER FUNCTION public._has_role(name) OWNER TO postgres;

--
-- Name: _has_type(name, character[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_type(name, character[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_type t
         WHERE t.typisdefined
           AND pg_catalog.pg_type_is_visible(t.oid)
           AND t.typname = $1
           AND t.typtype = ANY( COALESCE($2, ARRAY['b', 'c', 'd', 'p', 'e']) )
    );
$_$;


ALTER FUNCTION public._has_type(name, character[]) OWNER TO postgres;

--
-- Name: _has_type(name, name, character[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_type(name, name, character[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_type t
          JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
         WHERE t.typisdefined
           AND n.nspname = $1
           AND t.typname = $2
           AND t.typtype = ANY( COALESCE($3, ARRAY['b', 'c', 'd', 'p', 'e']) )
    );
$_$;


ALTER FUNCTION public._has_type(name, name, character[]) OWNER TO postgres;

--
-- Name: _has_user(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._has_user(name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$
    SELECT EXISTS( SELECT true FROM pg_catalog.pg_user WHERE usename = $1);
$_$;


ALTER FUNCTION public._has_user(name) OWNER TO postgres;

--
-- Name: _hasc(name, character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._hasc(name, character) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
            SELECT true
              FROM pg_catalog.pg_class c
              JOIN pg_catalog.pg_constraint x ON c.oid = x.conrelid
             WHERE pg_table_is_visible(c.oid)
               AND c.relname = $1
               AND x.contype = $2
    );
$_$;


ALTER FUNCTION public._hasc(name, character) OWNER TO postgres;

--
-- Name: _hasc(name, name, character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._hasc(name, name, character) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
            SELECT true
              FROM pg_catalog.pg_namespace n
              JOIN pg_catalog.pg_class c      ON c.relnamespace = n.oid
              JOIN pg_catalog.pg_constraint x ON c.oid = x.conrelid
             WHERE n.nspname = $1
               AND c.relname = $2
               AND x.contype = $3
    );
$_$;


ALTER FUNCTION public._hasc(name, name, character) OWNER TO postgres;

--
-- Name: _have_index(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._have_index(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
    SELECT TRUE
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
     WHERE ct.relname = $1
       AND ci.relname = $2
       AND pg_catalog.pg_table_is_visible(ct.oid)
    );
$_$;


ALTER FUNCTION public._have_index(name, name) OWNER TO postgres;

--
-- Name: _have_index(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._have_index(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
    SELECT TRUE
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
     WHERE n.nspname  = $1
       AND ct.relname = $2
       AND ci.relname = $3
    );
$_$;


ALTER FUNCTION public._have_index(name, name, name) OWNER TO postgres;

--
-- Name: _ident_array_to_sorted_string(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ident_array_to_sorted_string(name[], text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT array_to_string(ARRAY(
        SELECT quote_ident($1[i])
          FROM generate_series(1, array_upper($1, 1)) s(i)
         ORDER BY $1[i]
    ), $2);
$_$;


ALTER FUNCTION public._ident_array_to_sorted_string(name[], text) OWNER TO postgres;

--
-- Name: _ident_array_to_string(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ident_array_to_string(name[], text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT array_to_string(ARRAY(
        SELECT quote_ident($1[i])
          FROM generate_series(1, array_upper($1, 1)) s(i)
         ORDER BY i
    ), $2);
$_$;


ALTER FUNCTION public._ident_array_to_string(name[], text) OWNER TO postgres;

--
-- Name: _ikeys(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ikeys(name, name) RETURNS text[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT pg_catalog.pg_get_indexdef( ci.oid, s.i + 1, false)
          FROM pg_catalog.pg_index x
          JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
          JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
          JOIN generate_series(0, current_setting('max_index_keys')::int - 1) s(i)
            ON x.indkey[s.i] IS NOT NULL
         WHERE ct.relname = $1
           AND ci.relname = $2
           AND pg_catalog.pg_table_is_visible(ct.oid)
         ORDER BY s.i
    );
$_$;


ALTER FUNCTION public._ikeys(name, name) OWNER TO postgres;

--
-- Name: _ikeys(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._ikeys(name, name, name) RETURNS text[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT pg_catalog.pg_get_indexdef( ci.oid, s.i + 1, false)
          FROM pg_catalog.pg_index x
          JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
          JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
          JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
          JOIN generate_series(0, current_setting('max_index_keys')::int - 1) s(i)
            ON x.indkey[s.i] IS NOT NULL
         WHERE ct.relname = $2
           AND ci.relname = $3
           AND n.nspname  = $1
         ORDER BY s.i
    );
$_$;


ALTER FUNCTION public._ikeys(name, name, name) OWNER TO postgres;

--
-- Name: _inherited(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._inherited(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_class c
         WHERE c.relkind = 'r'
           AND pg_catalog.pg_table_is_visible( c.oid )
           AND c.relname = $1
           AND c.relhassubclass = true
    );
$_$;


ALTER FUNCTION public._inherited(name) OWNER TO postgres;

--
-- Name: _inherited(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._inherited(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE c.relkind = 'r'
           AND n.nspname = $1
           AND c.relname = $2
           AND c.relhassubclass = true
  );
$_$;


ALTER FUNCTION public._inherited(name, name) OWNER TO postgres;

--
-- Name: _is_indexed(name, name, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_indexed(name, name, text[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
SELECT EXISTS( SELECT TRUE FROM (
        SELECT _ikeys(coalesce($1, n.nspname), $2, ci.relname) AS cols
          FROM pg_catalog.pg_index x
          JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
          JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
          JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
         WHERE ($1 IS NULL OR n.nspname  = $1)
           AND ct.relname = $2
    ) icols
    WHERE cols = $3 )
$_$;


ALTER FUNCTION public._is_indexed(name, name, text[]) OWNER TO postgres;

--
-- Name: _is_instead(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_instead(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT r.is_instead
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
     WHERE r.rulename = $2
       AND c.relname  = $1
       AND pg_catalog.pg_table_is_visible(c.oid)
$_$;


ALTER FUNCTION public._is_instead(name, name) OWNER TO postgres;

--
-- Name: _is_instead(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_instead(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT r.is_instead
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
      JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
     WHERE r.rulename = $3
       AND c.relname  = $2
       AND n.nspname  = $1
$_$;


ALTER FUNCTION public._is_instead(name, name, name) OWNER TO postgres;

--
-- Name: _is_schema(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_schema(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace
          WHERE nspname = $1
    );
$_$;


ALTER FUNCTION public._is_schema(name) OWNER TO postgres;

--
-- Name: _is_super(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_super(name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$
    SELECT rolsuper
      FROM pg_catalog.pg_roles
     WHERE rolname = $1
$_$;


ALTER FUNCTION public._is_super(name) OWNER TO postgres;

--
-- Name: _is_trusted(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_trusted(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT lanpltrusted FROM pg_catalog.pg_language WHERE lanname = $1;
$_$;


ALTER FUNCTION public._is_trusted(name) OWNER TO postgres;

--
-- Name: _is_verbose(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._is_verbose() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT current_setting('client_min_messages') NOT IN (
        'warning', 'error', 'fatal', 'panic'
    );
$$;


ALTER FUNCTION public._is_verbose() OWNER TO postgres;

--
-- Name: _keys(name, character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._keys(name, character) RETURNS SETOF name[]
    LANGUAGE sql
    AS $_$
    SELECT _pg_sv_column_array(x.conrelid,x.conkey) -- name[] doesn't support collation
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_constraint x  ON c.oid = x.conrelid
       AND c.relname = $1
       AND x.contype = $2
     WHERE pg_catalog.pg_table_is_visible(c.oid)
  ORDER BY 1
$_$;


ALTER FUNCTION public._keys(name, character) OWNER TO postgres;

--
-- Name: _keys(name, name, character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._keys(name, name, character) RETURNS SETOF name[]
    LANGUAGE sql
    AS $_$
    SELECT _pg_sv_column_array(x.conrelid,x.conkey) -- name[] doesn't support collation
      FROM pg_catalog.pg_namespace n
      JOIN pg_catalog.pg_class c       ON n.oid = c.relnamespace
      JOIN pg_catalog.pg_constraint x  ON c.oid = x.conrelid
     WHERE n.nspname = $1
       AND c.relname = $2
       AND x.contype = $3
  ORDER BY 1
$_$;


ALTER FUNCTION public._keys(name, name, character) OWNER TO postgres;

--
-- Name: _lang(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._lang(name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT l.lanname
      FROM tap_funky f
      JOIN pg_catalog.pg_language l ON f.langoid = l.oid
     WHERE f.name = $1
       AND f.is_visible;
$_$;


ALTER FUNCTION public._lang(name) OWNER TO postgres;

--
-- Name: _lang(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._lang(name, name[]) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT l.lanname
      FROM tap_funky f
      JOIN pg_catalog.pg_language l ON f.langoid = l.oid
     WHERE f.name = $1
       AND f.args = _funkargs($2)
       AND f.is_visible;
$_$;


ALTER FUNCTION public._lang(name, name[]) OWNER TO postgres;

--
-- Name: _lang(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._lang(name, name) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT l.lanname
      FROM tap_funky f
      JOIN pg_catalog.pg_language l ON f.langoid = l.oid
     WHERE f.schema = $1
       and f.name   = $2
$_$;


ALTER FUNCTION public._lang(name, name) OWNER TO postgres;

--
-- Name: _lang(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._lang(name, name, name[]) RETURNS name
    LANGUAGE sql
    AS $_$
    SELECT l.lanname
      FROM tap_funky f
      JOIN pg_catalog.pg_language l ON f.langoid = l.oid
     WHERE f.schema = $1
       and f.name   = $2
       AND f.args   = _funkargs($3)
$_$;


ALTER FUNCTION public._lang(name, name, name[]) OWNER TO postgres;

--
-- Name: _missing(character[], name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._missing(character[], name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT $2[i]
          FROM generate_series(1, array_upper($2, 1)) s(i)
        EXCEPT
        SELECT c.relname
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE pg_catalog.pg_table_is_visible(c.oid)
           AND n.nspname NOT IN ('pg_catalog', 'information_schema')
           AND c.relkind = ANY($1)
    );
$_$;


ALTER FUNCTION public._missing(character[], name[]) OWNER TO postgres;

--
-- Name: _missing(character, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._missing(character, name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT _missing(ARRAY[$1], $2);
$_$;


ALTER FUNCTION public._missing(character, name[]) OWNER TO postgres;

--
-- Name: _missing(character[], name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._missing(character[], name, name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT $3[i]
          FROM generate_series(1, array_upper($3, 1)) s(i)
        EXCEPT
        SELECT c.relname
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE c.relkind = ANY($1)
           AND n.nspname = $2
    );
$_$;


ALTER FUNCTION public._missing(character[], name, name[]) OWNER TO postgres;

--
-- Name: _missing(character, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._missing(character, name, name[]) RETURNS name[]
    LANGUAGE sql
    AS $_$
    SELECT _missing(ARRAY[$1], $2, $3);
$_$;


ALTER FUNCTION public._missing(character, name, name[]) OWNER TO postgres;

--
-- Name: _nosuch(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._nosuch(name, name, name[]) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT E'\n' || diag(
        '    Function '
          || CASE WHEN $1 IS NOT NULL THEN quote_ident($1) || '.' ELSE '' END
          || quote_ident($2) || '('
          || array_to_string($3, ', ') || ') does not exist'
    );
$_$;


ALTER FUNCTION public._nosuch(name, name, name[]) OWNER TO postgres;

--
-- Name: _op_exists(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._op_exists(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
       SELECT TRUE
         FROM pg_catalog.pg_operator o
        WHERE pg_catalog.pg_operator_is_visible(o.oid)
          AND o.oprname = $2
          AND CASE o.oprkind WHEN 'l' THEN $1 IS NULL
              ELSE _cmp_types(o.oprleft, _typename($1)) END
          AND CASE o.oprkind WHEN 'r' THEN $3 IS NULL
              ELSE _cmp_types(o.oprright, _typename($3)) END
   );
$_$;


ALTER FUNCTION public._op_exists(name, name, name) OWNER TO postgres;

--
-- Name: _op_exists(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._op_exists(name, name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
       SELECT TRUE
         FROM pg_catalog.pg_operator o
        WHERE pg_catalog.pg_operator_is_visible(o.oid)
          AND o.oprname = $2
          AND CASE o.oprkind WHEN 'l' THEN $1 IS NULL
              ELSE _cmp_types(o.oprleft, _typename($1)) END
          AND CASE o.oprkind WHEN 'r' THEN $3 IS NULL
              ELSE _cmp_types(o.oprright, _typename($3)) END
          AND _cmp_types(o.oprresult, $4)
   );
$_$;


ALTER FUNCTION public._op_exists(name, name, name, name) OWNER TO postgres;

--
-- Name: _op_exists(name, name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._op_exists(name, name, name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
       SELECT TRUE
         FROM pg_catalog.pg_operator o
         JOIN pg_catalog.pg_namespace n ON o.oprnamespace = n.oid
        WHERE n.nspname = $2
          AND o.oprname = $3
          AND CASE o.oprkind WHEN 'l' THEN $1 IS NULL
              ELSE _cmp_types(o.oprleft, _typename($1)) END
          AND CASE o.oprkind WHEN 'r' THEN $4 IS NULL
              ELSE _cmp_types(o.oprright, _typename($4)) END
          AND _cmp_types(o.oprresult, $5)
   );
$_$;


ALTER FUNCTION public._op_exists(name, name, name, name, name) OWNER TO postgres;

--
-- Name: _opc_exists(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._opc_exists(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
        SELECT TRUE
          FROM pg_catalog.pg_opclass oc
         WHERE oc.opcname = $1
           AND pg_opclass_is_visible(oid)
    );
$_$;


ALTER FUNCTION public._opc_exists(name) OWNER TO postgres;

--
-- Name: _opc_exists(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._opc_exists(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS (
        SELECT TRUE
          FROM pg_catalog.pg_opclass oc
          JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
         WHERE n.nspname  = $1
           AND oc.opcname = $2
    );
$_$;


ALTER FUNCTION public._opc_exists(name, name) OWNER TO postgres;

--
-- Name: _partof(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._partof(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_class cc
          JOIN pg_catalog.pg_inherits i ON cc.oid = i.inhrelid
          JOIN pg_catalog.pg_class pc ON i.inhparent = pc.oid
         WHERE cc.relname = $1
           AND cc.relispartition
           AND pc.relname = $2
           AND pc.relkind = 'p'
           AND pg_catalog.pg_table_is_visible(cc.oid)
           AND pg_catalog.pg_table_is_visible(pc.oid)
    )
$_$;


ALTER FUNCTION public._partof(name, name) OWNER TO postgres;

--
-- Name: _partof(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._partof(name, name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace cn
          JOIN pg_catalog.pg_class cc ON cn.oid = cc.relnamespace
          JOIN pg_catalog.pg_inherits i ON cc.oid = i.inhrelid
          JOIN pg_catalog.pg_class pc ON i.inhparent = pc.oid
          JOIN pg_catalog.pg_namespace pn ON pc.relnamespace = pn.oid
         WHERE cn.nspname = $1
           AND cc.relname = $2
           AND cc.relispartition
           AND pn.nspname = $3
           AND pc.relname = $4
           AND pc.relkind = 'p'
    )
$_$;


ALTER FUNCTION public._partof(name, name, name, name) OWNER TO postgres;

--
-- Name: _parts(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._parts(name) RETURNS SETOF name
    LANGUAGE sql
    AS $_$
    SELECT i.inhrelid::regclass::name
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_inherits i ON c.oid = i.inhparent
     WHERE c.relname = $1
       AND c.relkind = 'p'
       AND pg_catalog.pg_table_is_visible(c.oid)
$_$;


ALTER FUNCTION public._parts(name) OWNER TO postgres;

--
-- Name: _parts(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._parts(name, name) RETURNS SETOF name
    LANGUAGE sql
    AS $_$
    SELECT i.inhrelid::regclass::name
      FROM pg_catalog.pg_namespace n
      JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
      JOIN pg_catalog.pg_inherits i ON c.oid = i.inhparent
     WHERE n.nspname = $1
       AND c.relname = $2
       AND c.relkind = 'p'
$_$;


ALTER FUNCTION public._parts(name, name) OWNER TO postgres;

--
-- Name: _pg_sv_column_array(oid, smallint[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._pg_sv_column_array(oid, smallint[]) RETURNS name[]
    LANGUAGE sql STABLE
    AS $_$
    SELECT ARRAY(
        SELECT a.attname
          FROM pg_catalog.pg_attribute a
          JOIN generate_series(1, array_upper($2, 1)) s(i) ON a.attnum = $2[i]
         WHERE attrelid = $1
         ORDER BY i
    )
$_$;


ALTER FUNCTION public._pg_sv_column_array(oid, smallint[]) OWNER TO postgres;

--
-- Name: _pg_sv_table_accessible(oid, oid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._pg_sv_table_accessible(oid, oid) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    SELECT CASE WHEN has_schema_privilege($1, 'USAGE') THEN (
                  has_table_privilege($2, 'SELECT')
               OR has_table_privilege($2, 'INSERT')
               or has_table_privilege($2, 'UPDATE')
               OR has_table_privilege($2, 'DELETE')
               OR has_table_privilege($2, 'RULE')
               OR has_table_privilege($2, 'REFERENCES')
               OR has_table_privilege($2, 'TRIGGER')
           ) ELSE FALSE
    END;
$_$;


ALTER FUNCTION public._pg_sv_table_accessible(oid, oid) OWNER TO postgres;

--
-- Name: _pg_sv_type_array(oid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._pg_sv_type_array(oid[]) RETURNS name[]
    LANGUAGE sql STABLE
    AS $_$
    SELECT ARRAY(
        SELECT t.typname
          FROM pg_catalog.pg_type t
          JOIN generate_series(1, array_upper($1, 1)) s(i) ON t.oid = $1[i]
         ORDER BY i
    )
$_$;


ALTER FUNCTION public._pg_sv_type_array(oid[]) OWNER TO postgres;

--
-- Name: _prokind(oid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._prokind(p_oid oid) RETURNS "char"
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    IF pg_version_num() >= 110000 THEN
        RETURN prokind FROM pg_catalog.pg_proc WHERE oid = p_oid;
    ELSE
        RETURN CASE WHEN proisagg THEN 'a' WHEN proiswindow THEN 'w' ELSE 'f' END
            FROM pg_catalog.pg_proc WHERE oid = p_oid;
    END IF;
END;
$$;


ALTER FUNCTION public._prokind(p_oid oid) OWNER TO postgres;

--
-- Name: _query(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._query(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE
        WHEN $1 LIKE '"%' OR $1 !~ '[[:space:]]' THEN 'EXECUTE ' || $1
        ELSE $1
    END;
$_$;


ALTER FUNCTION public._query(text) OWNER TO postgres;

--
-- Name: _refine_vol(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._refine_vol(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT _expand_vol(substring(LOWER($1) FROM 1 FOR 1)::char);
$_$;


ALTER FUNCTION public._refine_vol(text) OWNER TO postgres;

--
-- Name: _relcomp(text, anyarray, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relcomp(text, anyarray, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _docomp(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$_$;


ALTER FUNCTION public._relcomp(text, anyarray, text, text) OWNER TO postgres;

--
-- Name: _relcomp(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relcomp(text, text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _docomp(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$_$;


ALTER FUNCTION public._relcomp(text, text, text, text) OWNER TO postgres;

--
-- Name: _relcomp(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relcomp(text, text, text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have    TEXT    := _temptable( $1, '__taphave__' );
    want    TEXT    := _temptable( $2, '__tapwant__' );
    results TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
    rec     RECORD;
BEGIN
    BEGIN
        -- Find relevant records.
        FOR rec in EXECUTE 'SELECT * FROM ' || want || ' ' || $4
                       || ' SELECT * FROM ' || have LOOP
            results := results || rec::text;
        END LOOP;

        -- Drop the temporary tables.
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
    EXCEPTION WHEN syntax_error OR datatype_mismatch THEN
        msg := E'\n' || diag(
            E'    Columns differ between queries:\n'
            || '        have: (' || _temptypes(have) || E')\n'
            || '        want: (' || _temptypes(want) || ')'
        );
        EXECUTE 'DROP TABLE ' || have;
        EXECUTE 'DROP TABLE ' || want;
        RETURN ok(FALSE, $3) || msg;
    END;

    -- What records do we have?
    IF results[1] IS NOT NULL THEN
        res := FALSE;
        msg := msg || E'\n' || diag(
            '    ' || $5 || E' records:\n        '
            ||  array_to_string( results, E'\n        ' )
        );
    END IF;

    RETURN ok(res, $3) || msg;
END;
$_$;


ALTER FUNCTION public._relcomp(text, text, text, text, text) OWNER TO postgres;

--
-- Name: _relexists(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relexists(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_class c
         WHERE pg_catalog.pg_table_is_visible(c.oid)
           AND c.relname = $1
    );
$_$;


ALTER FUNCTION public._relexists(name) OWNER TO postgres;

--
-- Name: _relexists(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relexists(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE n.nspname = $1
           AND c.relname = $2
    );
$_$;


ALTER FUNCTION public._relexists(name, name) OWNER TO postgres;

--
-- Name: _relne(text, anyarray, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relne(text, anyarray, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _do_ne(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$_$;


ALTER FUNCTION public._relne(text, anyarray, text, text) OWNER TO postgres;

--
-- Name: _relne(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._relne(text, text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _do_ne(
        _temptable( $1, '__taphave__' ),
        _temptable( $2, '__tapwant__' ),
        $3, $4
    );
$_$;


ALTER FUNCTION public._relne(text, text, text, text) OWNER TO postgres;

--
-- Name: _returns(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._returns(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT returns FROM tap_funky WHERE name = $1 AND is_visible;
$_$;


ALTER FUNCTION public._returns(name) OWNER TO postgres;

--
-- Name: _returns(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._returns(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT returns
      FROM tap_funky
     WHERE name = $1
       AND args = _funkargs($2)
       AND is_visible;
$_$;


ALTER FUNCTION public._returns(name, name[]) OWNER TO postgres;

--
-- Name: _returns(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._returns(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT returns FROM tap_funky WHERE schema = $1 AND name = $2
$_$;


ALTER FUNCTION public._returns(name, name) OWNER TO postgres;

--
-- Name: _returns(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._returns(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT returns
      FROM tap_funky
     WHERE schema = $1
       AND name   = $2
       AND args   = _funkargs($3)
$_$;


ALTER FUNCTION public._returns(name, name, name[]) OWNER TO postgres;

--
-- Name: _retval(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._retval(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    setof TEXT := substring($1 FROM '^setof[[:space:]]+');
BEGIN
    IF setof IS NULL THEN RETURN _typename($1); END IF;
    RETURN setof || _typename(substring($1 FROM char_length(setof)+1));
END;
$_$;


ALTER FUNCTION public._retval(text) OWNER TO postgres;

--
-- Name: _rexists(character[], name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._rexists(character[], name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_class c
         WHERE c.relkind = ANY($1)
           AND pg_catalog.pg_table_is_visible(c.oid)
           AND c.relname = $2
    );
$_$;


ALTER FUNCTION public._rexists(character[], name) OWNER TO postgres;

--
-- Name: _rexists(character, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._rexists(character, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
SELECT _rexists(ARRAY[$1], $2);
$_$;


ALTER FUNCTION public._rexists(character, name) OWNER TO postgres;

--
-- Name: _rexists(character[], name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._rexists(character[], name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
         WHERE c.relkind = ANY($1)
           AND n.nspname = $2
           AND c.relname = $3
    );
$_$;


ALTER FUNCTION public._rexists(character[], name, name) OWNER TO postgres;

--
-- Name: _rexists(character, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._rexists(character, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT _rexists(ARRAY[$1], $2, $3);
$_$;


ALTER FUNCTION public._rexists(character, name, name) OWNER TO postgres;

--
-- Name: _rule_on(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._rule_on(name, name) RETURNS "char"
    LANGUAGE sql
    AS $_$
    SELECT r.ev_type
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
     WHERE r.rulename = $2
       AND c.relname  = $1
$_$;


ALTER FUNCTION public._rule_on(name, name) OWNER TO postgres;

--
-- Name: _rule_on(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._rule_on(name, name, name) RETURNS "char"
    LANGUAGE sql
    AS $_$
    SELECT r.ev_type
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
      JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
     WHERE r.rulename = $3
       AND c.relname  = $2
       AND n.nspname  = $1
$_$;


ALTER FUNCTION public._rule_on(name, name, name) OWNER TO postgres;

--
-- Name: _runem(text[], boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._runem(text[], boolean) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tap    text;
    lbound int := array_lower($1, 1);
BEGIN
    IF lbound IS NULL THEN RETURN; END IF;
    FOR i IN lbound..array_upper($1, 1) LOOP
        -- Send the name of the function to diag if warranted.
        IF $2 THEN RETURN NEXT diag( $1[i] || '()' ); END IF;
        -- Execute the tap function and return its results.
        FOR tap IN EXECUTE 'SELECT * FROM ' || $1[i] || '()' LOOP
            RETURN NEXT tap;
        END LOOP;
    END LOOP;
    RETURN;
END;
$_$;


ALTER FUNCTION public._runem(text[], boolean) OWNER TO postgres;

--
-- Name: _runner(text[], text[], text[], text[], text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._runner(text[], text[], text[], text[], text[]) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    startup  ALIAS FOR $1;
    shutdown ALIAS FOR $2;
    setup    ALIAS FOR $3;
    teardown ALIAS FOR $4;
    tests    ALIAS FOR $5;
    tap      TEXT;
    tfaild   INTEGER := 0;
    ffaild   INTEGER := 0;
    tnumb    INTEGER := 0;
    fnumb    INTEGER := 0;
    tok      BOOLEAN := TRUE;
BEGIN
    BEGIN
        -- No plan support.
        PERFORM * FROM no_plan();
        FOR tap IN SELECT * FROM _runem(startup, false) LOOP RETURN NEXT tap; END LOOP;
    EXCEPTION
        -- Catch all exceptions and simply rethrow custom exceptions. This
        -- will roll back everything in the above block.
        WHEN raise_exception THEN RAISE EXCEPTION '%', SQLERRM;
    END;

    -- Record how startup tests have failed.
    tfaild := num_failed();

    FOR i IN 1..COALESCE(array_upper(tests, 1), 0) LOOP

        -- What subtest are we running?
        RETURN NEXT diag_test_name('Subtest: ' || tests[i]);

        -- Reset the results.
        tok := TRUE;
        tnumb := COALESCE(_get('curr_test'), 0);

        IF tnumb > 0 THEN
            EXECUTE 'ALTER SEQUENCE __tresults___numb_seq RESTART WITH 1';
            PERFORM _set('curr_test', 0);
            PERFORM _set('failed', 0);
        END IF;

        DECLARE
            errstate text;
            errmsg   text;
            detail   text;
            hint     text;
            context  text;
            schname  text;
            tabname  text;
            colname  text;
            chkname  text;
            typname  text;
        BEGIN
            BEGIN
                -- Run the setup functions.
                FOR tap IN SELECT * FROM _runem(setup, false) LOOP
                    RETURN NEXT regexp_replace(tap, '^', '    ', 'gn');
                END LOOP;

                -- Run the actual test function.
                FOR tap IN EXECUTE 'SELECT * FROM ' || tests[i] || '()' LOOP
                    RETURN NEXT regexp_replace(tap, '^', '    ', 'gn');
                END LOOP;

                -- Run the teardown functions.
                FOR tap IN SELECT * FROM _runem(teardown, false) LOOP
                    RETURN NEXT regexp_replace(tap, '^', '    ', 'gn');
                END LOOP;

                -- Emit the plan.
                fnumb := COALESCE(_get('curr_test'), 0);
                RETURN NEXT '    1..' || fnumb;

                -- Emit any error messages.
                IF fnumb = 0 THEN
                    RETURN NEXT '    # No tests run!';
                    tok = false;
                ELSE
                    -- Report failures.
                    ffaild := num_failed();
                    IF ffaild > 0 THEN
                        tok := FALSE;
                        RETURN NEXT '    ' || diag(
                            'Looks like you failed ' || ffaild || ' test' ||
                             CASE ffaild WHEN 1 THEN '' ELSE 's' END
                             || ' of ' || fnumb
                        );
                    END IF;
                END IF;

            EXCEPTION WHEN OTHERS THEN
                -- Something went wrong. Record that fact.
                errstate := SQLSTATE;
                errmsg := SQLERRM;
                GET STACKED DIAGNOSTICS
                    detail  = PG_EXCEPTION_DETAIL,
                    hint    = PG_EXCEPTION_HINT,
                    context = PG_EXCEPTION_CONTEXT,
                    schname = SCHEMA_NAME,
                    tabname = TABLE_NAME,
                    colname = COLUMN_NAME,
                    chkname = CONSTRAINT_NAME,
                    typname = PG_DATATYPE_NAME;
            END;

            -- Always raise an exception to rollback any changes.
            RAISE EXCEPTION '__TAP_ROLLBACK__';

        EXCEPTION WHEN raise_exception THEN
            IF errmsg IS NOT NULL THEN
                -- Something went wrong. Emit the error message.
                tok := FALSE;
               RETURN NEXT regexp_replace( diag('Test died: ' || _error_diag(
                   errstate, errmsg, detail, hint, context, schname, tabname, colname, chkname, typname
               )), '^', '    ', 'gn');
                errmsg := NULL;
            END IF;
        END;

        -- Restore the sequence.
        EXECUTE 'ALTER SEQUENCE __tresults___numb_seq RESTART WITH ' || tnumb + 1;
        PERFORM _set('curr_test', tnumb);
        PERFORM _set('failed', tfaild);

        -- Record this test.
        RETURN NEXT ok(tok, tests[i]);
        IF NOT tok THEN tfaild := tfaild + 1; END IF;

    END LOOP;

    -- Run the shutdown functions.
    FOR tap IN SELECT * FROM _runem(shutdown, false) LOOP RETURN NEXT tap; END LOOP;

    -- Finish up.
    FOR tap IN SELECT * FROM _finish( COALESCE(_get('curr_test'), 0), 0, tfaild ) LOOP
        RETURN NEXT tap;
    END LOOP;

    -- Clean up and return.
    PERFORM _cleanup();
    RETURN;
END;
$_$;


ALTER FUNCTION public._runner(text[], text[], text[], text[], text[]) OWNER TO postgres;

--
-- Name: _set(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._set(integer, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE 'UPDATE __tcache__ SET value = ' || $2
        || ' WHERE id = ' || $1;
    RETURN $2;
END;
$_$;


ALTER FUNCTION public._set(integer, integer) OWNER TO postgres;

--
-- Name: _set(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._set(text, integer) RETURNS integer
    LANGUAGE sql
    AS $_$
    SELECT _set($1, $2, '')
$_$;


ALTER FUNCTION public._set(text, integer) OWNER TO postgres;

--
-- Name: _set(text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._set(text, integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    rcount integer;
BEGIN
    EXECUTE 'UPDATE __tcache__ SET value = ' || $2
        || CASE WHEN $3 IS NULL THEN '' ELSE ', note = ' || quote_literal($3) END
        || ' WHERE label = ' || quote_literal($1);
    GET DIAGNOSTICS rcount = ROW_COUNT;
    IF rcount = 0 THEN
       RETURN _add( $1, $2, $3 );
    END IF;
    RETURN $2;
END;
$_$;


ALTER FUNCTION public._set(text, integer, text) OWNER TO postgres;

--
-- Name: _strict(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._strict(name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_strict FROM tap_funky WHERE name = $1 AND is_visible;
$_$;


ALTER FUNCTION public._strict(name) OWNER TO postgres;

--
-- Name: _strict(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._strict(name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_strict
      FROM tap_funky
     WHERE name = $1
       AND args = _funkargs($2)
       AND is_visible;
$_$;


ALTER FUNCTION public._strict(name, name[]) OWNER TO postgres;

--
-- Name: _strict(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._strict(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_strict FROM tap_funky WHERE schema = $1 AND name = $2
$_$;


ALTER FUNCTION public._strict(name, name) OWNER TO postgres;

--
-- Name: _strict(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._strict(name, name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT is_strict
      FROM tap_funky
     WHERE schema = $1
       AND name   = $2
       AND args   = _funkargs($3)
$_$;


ALTER FUNCTION public._strict(name, name, name[]) OWNER TO postgres;

--
-- Name: _table_privs(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._table_privs() RETURNS name[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    pgversion INTEGER := pg_version_num();
BEGIN
    IF pgversion < 80200 THEN RETURN ARRAY[
        'DELETE', 'INSERT', 'REFERENCES', 'RULE', 'SELECT', 'TRIGGER', 'UPDATE'
    ];
    ELSIF pgversion < 80400 THEN RETURN ARRAY[
        'DELETE', 'INSERT', 'REFERENCES', 'SELECT', 'TRIGGER', 'UPDATE'
    ];
    ELSE RETURN ARRAY[
        'DELETE', 'INSERT', 'REFERENCES', 'SELECT', 'TRIGGER', 'TRUNCATE', 'UPDATE'
    ];
    END IF;
END;
$$;


ALTER FUNCTION public._table_privs() OWNER TO postgres;

--
-- Name: _temptable(anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._temptable(anyarray, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    CREATE TEMP TABLE _____coltmp___ AS
    SELECT $1[i]
    FROM generate_series(array_lower($1, 1), array_upper($1, 1)) s(i);
    EXECUTE 'ALTER TABLE _____coltmp___ RENAME TO ' || $2;
    return $2;
END;
$_$;


ALTER FUNCTION public._temptable(anyarray, text) OWNER TO postgres;

--
-- Name: _temptable(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._temptable(text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE 'CREATE TEMP TABLE ' || $2 || ' AS ' || _query($1);
    return $2;
END;
$_$;


ALTER FUNCTION public._temptable(text, text) OWNER TO postgres;

--
-- Name: _temptypes(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._temptypes(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT array_to_string(ARRAY(
        SELECT pg_catalog.format_type(a.atttypid, a.atttypmod)
          FROM pg_catalog.pg_attribute a
          JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
         WHERE c.oid = ('pg_temp.' || $1)::pg_catalog.regclass
           AND attnum > 0
           AND NOT attisdropped
         ORDER BY attnum
    ), ',');
$_$;


ALTER FUNCTION public._temptypes(text) OWNER TO postgres;

--
-- Name: _time_trials(text, integer, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._time_trials(text, integer, numeric) RETURNS SETOF public._time_trial_type
    LANGUAGE plpgsql
    AS $_$
DECLARE
    query            TEXT := _query($1);
    iterations       ALIAS FOR $2;
    return_percent   ALIAS FOR $3;
    start_time       TEXT;
    act_time         NUMERIC;
    times            NUMERIC[];
    offset_it        INT;
    limit_it         INT;
    offset_percent   NUMERIC;
    a_time           _time_trial_type;
BEGIN
    -- Execute the query over and over
    FOR i IN 1..iterations LOOP
        start_time := timeofday();
        EXECUTE query;
        -- Store the execution time for the run in an array of times
        times[i] := extract(millisecond from timeofday()::timestamptz - start_time::timestamptz);
    END LOOP;
    offset_percent := (1.0 - return_percent) / 2.0;
    -- Ensure that offset skips the bottom X% of runs, or set it to 0
    SELECT GREATEST((offset_percent * iterations)::int, 0) INTO offset_it;
    -- Ensure that with limit the query to returning only the middle X% of runs
    SELECT GREATEST((return_percent * iterations)::int, 1) INTO limit_it;

    FOR a_time IN SELECT times[i]
        FROM generate_series(array_lower(times, 1), array_upper(times, 1)) i
                  ORDER BY 1
                  OFFSET offset_it
                  LIMIT limit_it LOOP
    RETURN NEXT a_time;
    END LOOP;
END;
$_$;


ALTER FUNCTION public._time_trials(text, integer, numeric) OWNER TO postgres;

--
-- Name: _tlike(boolean, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._tlike(boolean, text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( $1, $4 ) || CASE WHEN $1 THEN '' ELSE E'\n' || diag(
           '   error message: ' || COALESCE( quote_literal($2), 'NULL' ) ||
       E'\n   doesn''t match: ' || COALESCE( quote_literal($3), 'NULL' )
    ) END;
$_$;


ALTER FUNCTION public._tlike(boolean, text, text, text) OWNER TO postgres;

--
-- Name: _todo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._todo() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    todos INT[];
    note text;
BEGIN
    -- Get the latest id and value, because todo() might have been called
    -- again before the todos ran out for the first call to todo(). This
    -- allows them to nest.
    todos := _get_latest('todo');
    IF todos IS NULL THEN
        -- No todos.
        RETURN NULL;
    END IF;
    IF todos[2] = 0 THEN
        -- Todos depleted. Clean up.
        EXECUTE 'DELETE FROM __tcache__ WHERE id = ' || todos[1];
        RETURN NULL;
    END IF;
    -- Decrement the count of counted todos and return the reason.
    IF todos[2] <> -1 THEN
        PERFORM _set(todos[1], todos[2] - 1);
    END IF;
    note := _get_note(todos[1]);

    IF todos[2] = 1 THEN
        -- This was the last todo, so delete the record.
        EXECUTE 'DELETE FROM __tcache__ WHERE id = ' || todos[1];
    END IF;

    RETURN note;
END;
$$;


ALTER FUNCTION public._todo() OWNER TO postgres;

--
-- Name: _trig(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._trig(name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_trigger t
          JOIN pg_catalog.pg_class c     ON c.oid = t.tgrelid
         WHERE c.relname = $1
           AND t.tgname  = $2
           AND pg_catalog.pg_table_is_visible(c.oid)
    );
$_$;


ALTER FUNCTION public._trig(name, name) OWNER TO postgres;

--
-- Name: _trig(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._trig(name, name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT EXISTS(
        SELECT true
          FROM pg_catalog.pg_trigger t
          JOIN pg_catalog.pg_class c     ON c.oid = t.tgrelid
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = $1
           AND c.relname = $2
           AND t.tgname  = $3
    );
$_$;


ALTER FUNCTION public._trig(name, name, name) OWNER TO postgres;

--
-- Name: _type_func("char", name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._type_func("char", name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT kind = $1 FROM tap_funky WHERE name = $2 AND is_visible;
$_$;


ALTER FUNCTION public._type_func("char", name) OWNER TO postgres;

--
-- Name: _type_func("char", name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._type_func("char", name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT kind = $1
      FROM tap_funky
     WHERE name = $2
       AND args = _funkargs($3)
       AND is_visible;
$_$;


ALTER FUNCTION public._type_func("char", name, name[]) OWNER TO postgres;

--
-- Name: _type_func("char", name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._type_func("char", name, name) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT kind = $1 FROM tap_funky WHERE schema = $2 AND name = $3
$_$;


ALTER FUNCTION public._type_func("char", name, name) OWNER TO postgres;

--
-- Name: _type_func("char", name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._type_func("char", name, name, name[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
    SELECT kind = $1
      FROM tap_funky
     WHERE schema = $2
       AND name   = $3
       AND args   = _funkargs($4)
$_$;


ALTER FUNCTION public._type_func("char", name, name, name[]) OWNER TO postgres;

--
-- Name: _typename(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._typename(name) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN RETURN $1::REGTYPE;
EXCEPTION WHEN undefined_object THEN RETURN $1;
END;
$_$;


ALTER FUNCTION public._typename(name) OWNER TO postgres;

--
-- Name: _types_are(name[], text, character[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._types_are(name[], text, character[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'types',
        ARRAY(
            SELECT t.typname
              FROM pg_catalog.pg_type t
              LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
             WHERE (
                     t.typrelid = 0
                 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)
             )
               AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_type_is_visible(t.oid)
               AND t.typtype = ANY( COALESCE($3, ARRAY['b', 'c', 'd', 'p', 'e']) )
            EXCEPT
            SELECT _typename($1[i])
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT _typename($1[i])
               FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT t.typname
              FROM pg_catalog.pg_type t
              LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
             WHERE (
                     t.typrelid = 0
                 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)
             )
               AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_type_is_visible(t.oid)
               AND t.typtype = ANY( COALESCE($3, ARRAY['b', 'c', 'd', 'p', 'e']) )
        ),
        $2
    );
$_$;


ALTER FUNCTION public._types_are(name[], text, character[]) OWNER TO postgres;

--
-- Name: _types_are(name, name[], text, character[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._types_are(name, name[], text, character[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'types',
        ARRAY(
            SELECT t.typname
              FROM pg_catalog.pg_type t
              LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
             WHERE (
                     t.typrelid = 0
                 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)
             )
               AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
               AND n.nspname = $1
               AND t.typtype = ANY( COALESCE($4, ARRAY['b', 'c', 'd', 'p', 'e']) )
            EXCEPT
            SELECT _typename($2[i])
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT _typename($2[i])
               FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT t.typname
              FROM pg_catalog.pg_type t
              LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
             WHERE (
                     t.typrelid = 0
                 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)
             )
               AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
               AND n.nspname = $1
               AND t.typtype = ANY( COALESCE($4, ARRAY['b', 'c', 'd', 'p', 'e']) )
        ),
        $3
    );
$_$;


ALTER FUNCTION public._types_are(name, name[], text, character[]) OWNER TO postgres;

--
-- Name: _unalike(boolean, anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._unalike(boolean, anyelement, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    result ALIAS FOR $1;
    got    ALIAS FOR $2;
    rx     ALIAS FOR $3;
    descr  ALIAS FOR $4;
    output TEXT;
BEGIN
    output := ok( result, descr );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '                  ' || COALESCE( quote_literal(got), 'NULL' ) ||
        E'\n         matches: ' || COALESCE( quote_literal(rx), 'NULL' )
    ) END;
END;
$_$;


ALTER FUNCTION public._unalike(boolean, anyelement, text, text) OWNER TO postgres;

--
-- Name: _vol(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vol(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _expand_vol(volatility) FROM tap_funky f
     WHERE f.name = $1 AND f.is_visible;
$_$;


ALTER FUNCTION public._vol(name) OWNER TO postgres;

--
-- Name: _vol(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vol(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _expand_vol(volatility)
      FROM tap_funky f
     WHERE f.name = $1
       AND f.args = _funkargs($2)
       AND f.is_visible;
$_$;


ALTER FUNCTION public._vol(name, name[]) OWNER TO postgres;

--
-- Name: _vol(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vol(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _expand_vol(volatility) FROM tap_funky f
     WHERE f.schema = $1 and f.name = $2
$_$;


ALTER FUNCTION public._vol(name, name) OWNER TO postgres;

--
-- Name: _vol(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vol(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _expand_vol(volatility)
      FROM tap_funky f
     WHERE f.schema = $1
       and f.name   = $2
       AND f.args   = _funkargs($3)
$_$;


ALTER FUNCTION public._vol(name, name, name[]) OWNER TO postgres;

--
-- Name: add_point_tile_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_point_tile_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	New.tile_id := pos_to_tile_id(18, ST_Y(NEW.geom::geometry), ST_X(NEW.geom::geometry));
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_point_tile_id() OWNER TO postgres;

--
-- Name: add_result(boolean, boolean, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_result(boolean, boolean, text, text, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT $1 THEN PERFORM _set('failed', _get('failed') + 1); END IF;
    RETURN nextval('__tresults___numb_seq');
END;
$_$;


ALTER FUNCTION public.add_result(boolean, boolean, text, text, text) OWNER TO postgres;

--
-- Name: alike(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.alike(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~~ $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.alike(anyelement, text) OWNER TO postgres;

--
-- Name: alike(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.alike(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~~ $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.alike(anyelement, text, text) OWNER TO postgres;

--
-- Name: any_column_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.any_column_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT any_column_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on any column in ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.any_column_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: any_column_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.any_column_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_ac_privs( $2, quote_ident($1) );
BEGIN
    IF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.any_column_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: any_column_privs_are(name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.any_column_privs_are(name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT any_column_privs_are(
        $1, $2, $3, $4,
        'Role ' || quote_ident($3) || ' should be granted '
            || CASE WHEN $4[1] IS NULL THEN 'no privileges' ELSE array_to_string($4, ', ') END
            || ' on any column in '|| quote_ident($1) || '.' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.any_column_privs_are(name, name, name, name[]) OWNER TO postgres;

--
-- Name: any_column_privs_are(name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.any_column_privs_are(name, name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_ac_privs( $3, quote_ident($1) || '.' || quote_ident($2) );
BEGIN
    IF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Role ' || quote_ident($3) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $4, $5);
END;
$_$;


ALTER FUNCTION public.any_column_privs_are(name, name, name, name[], text) OWNER TO postgres;

--
-- Name: bag_eq(text, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_eq(text, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::text, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_eq(text, anyarray) OWNER TO postgres;

--
-- Name: bag_eq(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_eq(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::text, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_eq(text, text) OWNER TO postgres;

--
-- Name: bag_eq(text, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_eq(text, anyarray, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_eq(text, anyarray, text) OWNER TO postgres;

--
-- Name: bag_eq(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_eq(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_eq(text, text, text) OWNER TO postgres;

--
-- Name: bag_has(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_has(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'EXCEPT ALL', 'Missing' );
$_$;


ALTER FUNCTION public.bag_has(text, text) OWNER TO postgres;

--
-- Name: bag_has(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_has(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, 'EXCEPT ALL', 'Missing' );
$_$;


ALTER FUNCTION public.bag_has(text, text, text) OWNER TO postgres;

--
-- Name: bag_hasnt(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_hasnt(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'INTERSECT ALL', 'Extra' );
$_$;


ALTER FUNCTION public.bag_hasnt(text, text) OWNER TO postgres;

--
-- Name: bag_hasnt(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_hasnt(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, 'INTERSECT ALL', 'Extra' );
$_$;


ALTER FUNCTION public.bag_hasnt(text, text, text) OWNER TO postgres;

--
-- Name: bag_ne(text, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_ne(text, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, NULL::text, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_ne(text, anyarray) OWNER TO postgres;

--
-- Name: bag_ne(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_ne(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, NULL::text, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_ne(text, text) OWNER TO postgres;

--
-- Name: bag_ne(text, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_ne(text, anyarray, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, $3, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_ne(text, anyarray, text) OWNER TO postgres;

--
-- Name: bag_ne(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bag_ne(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, $3, 'ALL ' );
$_$;


ALTER FUNCTION public.bag_ne(text, text, text) OWNER TO postgres;

--
-- Name: can(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT can( $1, 'Schema ' || _ident_array_to_string(current_schemas(true), ' or ') || ' can' );
$_$;


ALTER FUNCTION public.can(name[]) OWNER TO postgres;

--
-- Name: can(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can(name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    missing text[];
BEGIN
    SELECT ARRAY(
        SELECT quote_ident($1[i])
          FROM generate_series(1, array_upper($1, 1)) s(i)
          LEFT JOIN pg_catalog.pg_proc p
            ON $1[i] = p.proname
           AND pg_catalog.pg_function_is_visible(p.oid)
         WHERE p.oid IS NULL
         ORDER BY s.i
    ) INTO missing;
    IF missing[1] IS NULL THEN
        RETURN ok( true, $2 );
    END IF;
    RETURN ok( false, $2 ) || E'\n' || diag(
        '    ' ||
        array_to_string( missing, E'() missing\n    ') ||
        '() missing'
    );
END;
$_$;


ALTER FUNCTION public.can(name[], text) OWNER TO postgres;

--
-- Name: can(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT can( $1, $2, 'Schema ' || quote_ident($1) || ' can' );
$_$;


ALTER FUNCTION public.can(name, name[]) OWNER TO postgres;

--
-- Name: can(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can(name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    missing text[];
BEGIN
    SELECT ARRAY(
        SELECT quote_ident($2[i])
          FROM generate_series(1, array_upper($2, 1)) s(i)
          LEFT JOIN tap_funky ON name = $2[i] AND schema = $1
         WHERE oid IS NULL
         GROUP BY $2[i], s.i
         ORDER BY MIN(s.i)
    ) INTO missing;
    IF missing[1] IS NULL THEN
        RETURN ok( true, $3 );
    END IF;
    RETURN ok( false, $3 ) || E'\n' || diag(
        '    ' || quote_ident($1) || '.' ||
        array_to_string( missing, E'() missing\n    ' || quote_ident($1) || '.') ||
        '() missing'
    );
END;
$_$;


ALTER FUNCTION public.can(name, name[], text) OWNER TO postgres;

--
-- Name: cast_context_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_context_is(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT cast_context_is(
        $1, $2, $3,
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') context should be ' || _expand_context(substring(LOWER($3) FROM 1 FOR 1))
    );
$_$;


ALTER FUNCTION public.cast_context_is(name, name, text) OWNER TO postgres;

--
-- Name: cast_context_is(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_context_is(name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want char = substring(LOWER($3) FROM 1 FOR 1);
    have char := _get_context($1, $2);
BEGIN
    IF have IS NOT NULL THEN
        RETURN is( _expand_context(have), _expand_context(want), $4 );
    END IF;

    RETURN ok( false, $4 ) || E'\n' || diag(
       '    Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
      || ') does not exist'
    );
END;
$_$;


ALTER FUNCTION public.cast_context_is(name, name, text, text) OWNER TO postgres;

--
-- Name: casts_are(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.casts_are(text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT casts_are( $1, 'There should be the correct casts');
$_$;


ALTER FUNCTION public.casts_are(text[]) OWNER TO postgres;

--
-- Name: casts_are(text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.casts_are(text[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _areni(
        'casts',
        ARRAY(
            SELECT pg_catalog.format_type(castsource, NULL)
                   || ' AS ' || pg_catalog.format_type(casttarget, NULL)
              FROM pg_catalog.pg_cast c
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT pg_catalog.format_type(castsource, NULL)
                   || ' AS ' || pg_catalog.format_type(casttarget, NULL)
              FROM pg_catalog.pg_cast c
        ),
        $2
    );
$_$;


ALTER FUNCTION public.casts_are(text[], text) OWNER TO postgres;

--
-- Name: check_test(text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_test(text, boolean) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM check_test( $1, $2, NULL, NULL, NULL, FALSE );
$_$;


ALTER FUNCTION public.check_test(text, boolean) OWNER TO postgres;

--
-- Name: check_test(text, boolean, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_test(text, boolean, text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM check_test( $1, $2, $3, NULL, NULL, FALSE );
$_$;


ALTER FUNCTION public.check_test(text, boolean, text) OWNER TO postgres;

--
-- Name: check_test(text, boolean, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_test(text, boolean, text, text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM check_test( $1, $2, $3, $4, NULL, FALSE );
$_$;


ALTER FUNCTION public.check_test(text, boolean, text, text) OWNER TO postgres;

--
-- Name: check_test(text, boolean, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_test(text, boolean, text, text, text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM check_test( $1, $2, $3, $4, $5, FALSE );
$_$;


ALTER FUNCTION public.check_test(text, boolean, text, text, text) OWNER TO postgres;

--
-- Name: check_test(text, boolean, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_test(text, boolean, text, text, text, boolean) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tnumb   INTEGER;
    aok     BOOLEAN;
    adescr  TEXT;
    res     BOOLEAN;
    descr   TEXT;
    adiag   TEXT;
    have    ALIAS FOR $1;
    eok     ALIAS FOR $2;
    name    ALIAS FOR $3;
    edescr  ALIAS FOR $4;
    ediag   ALIAS FOR $5;
    matchit ALIAS FOR $6;
BEGIN
    -- What test was it that just ran?
    tnumb := currval('__tresults___numb_seq');

    -- Fetch the results.
    aok    := substring(have, 1, 2) = 'ok';
    adescr := COALESCE(substring(have FROM  E'(?:not )?ok [[:digit:]]+ - ([^\n]+)'), '');

    -- Now delete those results.
    EXECUTE 'ALTER SEQUENCE __tresults___numb_seq RESTART WITH ' || tnumb;
    IF NOT aok THEN PERFORM _set('failed', _get('failed') - 1); END IF;

    -- Set up the description.
    descr := coalesce( name || ' ', 'Test ' ) || 'should ';

    -- So, did the test pass?
    RETURN NEXT is(
        aok,
        eok,
        descr || CASE eok WHEN true then 'pass' ELSE 'fail' END
    );

    -- Was the description as expected?
    IF edescr IS NOT NULL THEN
        RETURN NEXT is(
            adescr,
            edescr,
            descr || 'have the proper description'
        );
    END IF;

    -- Were the diagnostics as expected?
    IF ediag IS NOT NULL THEN
        -- Remove ok and the test number.
        adiag := substring(
            have
            FROM CASE WHEN aok THEN 4 ELSE 9 END + char_length(tnumb::text)
        );

        -- Remove the description, if there is one.
        IF adescr <> '' THEN
            adiag := substring(
                adiag FROM 1 + char_length( ' - ' || substr(diag( adescr ), 3) )
            );
        END IF;

        IF NOT aok THEN
            -- Remove failure message from ok().
            adiag := substring(adiag FROM 1 + char_length(diag(
                'Failed test ' || tnumb ||
                CASE adescr WHEN '' THEN '' ELSE COALESCE(': "' || adescr || '"', '') END
            )));
        END IF;

        IF ediag <> '' THEN
           -- Remove the space before the diagnostics.
           adiag := substring(adiag FROM 2);
        END IF;

        -- Remove the #s.
        adiag := replace( substring(adiag from 3), E'\n# ', E'\n' );

        -- Now compare the diagnostics.
        IF matchit THEN
            RETURN NEXT matches(
                adiag,
                ediag,
                descr || 'have the proper diagnostics'
            );
        ELSE
            RETURN NEXT is(
                adiag,
                ediag,
                descr || 'have the proper diagnostics'
            );
        END IF;
    END IF;

    -- And we're done
    RETURN;
END;
$_$;


ALTER FUNCTION public.check_test(text, boolean, text, text, text, boolean) OWNER TO postgres;

--
-- Name: cmp_ok(anyelement, text, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cmp_ok(anyelement, text, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT cmp_ok( $1, $2, $3, NULL );
$_$;


ALTER FUNCTION public.cmp_ok(anyelement, text, anyelement) OWNER TO postgres;

--
-- Name: cmp_ok(anyelement, text, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cmp_ok(anyelement, text, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have   ALIAS FOR $1;
    op     ALIAS FOR $2;
    want   ALIAS FOR $3;
    descr  ALIAS FOR $4;
    result BOOLEAN;
    output TEXT;
BEGIN
    EXECUTE 'SELECT ' ||
            COALESCE(quote_literal( have ), 'NULL') || '::' || pg_typeof(have) || ' '
            || op || ' ' ||
            COALESCE(quote_literal( want ), 'NULL') || '::' || pg_typeof(want)
       INTO result;
    output := ok( COALESCE(result, FALSE), descr );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '    ' || COALESCE( quote_literal(have), 'NULL' ) ||
           E'\n        ' || op ||
           E'\n    ' || COALESCE( quote_literal(want), 'NULL' )
    ) END;
END;
$_$;


ALTER FUNCTION public.cmp_ok(anyelement, text, anyelement, text) OWNER TO postgres;

--
-- Name: col_default_is(name, name, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_default_is(name, name, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _cdi( $1, $2, $3 );
$_$;


ALTER FUNCTION public.col_default_is(name, name, anyelement) OWNER TO postgres;

--
-- Name: col_default_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_default_is(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _cdi( $1, $2, $3 );
$_$;


ALTER FUNCTION public.col_default_is(name, name, text) OWNER TO postgres;

--
-- Name: col_default_is(name, name, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_default_is(name, name, anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _cdi( $1, $2, $3, $4 );
$_$;


ALTER FUNCTION public.col_default_is(name, name, anyelement, text) OWNER TO postgres;

--
-- Name: col_default_is(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_default_is(name, name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _cdi( $1, $2, $3, $4 );
$_$;


ALTER FUNCTION public.col_default_is(name, name, text, text) OWNER TO postgres;

--
-- Name: col_default_is(name, name, name, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_default_is(name, name, name, anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _cdi( $1, $2, $3, $4, $5 );
$_$;


ALTER FUNCTION public.col_default_is(name, name, name, anyelement, text) OWNER TO postgres;

--
-- Name: col_default_is(name, name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_default_is(name, name, name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _cdi( $1, $2, $3, $4, $5 );
$_$;


ALTER FUNCTION public.col_default_is(name, name, name, text, text) OWNER TO postgres;

--
-- Name: col_has_check(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_check(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_has_check( $1, $2, 'Columns ' || quote_ident($1) || '(' || _ident_array_to_string($2, ', ') || ') should have a check constraint' );
$_$;


ALTER FUNCTION public.col_has_check(name, name[]) OWNER TO postgres;

--
-- Name: col_has_check(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_check(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_has_check( $1, $2, 'Column ' || quote_ident($1) || '(' || quote_ident($2) || ') should have a check constraint' );
$_$;


ALTER FUNCTION public.col_has_check(name, name) OWNER TO postgres;

--
-- Name: col_has_check(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_check(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _constraint( $1, 'c', $2, $3, 'check' );
$_$;


ALTER FUNCTION public.col_has_check(name, name[], text) OWNER TO postgres;

--
-- Name: col_has_check(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_check(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_has_check( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.col_has_check(name, name, text) OWNER TO postgres;

--
-- Name: col_has_check(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_check(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _constraint( $1, $2, 'c', $3, $4, 'check' );
$_$;


ALTER FUNCTION public.col_has_check(name, name, name[], text) OWNER TO postgres;

--
-- Name: col_has_check(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_check(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_has_check( $1, $2, ARRAY[$3], $4 );
$_$;


ALTER FUNCTION public.col_has_check(name, name, name, text) OWNER TO postgres;

--
-- Name: col_has_default(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_default(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_has_default( $1, $2, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || ' should have a default' );
$_$;


ALTER FUNCTION public.col_has_default(name, name) OWNER TO postgres;

--
-- Name: col_has_default(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_default(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT _cexists( $1, $2 ) THEN
        RETURN fail( $3 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist' );
    END IF;
    RETURN ok( _has_def( $1, $2 ), $3 );
END;
$_$;


ALTER FUNCTION public.col_has_default(name, name, text) OWNER TO postgres;

--
-- Name: col_has_default(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_has_default(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT _cexists( $1, $2, $3 ) THEN
        RETURN fail( $4 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3) || ' does not exist' );
    END IF;
    RETURN ok( _has_def( $1, $2, $3 ), $4 );
END
$_$;


ALTER FUNCTION public.col_has_default(name, name, name, text) OWNER TO postgres;

--
-- Name: col_hasnt_default(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_hasnt_default(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_hasnt_default( $1, $2, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || ' should not have a default' );
$_$;


ALTER FUNCTION public.col_hasnt_default(name, name) OWNER TO postgres;

--
-- Name: col_hasnt_default(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_hasnt_default(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT _cexists( $1, $2 ) THEN
        RETURN fail( $3 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist' );
    END IF;
    RETURN ok( NOT _has_def( $1, $2 ), $3 );
END;
$_$;


ALTER FUNCTION public.col_hasnt_default(name, name, text) OWNER TO postgres;

--
-- Name: col_hasnt_default(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_hasnt_default(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT _cexists( $1, $2, $3 ) THEN
        RETURN fail( $4 ) || E'\n'
            || diag ('    Column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3) || ' does not exist' );
    END IF;
    RETURN ok( NOT _has_def( $1, $2, $3 ), $4 );
END;
$_$;


ALTER FUNCTION public.col_hasnt_default(name, name, name, text) OWNER TO postgres;

--
-- Name: col_is_fk(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_fk(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_fk( $1, $2, 'Columns ' || quote_ident($1) || '(' || _ident_array_to_string($2, ', ') || ') should be a foreign key' );
$_$;


ALTER FUNCTION public.col_is_fk(name, name[]) OWNER TO postgres;

--
-- Name: col_is_fk(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_fk(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_fk( $1, $2, 'Column ' || quote_ident($1) || '(' || quote_ident($2) || ') should be a foreign key' );
$_$;


ALTER FUNCTION public.col_is_fk(name, name) OWNER TO postgres;

--
-- Name: col_is_fk(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_fk(name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    names text[];
BEGIN
    IF _fkexists($1, $2) THEN
        RETURN pass( $3 );
    END IF;

    -- Try to show the columns.
    SELECT ARRAY(
        SELECT _ident_array_to_string(fk_columns, ', ')
          FROM pg_all_foreign_keys
         WHERE fk_table_name  = $1
         ORDER BY fk_columns
    ) INTO names;

    IF NAMES[1] IS NOT NULL THEN
        RETURN fail($3) || E'\n' || diag(
            '    Table ' || quote_ident($1) || E' has foreign key constraints on these columns:\n        '
            || array_to_string( names, E'\n        ' )
        );
    END IF;

    -- No FKs in this table.
    RETURN fail($3) || E'\n' || diag(
        '    Table ' || quote_ident($1) || ' has no foreign key columns'
    );
END;
$_$;


ALTER FUNCTION public.col_is_fk(name, name[], text) OWNER TO postgres;

--
-- Name: col_is_fk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_fk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_fk( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.col_is_fk(name, name, text) OWNER TO postgres;

--
-- Name: col_is_fk(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_fk(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    names text[];
BEGIN
    IF _fkexists($1, $2, $3) THEN
        RETURN pass( $4 );
    END IF;

    -- Try to show the columns.
    SELECT ARRAY(
        SELECT _ident_array_to_string(fk_columns, ', ')
          FROM pg_all_foreign_keys
         WHERE fk_schema_name = $1
           AND fk_table_name  = $2
         ORDER BY fk_columns
    ) INTO names;

    IF names[1] IS NOT NULL THEN
        RETURN fail($4) || E'\n' || diag(
            '    Table ' || quote_ident($1) || '.' || quote_ident($2) || E' has foreign key constraints on these columns:\n        '
            ||  array_to_string( names, E'\n        ' )
        );
    END IF;

    -- No FKs in this table.
    RETURN fail($4) || E'\n' || diag(
        '    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' has no foreign key columns'
    );
END;
$_$;


ALTER FUNCTION public.col_is_fk(name, name, name[], text) OWNER TO postgres;

--
-- Name: col_is_fk(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_fk(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_fk( $1, $2, ARRAY[$3], $4 );
$_$;


ALTER FUNCTION public.col_is_fk(name, name, name, text) OWNER TO postgres;

--
-- Name: col_is_null(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_null(table_name name, column_name name, description text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _col_is_null( $1, $2, $3, false );
$_$;


ALTER FUNCTION public.col_is_null(table_name name, column_name name, description text) OWNER TO postgres;

--
-- Name: col_is_null(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_null(schema_name name, table_name name, column_name name, description text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _col_is_null( $1, $2, $3, $4, false );
$_$;


ALTER FUNCTION public.col_is_null(schema_name name, table_name name, column_name name, description text) OWNER TO postgres;

--
-- Name: col_is_pk(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_pk( $1, $2, 'Columns ' || quote_ident($1) || '(' || _ident_array_to_string($2, ', ') || ') should be a primary key' );
$_$;


ALTER FUNCTION public.col_is_pk(name, name[]) OWNER TO postgres;

--
-- Name: col_is_pk(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_pk( $1, $2, 'Column ' || quote_ident($1) || '(' || quote_ident($2) || ') should be a primary key' );
$_$;


ALTER FUNCTION public.col_is_pk(name, name) OWNER TO postgres;

--
-- Name: col_is_pk(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is( _ckeys( $1, 'p' ), $2, $3 );
$_$;


ALTER FUNCTION public.col_is_pk(name, name[], text) OWNER TO postgres;

--
-- Name: col_is_pk(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_pk( $1, $2, $3, 'Columns ' || quote_ident($1) || '.' || quote_ident($2) || '(' || _ident_array_to_string($3, ', ') || ') should be a primary key' );
$_$;


ALTER FUNCTION public.col_is_pk(name, name, name[]) OWNER TO postgres;

--
-- Name: col_is_pk(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_pk( $1, $2, $3, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || '(' || quote_ident($3) || ') should be a primary key' );
$_$;


ALTER FUNCTION public.col_is_pk(name, name, name) OWNER TO postgres;

--
-- Name: col_is_pk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_pk( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.col_is_pk(name, name, text) OWNER TO postgres;

--
-- Name: col_is_pk(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is( _ckeys( $1, $2, 'p' ), $3, $4 );
$_$;


ALTER FUNCTION public.col_is_pk(name, name, name[], text) OWNER TO postgres;

--
-- Name: col_is_pk(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_pk(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_pk( $1, $2, ARRAY[$3], $4 );
$_$;


ALTER FUNCTION public.col_is_pk(name, name, name, text) OWNER TO postgres;

--
-- Name: col_is_unique(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_unique( $1, $2, 'Columns ' || quote_ident($1) || '(' || _ident_array_to_string($2, ', ') || ') should have a unique constraint' );
$_$;


ALTER FUNCTION public.col_is_unique(name, name[]) OWNER TO postgres;

--
-- Name: col_is_unique(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_unique( $1, $2, 'Column ' || quote_ident($1) || '(' || quote_ident($2) || ') should have a unique constraint' );
$_$;


ALTER FUNCTION public.col_is_unique(name, name) OWNER TO postgres;

--
-- Name: col_is_unique(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _constraint( $1, 'u', $2, $3, 'unique' );
$_$;


ALTER FUNCTION public.col_is_unique(name, name[], text) OWNER TO postgres;

--
-- Name: col_is_unique(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_unique( $1, $2, $3, 'Columns ' || quote_ident($2) || '(' || _ident_array_to_string($3, ', ') || ') should have a unique constraint' );
$_$;


ALTER FUNCTION public.col_is_unique(name, name, name[]) OWNER TO postgres;

--
-- Name: col_is_unique(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_unique( $1, $2, ARRAY[$3], 'Column ' || quote_ident($2) || '(' || quote_ident($3) || ') should have a unique constraint' );
$_$;


ALTER FUNCTION public.col_is_unique(name, name, name) OWNER TO postgres;

--
-- Name: col_is_unique(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_unique( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.col_is_unique(name, name, text) OWNER TO postgres;

--
-- Name: col_is_unique(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _constraint( $1, $2, 'u', $3, $4, 'unique' );
$_$;


ALTER FUNCTION public.col_is_unique(name, name, name[], text) OWNER TO postgres;

--
-- Name: col_is_unique(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_is_unique(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_is_unique( $1, $2, ARRAY[$3], $4 );
$_$;


ALTER FUNCTION public.col_is_unique(name, name, name, text) OWNER TO postgres;

--
-- Name: col_isnt_fk(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_fk(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_fk( $1, $2, 'Columns ' || quote_ident($1) || '(' || _ident_array_to_string($2, ', ') || ') should not be a foreign key' );
$_$;


ALTER FUNCTION public.col_isnt_fk(name, name[]) OWNER TO postgres;

--
-- Name: col_isnt_fk(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_fk(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_fk( $1, $2, 'Column ' || quote_ident($1) || '(' || quote_ident($2) || ') should not be a foreign key' );
$_$;


ALTER FUNCTION public.col_isnt_fk(name, name) OWNER TO postgres;

--
-- Name: col_isnt_fk(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_fk(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _fkexists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.col_isnt_fk(name, name[], text) OWNER TO postgres;

--
-- Name: col_isnt_fk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_fk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_fk( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.col_isnt_fk(name, name, text) OWNER TO postgres;

--
-- Name: col_isnt_fk(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_fk(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _fkexists( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.col_isnt_fk(name, name, name[], text) OWNER TO postgres;

--
-- Name: col_isnt_fk(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_fk(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_fk( $1, $2, ARRAY[$3], $4 );
$_$;


ALTER FUNCTION public.col_isnt_fk(name, name, name, text) OWNER TO postgres;

--
-- Name: col_isnt_pk(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_pk(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_pk( $1, $2, 'Columns ' || quote_ident($1) || '(' || _ident_array_to_string($2, ', ') || ') should not be a primary key' );
$_$;


ALTER FUNCTION public.col_isnt_pk(name, name[]) OWNER TO postgres;

--
-- Name: col_isnt_pk(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_pk(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_pk( $1, $2, 'Column ' || quote_ident($1) || '(' || quote_ident($2) || ') should not be a primary key' );
$_$;


ALTER FUNCTION public.col_isnt_pk(name, name) OWNER TO postgres;

--
-- Name: col_isnt_pk(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_pk(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt( _ckeys( $1, 'p' ), $2, $3 );
$_$;


ALTER FUNCTION public.col_isnt_pk(name, name[], text) OWNER TO postgres;

--
-- Name: col_isnt_pk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_pk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_pk( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.col_isnt_pk(name, name, text) OWNER TO postgres;

--
-- Name: col_isnt_pk(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_pk(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt( _ckeys( $1, $2, 'p' ), $3, $4 );
$_$;


ALTER FUNCTION public.col_isnt_pk(name, name, name[], text) OWNER TO postgres;

--
-- Name: col_isnt_pk(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_isnt_pk(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_isnt_pk( $1, $2, ARRAY[$3], $4 );
$_$;


ALTER FUNCTION public.col_isnt_pk(name, name, name, text) OWNER TO postgres;

--
-- Name: col_not_null(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_not_null(table_name name, column_name name, description text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _col_is_null( $1, $2, $3, true );
$_$;


ALTER FUNCTION public.col_not_null(table_name name, column_name name, description text) OWNER TO postgres;

--
-- Name: col_not_null(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_not_null(schema_name name, table_name name, column_name name, description text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _col_is_null( $1, $2, $3, $4, true );
$_$;


ALTER FUNCTION public.col_not_null(schema_name name, table_name name, column_name name, description text) OWNER TO postgres;

--
-- Name: col_type_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_type_is(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_type_is( $1, $2, $3, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || ' should be type ' || $3 );
$_$;


ALTER FUNCTION public.col_type_is(name, name, text) OWNER TO postgres;

--
-- Name: col_type_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_type_is(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_type_is( $1, $2, $3, $4, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3) || ' should be type ' || $4 );
$_$;


ALTER FUNCTION public.col_type_is(name, name, name, text) OWNER TO postgres;

--
-- Name: col_type_is(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_type_is(name, name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_type_is( NULL, $1, $2, $3, $4 );
$_$;


ALTER FUNCTION public.col_type_is(name, name, text, text) OWNER TO postgres;

--
-- Name: col_type_is(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_type_is(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT col_type_is( $1, $2, $3, $4, $5, 'Column ' || quote_ident($1) || '.' || quote_ident($2)
        || '.' || quote_ident($3) || ' should be type ' || quote_ident($4) || '.' || $5);
$_$;


ALTER FUNCTION public.col_type_is(name, name, name, name, text) OWNER TO postgres;

--
-- Name: col_type_is(name, name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_type_is(name, name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have_type TEXT;
    want_type TEXT;
BEGIN
    -- Get the data type.
    IF $1 IS NULL THEN
        have_type := _get_col_type($2, $3);
    ELSE
        have_type := _get_col_type($1, $2, $3);
    END IF;

    IF have_type IS NULL THEN
        RETURN fail( $5 ) || E'\n' || diag (
            '   Column ' || COALESCE(quote_ident($1) || '.', '')
            || quote_ident($2) || '.' || quote_ident($3) || ' does not exist'
        );
    END IF;

    want_type := format_type_string($4);
    IF want_type IS NULL THEN
        RETURN fail( $5 ) || E'\n' || diag (
            '    Type ' || $4 || ' does not exist'
        );
    END IF;

    IF have_type = want_type THEN
        -- We're good to go.
        RETURN ok( true, $5 );
    END IF;

    -- Wrong data type. tell 'em what we really got.
    RETURN ok( false, $5 ) || E'\n' || diag(
           '        have: ' || have_type ||
        E'\n        want: ' || want_type
    );
END;
$_$;


ALTER FUNCTION public.col_type_is(name, name, name, text, text) OWNER TO postgres;

--
-- Name: col_type_is(name, name, name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.col_type_is(name, name, name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have_type TEXT := _get_col_ns_type($1, $2, $3);
    want_type TEXT;
BEGIN
    IF have_type IS NULL THEN
        RETURN fail( $6 ) || E'\n' || diag (
            '   Column ' || COALESCE(quote_ident($1) || '.', '')
            || quote_ident($2) || '.' || quote_ident($3) || ' does not exist'
        );
    END IF;

    IF quote_ident($4) = ANY(current_schemas(true)) THEN
        want_type := quote_ident($4) || '.' || format_type_string($5);
    ELSE
        want_type := format_type_string(quote_ident($4) || '.' || $5);
    END IF;

    IF want_type IS NULL THEN
        RETURN fail( $6 ) || E'\n' || diag (
            '    Type ' || quote_ident($4) || '.' || $5 || ' does not exist'
        );
    END IF;

    IF have_type = want_type THEN
        -- We're good to go.
        RETURN ok( true, $6 );
    END IF;

    -- Wrong data type. tell 'em what we really got.
    RETURN ok( false, $6 ) || E'\n' || diag(
           '        have: ' || have_type ||
        E'\n        want: ' || want_type
    );
END;
$_$;


ALTER FUNCTION public.col_type_is(name, name, name, name, text, text) OWNER TO postgres;

--
-- Name: collect_tap(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.collect_tap(VARIADIC text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT array_to_string($1, E'\n');
$_$;


ALTER FUNCTION public.collect_tap(VARIADIC text[]) OWNER TO postgres;

--
-- Name: collect_tap(character varying[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.collect_tap(character varying[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT array_to_string($1, E'\n');
$_$;


ALTER FUNCTION public.collect_tap(character varying[]) OWNER TO postgres;

--
-- Name: column_privs_are(name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.column_privs_are(name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT column_privs_are(
        $1, $2, $3, $4,
        'Role ' || quote_ident($3) || ' should be granted '
            || CASE WHEN $4[1] IS NULL THEN 'no privileges' ELSE array_to_string($4, ', ') END
            || ' on column ' || quote_ident($1) || '.' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.column_privs_are(name, name, name, name[]) OWNER TO postgres;

--
-- Name: column_privs_are(name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.column_privs_are(name, name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_col_privs( $3, quote_ident($1), $2 );
BEGIN
    IF grants[1] = 'undefined_column' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Column ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Table ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Role ' || quote_ident($3) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $4, $5);
END;
$_$;


ALTER FUNCTION public.column_privs_are(name, name, name, name[], text) OWNER TO postgres;

--
-- Name: column_privs_are(name, name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.column_privs_are(name, name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT column_privs_are(
        $1, $2, $3, $4, $5,
        'Role ' || quote_ident($4) || ' should be granted '
            || CASE WHEN $5[1] IS NULL THEN 'no privileges' ELSE array_to_string($5, ', ') END
            || ' on column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.column_privs_are(name, name, name, name, name[]) OWNER TO postgres;

--
-- Name: column_privs_are(name, name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.column_privs_are(name, name, name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_col_privs( $4, quote_ident($1) || '.' || quote_ident($2), $3 );
BEGIN
    IF grants[1] = 'undefined_column' THEN
        RETURN ok(FALSE, $6) || E'\n' || diag(
            '    Column ' || quote_ident($1) || '.' || quote_ident($2) || '.' || quote_ident($3)
            || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $6) || E'\n' || diag(
            '    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $6) || E'\n' || diag(
            '    Role ' || quote_ident($4) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $5, $6);
END;
$_$;


ALTER FUNCTION public.column_privs_are(name, name, name, name, name[], text) OWNER TO postgres;

--
-- Name: columns_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.columns_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT columns_are( $1, $2, 'Table ' || quote_ident($1) || ' should have the correct columns' );
$_$;


ALTER FUNCTION public.columns_are(name, name[]) OWNER TO postgres;

--
-- Name: columns_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.columns_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'columns',
        ARRAY(
            SELECT a.attname
              FROM pg_catalog.pg_namespace n
              JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
              JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
             WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_table_is_visible(c.oid)
               AND c.relname = $1
               AND a.attnum > 0
               AND NOT a.attisdropped
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT a.attname
              FROM pg_catalog.pg_namespace n
              JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
              JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
             WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_table_is_visible(c.oid)
               AND c.relname = $1
               AND a.attnum > 0
               AND NOT a.attisdropped
        ),
        $3
    );
$_$;


ALTER FUNCTION public.columns_are(name, name[], text) OWNER TO postgres;

--
-- Name: columns_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.columns_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT columns_are( $1, $2, $3, 'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct columns' );
$_$;


ALTER FUNCTION public.columns_are(name, name, name[]) OWNER TO postgres;

--
-- Name: columns_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.columns_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'columns',
        ARRAY(
            SELECT a.attname
              FROM pg_catalog.pg_namespace n
              JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
              JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
             WHERE n.nspname = $1
               AND c.relname = $2
               AND a.attnum > 0
               AND NOT a.attisdropped
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
        ),
        ARRAY(
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT a.attname
              FROM pg_catalog.pg_namespace n
              JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
              JOIN pg_catalog.pg_attribute a ON c.oid = a.attrelid
             WHERE n.nspname = $1
               AND c.relname = $2
               AND a.attnum > 0
               AND NOT a.attisdropped
        ),
        $4
    );
$_$;


ALTER FUNCTION public.columns_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: combine_lines_into_polygon(public.geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.combine_lines_into_polygon(input_geom public.geometry[]) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
DECLARE
    conn1 geometry;
    conn2 geometry;
    merged_boundary geometry;
BEGIN

    IF ARRAY_LENGTH(input_geom, 1) = 1 THEN
        IF NOT ST_IsClosed(input_geom[1]) THEN
            input_geom[1] := ST_AddPoint(input_geom[1], ST_StartPoint(input_geom[1]));
        END IF;
        RETURN ST_MakePolygon(input_geom[1]);
    END IF;

    conn1 := ST_MakeLine(ST_StartPoint(input_geom[1]), ST_EndPoint(input_geom[2]));
    conn2 := ST_MakeLine(ST_StartPoint(input_geom[2]), ST_EndPoint(input_geom[1]));

    merged_boundary := ST_LineMerge(
        ST_Collect(
            ARRAY[input_geom[1], input_geom[2], conn1, conn2]
        )
    );

    RETURN ST_MakePolygon(merged_boundary);
END;
$$;


ALTER FUNCTION public.combine_lines_into_polygon(input_geom public.geometry[]) OWNER TO postgres;

--
-- Name: composite_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.composite_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT composite_owner_is(
        $1, $2,
        'Composite type ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.composite_owner_is(name, name) OWNER TO postgres;

--
-- Name: composite_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.composite_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT composite_owner_is(
        $1, $2, $3,
        'Composite type ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.composite_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: composite_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.composite_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('c'::char, $1);
BEGIN
    -- Make sure the composite exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Composite type ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.composite_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: composite_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.composite_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('c'::char, $1, $2);
BEGIN
    -- Make sure the composite exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Composite type ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.composite_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: database_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.database_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT database_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on database ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.database_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: database_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.database_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_db_privs( $2, $1::TEXT );
BEGIN
    IF grants[1] = 'invalid_catalog_name' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Database ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.database_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: db_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.db_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT db_owner_is(
        $1, $2,
        'Database ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.db_owner_is(name, name) OWNER TO postgres;

--
-- Name: db_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.db_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    dbowner NAME := _get_db_owner($1);
BEGIN
    -- Make sure the database exists.
    IF dbowner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Database ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(dbowner, $2, $3);
END;
$_$;


ALTER FUNCTION public.db_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: diag(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diag(VARIADIC text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT diag(array_to_string($1, ''));
$_$;


ALTER FUNCTION public.diag(VARIADIC text[]) OWNER TO postgres;

--
-- Name: diag(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diag(VARIADIC anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT diag(array_to_string($1, ''));
$_$;


ALTER FUNCTION public.diag(VARIADIC anyarray) OWNER TO postgres;

--
-- Name: diag(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diag(msg anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT diag($1::text);
$_$;


ALTER FUNCTION public.diag(msg anyelement) OWNER TO postgres;

--
-- Name: diag(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diag(msg text) RETURNS text
    LANGUAGE sql STRICT
    AS $_$
    SELECT '# ' || replace(
       replace(
            replace( $1, E'\r\n', E'\n# ' ),
            E'\n',
            E'\n# '
        ),
        E'\r',
        E'\n# '
    );
$_$;


ALTER FUNCTION public.diag(msg text) OWNER TO postgres;

--
-- Name: diag_test_name(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diag_test_name(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT diag($1 || '()');
$_$;


ALTER FUNCTION public.diag_test_name(text) OWNER TO postgres;

--
-- Name: display_oper(name, oid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.display_oper(name, oid) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT $1 || substring($2::regoperator::text, '[(][^)]+[)]$')
$_$;


ALTER FUNCTION public.display_oper(name, oid) OWNER TO postgres;

--
-- Name: do_tap(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.do_tap() RETURNS SETOF text
    LANGUAGE sql
    AS $$
    SELECT * FROM _runem( findfuncs('^test'), _is_verbose());
$$;


ALTER FUNCTION public.do_tap() OWNER TO postgres;

--
-- Name: do_tap(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.do_tap(name) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM _runem( findfuncs($1, '^test'), _is_verbose() );
$_$;


ALTER FUNCTION public.do_tap(name) OWNER TO postgres;

--
-- Name: do_tap(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.do_tap(text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM _runem( findfuncs($1), _is_verbose() );
$_$;


ALTER FUNCTION public.do_tap(text) OWNER TO postgres;

--
-- Name: do_tap(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.do_tap(name, text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM _runem( findfuncs($1, $2), _is_verbose() );
$_$;


ALTER FUNCTION public.do_tap(name, text) OWNER TO postgres;

--
-- Name: doesnt_imatch(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doesnt_imatch(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~* $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.doesnt_imatch(anyelement, text) OWNER TO postgres;

--
-- Name: doesnt_imatch(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doesnt_imatch(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~* $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.doesnt_imatch(anyelement, text, text) OWNER TO postgres;

--
-- Name: doesnt_match(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doesnt_match(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~ $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.doesnt_match(anyelement, text) OWNER TO postgres;

--
-- Name: doesnt_match(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doesnt_match(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~ $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.doesnt_match(anyelement, text, text) OWNER TO postgres;

--
-- Name: domain_type_is(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_is(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT domain_type_is(
        $1, $2,
        'Domain ' || $1 || ' should extend type ' || $2
    );
$_$;


ALTER FUNCTION public.domain_type_is(text, text) OWNER TO postgres;

--
-- Name: domain_type_is(name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_is(name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT domain_type_is(
        $1, $2, $3,
        'Domain ' || quote_ident($1) || '.' || $2
        || ' should extend type ' || $3
    );
$_$;


ALTER FUNCTION public.domain_type_is(name, text, text) OWNER TO postgres;

--
-- Name: domain_type_is(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_is(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    actual_type TEXT := _get_dtype($1);
BEGIN
    IF actual_type IS NULL THEN
        RETURN fail( $3 ) || E'\n' || diag (
            '   Domain ' ||  $1 || ' does not exist'
        );
    END IF;

    RETURN is( actual_type, _typename($2), $3 );
END;
$_$;


ALTER FUNCTION public.domain_type_is(text, text, text) OWNER TO postgres;

--
-- Name: domain_type_is(name, text, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_is(name, text, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT domain_type_is(
        $1, $2, $3, $4,
        'Domain ' || quote_ident($1) || '.' || $2
        || ' should extend type ' || quote_ident($3) || '.' || $4
    );
$_$;


ALTER FUNCTION public.domain_type_is(name, text, name, text) OWNER TO postgres;

--
-- Name: domain_type_is(name, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_is(name, text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    actual_type TEXT := _get_dtype($1, $2, false);
BEGIN
    IF actual_type IS NULL THEN
        RETURN fail( $4 ) || E'\n' || diag (
            '   Domain ' || quote_ident($1) || '.' || $2
            || ' does not exist'
        );
    END IF;

    RETURN is( actual_type, _typename($3), $4 );
END;
$_$;


ALTER FUNCTION public.domain_type_is(name, text, text, text) OWNER TO postgres;

--
-- Name: domain_type_is(name, text, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_is(name, text, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    actual_type TEXT := _get_dtype($1, $2, true);
BEGIN
    IF actual_type IS NULL THEN
        RETURN fail( $5 ) || E'\n' || diag (
            '   Domain ' || quote_ident($1) || '.' || $2
            || ' does not exist'
        );
    END IF;

    IF quote_ident($3) = ANY(current_schemas(true)) THEN
        RETURN is( actual_type, quote_ident($3) || '.' || _typename($4), $5);
    END IF;
    RETURN is( actual_type, _typename(quote_ident($3) || '.' || $4), $5);
END;
$_$;


ALTER FUNCTION public.domain_type_is(name, text, name, text, text) OWNER TO postgres;

--
-- Name: domain_type_isnt(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_isnt(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT domain_type_isnt(
        $1, $2,
        'Domain ' || $1 || ' should not extend type ' || $2
    );
$_$;


ALTER FUNCTION public.domain_type_isnt(text, text) OWNER TO postgres;

--
-- Name: domain_type_isnt(name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_isnt(name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT domain_type_isnt(
        $1, $2, $3,
        'Domain ' || quote_ident($1) || '.' || $2
        || ' should not extend type ' || $3
    );
$_$;


ALTER FUNCTION public.domain_type_isnt(name, text, text) OWNER TO postgres;

--
-- Name: domain_type_isnt(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_isnt(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    actual_type TEXT := _get_dtype($1);
BEGIN
    IF actual_type IS NULL THEN
        RETURN fail( $3 ) || E'\n' || diag (
            '   Domain ' ||  $1 || ' does not exist'
        );
    END IF;

    RETURN isnt( actual_type, _typename($2), $3 );
END;
$_$;


ALTER FUNCTION public.domain_type_isnt(text, text, text) OWNER TO postgres;

--
-- Name: domain_type_isnt(name, text, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_isnt(name, text, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT domain_type_isnt(
        $1, $2, $3, $4,
        'Domain ' || quote_ident($1) || '.' || $2
        || ' should not extend type ' || quote_ident($3) || '.' || $4
    );
$_$;


ALTER FUNCTION public.domain_type_isnt(name, text, name, text) OWNER TO postgres;

--
-- Name: domain_type_isnt(name, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_isnt(name, text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    actual_type TEXT := _get_dtype($1, $2, false);
BEGIN
    IF actual_type IS NULL THEN
        RETURN fail( $4 ) || E'\n' || diag (
            '   Domain ' || quote_ident($1) || '.' || $2
            || ' does not exist'
        );
    END IF;

    RETURN isnt( actual_type, _typename($3), $4 );
END;
$_$;


ALTER FUNCTION public.domain_type_isnt(name, text, text, text) OWNER TO postgres;

--
-- Name: domain_type_isnt(name, text, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domain_type_isnt(name, text, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    actual_type TEXT := _get_dtype($1, $2, true);
BEGIN
    IF actual_type IS NULL THEN
        RETURN fail( $5 ) || E'\n' || diag (
            '   Domain ' || quote_ident($1) || '.' || $2
            || ' does not exist'
        );
    END IF;

    IF quote_ident($3) = ANY(current_schemas(true)) THEN
        RETURN isnt( actual_type, quote_ident($3) || '.' || _typename($4), $5);
    END IF;
    RETURN isnt( actual_type, _typename(quote_ident($3) || '.' || $4), $5);
END;
$_$;


ALTER FUNCTION public.domain_type_isnt(name, text, name, text, text) OWNER TO postgres;

--
-- Name: domains_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domains_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, 'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct domains', ARRAY['d'] );
$_$;


ALTER FUNCTION public.domains_are(name[]) OWNER TO postgres;

--
-- Name: domains_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domains_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, ARRAY['d'] );
$_$;


ALTER FUNCTION public.domains_are(name[], text) OWNER TO postgres;

--
-- Name: domains_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domains_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, 'Schema ' || quote_ident($1) || ' should have the correct domains', ARRAY['d'] );
$_$;


ALTER FUNCTION public.domains_are(name, name[]) OWNER TO postgres;

--
-- Name: domains_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.domains_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, $3, ARRAY['d'] );
$_$;


ALTER FUNCTION public.domains_are(name, name[], text) OWNER TO postgres;

--
-- Name: enum_has_labels(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enum_has_labels(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT enum_has_labels(
        $1, $2,
        'Enum ' || quote_ident($1) || ' should have labels (' || array_to_string( $2, ', ' ) || ')'
    );
$_$;


ALTER FUNCTION public.enum_has_labels(name, name[]) OWNER TO postgres;

--
-- Name: enum_has_labels(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enum_has_labels(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is(
        ARRAY(
            SELECT e.enumlabel
              FROM pg_catalog.pg_type t
              JOIN pg_catalog.pg_enum e ON t.oid = e.enumtypid
              WHERE t.typisdefined
               AND pg_catalog.pg_type_is_visible(t.oid)
               AND t.typname = $1
               AND t.typtype = 'e'
             ORDER BY e.enumsortorder
        ),
        $2,
        $3
    );
$_$;


ALTER FUNCTION public.enum_has_labels(name, name[], text) OWNER TO postgres;

--
-- Name: enum_has_labels(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enum_has_labels(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT enum_has_labels(
        $1, $2, $3,
        'Enum ' || quote_ident($1) || '.' || quote_ident($2) || ' should have labels (' || array_to_string( $3, ', ' ) || ')'
    );
$_$;


ALTER FUNCTION public.enum_has_labels(name, name, name[]) OWNER TO postgres;

--
-- Name: enum_has_labels(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enum_has_labels(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is(
        ARRAY(
            SELECT e.enumlabel
              FROM pg_catalog.pg_type t
              JOIN pg_catalog.pg_enum e      ON t.oid = e.enumtypid
              JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
              WHERE t.typisdefined
               AND n.nspname = $1
               AND t.typname = $2
               AND t.typtype = 'e'
             ORDER BY e.enumsortorder
        ),
        $3,
        $4
    );
$_$;


ALTER FUNCTION public.enum_has_labels(name, name, name[], text) OWNER TO postgres;

--
-- Name: enums_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enums_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, 'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct enums', ARRAY['e'] );
$_$;


ALTER FUNCTION public.enums_are(name[]) OWNER TO postgres;

--
-- Name: enums_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enums_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, ARRAY['e'] );
$_$;


ALTER FUNCTION public.enums_are(name[], text) OWNER TO postgres;

--
-- Name: enums_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enums_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, 'Schema ' || quote_ident($1) || ' should have the correct enums', ARRAY['e'] );
$_$;


ALTER FUNCTION public.enums_are(name, name[]) OWNER TO postgres;

--
-- Name: enums_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enums_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, $3, ARRAY['e'] );
$_$;


ALTER FUNCTION public.enums_are(name, name[], text) OWNER TO postgres;

--
-- Name: extensions_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.extensions_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
  SELECT extensions_are($1, 'Should have the correct extensions');
$_$;


ALTER FUNCTION public.extensions_are(name[]) OWNER TO postgres;

--
-- Name: extensions_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.extensions_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'extensions',
        ARRAY(SELECT _extensions() EXCEPT SELECT unnest($1)),
        ARRAY(SELECT unnest($1) EXCEPT SELECT _extensions()),
        $2
    );
$_$;


ALTER FUNCTION public.extensions_are(name[], text) OWNER TO postgres;

--
-- Name: extensions_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.extensions_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
  SELECT extensions_are(
        $1, $2,
        'Schema ' || quote_ident($1) || ' should have the correct extensions'
    );
$_$;


ALTER FUNCTION public.extensions_are(name, name[]) OWNER TO postgres;

--
-- Name: extensions_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.extensions_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'extensions',
        ARRAY(SELECT _extensions($1) EXCEPT SELECT unnest($2)),
        ARRAY(SELECT unnest($2) EXCEPT SELECT _extensions($1)),
        $3
    );
$_$;


ALTER FUNCTION public.extensions_are(name, name[], text) OWNER TO postgres;

--
-- Name: fail(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fail() RETURNS text
    LANGUAGE sql
    AS $$
    SELECT ok( FALSE, NULL );
$$;


ALTER FUNCTION public.fail() OWNER TO postgres;

--
-- Name: fail(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fail(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( FALSE, $1 );
$_$;


ALTER FUNCTION public.fail(text) OWNER TO postgres;

--
-- Name: fdw_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fdw_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fdw_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on FDW ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.fdw_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: fdw_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fdw_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_fdw_privs( $2, $1::TEXT );
BEGIN
    IF grants[1] = 'undefined_fdw' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    FDW ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.fdw_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: findfuncs(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.findfuncs(text) RETURNS text[]
    LANGUAGE sql
    AS $_$
    SELECT findfuncs( $1, NULL )
$_$;


ALTER FUNCTION public.findfuncs(text) OWNER TO postgres;

--
-- Name: findfuncs(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.findfuncs(name, text) RETURNS text[]
    LANGUAGE sql
    AS $_$
    SELECT findfuncs( $1, $2, NULL )
$_$;


ALTER FUNCTION public.findfuncs(name, text) OWNER TO postgres;

--
-- Name: findfuncs(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.findfuncs(text, text) RETURNS text[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT DISTINCT (quote_ident(n.nspname) || '.' || quote_ident(p.proname)) COLLATE "C" AS pname
          FROM pg_catalog.pg_proc p
          JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
         WHERE pg_catalog.pg_function_is_visible(p.oid)
           AND p.proname ~ $1
           AND ($2 IS NULL OR p.proname !~ $2)
         ORDER BY pname
    );
$_$;


ALTER FUNCTION public.findfuncs(text, text) OWNER TO postgres;

--
-- Name: findfuncs(name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.findfuncs(name, text, text) RETURNS text[]
    LANGUAGE sql
    AS $_$
    SELECT ARRAY(
        SELECT DISTINCT (quote_ident(n.nspname) || '.' || quote_ident(p.proname)) COLLATE "C" AS pname
          FROM pg_catalog.pg_proc p
          JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = $1
           AND p.proname ~ $2
           AND ($3 IS NULL OR p.proname !~ $3)
         ORDER BY pname
    );
$_$;


ALTER FUNCTION public.findfuncs(name, text, text) OWNER TO postgres;

--
-- Name: finish(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.finish(exception_on_failure boolean DEFAULT NULL::boolean) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM _finish(
        _get('curr_test'),
        _get('plan'),
        num_failed(),
        $1
    );
$_$;


ALTER FUNCTION public.finish(exception_on_failure boolean) OWNER TO postgres;

--
-- Name: fix_split_line(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fix_split_line(geom public.geometry) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
DECLARE
	val_sign NUMERIC;
	fixed_line geometry;
BEGIN
	SELECT SIGN(ST_X(d.geom)) 
	INTO val_sign 
	FROM ST_DumpPoints(geom) d
	WHERE ST_X(d.geom) != 0 LIMIT 1; 
	
	SELECT ST_MakeLine
	(
		ARRAY_AGG(
			CASE 
				WHEN ST_X(d.geom) = 0 THEN ST_SetSRID(ST_MakePoint(val_sign * 180, ST_Y(d.geom)), 4326)
				ELSE d.geom
			END
			ORDER BY d.path[1]
		)
	)
	INTO fixed_line
	FROM ST_DumpPoints(geom) d;
	
	RETURN fixed_line;
END
$$;


ALTER FUNCTION public.fix_split_line(geom public.geometry) OWNER TO postgres;

--
-- Name: fk_ok(name, name[], name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name[], name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fk_ok( $1, $2, $3, $4,
        $1 || '(' || _ident_array_to_string( $2, ', ' )
        || ') should reference ' ||
        $3 || '(' || _ident_array_to_string( $4, ', ' ) || ')'
    );
$_$;


ALTER FUNCTION public.fk_ok(name, name[], name, name[]) OWNER TO postgres;

--
-- Name: fk_ok(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fk_ok( $1, ARRAY[$2], $3, ARRAY[$4] );
$_$;


ALTER FUNCTION public.fk_ok(name, name, name, name) OWNER TO postgres;

--
-- Name: fk_ok(name, name[], name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name[], name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tab  name;
    cols name[];
BEGIN
    SELECT pk_table_name, pk_columns
      FROM pg_all_foreign_keys
     WHERE fk_table_name = $1
       AND fk_columns    = $2
       AND pg_catalog.pg_table_is_visible(fk_table_oid)
      INTO tab, cols;

    RETURN is(
        -- have
        $1 || '(' || _ident_array_to_string( $2, ', ' )
        || ') REFERENCES ' || COALESCE( tab || '(' || _ident_array_to_string( cols, ', ' ) || ')', 'NOTHING'),
        -- want
        $1 || '(' || _ident_array_to_string( $2, ', ' )
        || ') REFERENCES ' ||
        $3 || '(' || _ident_array_to_string( $4, ', ' ) || ')',
        $5
    );
END;
$_$;


ALTER FUNCTION public.fk_ok(name, name[], name, name[], text) OWNER TO postgres;

--
-- Name: fk_ok(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fk_ok( $1, ARRAY[$2], $3, ARRAY[$4], $5 );
$_$;


ALTER FUNCTION public.fk_ok(name, name, name, name, text) OWNER TO postgres;

--
-- Name: fk_ok(name, name, name[], name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name, name[], name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fk_ok( $1, $2, $3, $4, $5, $6,
        quote_ident($1) || '.' || quote_ident($2) || '(' || _ident_array_to_string( $3, ', ' )
        || ') should reference ' ||
        $4 || '.' || $5 || '(' || _ident_array_to_string( $6, ', ' ) || ')'
    );
$_$;


ALTER FUNCTION public.fk_ok(name, name, name[], name, name, name[]) OWNER TO postgres;

--
-- Name: fk_ok(name, name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fk_ok( $1, $2, ARRAY[$3], $4, $5, ARRAY[$6] );
$_$;


ALTER FUNCTION public.fk_ok(name, name, name, name, name, text) OWNER TO postgres;

--
-- Name: fk_ok(name, name, name[], name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name, name[], name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    sch  name;
    tab  name;
    cols name[];
BEGIN
    SELECT pk_schema_name, pk_table_name, pk_columns
      FROM pg_all_foreign_keys
      WHERE fk_schema_name = $1
        AND fk_table_name  = $2
        AND fk_columns     = $3
      INTO sch, tab, cols;

    RETURN is(
        -- have
        quote_ident($1) || '.' || quote_ident($2) || '(' || _ident_array_to_string( $3, ', ' )
        || ') REFERENCES ' || COALESCE ( sch || '.' || tab || '(' || _ident_array_to_string( cols, ', ' ) || ')', 'NOTHING' ),
        -- want
        quote_ident($1) || '.' || quote_ident($2) || '(' || _ident_array_to_string( $3, ', ' )
        || ') REFERENCES ' ||
        $4 || '.' || $5 || '(' || _ident_array_to_string( $6, ', ' ) || ')',
        $7
    );
END;
$_$;


ALTER FUNCTION public.fk_ok(name, name, name[], name, name, name[], text) OWNER TO postgres;

--
-- Name: fk_ok(name, name, name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fk_ok(name, name, name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT fk_ok( $1, $2, ARRAY[$3], $4, $5, ARRAY[$6], $7 );
$_$;


ALTER FUNCTION public.fk_ok(name, name, name, name, name, name, text) OWNER TO postgres;

--
-- Name: foreign_table_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_table_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT foreign_table_owner_is(
        $1, $2,
        'Foreign table ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.foreign_table_owner_is(name, name) OWNER TO postgres;

--
-- Name: foreign_table_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_table_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT foreign_table_owner_is(
        $1, $2, $3,
        'Foreign table ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.foreign_table_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: foreign_table_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_table_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('f'::char, $1);
BEGIN
    -- Make sure the table exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Foreign table ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.foreign_table_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: foreign_table_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_table_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('f'::char, $1, $2);
BEGIN
    -- Make sure the table exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Foreign table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.foreign_table_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: foreign_tables_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_tables_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'foreign tables', _extras('f', $1), _missing('f', $1),
        'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct foreign tables'
    );
$_$;


ALTER FUNCTION public.foreign_tables_are(name[]) OWNER TO postgres;

--
-- Name: foreign_tables_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_tables_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'foreign tables', _extras('f', $1), _missing('f', $1), $2);
$_$;


ALTER FUNCTION public.foreign_tables_are(name[], text) OWNER TO postgres;

--
-- Name: foreign_tables_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_tables_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'foreign tables', _extras('f', $1, $2), _missing('f', $1, $2),
        'Schema ' || quote_ident($1) || ' should have the correct foreign tables'
    );
$_$;


ALTER FUNCTION public.foreign_tables_are(name, name[]) OWNER TO postgres;

--
-- Name: foreign_tables_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foreign_tables_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'foreign tables', _extras('f', $1, $2), _missing('f', $1, $2), $3);
$_$;


ALTER FUNCTION public.foreign_tables_are(name, name[], text) OWNER TO postgres;

--
-- Name: format_type_string(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.format_type_string(text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    want_type TEXT := $1;
BEGIN
    IF pg_version_num() >= 170000 THEN
        -- to_regtypemod() in 17 allows easy and corret normalization.
        RETURN format_type(to_regtype(want_type), to_regtypemod(want_type));
    END IF;

    IF want_type::regtype = 'interval'::regtype THEN
        -- We cannot normlize interval types without to_regtypemod(), So
        -- just return it as is.
        RETURN want_type;
    END IF;

    -- Use the typmodin functions to correctly normalize types.
    DECLARE
        typmodin_arg cstring[];
        typmodin_func regproc;
        typmod int;
    BEGIN
        -- Extract type modifier from type declaration and format as cstring[] literal.
        typmodin_arg := translate(substring(want_type FROM '[(][^")]+[)]'), '()', '{}');

        -- Find typmodin function for want_type.
        SELECT typmodin INTO typmodin_func
        FROM pg_catalog.pg_type
        WHERE oid = want_type::regtype;

        IF typmodin_func = 0 THEN
            -- Easy: types without typemods.
            RETURN format_type(want_type::regtype, null);
        END IF;

        -- Get typemod via type-specific typmodin function.
        EXECUTE format('SELECT %s(%L)', typmodin_func, typmodin_arg) INTO typmod;
        RETURN format_type(want_type::regtype, typmod);
    END;
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$_$;


ALTER FUNCTION public.format_type_string(text) OWNER TO postgres;

--
-- Name: function_lang_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_lang_is(
        $1, $2,
        'Function ' || quote_ident($1)
        || '() should be written in ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.function_lang_is(name, name) OWNER TO postgres;

--
-- Name: function_lang_is(name, name[], name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name[], name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_lang_is(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be written in ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.function_lang_is(name, name[], name) OWNER TO postgres;

--
-- Name: function_lang_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_lang_is(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '.' || quote_ident($2)
        || '() should be written in ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.function_lang_is(name, name, name) OWNER TO postgres;

--
-- Name: function_lang_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _lang($1), $2, $3 );
$_$;


ALTER FUNCTION public.function_lang_is(name, name, text) OWNER TO postgres;

--
-- Name: function_lang_is(name, name[], name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name[], name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _lang($1, $2), $3, $4 );
$_$;


ALTER FUNCTION public.function_lang_is(name, name[], name, text) OWNER TO postgres;

--
-- Name: function_lang_is(name, name, name[], name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name, name[], name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_lang_is(
        $1, $2, $3, $4,
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be written in ' || quote_ident($4)
    );
$_$;


ALTER FUNCTION public.function_lang_is(name, name, name[], name) OWNER TO postgres;

--
-- Name: function_lang_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _lang($1, $2), $3, $4 );
$_$;


ALTER FUNCTION public.function_lang_is(name, name, name, text) OWNER TO postgres;

--
-- Name: function_lang_is(name, name, name[], name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_lang_is(name, name, name[], name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _lang($1, $2, $3), $4, $5 );
$_$;


ALTER FUNCTION public.function_lang_is(name, name, name[], name, text) OWNER TO postgres;

--
-- Name: function_owner_is(name, name[], name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_owner_is(name, name[], name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_owner_is(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.function_owner_is(name, name[], name) OWNER TO postgres;

--
-- Name: function_owner_is(name, name[], name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_owner_is(name, name[], name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_func_owner($1, $2);
BEGIN
    -- Make sure the function exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Function ' || quote_ident($1) || '(' ||
                    array_to_string($2, ', ') || ') does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.function_owner_is(name, name[], name, text) OWNER TO postgres;

--
-- Name: function_owner_is(name, name, name[], name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_owner_is(name, name, name[], name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_owner_is(
        $1, $2, $3, $4,
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be owned by ' || quote_ident($4)
    );
$_$;


ALTER FUNCTION public.function_owner_is(name, name, name[], name) OWNER TO postgres;

--
-- Name: function_owner_is(name, name, name[], name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_owner_is(name, name, name[], name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_func_owner($1, $2, $3);
BEGIN
    -- Make sure the function exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            E'    Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
                    array_to_string($3, ', ') || ') does not exist'
        );
    END IF;

    RETURN is(owner, $4, $5);
END;
$_$;


ALTER FUNCTION public.function_owner_is(name, name, name[], name, text) OWNER TO postgres;

--
-- Name: function_privs_are(name, name[], name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_privs_are(name, name[], name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_privs_are(
        $1, $2, $3, $4,
        'Role ' || quote_ident($3) || ' should be granted '
            || CASE WHEN $4[1] IS NULL THEN 'no privileges' ELSE array_to_string($4, ', ') END
            || ' on function ' || quote_ident($1) || '(' || array_to_string($2, ', ') || ')'
    );
$_$;


ALTER FUNCTION public.function_privs_are(name, name[], name, name[]) OWNER TO postgres;

--
-- Name: function_privs_are(name, name[], name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_privs_are(name, name[], name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _fprivs_are(
        quote_ident($1) || '(' || array_to_string($2, ', ') || ')',
        $3, $4, $5
    );
$_$;


ALTER FUNCTION public.function_privs_are(name, name[], name, name[], text) OWNER TO postgres;

--
-- Name: function_privs_are(name, name, name[], name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_privs_are(name, name, name[], name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_privs_are(
        $1, $2, $3, $4, $5,
        'Role ' || quote_ident($4) || ' should be granted '
            || CASE WHEN $5[1] IS NULL THEN 'no privileges' ELSE array_to_string($5, ', ') END
            || ' on function ' || quote_ident($1) || '.' || quote_ident($2)
            || '(' || array_to_string($3, ', ') || ')'
    );
$_$;


ALTER FUNCTION public.function_privs_are(name, name, name[], name, name[]) OWNER TO postgres;

--
-- Name: function_privs_are(name, name, name[], name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_privs_are(name, name, name[], name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _fprivs_are(
        quote_ident($1) || '.' || quote_ident($2) || '(' || array_to_string($3, ', ') || ')',
        $4, $5, $6
    );
$_$;


ALTER FUNCTION public.function_privs_are(name, name, name[], name, name[], text) OWNER TO postgres;

--
-- Name: function_returns(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_returns(
        $1, $2,
        'Function ' || quote_ident($1) || '() should return ' || $2
    );
$_$;


ALTER FUNCTION public.function_returns(name, text) OWNER TO postgres;

--
-- Name: function_returns(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_returns(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should return ' || $3
    );
$_$;


ALTER FUNCTION public.function_returns(name, name[], text) OWNER TO postgres;

--
-- Name: function_returns(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_returns(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '.' || quote_ident($2)
        || '() should return ' || $3
    );
$_$;


ALTER FUNCTION public.function_returns(name, name, text) OWNER TO postgres;

--
-- Name: function_returns(name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _returns($1), _retval($2), $3 );
$_$;


ALTER FUNCTION public.function_returns(name, text, text) OWNER TO postgres;

--
-- Name: function_returns(name, name[], text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, name[], text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _returns($1, $2), _retval($3), $4 );
$_$;


ALTER FUNCTION public.function_returns(name, name[], text, text) OWNER TO postgres;

--
-- Name: function_returns(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT function_returns(
        $1, $2, $3, $4,
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should return ' || $4
    );
$_$;


ALTER FUNCTION public.function_returns(name, name, name[], text) OWNER TO postgres;

--
-- Name: function_returns(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _returns($1, $2), _retval($3), $4 );
$_$;


ALTER FUNCTION public.function_returns(name, name, text, text) OWNER TO postgres;

--
-- Name: function_returns(name, name, name[], text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_returns(name, name, name[], text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _returns($1, $2, $3), _retval($4), $5 );
$_$;


ALTER FUNCTION public.function_returns(name, name, name[], text, text) OWNER TO postgres;

--
-- Name: functions_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.functions_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT functions_are( $1, 'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct functions' );
$_$;


ALTER FUNCTION public.functions_are(name[]) OWNER TO postgres;

--
-- Name: functions_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.functions_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'functions',
        ARRAY(
            SELECT name FROM tap_funky WHERE is_visible
            AND schema NOT IN ('pg_catalog', 'information_schema')
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
               FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT name FROM tap_funky WHERE is_visible
            AND schema NOT IN ('pg_catalog', 'information_schema')
        ),
        $2
    );
$_$;


ALTER FUNCTION public.functions_are(name[], text) OWNER TO postgres;

--
-- Name: functions_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.functions_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT functions_are( $1, $2, 'Schema ' || quote_ident($1) || ' should have the correct functions' );
$_$;


ALTER FUNCTION public.functions_are(name, name[]) OWNER TO postgres;

--
-- Name: functions_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.functions_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'functions',
        ARRAY(
            SELECT name FROM tap_funky WHERE schema = $1
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
               FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT name FROM tap_funky WHERE schema = $1
        ),
        $3
    );
$_$;


ALTER FUNCTION public.functions_are(name, name[], text) OWNER TO postgres;

--
-- Name: get_line_split(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_line_split(geom public.geometry) RETURNS public.geometry[]
    LANGUAGE plpgsql
    AS $$
DECLARE 
	results geometry[];
BEGIN
	SELECT
		CASE 
			WHEN abs(ST_X(ST_StartPoint(geom)) - ST_X(ST_EndPoint(geom)))>180 
				THEN 
					(SELECT
						ARRAY_AGG(fix_split_line(simple_wrap(split_geom.geom, 0, 180)))
						FROM 							
							(SELECT d.geom 
							FROM 
								ST_Dump(
									ST_Split(
										simple_wrap(geom, 0, 180), 
										ST_SetSRID(St_MakeLine(ST_MakePoint(0, 90), ST_MakePoint(0, -90)), 4326)
									)
								) d
							) split_geom 
						)
			WHEN abs(ST_X(ST_StartPoint(geom)) - ST_X(ST_EndPoint(geom)))<=180 
				THEN ARRAY[geom]
		END
		
	INTO results;
	RETURN results;
END;
$$;


ALTER FUNCTION public.get_line_split(geom public.geometry) OWNER TO postgres;

--
-- Name: get_nearest_nodes_line(uuid, uuid, integer, public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_nearest_nodes_line(node_node_id uuid, node_way_id uuid, node_sequence_id integer, node_geometry public.geometry DEFAULT NULL::public.geometry) RETURNS public.geometry[]
    LANGUAGE plpgsql
    AS $$
DECLARE 
	nodes geometry[];
	line_geom geometry;
BEGIN

	SELECT ARRAY_REMOVE(ARRAY_AGG(n.geom), NULL) 
	INTO nodes 
	FROM Nodes n 
	WHERE id = ANY(get_neighbouring_points(node_sequence_id, node_way_id, node_node_id));

	IF (nodes IS NULL OR array_length(nodes, 1) IS NULL) AND node_geometry IS NULL THEN
		RETURN NULL;
	ELSIF node_geometry IS NOT NULL THEN
		IF array_length(nodes, 1) >= 2 THEN
		
			nodes := ARRAY_REMOVE(nodes[1:1] || node_geometry || nodes[2:array_length(nodes, 1)], NULL);
		ELSIF array_length(nodes, 1) = 1 THEN

			nodes := ARRAY_REMOVE(nodes || node_geometry, NULL);
		ELSE
			nodes := ARRAY[node_geometry];
		END IF;
	END IF;

	IF array_length(nodes, 1) < 2 THEN
		RETURN NULL;
	END IF;

	line_geom := ST_SetSRID(ST_MakeLine(nodes), 4326);

	RETURN public.get_way_split(line_geom);
END;
$$;


ALTER FUNCTION public.get_nearest_nodes_line(node_node_id uuid, node_way_id uuid, node_sequence_id integer, node_geometry public.geometry) OWNER TO postgres;

--
-- Name: get_neighbouring_points(integer, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_neighbouring_points(sequence_id integer, way_id uuid) RETURNS uuid[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	geom1 GEOMETRY;
	geom2 GEOMETRY;
BEGIN
		SELECT n.id INTO geom1 FROM WaysNodes wn JOIN Nodes n ON n.id = wn.node_id WHERE wn.way_id = NEW.way_id AND wn.sequence_id <= NEW.sequence_id AND wn.node_id != NEW.node_id ORDER BY wn.sequence_id DESC LIMIT 1;
		SELECT n.id INTO geom2 FROM WaysNodes wn JOIN Nodes n ON n.id = wn.node_id WHERE wn.way_id = NEW.way_id AND wn.sequence_id >= NEW.sequence_id AND wn.node_id != NEW.node_id ORDER BY wn.sequence_id ASC LIMIT 1;
	RETURN ARRAY_REMOVE(ARRAY[geom1, geom2], NULL);
END;
$$;


ALTER FUNCTION public.get_neighbouring_points(sequence_id integer, way_id uuid) OWNER TO postgres;

--
-- Name: get_neighbouring_points(integer, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_neighbouring_points(node_sequence_id integer, node_way_id uuid, node_node_id uuid) RETURNS uuid[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	geom1 UUID;
	geom2 UUID;
BEGIN
		SELECT n.id INTO geom1 FROM WaysNodes wn JOIN Nodes n ON n.id = wn.node_id WHERE wn.way_id = Node_way_id AND wn.sequence_id <= Node_sequence_id AND wn.node_id != Node_node_id ORDER BY wn.sequence_id DESC LIMIT 1;
		SELECT n.id INTO geom2 FROM WaysNodes wn JOIN Nodes n ON n.id = wn.node_id WHERE wn.way_id = Node_way_id AND wn.sequence_id >= Node_sequence_id AND wn.node_id != Node_node_id ORDER BY wn.sequence_id ASC LIMIT 1;
	RETURN ARRAY_REMOVE(ARRAY[geom1, geom2], NULL);
END;
$$;


ALTER FUNCTION public.get_neighbouring_points(node_sequence_id integer, node_way_id uuid, node_node_id uuid) OWNER TO postgres;

--
-- Name: get_tile_bbox(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tile_bbox(tile_id bigint) RETURNS public.box2d
    LANGUAGE plpgsql
    AS $$
DECLARE
	zoom_level INT;
	x_id BIGINT;
	y_id BIGINT;
	mask BIGINT := x'5555555555555555'::BIGINT;
	x_size DOUBLE PRECISION;
	y_size DOUBLE PRECISION;
BEGIN
	zoom_level := get_zoom_level(tile_id);

	x_id := (tile_id & (mask >> (64-(zoom_level * 2))));--get even bits
	x_id := (x_id | (x_id >> 1))  & x'3333333333333333'::BIGINT;
    x_id := (x_id | (x_id >> 2))  & x'0F0F0F0F0F0F0F0F'::BIGINT;
    x_id := (x_id | (x_id >> 4))  & x'00FF00FF00FF00FF'::BIGINT;
    x_id := (x_id | (x_id >> 8))  & x'0000FFFF0000FFFF'::BIGINT;
    x_id := (x_id | (x_id >> 16)) & x'00000000FFFFFFFF'::BIGINT;
	
	y_id := ((tile_id>>1) & (mask >> (64-(zoom_level * 2))));--get odd bits
	y_id := (y_id | (y_id >> 1))  & x'3333333333333333'::BIGINT;
    y_id := (y_id | (y_id >> 2))  & x'0F0F0F0F0F0F0F0F'::BIGINT;
    y_id := (y_id | (y_id >> 4))  & x'00FF00FF00FF00FF'::BIGINT;
    y_id := (y_id | (y_id >> 8))  & x'0000FFFF0000FFFF'::BIGINT;
    y_id:= 	(y_id | (y_id >> 16)) & x'00000000FFFFFFFF'::BIGINT;
	
	x_size := 360/POWER(2.0, zoom_level);
	y_size := 180/POWER(2.0, zoom_level);

	RETURN (SELECT ST_MakeEnvelope(x_size*x_id - 180.0, y_size*y_id -90.0, x_size*(x_id+1) - 180.0,  y_size*(y_id+1) -90.0, 4326)::box2d);
END;
$$;


ALTER FUNCTION public.get_tile_bbox(tile_id bigint) OWNER TO postgres;

--
-- Name: get_tiles_for_bbox(integer, public.box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tiles_for_bbox(zoom_level integer, bbox public.box2d) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	min_lng DOUBLE PRECISION := ST_XMin(bbox);
    max_lng DOUBLE PRECISION := ST_XMax(bbox);
    min_lat DOUBLE PRECISION := ST_YMin(bbox);
    max_lat DOUBLE PRECISION := ST_YMax(bbox);

	tile_width DOUBLE PRECISION 	:= 	360.0 / (POWER(2.0, zoom_level));
    tile_height DOUBLE PRECISION 	:= 180.0 / (POWER(2.0, zoom_level));
	box_width DOUBLE PRECISION  	:=	max_lng - min_lng;
	box_height DOUBLE PRECISION  	:=	max_lat - min_lat;

	step_x DOUBLE PRECISION := LEAST(360/(POWER(2.0, zoom_level)), box_width);
	step_y DOUBLE PRECISION := LEAST(180/(POWER(2.0, zoom_level)), box_height);
	steps_x INT := CASE WHEN step_x = 0 THEN 2 ELSE GREATEST(2, CEIL(box_width / step_x)::INT) END;
    steps_y INT := CASE WHEN step_y = 0 THEN 2 ELSE GREATEST(2, CEIL(box_height / step_y)::INT) END;
	
	results BIGINT[];
BEGIN

	SELECT ARRAY_AGG(
		DISTINCT pos_to_tile_id(
			zoom_level, 
			min_lat + (y * step_y),
			min_lng + (x * step_x)
		)
	)
	INTO results
	FROM generate_series(0, steps_x) AS x,
         generate_series(0, steps_y) AS y;
	return results;
END;
$$;


ALTER FUNCTION public.get_tiles_for_bbox(zoom_level integer, bbox public.box2d) OWNER TO postgres;

--
-- Name: get_tiles_intersecting_line(public.geometry[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tiles_intersecting_line(input_geom public.geometry[], zoom_level integer) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_tiles BIGINT[];
	splited_geom geometry[];
BEGIN

	SELECT ARRAY_AGG(DISTINCT unnested_tile_id) INTO new_tiles
	FROM 
		UNNEST (input_geom) AS geom_element,
		LATERAL UNNEST(get_tiles_for_bbox(zoom_level, ST_Envelope(geom_element))) AS unnested_tile_id;

	SELECT ARRAY(
		SELECT DISTINCT UNNEST(select_tiles_intersecting_geom(new_tiles, g.geom))
		FROM UNNEST(input_geom) AS g(geom)
	)INTO new_tiles;

	RETURN new_tiles;
END;
$$;


ALTER FUNCTION public.get_tiles_intersecting_line(input_geom public.geometry[], zoom_level integer) OWNER TO postgres;

--
-- Name: get_tiles_intersecting_line(public.geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tiles_intersecting_line(input_geom public.geometry, zoom_level integer) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_tiles BIGINT[];
	splited_geom geometry[];
BEGIN
	splited_geom := get_way_split(input_geom);

	SELECT ARRAY_AGG(DISTINCT unnested_tile_id) INTO new_tiles
	FROM 
		UNNEST (splited_geom) AS geom_element,
		LATERAL UNNEST(get_tiles_for_bbox(zoom_level, ST_Envelope(geom_element))) AS unnested_tile_id;

	SELECT ARRAY(
		SELECT DISTINCT UNNEST(select_tiles_intersecting_geom(new_tiles, g.geom))
		FROM UNNEST(splited_geom) AS g(geom)
	)INTO new_tiles;

	RETURN new_tiles;
END;
$$;


ALTER FUNCTION public.get_tiles_intersecting_line(input_geom public.geometry, zoom_level integer) OWNER TO postgres;

--
-- Name: get_tiles_of_neighbour_line(uuid, uuid, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tiles_of_neighbour_line(node_node_id uuid, node_way_id uuid, node_sequence_id integer, zoom_level integer, self_include boolean) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
DECLARE 
	lines geometry[];
	intersecting_tiles BIGINT[];
	test BOX2D[];
BEGIN
	IF self_include THEN
		lines := get_nearest_nodes_line(Node_node_id, Node_way_id, Node_sequence_id, (SELECT n.geom::geometry FROM Nodes n WHERE n.id = Node_node_id LIMIT 1));
	ELSE
		lines := get_nearest_nodes_line(Node_node_id, Node_way_id, Node_sequence_id);
	END IF;
	SELECT ARRAY_AGG(Box2D(ways)) FROM INTO test UNNEST (lines) AS ways;
	--return lines;
	SELECT ARRAY(
	    SELECT DISTINCT UNNEST(get_tiles_for_bbox(zoom_level, Box2D(way)))
	    FROM UNNEST(lines) AS way
	) INTO intersecting_tiles;
	SELECT ARRAY(
		SELECT DISTINCT UNNEST(select_tiles_intersecting_geom(intersecting_tiles, ways))
		FROM UNNEST(lines) AS ways 
	) INTO intersecting_tiles;
	RETURN intersecting_tiles;
END;
$$;


ALTER FUNCTION public.get_tiles_of_neighbour_line(node_node_id uuid, node_way_id uuid, node_sequence_id integer, zoom_level integer, self_include boolean) OWNER TO postgres;

--
-- Name: get_way_in_bbox(integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_way_in_bbox(minlat integer, minlng integer, maxlat integer, maxlng integer, zoom_level integer) RETURNS uuid[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	whole_way_ids uuid[];
	tile_ids BIGINT[] := get_tiles_for_bbox(zoom_level, ST_MakeEnvelope(minLat, minLng, maxLat, maxLng, 4326));
	way_ids uuid[];
	whole_match BIGINT[];
	new_whole_match BIGINT[];
	significant_bit INT := zoom_level*2 + 1;
BEGIN
	--making whole_match
	SELECT ARRAY_AGG(DISTINCT((base_mask>>2)::BIGINT)) 
	INTO new_whole_match 
	FROM UNNEST(tile_ids) base_mask
	WHERE (base_mask>>2) > 1;

	whole_match := whole_match || new_whole_match;

	WHILE array_length(new_whole_match, 1)>0 LOOP
		SELECT ARRAY_AGG(DISTINCT((base_mask>>2)::BIGINT)) 
		INTO new_whole_match 
		FROM UNNEST(new_whole_match) base_mask
		WHERE (base_mask>>2) > 1;
		whole_match := whole_match || new_whole_match;
	END LOOP;

	--select for whole match
	SELECT ARRAY_AGG(DISTINCT way_id) 
	INTO whole_way_ids
	FROM Traversal 
	WHERE tile_id = ANY(whole_match);

	--making ranges
	WITH ranges(from_id, to_id) AS 
	(
		SELECT tile_id<<shifts.val as from_id, ~((~tile_id)<<shifts.val) as to_id
		FROM (SELECT generate_series(2, (18-zoom_level)*2, 2) as val) shifts
		CROSS JOIN UNNEST(tile_ids) AS t(tile_id)
	)
	SELECT ARRAY_AGG(DISTINCT t.way_id)
	INTO way_ids
	FROM Traversal t
	JOIN ranges r ON t.tile_id>=r.from_id AND t.tile_id<=r.to_id;

	way_ids:=way_ids||whole_way_ids;

	RETURN way_ids;
END;
$$;


ALTER FUNCTION public.get_way_in_bbox(minlat integer, minlng integer, maxlat integer, maxlng integer, zoom_level integer) OWNER TO postgres;

--
-- Name: get_way_split(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_way_split(input_geom public.geometry) RETURNS public.geometry[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    separated_lines geometry[];
BEGIN
    WITH dumped_segments AS (
        SELECT 
            path[1]::float AS line_order,
            geom AS segment_geom
        FROM ST_DumpSegments(input_geom)
    ),
    split_segments AS (
        SELECT 
            s.line_order,
            sub.sub_idx,
            sub.split_geom,
            sub.is_split
        FROM dumped_segments s
        CROSS JOIN LATERAL (
            SELECT 
                elem AS split_geom,
                idx AS sub_idx,
                CASE WHEN ARRAY_LENGTH(get_line_split(s.segment_geom), 1) > 1 AND idx = 2 THEN 1 ELSE 0 END AS is_split
            FROM UNNEST(get_line_split(s.segment_geom)) WITH ORDINALITY AS u(elem, idx)
        ) sub
    ),
    boundary_detection AS (
        SELECT 
            (line_order + (sub_idx - 1) * 0.5) AS effective_order,
            split_geom,
            is_split
        FROM split_segments
    ),
    group_assignment AS (
        SELECT 
            effective_order,
            split_geom,
            SUM(is_split) OVER (ORDER BY effective_order) AS group_id
        FROM boundary_detection
    ),
    reconstructed_lines AS (
        SELECT 
            group_id,
            ST_MakeLine(ARRAY_AGG(split_geom ORDER BY effective_order)) AS line_geom
        FROM group_assignment
        GROUP BY group_id
    )
	SELECT 
	    CASE 
	        WHEN ST_Equals(ST_StartPoint(input_geom), ST_EndPoint(input_geom)) AND (SELECT MAX(group_id) FROM reconstructed_lines) > 0 THEN
            (
                SELECT ARRAY_AGG(
				    CASE 
				        WHEN a.group_id = b.group_id THEN
				            combine_lines_into_polygon(ARRAY[a.line_geom])
				        ELSE
				            combine_lines_into_polygon(ARRAY[a.line_geom, b.line_geom])
				    END
				    ORDER BY a.group_id
				)
				FROM reconstructed_lines a
				JOIN reconstructed_lines b 
				  ON b.group_id = (SELECT MAX(group_id) FROM reconstructed_lines) - (a.group_id)
				WHERE a.group_id <= b.group_id
            )
	        ELSE
	            (
	                SELECT ARRAY_AGG(line_geom ORDER BY group_id)
	                FROM reconstructed_lines
	            )
	    END
	INTO separated_lines;

    RETURN separated_lines;
END;
$$;


ALTER FUNCTION public.get_way_split(input_geom public.geometry) OWNER TO postgres;

--
-- Name: get_way_splitted(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_way_splitted(node_way_id uuid) RETURNS public.geometry[]
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN (SELECT ARRAY_AGG((dumped).geom) 
	FROM (
		SELECT ST_Dump(
		    ST_Split(
		       	ST_ShiftLongitude((SELECT ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id) FROM WaysNodes wn JOIN Nodes n ON n.id = wn.node_id WHERE wn.way_id = Node_way_id)), 
		        ST_SetSRID(ST_MakeLine(ST_MakePoint(180, -90), ST_MakePoint(180, 90)), 4326)
		   	)
		) AS dumped
	));
END;
$$;


ALTER FUNCTION public.get_way_splitted(node_way_id uuid) OWNER TO postgres;

--
-- Name: get_way_zoom_level(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_way_zoom_level(way_id_input uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	zoom_level int := -1;
BEGIN
	SELECT get_zoom_level(t.tile_id)--what if there is nothing returned?
	INTO zoom_level
	FROM Traversal t WHERE t.way_id = way_id_input LIMIT 1;

	IF zoom_level IS NULL THEN
		zoom_level := get_zoom_level_for_geom(get_way_split((SELECT ST_MakeLine(n.geom::geometry) FROM WaysNodes wn JOIN Nodes n ON n.id = wn.node_id WHERE wn.way_id = way_id_input)));
	END IF;

	RETURN zoom_level;
END;
$$;


ALTER FUNCTION public.get_way_zoom_level(way_id_input uuid) OWNER TO postgres;

--
-- Name: get_zoom_level(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_zoom_level(tile_id bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN FLOOR(LOG(2, tile_id))/2::INT;
END;
$$;


ALTER FUNCTION public.get_zoom_level(tile_id bigint) OWNER TO postgres;

--
-- Name: get_zoom_level_for_geom(public.geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_zoom_level_for_geom(geoms public.geometry[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	zoom_level int;
	new_bbox box2D[];
BEGIN
	SELECT ARRAY_AGG(ST_Envelope(geom)) 
	INTO new_bbox
	FROM UNNEST(geoms) AS geom;
	
	SELECT 
	FLOOR(
		LOG(
			2.0,
			LEAST(
				360/NULLIF(ST_XMax(t.bbox) - ST_XMin(t.bbox), 0), 
				180/NULLIF(ST_YMax(t.bbox) - ST_YMin(t.bbox), 0)
			)::NUMERIC
		)
	) AS desired_zoom 
	INTO zoom_level
	FROM UNNEST(new_bbox) as t(bbox)
	ORDER BY desired_zoom LIMIT 1; 

	RETURN zoom_level;
END;
$$;


ALTER FUNCTION public.get_zoom_level_for_geom(geoms public.geometry[]) OWNER TO postgres;

--
-- Name: groups_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.groups_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT groups_are( $1, 'There should be the correct groups' );
$_$;


ALTER FUNCTION public.groups_are(name[]) OWNER TO postgres;

--
-- Name: groups_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.groups_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'groups',
        ARRAY(
            SELECT groname
              FROM pg_catalog.pg_group
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT groname
              FROM pg_catalog.pg_group
        ),
        $2
    );
$_$;


ALTER FUNCTION public.groups_are(name[], text) OWNER TO postgres;

--
-- Name: has_cast(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_cast(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _cast_exists( $1, $2 ),
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') should exist'
    );
$_$;


ALTER FUNCTION public.has_cast(name, name) OWNER TO postgres;

--
-- Name: has_cast(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_cast(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok(
        _cast_exists( $1, $2, $3 ),
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') WITH FUNCTION ' || quote_ident($3) || '() should exist'
    );
$_$;


ALTER FUNCTION public.has_cast(name, name, name) OWNER TO postgres;

--
-- Name: has_cast(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_cast(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _cast_exists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_cast(name, name, text) OWNER TO postgres;

--
-- Name: has_cast(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_cast(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok(
       _cast_exists( $1, $2, $3, $4 ),
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') WITH FUNCTION ' || quote_ident($3)
        || '.' || quote_ident($4) || '() should exist'
    );
$_$;


ALTER FUNCTION public.has_cast(name, name, name, name) OWNER TO postgres;

--
-- Name: has_cast(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_cast(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok( _cast_exists( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.has_cast(name, name, name, text) OWNER TO postgres;

--
-- Name: has_cast(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_cast(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok( _cast_exists( $1, $2, $3, $4 ), $5 );
$_$;


ALTER FUNCTION public.has_cast(name, name, name, name, text) OWNER TO postgres;

--
-- Name: has_check(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_check(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_check( $1, 'Table ' || quote_ident($1) || ' should have a check constraint' );
$_$;


ALTER FUNCTION public.has_check(name) OWNER TO postgres;

--
-- Name: has_check(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_check(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, 'c' ), $2 );
$_$;


ALTER FUNCTION public.has_check(name, text) OWNER TO postgres;

--
-- Name: has_check(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_check(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, $2, 'c' ), $3 );
$_$;


ALTER FUNCTION public.has_check(name, name, text) OWNER TO postgres;

--
-- Name: has_column(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_column(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_column( $1, $2, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_column(name, name) OWNER TO postgres;

--
-- Name: has_column(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_column(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _cexists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_column(name, name, text) OWNER TO postgres;

--
-- Name: has_column(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_column(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _cexists( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.has_column(name, name, name, text) OWNER TO postgres;

--
-- Name: has_composite(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_composite(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_composite( $1, 'Composite type ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_composite(name) OWNER TO postgres;

--
-- Name: has_composite(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_composite(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_composite($1, $2,
        'Composite type ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_composite(name, name) OWNER TO postgres;

--
-- Name: has_composite(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_composite(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'c', $1 ), $2 );
$_$;


ALTER FUNCTION public.has_composite(name, text) OWNER TO postgres;

--
-- Name: has_composite(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_composite(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'c', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_composite(name, name, text) OWNER TO postgres;

--
-- Name: has_domain(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_domain(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, ARRAY['d'] ), ('Domain ' || quote_ident($1) || ' should exist')::text );
$_$;


ALTER FUNCTION public.has_domain(name) OWNER TO postgres;

--
-- Name: has_domain(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_domain(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_domain( $1, $2, 'Domain ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_domain(name, name) OWNER TO postgres;

--
-- Name: has_domain(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_domain(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, ARRAY['d'] ), $2 );
$_$;


ALTER FUNCTION public.has_domain(name, text) OWNER TO postgres;

--
-- Name: has_domain(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_domain(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, $2, ARRAY['d'] ), $3 );
$_$;


ALTER FUNCTION public.has_domain(name, name, text) OWNER TO postgres;

--
-- Name: has_enum(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_enum(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, ARRAY['e'] ), ('Enum ' || quote_ident($1) || ' should exist')::text );
$_$;


ALTER FUNCTION public.has_enum(name) OWNER TO postgres;

--
-- Name: has_enum(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_enum(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_enum( $1, $2, 'Enum ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_enum(name, name) OWNER TO postgres;

--
-- Name: has_enum(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_enum(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, ARRAY['e'] ), $2 );
$_$;


ALTER FUNCTION public.has_enum(name, text) OWNER TO postgres;

--
-- Name: has_enum(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_enum(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, $2, ARRAY['e'] ), $3 );
$_$;


ALTER FUNCTION public.has_enum(name, name, text) OWNER TO postgres;

--
-- Name: has_extension(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_extension(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ext_exists( $1 ),
        'Extension ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_extension(name) OWNER TO postgres;

--
-- Name: has_extension(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_extension(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ext_exists( $1, $2 ),
        'Extension ' || quote_ident($2)
        || ' should exist in schema ' || quote_ident($1) );
$_$;


ALTER FUNCTION public.has_extension(name, name) OWNER TO postgres;

--
-- Name: has_extension(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_extension(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ext_exists( $1 ), $2)
$_$;


ALTER FUNCTION public.has_extension(name, text) OWNER TO postgres;

--
-- Name: has_extension(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_extension(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ext_exists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_extension(name, name, text) OWNER TO postgres;

--
-- Name: has_fk(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_fk(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_fk( $1, 'Table ' || quote_ident($1) || ' should have a foreign key constraint' );
$_$;


ALTER FUNCTION public.has_fk(name) OWNER TO postgres;

--
-- Name: has_fk(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_fk(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, 'f' ), $2 );
$_$;


ALTER FUNCTION public.has_fk(name, text) OWNER TO postgres;

--
-- Name: has_fk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_fk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, $2, 'f' ), $3 );
$_$;


ALTER FUNCTION public.has_fk(name, name, text) OWNER TO postgres;

--
-- Name: has_foreign_table(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_foreign_table(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_foreign_table( $1, 'Foreign table ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_foreign_table(name) OWNER TO postgres;

--
-- Name: has_foreign_table(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_foreign_table(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _rexists( 'f', $1, $2 ),
        'Foreign table ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_foreign_table(name, name) OWNER TO postgres;

--
-- Name: has_foreign_table(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_foreign_table(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'f', $1 ), $2 );
$_$;


ALTER FUNCTION public.has_foreign_table(name, text) OWNER TO postgres;

--
-- Name: has_foreign_table(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_foreign_table(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'f', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_foreign_table(name, name, text) OWNER TO postgres;

--
-- Name: has_function(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _got_func($1), 'Function ' || quote_ident($1) || '() should exist' );
$_$;


ALTER FUNCTION public.has_function(name) OWNER TO postgres;

--
-- Name: has_function(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _got_func($1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should exist'
    );
$_$;


ALTER FUNCTION public.has_function(name, name[]) OWNER TO postgres;

--
-- Name: has_function(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _got_func($1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should exist'
    );
$_$;


ALTER FUNCTION public.has_function(name, name) OWNER TO postgres;

--
-- Name: has_function(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _got_func($1), $2 );
$_$;


ALTER FUNCTION public.has_function(name, text) OWNER TO postgres;

--
-- Name: has_function(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _got_func($1, $2), $3 );
$_$;


ALTER FUNCTION public.has_function(name, name[], text) OWNER TO postgres;

--
-- Name: has_function(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _got_func($1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should exist'
    );
$_$;


ALTER FUNCTION public.has_function(name, name, name[]) OWNER TO postgres;

--
-- Name: has_function(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _got_func($1, $2), $3 );
$_$;


ALTER FUNCTION public.has_function(name, name, text) OWNER TO postgres;

--
-- Name: has_function(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_function(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _got_func($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.has_function(name, name, name[], text) OWNER TO postgres;

--
-- Name: has_group(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_group(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_group($1), 'Group ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_group(name) OWNER TO postgres;

--
-- Name: has_group(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_group(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_group($1), $2 );
$_$;


ALTER FUNCTION public.has_group(name, text) OWNER TO postgres;

--
-- Name: has_index(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _have_index( $1, $2 ), 'Index ' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_index(name, name) OWNER TO postgres;

--
-- Name: has_index(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT has_index( $1, $2, $3, 'Index ' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_index(name, name, name[]) OWNER TO postgres;

--
-- Name: has_index(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
   IF _is_schema($1) THEN
       -- ( schema, table, index )
       RETURN ok( _have_index( $1, $2, $3 ), 'Index ' || quote_ident($3) || ' should exist' );
   ELSE
       -- ( table, index, column/expression )
       RETURN has_index( $1, $2, $3, 'Index ' || quote_ident($2) || ' should exist' );
   END IF;
END;
$_$;


ALTER FUNCTION public.has_index(name, name, name) OWNER TO postgres;

--
-- Name: has_index(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN $3 LIKE '%(%'
           THEN has_index( $1, $2, $3::name )
           ELSE ok( _have_index( $1, $2 ), $3 )
           END;
$_$;


ALTER FUNCTION public.has_index(name, name, text) OWNER TO postgres;

--
-- Name: has_index(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
     index_cols name[];
BEGIN
    index_cols := _ikeys($1, $2 );

    IF index_cols IS NULL OR index_cols = '{}'::name[] THEN
        RETURN ok( false, $4 ) || E'\n'
            || diag( 'Index ' || quote_ident($2) || ' ON ' || quote_ident($1) || ' not found');
    END IF;

    RETURN is(
        quote_ident($2) || ' ON ' || quote_ident($1) || '(' || array_to_string( index_cols, ', ' ) || ')',
        quote_ident($2) || ' ON ' || quote_ident($1) || '(' || array_to_string( $3, ', ' ) || ')',
        $4
    );
END;
$_$;


ALTER FUNCTION public.has_index(name, name, name[], text) OWNER TO postgres;

--
-- Name: has_index(name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT has_index( $1, $2, $3, $4, 'Index ' || quote_ident($3) || ' should exist' );
$_$;


ALTER FUNCTION public.has_index(name, name, name, name[]) OWNER TO postgres;

--
-- Name: has_index(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT has_index( $1, $2, $3, $4, 'Index ' || quote_ident($3) || ' should exist' );
$_$;


ALTER FUNCTION public.has_index(name, name, name, name) OWNER TO postgres;

--
-- Name: has_index(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN _is_schema( $1 ) THEN
        -- Looking for schema.table index.
            ok ( _have_index( $1, $2, $3 ), $4)
        ELSE
        -- Looking for particular columns.
            has_index( $1, $2, ARRAY[$3], $4 )
      END;
$_$;


ALTER FUNCTION public.has_index(name, name, name, text) OWNER TO postgres;

--
-- Name: has_index(name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
     index_cols name[];
BEGIN
    index_cols := _ikeys($1, $2, $3 );

    IF index_cols IS NULL OR index_cols = '{}'::name[] THEN
        RETURN ok( false, $5 ) || E'\n'
            || diag( 'Index ' || quote_ident($3) || ' ON ' || quote_ident($1) || '.' || quote_ident($2) || ' not found');
    END IF;

    RETURN is(
        quote_ident($3) || ' ON ' || quote_ident($1) || '.' || quote_ident($2) || '(' || array_to_string( index_cols, ', ' ) || ')',
        quote_ident($3) || ' ON ' || quote_ident($1) || '.' || quote_ident($2) || '(' || array_to_string( $4, ', ' ) || ')',
        $5
    );
END;
$_$;


ALTER FUNCTION public.has_index(name, name, name, name[], text) OWNER TO postgres;

--
-- Name: has_index(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_index(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_index( $1, $2, $3, ARRAY[$4], $5 );
$_$;


ALTER FUNCTION public.has_index(name, name, name, name, text) OWNER TO postgres;

--
-- Name: has_inherited_tables(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_inherited_tables(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _inherited( $1 ),
        'Table ' || quote_ident( $1 ) || ' should have descendents'
    );
$_$;


ALTER FUNCTION public.has_inherited_tables(name) OWNER TO postgres;

--
-- Name: has_inherited_tables(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_inherited_tables(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _inherited( $1, $2 ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 ) || ' should have descendents'
    );
$_$;


ALTER FUNCTION public.has_inherited_tables(name, name) OWNER TO postgres;

--
-- Name: has_inherited_tables(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_inherited_tables(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _inherited( $1 ), $2 );
$_$;


ALTER FUNCTION public.has_inherited_tables(name, text) OWNER TO postgres;

--
-- Name: has_inherited_tables(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_inherited_tables(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _inherited( $1, $2 ), $3);
$_$;


ALTER FUNCTION public.has_inherited_tables(name, name, text) OWNER TO postgres;

--
-- Name: has_language(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_language(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_trusted($1) IS NOT NULL, 'Procedural language ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_language(name) OWNER TO postgres;

--
-- Name: has_language(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_language(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_trusted($1) IS NOT NULL, $2 );
$_$;


ALTER FUNCTION public.has_language(name, text) OWNER TO postgres;

--
-- Name: has_leftop(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_leftop(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists(NULL, $1, $2 ),
        'Left operator ' || $1 || '(NONE,' || $2 || ') should exist'
    );
$_$;


ALTER FUNCTION public.has_leftop(name, name) OWNER TO postgres;

--
-- Name: has_leftop(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_leftop(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists(NULL, $1, $2, $3 ),
        'Left operator ' || $1 || '(NONE,' || $2 || ') RETURNS ' || $3 || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_leftop(name, name, name) OWNER TO postgres;

--
-- Name: has_leftop(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_leftop(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists(NULL, $1, $2), $3 );
$_$;


ALTER FUNCTION public.has_leftop(name, name, text) OWNER TO postgres;

--
-- Name: has_leftop(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_leftop(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists(NULL, $1, $2, $3, $4 ),
        'Left operator ' || quote_ident($1) || '.' || $2 || '(NONE,'
        || $3 || ') RETURNS ' || $4 || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_leftop(name, name, name, name) OWNER TO postgres;

--
-- Name: has_leftop(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_leftop(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists(NULL, $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.has_leftop(name, name, name, text) OWNER TO postgres;

--
-- Name: has_leftop(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_leftop(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists(NULL, $1, $2, $3, $4), $5 );
$_$;


ALTER FUNCTION public.has_leftop(name, name, name, name, text) OWNER TO postgres;

--
-- Name: has_materialized_view(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_materialized_view(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_materialized_view( $1, 'Materialized view ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_materialized_view(name) OWNER TO postgres;

--
-- Name: has_materialized_view(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_materialized_view(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'm', $1 ), $2 );
$_$;


ALTER FUNCTION public.has_materialized_view(name, text) OWNER TO postgres;

--
-- Name: has_materialized_view(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_materialized_view(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'm', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_materialized_view(name, name, text) OWNER TO postgres;

--
-- Name: has_opclass(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_opclass(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _opc_exists( $1 ), 'Operator class ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_opclass(name) OWNER TO postgres;

--
-- Name: has_opclass(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_opclass(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _opc_exists( $1, $2 ), 'Operator class ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_opclass(name, name) OWNER TO postgres;

--
-- Name: has_opclass(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_opclass(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _opc_exists( $1 ), $2)
$_$;


ALTER FUNCTION public.has_opclass(name, text) OWNER TO postgres;

--
-- Name: has_opclass(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_opclass(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _opc_exists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_opclass(name, name, text) OWNER TO postgres;

--
-- Name: has_operator(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_operator(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists($1, $2, $3 ),
        'Operator ' ||  $2 || '(' || $1 || ',' || $3
        || ') should exist'
    );
$_$;


ALTER FUNCTION public.has_operator(name, name, name) OWNER TO postgres;

--
-- Name: has_operator(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_operator(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists($1, $2, $3, $4 ),
        'Operator ' ||  $2 || '(' || $1 || ',' || $3
        || ') RETURNS ' || $4 || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_operator(name, name, name, name) OWNER TO postgres;

--
-- Name: has_operator(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_operator(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists($1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.has_operator(name, name, name, text) OWNER TO postgres;

--
-- Name: has_operator(name, name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_operator(name, name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists($1, $2, $3, $4, $5 ),
        'Operator ' || quote_ident($2) || '.' || $3 || '(' || $1 || ',' || $4
        || ') RETURNS ' || $5 || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_operator(name, name, name, name, name) OWNER TO postgres;

--
-- Name: has_operator(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_operator(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists($1, $2, $3, $4 ), $5 );
$_$;


ALTER FUNCTION public.has_operator(name, name, name, name, text) OWNER TO postgres;

--
-- Name: has_operator(name, name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_operator(name, name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists($1, $2, $3, $4, $5 ), $6 );
$_$;


ALTER FUNCTION public.has_operator(name, name, name, name, name, text) OWNER TO postgres;

--
-- Name: has_pk(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_pk(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_pk( $1, 'Table ' || quote_ident($1) || ' should have a primary key' );
$_$;


ALTER FUNCTION public.has_pk(name) OWNER TO postgres;

--
-- Name: has_pk(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_pk(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_pk( $1, $2, 'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have a primary key' );
$_$;


ALTER FUNCTION public.has_pk(name, name) OWNER TO postgres;

--
-- Name: has_pk(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_pk(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, 'p' ), $2 );
$_$;


ALTER FUNCTION public.has_pk(name, text) OWNER TO postgres;

--
-- Name: has_pk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_pk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, $2, 'p' ), $3 );
$_$;


ALTER FUNCTION public.has_pk(name, name, text) OWNER TO postgres;

--
-- Name: has_relation(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_relation(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_relation( $1, 'Relation ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_relation(name) OWNER TO postgres;

--
-- Name: has_relation(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_relation(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _relexists( $1 ), $2 );
$_$;


ALTER FUNCTION public.has_relation(name, text) OWNER TO postgres;

--
-- Name: has_relation(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_relation(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _relexists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_relation(name, name, text) OWNER TO postgres;

--
-- Name: has_rightop(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rightop(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists($1, $2, NULL ),
        'Right operator ' || $2 || '(' || $1 || ',NONE) should exist'
    );
$_$;


ALTER FUNCTION public.has_rightop(name, name) OWNER TO postgres;

--
-- Name: has_rightop(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rightop(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists($1, $2, NULL, $3 ),
        'Right operator ' || $2 || '('
        || $1 || ',NONE) RETURNS ' || $3 || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_rightop(name, name, name) OWNER TO postgres;

--
-- Name: has_rightop(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rightop(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists( $1, $2, NULL), $3 );
$_$;


ALTER FUNCTION public.has_rightop(name, name, text) OWNER TO postgres;

--
-- Name: has_rightop(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rightop(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         _op_exists($1, $2, $3, NULL, $4 ),
        'Right operator ' || quote_ident($2) || '.' || $3 || '('
        || $1 || ',NONE) RETURNS ' || $4 || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_rightop(name, name, name, name) OWNER TO postgres;

--
-- Name: has_rightop(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rightop(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists( $1, $2, NULL, $3), $4 );
$_$;


ALTER FUNCTION public.has_rightop(name, name, name, text) OWNER TO postgres;

--
-- Name: has_rightop(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rightop(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _op_exists( $1, $2, $3, NULL, $4), $5 );
$_$;


ALTER FUNCTION public.has_rightop(name, name, name, name, text) OWNER TO postgres;

--
-- Name: has_role(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_role(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_role($1), 'Role ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_role(name) OWNER TO postgres;

--
-- Name: has_role(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_role(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_role($1), $2 );
$_$;


ALTER FUNCTION public.has_role(name, text) OWNER TO postgres;

--
-- Name: has_rule(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rule(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2) IS NOT NULL, 'Relation ' || quote_ident($1) || ' should have rule ' || quote_ident($2) );
$_$;


ALTER FUNCTION public.has_rule(name, name) OWNER TO postgres;

--
-- Name: has_rule(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rule(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2, $3) IS NOT NULL, 'Relation ' || quote_ident($1) || '.' || quote_ident($2) || ' should have rule ' || quote_ident($3) );
$_$;


ALTER FUNCTION public.has_rule(name, name, name) OWNER TO postgres;

--
-- Name: has_rule(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rule(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2) IS NOT NULL, $3 );
$_$;


ALTER FUNCTION public.has_rule(name, name, text) OWNER TO postgres;

--
-- Name: has_rule(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_rule(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2, $3) IS NOT NULL, $4 );
$_$;


ALTER FUNCTION public.has_rule(name, name, name, text) OWNER TO postgres;

--
-- Name: has_schema(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_schema(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_schema( $1, 'Schema ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_schema(name) OWNER TO postgres;

--
-- Name: has_schema(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_schema(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        EXISTS(
            SELECT true
              FROM pg_catalog.pg_namespace
             WHERE nspname = $1
        ), $2
    );
$_$;


ALTER FUNCTION public.has_schema(name, text) OWNER TO postgres;

--
-- Name: has_sequence(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_sequence(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_sequence( $1, 'Sequence ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_sequence(name) OWNER TO postgres;

--
-- Name: has_sequence(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_sequence(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _rexists( 'S', $1, $2 ),
        'Sequence ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_sequence(name, name) OWNER TO postgres;

--
-- Name: has_sequence(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_sequence(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'S', $1 ), $2 );
$_$;


ALTER FUNCTION public.has_sequence(name, text) OWNER TO postgres;

--
-- Name: has_sequence(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_sequence(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'S', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_sequence(name, name, text) OWNER TO postgres;

--
-- Name: has_table(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_table(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_table( $1, 'Table ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_table(name) OWNER TO postgres;

--
-- Name: has_table(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_table(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _rexists( '{r,p}'::char[], $1, $2 ),
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_table(name, name) OWNER TO postgres;

--
-- Name: has_table(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_table(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( '{r,p}'::char[], $1 ), $2 );
$_$;


ALTER FUNCTION public.has_table(name, text) OWNER TO postgres;

--
-- Name: has_table(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_table(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( '{r,p}'::char[], $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_table(name, name, text) OWNER TO postgres;

--
-- Name: has_tablespace(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_tablespace(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_tablespace( $1, 'Tablespace ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_tablespace(name) OWNER TO postgres;

--
-- Name: has_tablespace(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_tablespace(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        EXISTS(
            SELECT true
              FROM pg_catalog.pg_tablespace
             WHERE spcname = $1
        ), $2
    );
$_$;


ALTER FUNCTION public.has_tablespace(name, text) OWNER TO postgres;

--
-- Name: has_tablespace(name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_tablespace(name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF pg_version_num() >= 90200 THEN
        RETURN ok(
            EXISTS(
                SELECT true
                  FROM pg_catalog.pg_tablespace
                 WHERE spcname = $1
                   AND pg_tablespace_location(oid) = $2
            ), $3
        );
    ELSE
        RETURN ok(
            EXISTS(
                SELECT true
                  FROM pg_catalog.pg_tablespace
                 WHERE spcname = $1
                   AND spclocation = $2
            ), $3
        );
    END IF;
END;
$_$;


ALTER FUNCTION public.has_tablespace(name, text, text) OWNER TO postgres;

--
-- Name: has_trigger(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_trigger(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _trig($1, $2), 'Table ' || quote_ident($1) || ' should have trigger ' || quote_ident($2));
$_$;


ALTER FUNCTION public.has_trigger(name, name) OWNER TO postgres;

--
-- Name: has_trigger(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_trigger(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_trigger(
        $1, $2, $3,
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have trigger ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.has_trigger(name, name, name) OWNER TO postgres;

--
-- Name: has_trigger(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_trigger(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _trig($1, $2), $3);
$_$;


ALTER FUNCTION public.has_trigger(name, name, text) OWNER TO postgres;

--
-- Name: has_trigger(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_trigger(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _trig($1, $2, $3), $4);
$_$;


ALTER FUNCTION public.has_trigger(name, name, name, text) OWNER TO postgres;

--
-- Name: has_type(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_type(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, NULL ), ('Type ' || quote_ident($1) || ' should exist')::text );
$_$;


ALTER FUNCTION public.has_type(name) OWNER TO postgres;

--
-- Name: has_type(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_type(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_type( $1, $2, 'Type ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist' );
$_$;


ALTER FUNCTION public.has_type(name, name) OWNER TO postgres;

--
-- Name: has_type(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_type(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, NULL ), $2 );
$_$;


ALTER FUNCTION public.has_type(name, text) OWNER TO postgres;

--
-- Name: has_type(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_type(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_type( $1, $2, NULL ), $3 );
$_$;


ALTER FUNCTION public.has_type(name, name, text) OWNER TO postgres;

--
-- Name: has_unique(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_unique(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_unique( $1, 'Table ' || quote_ident($1) || ' should have a unique constraint' );
$_$;


ALTER FUNCTION public.has_unique(text) OWNER TO postgres;

--
-- Name: has_unique(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_unique(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, 'u' ), $2 );
$_$;


ALTER FUNCTION public.has_unique(text, text) OWNER TO postgres;

--
-- Name: has_unique(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_unique(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _hasc( $1, $2, 'u' ), $3 );
$_$;


ALTER FUNCTION public.has_unique(text, text, text) OWNER TO postgres;

--
-- Name: has_user(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_user(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_user( $1 ), 'User ' || quote_ident($1) || ' should exist');
$_$;


ALTER FUNCTION public.has_user(name) OWNER TO postgres;

--
-- Name: has_user(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_user(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _has_user($1), $2 );
$_$;


ALTER FUNCTION public.has_user(name, text) OWNER TO postgres;

--
-- Name: has_view(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_view(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_view( $1, 'View ' || quote_ident($1) || ' should exist' );
$_$;


ALTER FUNCTION public.has_view(name) OWNER TO postgres;

--
-- Name: has_view(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_view(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT has_view (
        $1, $2,
        'View ' || quote_ident($1) || '.' || quote_ident($2) || ' should exist'
    );
$_$;


ALTER FUNCTION public.has_view(name, name) OWNER TO postgres;

--
-- Name: has_view(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_view(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'v', $1 ), $2 );
$_$;


ALTER FUNCTION public.has_view(name, text) OWNER TO postgres;

--
-- Name: has_view(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_view(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists( 'v', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.has_view(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_cast(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_cast(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _cast_exists( $1, $2 ),
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_cast(name, name) OWNER TO postgres;

--
-- Name: hasnt_cast(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_cast(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok(
        NOT _cast_exists( $1, $2, $3 ),
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') WITH FUNCTION ' || quote_ident($3) || '() should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_cast(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_cast(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_cast(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _cast_exists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_cast(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_cast(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_cast(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok(
       NOT _cast_exists( $1, $2, $3, $4 ),
        'Cast (' || quote_ident($1) || ' AS ' || quote_ident($2)
        || ') WITH FUNCTION ' || quote_ident($3)
        || '.' || quote_ident($4) || '() should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_cast(name, name, name, name) OWNER TO postgres;

--
-- Name: hasnt_cast(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_cast(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok( NOT _cast_exists( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.hasnt_cast(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_cast(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_cast(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok( NOT _cast_exists( $1, $2, $3, $4 ), $5 );
$_$;


ALTER FUNCTION public.hasnt_cast(name, name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_column(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_column(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_column( $1, $2, 'Column ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_column(name, name) OWNER TO postgres;

--
-- Name: hasnt_column(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_column(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _cexists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_column(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_column(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_column(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _cexists( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.hasnt_column(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_composite(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_composite(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_composite( $1, 'Composite type ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_composite(name) OWNER TO postgres;

--
-- Name: hasnt_composite(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_composite(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_composite(
        $1, $2,
        'Composite type ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_composite(name, name) OWNER TO postgres;

--
-- Name: hasnt_composite(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_composite(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'c', $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_composite(name, text) OWNER TO postgres;

--
-- Name: hasnt_composite(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_composite(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'c', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_composite(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_domain(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_domain(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, ARRAY['d'] ), ('Domain ' || quote_ident($1) || ' should not exist')::text );
$_$;


ALTER FUNCTION public.hasnt_domain(name) OWNER TO postgres;

--
-- Name: hasnt_domain(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_domain(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_domain( $1, $2, 'Domain ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_domain(name, name) OWNER TO postgres;

--
-- Name: hasnt_domain(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_domain(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, ARRAY['d'] ), $2 );
$_$;


ALTER FUNCTION public.hasnt_domain(name, text) OWNER TO postgres;

--
-- Name: hasnt_domain(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_domain(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, $2, ARRAY['d'] ), $3 );
$_$;


ALTER FUNCTION public.hasnt_domain(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_enum(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_enum(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, ARRAY['e'] ), ('Enum ' || quote_ident($1) || ' should not exist')::text );
$_$;


ALTER FUNCTION public.hasnt_enum(name) OWNER TO postgres;

--
-- Name: hasnt_enum(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_enum(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_enum( $1, $2, 'Enum ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_enum(name, name) OWNER TO postgres;

--
-- Name: hasnt_enum(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_enum(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, ARRAY['e'] ), $2 );
$_$;


ALTER FUNCTION public.hasnt_enum(name, text) OWNER TO postgres;

--
-- Name: hasnt_enum(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_enum(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, $2, ARRAY['e'] ), $3 );
$_$;


ALTER FUNCTION public.hasnt_enum(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_extension(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_extension(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _ext_exists( $1 ),
        'Extension ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_extension(name) OWNER TO postgres;

--
-- Name: hasnt_extension(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_extension(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _ext_exists( $1, $2 ),
        'Extension ' || quote_ident($2)
        || ' should not exist in schema ' || quote_ident($1) );
$_$;


ALTER FUNCTION public.hasnt_extension(name, name) OWNER TO postgres;

--
-- Name: hasnt_extension(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_extension(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _ext_exists( $1 ), $2)
$_$;


ALTER FUNCTION public.hasnt_extension(name, text) OWNER TO postgres;

--
-- Name: hasnt_extension(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_extension(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _ext_exists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_extension(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_fk(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_fk(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_fk( $1, 'Table ' || quote_ident($1) || ' should not have a foreign key constraint' );
$_$;


ALTER FUNCTION public.hasnt_fk(name) OWNER TO postgres;

--
-- Name: hasnt_fk(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_fk(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _hasc( $1, 'f' ), $2 );
$_$;


ALTER FUNCTION public.hasnt_fk(name, text) OWNER TO postgres;

--
-- Name: hasnt_fk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_fk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _hasc( $1, $2, 'f' ), $3 );
$_$;


ALTER FUNCTION public.hasnt_fk(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_foreign_table(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_foreign_table(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_foreign_table( $1, 'Foreign table ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_foreign_table(name) OWNER TO postgres;

--
-- Name: hasnt_foreign_table(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_foreign_table(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _rexists( 'f', $1, $2 ),
        'Foreign table ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_foreign_table(name, name) OWNER TO postgres;

--
-- Name: hasnt_foreign_table(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_foreign_table(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'f', $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_foreign_table(name, text) OWNER TO postgres;

--
-- Name: hasnt_foreign_table(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_foreign_table(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'f', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_foreign_table(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_function(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _got_func($1), 'Function ' || quote_ident($1) || '() should not exist' );
$_$;


ALTER FUNCTION public.hasnt_function(name) OWNER TO postgres;

--
-- Name: hasnt_function(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _got_func($1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_function(name, name[]) OWNER TO postgres;

--
-- Name: hasnt_function(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _got_func($1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_function(name, name) OWNER TO postgres;

--
-- Name: hasnt_function(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _got_func($1), $2 );
$_$;


ALTER FUNCTION public.hasnt_function(name, text) OWNER TO postgres;

--
-- Name: hasnt_function(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _got_func($1, $2), $3 );
$_$;


ALTER FUNCTION public.hasnt_function(name, name[], text) OWNER TO postgres;

--
-- Name: hasnt_function(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _got_func($1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_function(name, name, name[]) OWNER TO postgres;

--
-- Name: hasnt_function(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _got_func($1, $2), $3 );
$_$;


ALTER FUNCTION public.hasnt_function(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_function(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_function(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _got_func($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.hasnt_function(name, name, name[], text) OWNER TO postgres;

--
-- Name: hasnt_group(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_group(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_group($1), 'Group ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_group(name) OWNER TO postgres;

--
-- Name: hasnt_group(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_group(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_group($1), $2 );
$_$;


ALTER FUNCTION public.hasnt_group(name, text) OWNER TO postgres;

--
-- Name: hasnt_index(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_index(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _have_index( $1, $2 ),
        'Index ' || quote_ident($2) || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_index(name, name) OWNER TO postgres;

--
-- Name: hasnt_index(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_index(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _have_index( $1, $2, $3 ),
        'Index ' || quote_ident($3) || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_index(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_index(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_index(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _have_index( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_index(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_index(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_index(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN ok( NOT _have_index( $1, $2, $3 ), $4 );
END;
$_$;


ALTER FUNCTION public.hasnt_index(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_inherited_tables(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_inherited_tables(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _inherited( $1 ),
        'Table ' || quote_ident( $1 ) || ' should not have descendents'
    );
$_$;


ALTER FUNCTION public.hasnt_inherited_tables(name) OWNER TO postgres;

--
-- Name: hasnt_inherited_tables(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_inherited_tables(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _inherited( $1, $2 ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 ) || ' should not have descendents'
    );
$_$;


ALTER FUNCTION public.hasnt_inherited_tables(name, name) OWNER TO postgres;

--
-- Name: hasnt_inherited_tables(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_inherited_tables(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _inherited( $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_inherited_tables(name, text) OWNER TO postgres;

--
-- Name: hasnt_inherited_tables(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_inherited_tables(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
       SELECT ok( NOT _inherited( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_inherited_tables(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_language(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_language(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_trusted($1) IS NULL, 'Procedural language ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_language(name) OWNER TO postgres;

--
-- Name: hasnt_language(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_language(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_trusted($1) IS NULL, $2 );
$_$;


ALTER FUNCTION public.hasnt_language(name, text) OWNER TO postgres;

--
-- Name: hasnt_leftop(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_leftop(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists(NULL, $1, $2 ),
        'Left operator ' || $1 || '(NONE,' || $2 || ') should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_leftop(name, name) OWNER TO postgres;

--
-- Name: hasnt_leftop(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_leftop(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists(NULL, $1, $2, $3 ),
        'Left operator ' || $1 || '(NONE,' || $2 || ') RETURNS ' || $3 || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_leftop(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_leftop(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_leftop(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists(NULL, $1, $2), $3 );
$_$;


ALTER FUNCTION public.hasnt_leftop(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_leftop(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_leftop(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists(NULL, $1, $2, $3, $4 ),
        'Left operator ' || quote_ident($1) || '.' || $2 || '(NONE,'
        || $3 || ') RETURNS ' || $4 || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_leftop(name, name, name, name) OWNER TO postgres;

--
-- Name: hasnt_leftop(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_leftop(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists(NULL, $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.hasnt_leftop(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_leftop(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_leftop(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists(NULL, $1, $2, $3, $4), $5 );
$_$;


ALTER FUNCTION public.hasnt_leftop(name, name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_materialized_view(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_materialized_view(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_materialized_view( $1, 'Materialized view ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_materialized_view(name) OWNER TO postgres;

--
-- Name: hasnt_materialized_view(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_materialized_view(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'm', $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_materialized_view(name, text) OWNER TO postgres;

--
-- Name: hasnt_materialized_view(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_materialized_view(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'm', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_materialized_view(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_opclass(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_opclass(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _opc_exists( $1 ), 'Operator class ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_opclass(name) OWNER TO postgres;

--
-- Name: hasnt_opclass(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_opclass(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _opc_exists( $1, $2 ), 'Operator class ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_opclass(name, name) OWNER TO postgres;

--
-- Name: hasnt_opclass(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_opclass(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _opc_exists( $1 ), $2)
$_$;


ALTER FUNCTION public.hasnt_opclass(name, text) OWNER TO postgres;

--
-- Name: hasnt_opclass(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_opclass(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _opc_exists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_opclass(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_operator(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_operator(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists($1, $2, $3 ),
        'Operator ' ||  $2 || '(' || $1 || ',' || $3
        || ') should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_operator(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_operator(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_operator(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists($1, $2, $3, $4 ),
        'Operator ' ||  $2 || '(' || $1 || ',' || $3
        || ') RETURNS ' || $4 || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_operator(name, name, name, name) OWNER TO postgres;

--
-- Name: hasnt_operator(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_operator(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists($1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.hasnt_operator(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_operator(name, name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_operator(name, name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists($1, $2, $3, $4, $5 ),
        'Operator ' || quote_ident($2) || '.' || $3 || '(' || $1 || ',' || $4
        || ') RETURNS ' || $5 || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_operator(name, name, name, name, name) OWNER TO postgres;

--
-- Name: hasnt_operator(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_operator(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists($1, $2, $3, $4 ), $5 );
$_$;


ALTER FUNCTION public.hasnt_operator(name, name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_operator(name, name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_operator(name, name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists($1, $2, $3, $4, $5 ), $6 );
$_$;


ALTER FUNCTION public.hasnt_operator(name, name, name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_pk(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_pk(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_pk( $1, 'Table ' || quote_ident($1) || ' should not have a primary key' );
$_$;


ALTER FUNCTION public.hasnt_pk(name) OWNER TO postgres;

--
-- Name: hasnt_pk(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_pk(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _hasc( $1, 'p' ), $2 );
$_$;


ALTER FUNCTION public.hasnt_pk(name, text) OWNER TO postgres;

--
-- Name: hasnt_pk(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_pk(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _hasc( $1, $2, 'p' ), $3 );
$_$;


ALTER FUNCTION public.hasnt_pk(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_relation(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_relation(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_relation( $1, 'Relation ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_relation(name) OWNER TO postgres;

--
-- Name: hasnt_relation(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_relation(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _relexists( $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_relation(name, text) OWNER TO postgres;

--
-- Name: hasnt_relation(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_relation(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _relexists( $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_relation(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_rightop(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rightop(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists($1, $2, NULL ),
        'Right operator ' || $2 || '(' || $1 || ',NONE) should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_rightop(name, name) OWNER TO postgres;

--
-- Name: hasnt_rightop(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rightop(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists($1, $2, NULL, $3 ),
        'Right operator ' || $2 || '('
        || $1 || ',NONE) RETURNS ' || $3 || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_rightop(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_rightop(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rightop(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists( $1, $2, NULL), $3 );
$_$;


ALTER FUNCTION public.hasnt_rightop(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_rightop(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rightop(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
         NOT _op_exists($1, $2, $3, NULL, $4 ),
        'Right operator ' || quote_ident($2) || '.' || $3 || '('
        || $1 || ',NONE) RETURNS ' || $4 || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_rightop(name, name, name, name) OWNER TO postgres;

--
-- Name: hasnt_rightop(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rightop(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists( $1, $2, NULL, $3), $4 );
$_$;


ALTER FUNCTION public.hasnt_rightop(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_rightop(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rightop(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _op_exists( $1, $2, $3, NULL, $4), $5 );
$_$;


ALTER FUNCTION public.hasnt_rightop(name, name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_role(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_role(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_role($1), 'Role ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_role(name) OWNER TO postgres;

--
-- Name: hasnt_role(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_role(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_role($1), $2 );
$_$;


ALTER FUNCTION public.hasnt_role(name, text) OWNER TO postgres;

--
-- Name: hasnt_rule(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rule(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2) IS NULL, 'Relation ' || quote_ident($1) || ' should not have rule ' || quote_ident($2) );
$_$;


ALTER FUNCTION public.hasnt_rule(name, name) OWNER TO postgres;

--
-- Name: hasnt_rule(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rule(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2, $3) IS NULL, 'Relation ' || quote_ident($1) || '.' || quote_ident($2) || ' should not have rule ' || quote_ident($3) );
$_$;


ALTER FUNCTION public.hasnt_rule(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_rule(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rule(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2) IS NULL, $3 );
$_$;


ALTER FUNCTION public.hasnt_rule(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_rule(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_rule(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _is_instead($1, $2, $3) IS NULL, $4 );
$_$;


ALTER FUNCTION public.hasnt_rule(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_schema(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_schema(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_schema( $1, 'Schema ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_schema(name) OWNER TO postgres;

--
-- Name: hasnt_schema(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_schema(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT EXISTS(
            SELECT true
              FROM pg_catalog.pg_namespace
             WHERE nspname = $1
        ), $2
    );
$_$;


ALTER FUNCTION public.hasnt_schema(name, text) OWNER TO postgres;

--
-- Name: hasnt_sequence(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_sequence(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_sequence( $1, 'Sequence ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_sequence(name) OWNER TO postgres;

--
-- Name: hasnt_sequence(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_sequence(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'S', $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_sequence(name, text) OWNER TO postgres;

--
-- Name: hasnt_sequence(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_sequence(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'S', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_sequence(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_table(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_table(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_table( $1, 'Table ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_table(name) OWNER TO postgres;

--
-- Name: hasnt_table(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_table(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _rexists( '{r,p}'::char[], $1, $2 ),
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_table(name, name) OWNER TO postgres;

--
-- Name: hasnt_table(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_table(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( '{r,p}'::char[], $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_table(name, text) OWNER TO postgres;

--
-- Name: hasnt_table(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_table(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( '{r,p}'::char[], $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_table(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_tablespace(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_tablespace(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_tablespace( $1, 'Tablespace ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_tablespace(name) OWNER TO postgres;

--
-- Name: hasnt_tablespace(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_tablespace(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT EXISTS(
            SELECT true
              FROM pg_catalog.pg_tablespace
             WHERE spcname = $1
        ), $2
    );
$_$;


ALTER FUNCTION public.hasnt_tablespace(name, text) OWNER TO postgres;

--
-- Name: hasnt_trigger(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_trigger(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _trig($1, $2), 'Table ' || quote_ident($1) || ' should not have trigger ' || quote_ident($2));
$_$;


ALTER FUNCTION public.hasnt_trigger(name, name) OWNER TO postgres;

--
-- Name: hasnt_trigger(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_trigger(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _trig($1, $2, $3),
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should not have trigger ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.hasnt_trigger(name, name, name) OWNER TO postgres;

--
-- Name: hasnt_trigger(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_trigger(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _trig($1, $2), $3);
$_$;


ALTER FUNCTION public.hasnt_trigger(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_trigger(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_trigger(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _trig($1, $2, $3), $4);
$_$;


ALTER FUNCTION public.hasnt_trigger(name, name, name, text) OWNER TO postgres;

--
-- Name: hasnt_type(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_type(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, NULL ), ('Type ' || quote_ident($1) || ' should not exist')::text );
$_$;


ALTER FUNCTION public.hasnt_type(name) OWNER TO postgres;

--
-- Name: hasnt_type(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_type(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_type( $1, $2, 'Type ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_type(name, name) OWNER TO postgres;

--
-- Name: hasnt_type(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_type(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, NULL ), $2 );
$_$;


ALTER FUNCTION public.hasnt_type(name, text) OWNER TO postgres;

--
-- Name: hasnt_type(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_type(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_type( $1, $2, NULL ), $3 );
$_$;


ALTER FUNCTION public.hasnt_type(name, name, text) OWNER TO postgres;

--
-- Name: hasnt_user(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_user(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_user( $1 ), 'User ' || quote_ident($1) || ' should not exist');
$_$;


ALTER FUNCTION public.hasnt_user(name) OWNER TO postgres;

--
-- Name: hasnt_user(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_user(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _has_user($1), $2 );
$_$;


ALTER FUNCTION public.hasnt_user(name, text) OWNER TO postgres;

--
-- Name: hasnt_view(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_view(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_view( $1, 'View ' || quote_ident($1) || ' should not exist' );
$_$;


ALTER FUNCTION public.hasnt_view(name) OWNER TO postgres;

--
-- Name: hasnt_view(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_view(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT hasnt_view( $1, $2,
        'View ' || quote_ident($1) || '.' || quote_ident($2) || ' should not exist'
    );
$_$;


ALTER FUNCTION public.hasnt_view(name, name) OWNER TO postgres;

--
-- Name: hasnt_view(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_view(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'v', $1 ), $2 );
$_$;


ALTER FUNCTION public.hasnt_view(name, text) OWNER TO postgres;

--
-- Name: hasnt_view(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hasnt_view(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists( 'v', $1, $2 ), $3 );
$_$;


ALTER FUNCTION public.hasnt_view(name, name, text) OWNER TO postgres;

--
-- Name: ialike(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ialike(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~~* $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.ialike(anyelement, text) OWNER TO postgres;

--
-- Name: ialike(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ialike(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~~* $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.ialike(anyelement, text, text) OWNER TO postgres;

--
-- Name: imatches(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.imatches(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~* $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.imatches(anyelement, text) OWNER TO postgres;

--
-- Name: imatches(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.imatches(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~* $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.imatches(anyelement, text, text) OWNER TO postgres;

--
-- Name: in_todo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.in_todo() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    todos integer;
BEGIN
    todos := _get('todo');
    RETURN CASE WHEN todos IS NULL THEN FALSE ELSE TRUE END;
END;
$$;


ALTER FUNCTION public.in_todo() OWNER TO postgres;

--
-- Name: index_is_partial(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_partial(name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indpred IS NOT NULL
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
     WHERE ci.relname = $1
       AND pg_catalog.pg_table_is_visible(ct.oid)
      INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Index ' || quote_ident($1) || ' should be partial'
      );
END;
$_$;


ALTER FUNCTION public.index_is_partial(name) OWNER TO postgres;

--
-- Name: index_is_partial(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_partial(name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indpred IS NOT NULL
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
     WHERE ct.relname = $1
       AND ci.relname = $2
       AND pg_catalog.pg_table_is_visible(ct.oid)
     INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Index ' || quote_ident($2) || ' should be partial'
      );
END;
$_$;


ALTER FUNCTION public.index_is_partial(name, name) OWNER TO postgres;

--
-- Name: index_is_partial(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_partial(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT index_is_partial(
        $1, $2, $3,
        'Index ' || quote_ident($3) || ' should be partial'
    );
$_$;


ALTER FUNCTION public.index_is_partial(name, name, name) OWNER TO postgres;

--
-- Name: index_is_partial(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_partial(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indpred IS NOT NULL
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
     WHERE ct.relname = $2
       AND ci.relname = $3
       AND n.nspname  = $1
      INTO res;

      RETURN ok( COALESCE(res, false), $4 );
END;
$_$;


ALTER FUNCTION public.index_is_partial(name, name, name, text) OWNER TO postgres;

--
-- Name: index_is_primary(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_primary(name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisprimary
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
     WHERE ci.relname = $1
       AND pg_catalog.pg_table_is_visible(ct.oid)
      INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Index ' || quote_ident($1) || ' should be on a primary key'
      );
END;
$_$;


ALTER FUNCTION public.index_is_primary(name) OWNER TO postgres;

--
-- Name: index_is_primary(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_primary(name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisprimary
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
     WHERE ct.relname = $1
       AND ci.relname = $2
       AND pg_catalog.pg_table_is_visible(ct.oid)
     INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Index ' || quote_ident($2) || ' should be on a primary key'
      );
END;
$_$;


ALTER FUNCTION public.index_is_primary(name, name) OWNER TO postgres;

--
-- Name: index_is_primary(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_primary(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT index_is_primary(
        $1, $2, $3,
        'Index ' || quote_ident($3) || ' should be on a primary key'
    );
$_$;


ALTER FUNCTION public.index_is_primary(name, name, name) OWNER TO postgres;

--
-- Name: index_is_primary(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_primary(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisprimary
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
     WHERE ct.relname = $2
       AND ci.relname = $3
       AND n.nspname  = $1
      INTO res;

      RETURN ok( COALESCE(res, false), $4 );
END;
$_$;


ALTER FUNCTION public.index_is_primary(name, name, name, text) OWNER TO postgres;

--
-- Name: index_is_type(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_type(name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    aname name;
BEGIN
    SELECT am.amname
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_am am    ON ci.relam = am.oid
     WHERE ci.relname = $1
      INTO aname;

      return is(
          aname, $2,
          'Index ' || quote_ident($1) || ' should be a ' || quote_ident($2) || ' index'
      );
END;
$_$;


ALTER FUNCTION public.index_is_type(name, name) OWNER TO postgres;

--
-- Name: index_is_type(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_type(name, name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    aname name;
BEGIN
    SELECT am.amname
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_am am    ON ci.relam = am.oid
     WHERE ct.relname = $1
       AND ci.relname = $2
      INTO aname;

      return is(
          aname, $3,
          'Index ' || quote_ident($2) || ' should be a ' || quote_ident($3) || ' index'
      );
END;
$_$;


ALTER FUNCTION public.index_is_type(name, name, name) OWNER TO postgres;

--
-- Name: index_is_type(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_type(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT index_is_type(
        $1, $2, $3, $4,
        'Index ' || quote_ident($3) || ' should be a ' || quote_ident($4) || ' index'
    );
$_$;


ALTER FUNCTION public.index_is_type(name, name, name, name) OWNER TO postgres;

--
-- Name: index_is_type(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_type(name, name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    aname name;
BEGIN
    SELECT am.amname
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
      JOIN pg_catalog.pg_am am       ON ci.relam = am.oid
     WHERE ct.relname = $2
       AND ci.relname = $3
       AND n.nspname  = $1
      INTO aname;

      return is( aname, $4, $5 );
END;
$_$;


ALTER FUNCTION public.index_is_type(name, name, name, name, text) OWNER TO postgres;

--
-- Name: index_is_unique(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_unique(name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisunique
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
     WHERE ci.relname = $1
       AND pg_catalog.pg_table_is_visible(ct.oid)
      INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Index ' || quote_ident($1) || ' should be unique'
      );
END;
$_$;


ALTER FUNCTION public.index_is_unique(name) OWNER TO postgres;

--
-- Name: index_is_unique(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_unique(name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisunique
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
     WHERE ct.relname = $1
       AND ci.relname = $2
       AND pg_catalog.pg_table_is_visible(ct.oid)
      INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Index ' || quote_ident($2) || ' should be unique'
      );
END;
$_$;


ALTER FUNCTION public.index_is_unique(name, name) OWNER TO postgres;

--
-- Name: index_is_unique(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_unique(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT index_is_unique(
        $1, $2, $3,
        'Index ' || quote_ident($3) || ' should be unique'
    );
$_$;


ALTER FUNCTION public.index_is_unique(name, name, name) OWNER TO postgres;

--
-- Name: index_is_unique(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_is_unique(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisunique
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
     WHERE ct.relname = $2
       AND ci.relname = $3
       AND n.nspname  = $1
      INTO res;

      RETURN ok( COALESCE(res, false), $4 );
END;
$_$;


ALTER FUNCTION public.index_is_unique(name, name, name, text) OWNER TO postgres;

--
-- Name: index_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT index_owner_is(
        $1, $2, $3,
        'Index ' || quote_ident($2) || ' ON '
        || quote_ident($1) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.index_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: index_owner_is(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_owner_is(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT index_owner_is(
        $1, $2, $3, $4,
        'Index ' || quote_ident($3) || ' ON '
        || quote_ident($1) || '.' || quote_ident($2)
        || ' should be owned by ' || quote_ident($4)
    );
$_$;


ALTER FUNCTION public.index_owner_is(name, name, name, name) OWNER TO postgres;

--
-- Name: index_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_index_owner($1, $2);
BEGIN
    -- Make sure the index exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Index ' || quote_ident($2) || ' ON ' || quote_ident($1) || ' not found'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.index_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: index_owner_is(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.index_owner_is(name, name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_index_owner($1, $2, $3);
BEGIN
    -- Make sure the index exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            E'    Index ' || quote_ident($3) || ' ON '
            || quote_ident($1) || '.' || quote_ident($2) || ' not found'
        );
    END IF;

    RETURN is(owner, $4, $5);
END;
$_$;


ALTER FUNCTION public.index_owner_is(name, name, name, name, text) OWNER TO postgres;

--
-- Name: indexes_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.indexes_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT indexes_are( $1, $2, 'Table ' || quote_ident($1) || ' should have the correct indexes' );
$_$;


ALTER FUNCTION public.indexes_are(name, name[]) OWNER TO postgres;

--
-- Name: indexes_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.indexes_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'indexes',
        ARRAY(
            SELECT ci.relname
              FROM pg_catalog.pg_index x
              JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
              JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
             WHERE ct.relname = $1
               AND pg_catalog.pg_table_is_visible(ct.oid)
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT ci.relname
              FROM pg_catalog.pg_index x
              JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
              JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
             WHERE ct.relname = $1
               AND pg_catalog.pg_table_is_visible(ct.oid)
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        ),
        $3
    );
$_$;


ALTER FUNCTION public.indexes_are(name, name[], text) OWNER TO postgres;

--
-- Name: indexes_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.indexes_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT indexes_are( $1, $2, $3, 'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct indexes' );
$_$;


ALTER FUNCTION public.indexes_are(name, name, name[]) OWNER TO postgres;

--
-- Name: indexes_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.indexes_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'indexes',
        ARRAY(
            SELECT ci.relname
              FROM pg_catalog.pg_index x
              JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
              JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
             WHERE ct.relname = $2
               AND n.nspname  = $1
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
        ),
        ARRAY(
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT ci.relname
              FROM pg_catalog.pg_index x
              JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
              JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
             WHERE ct.relname = $2
               AND n.nspname  = $1
        ),
        $4
    );
$_$;


ALTER FUNCTION public.indexes_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: is(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."is"(anyelement, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is( $1, $2, NULL);
$_$;


ALTER FUNCTION public."is"(anyelement, anyelement) OWNER TO postgres;

--
-- Name: is(anyelement, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."is"(anyelement, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    result BOOLEAN;
    output TEXT;
BEGIN
    -- Would prefer $1 IS NOT DISTINCT FROM, but that's not supported by 8.1.
    result := NOT $1 IS DISTINCT FROM $2;
    output := ok( result, $3 );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '        have: ' || CASE WHEN $1 IS NULL THEN 'NULL' ELSE $1::text END ||
        E'\n        want: ' || CASE WHEN $2 IS NULL THEN 'NULL' ELSE $2::text END
    ) END;
END;
$_$;


ALTER FUNCTION public."is"(anyelement, anyelement, text) OWNER TO postgres;

--
-- Name: is_aggregate(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1,  _type_func('a', $1),
        'Function ' || quote_ident($1) || '() should be an aggregate function'
    );
$_$;


ALTER FUNCTION public.is_aggregate(name) OWNER TO postgres;

--
-- Name: is_aggregate(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, _type_func('a', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be an aggregate function'
    );
$_$;


ALTER FUNCTION public.is_aggregate(name, name[]) OWNER TO postgres;

--
-- Name: is_aggregate(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, _type_func('a', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should be an aggregate function'
    );
$_$;


ALTER FUNCTION public.is_aggregate(name, name) OWNER TO postgres;

--
-- Name: is_aggregate(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _type_func('a', $1), $2 );
$_$;


ALTER FUNCTION public.is_aggregate(name, text) OWNER TO postgres;

--
-- Name: is_aggregate(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare( NULL, $1, $2, _type_func('a', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_aggregate(name, name[], text) OWNER TO postgres;

--
-- Name: is_aggregate(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, _type_func('a', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be an aggregate function'
    );
$_$;


ALTER FUNCTION public.is_aggregate(name, name, name[]) OWNER TO postgres;

--
-- Name: is_aggregate(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _type_func('a', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_aggregate(name, name, text) OWNER TO postgres;

--
-- Name: is_aggregate(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_aggregate(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _type_func( 'a', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_aggregate(name, name, name[], text) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $1, $2, NULL ),
        'Table ' || quote_ident( $1 ) || ' should be an ancestor of ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $1, $2, $3 ),
        'Table ' || quote_ident( $1 ) || ' should be ancestor ' || $3 || ' of ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, integer) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $1, $2, NULL ), $3 );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, text) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, integer, text) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $1, $2, $3, $4, NULL ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should be an ancestor of '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, name, name) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $1, $2, $3, $4, $5 ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should be ancestor ' || $5 || ' for '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, name, name, integer) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $1, $2, $3, $4, NULL ), $5 );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, name, name, text) OWNER TO postgres;

--
-- Name: is_ancestor_of(name, name, name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_ancestor_of(name, name, name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $1, $2, $3, $4, $5 ), $6 );
$_$;


ALTER FUNCTION public.is_ancestor_of(name, name, name, name, integer, text) OWNER TO postgres;

--
-- Name: is_clustered(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_clustered(name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisclustered
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
     WHERE ci.relname = $1
      INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Table should be clustered on index ' || quote_ident($1)
      );
END;
$_$;


ALTER FUNCTION public.is_clustered(name) OWNER TO postgres;

--
-- Name: is_clustered(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_clustered(name, name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisclustered
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci ON ci.oid = x.indexrelid
     WHERE ct.relname = $1
       AND ci.relname = $2
      INTO res;

      RETURN ok(
          COALESCE(res, false),
          'Table ' || quote_ident($1) || ' should be clustered on index ' || quote_ident($2)
      );
END;
$_$;


ALTER FUNCTION public.is_clustered(name, name) OWNER TO postgres;

--
-- Name: is_clustered(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_clustered(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is_clustered(
        $1, $2, $3,
        'Table ' || quote_ident($1) || '.' || quote_ident($2) ||
        ' should be clustered on index ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.is_clustered(name, name, name) OWNER TO postgres;

--
-- Name: is_clustered(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_clustered(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res boolean;
BEGIN
    SELECT x.indisclustered
      FROM pg_catalog.pg_index x
      JOIN pg_catalog.pg_class ct    ON ct.oid = x.indrelid
      JOIN pg_catalog.pg_class ci    ON ci.oid = x.indexrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = ct.relnamespace
     WHERE ct.relname = $2
       AND ci.relname = $3
       AND n.nspname  = $1
      INTO res;

      RETURN ok( COALESCE(res, false), $4 );
END;
$_$;


ALTER FUNCTION public.is_clustered(name, name, name, text) OWNER TO postgres;

--
-- Name: is_definer(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _definer($1), 'Function ' || quote_ident($1) || '() should be security definer' );
$_$;


ALTER FUNCTION public.is_definer(name) OWNER TO postgres;

--
-- Name: is_definer(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _definer($1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be security definer'
    );
$_$;


ALTER FUNCTION public.is_definer(name, name[]) OWNER TO postgres;

--
-- Name: is_definer(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _definer($1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should be security definer'
    );
$_$;


ALTER FUNCTION public.is_definer(name, name) OWNER TO postgres;

--
-- Name: is_definer(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _definer($1), $2 );
$_$;


ALTER FUNCTION public.is_definer(name, text) OWNER TO postgres;

--
-- Name: is_definer(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _definer($1, $2), $3 );
$_$;


ALTER FUNCTION public.is_definer(name, name[], text) OWNER TO postgres;

--
-- Name: is_definer(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _definer($1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be security definer'
    );
$_$;


ALTER FUNCTION public.is_definer(name, name, name[]) OWNER TO postgres;

--
-- Name: is_definer(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _definer($1, $2), $3 );
$_$;


ALTER FUNCTION public.is_definer(name, name, text) OWNER TO postgres;

--
-- Name: is_definer(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_definer(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _definer($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_definer(name, name, name[], text) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $2, $1, NULL ),
        'Table ' || quote_ident( $1 ) || ' should be a descendent of ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $2, $1, $3 ),
        'Table ' || quote_ident( $1 ) || ' should be descendent ' || $3 || ' from ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, integer) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $2, $1, NULL ), $3 );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, text) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $2, $1, $3 ), $4 );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, integer, text) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $3, $4, $1, $2, NULL ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should be a descendent of '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, name, name) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _ancestor_of( $3, $4, $1, $2, $5 ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should be descendent ' || $5 || ' from '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, name, name, integer) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $3, $4, $1, $2, NULL ), $5 );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, name, name, text) OWNER TO postgres;

--
-- Name: is_descendent_of(name, name, name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_descendent_of(name, name, name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _ancestor_of( $3, $4, $1, $2, $5 ), $6 );
$_$;


ALTER FUNCTION public.is_descendent_of(name, name, name, name, integer, text) OWNER TO postgres;

--
-- Name: is_empty(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_empty(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is_empty( $1, NULL );
$_$;


ALTER FUNCTION public.is_empty(text) OWNER TO postgres;

--
-- Name: is_empty(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_empty(text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    extras  TEXT[]  := '{}';
    res     BOOLEAN := TRUE;
    msg     TEXT    := '';
    rec     RECORD;
BEGIN
    -- Find extra records.
    FOR rec in EXECUTE _query($1) LOOP
        extras := extras || rec::text;
    END LOOP;

    -- What extra records do we have?
    IF extras[1] IS NOT NULL THEN
        res := FALSE;
        msg := E'\n' || diag(
            E'    Unexpected records:\n        '
            ||  array_to_string( extras, E'\n        ' )
        );
    END IF;

    RETURN ok(res, $2) || msg;
END;
$_$;


ALTER FUNCTION public.is_empty(text, text) OWNER TO postgres;

--
-- Name: is_indexed(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok(
       _is_indexed(NULL, $1, $2),
       'Should have an index on ' ||  quote_ident($1) || '(' || array_to_string( $2, ', ' ) || ')'
   );
$_$;


ALTER FUNCTION public.is_indexed(name, name[]) OWNER TO postgres;

--
-- Name: is_indexed(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok ( _is_indexed( NULL, $1, ARRAY[$2]::NAME[]) );
$_$;


ALTER FUNCTION public.is_indexed(name, name) OWNER TO postgres;

--
-- Name: is_indexed(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok( _is_indexed(NULL, $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_indexed(name, name[], text) OWNER TO postgres;

--
-- Name: is_indexed(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok(
       _is_indexed($1, $2, $3),
       'Should have an index on ' ||  quote_ident($1) || '.' || quote_ident($2) || '(' || array_to_string( $3, ', ' ) || ')'
    );
$_$;


ALTER FUNCTION public.is_indexed(name, name, name[]) OWNER TO postgres;

--
-- Name: is_indexed(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT CASE WHEN _is_schema( $1 ) THEN
                -- Looking for schema.table index.
                is_indexed( $1, $2, ARRAY[$3]::NAME[] )
           ELSE
                -- Looking for particular columns.
                is_indexed( $1, ARRAY[$2]::NAME[], $3 )
           END;
$_$;


ALTER FUNCTION public.is_indexed(name, name, name) OWNER TO postgres;

--
-- Name: is_indexed(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok( _is_indexed($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_indexed(name, name, name[], text) OWNER TO postgres;

--
-- Name: is_indexed(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_indexed(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT ok ( _is_indexed( $1, $2, ARRAY[$3]::NAME[]), $4);
$_$;


ALTER FUNCTION public.is_indexed(name, name, name, text) OWNER TO postgres;

--
-- Name: is_member_of(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_member_of(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is_member_of( $1, $2, 'Should have members of role ' || quote_ident($1) );
$_$;


ALTER FUNCTION public.is_member_of(name, name[]) OWNER TO postgres;

--
-- Name: is_member_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_member_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is_member_of( $1, ARRAY[$2] );
$_$;


ALTER FUNCTION public.is_member_of(name, name) OWNER TO postgres;

--
-- Name: is_member_of(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_member_of(name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    missing text[];
BEGIN
    IF NOT _has_role($1) THEN
        RETURN fail( $3 ) || E'\n' || diag (
            '    Role ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    SELECT ARRAY(
        SELECT quote_ident($2[i])
          FROM generate_series(1, array_upper($2, 1)) s(i)
          LEFT JOIN pg_catalog.pg_roles r ON rolname = $2[i]
         WHERE r.oid IS NULL
            OR NOT r.oid = ANY ( _grolist($1) )
         ORDER BY s.i
    ) INTO missing;
    IF missing[1] IS NULL THEN
        RETURN ok( true, $3 );
    END IF;
    RETURN ok( false, $3 ) || E'\n' || diag(
        '    Members missing from the ' || quote_ident($1) || E' role:\n        ' ||
        array_to_string( missing, E'\n        ')
    );
END;
$_$;


ALTER FUNCTION public.is_member_of(name, name[], text) OWNER TO postgres;

--
-- Name: is_member_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_member_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is_member_of( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.is_member_of(name, name, text) OWNER TO postgres;

--
-- Name: is_normal_function(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, _type_func('f', $1),
        'Function ' || quote_ident($1) || '() should be a normal function'
    );
$_$;


ALTER FUNCTION public.is_normal_function(name) OWNER TO postgres;

--
-- Name: is_normal_function(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, _type_func('f', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be a normal function'
    );
$_$;


ALTER FUNCTION public.is_normal_function(name, name[]) OWNER TO postgres;

--
-- Name: is_normal_function(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, _type_func('f', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should be a normal function'
    );
$_$;


ALTER FUNCTION public.is_normal_function(name, name) OWNER TO postgres;

--
-- Name: is_normal_function(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _type_func('f', $1), $2 );
$_$;


ALTER FUNCTION public.is_normal_function(name, text) OWNER TO postgres;

--
-- Name: is_normal_function(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _type_func('f', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_normal_function(name, name[], text) OWNER TO postgres;

--
-- Name: is_normal_function(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3,
        _type_func('f', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be a normal function'
    );
$_$;


ALTER FUNCTION public.is_normal_function(name, name, name[]) OWNER TO postgres;

--
-- Name: is_normal_function(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _type_func('f', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_normal_function(name, name, text) OWNER TO postgres;

--
-- Name: is_normal_function(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_normal_function(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _type_func('f', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_normal_function(name, name, name[], text) OWNER TO postgres;

--
-- Name: is_partition_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partition_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _partof($1, $2),
        'Table ' || quote_ident($1) || ' should be a partition of ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.is_partition_of(name, name) OWNER TO postgres;

--
-- Name: is_partition_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partition_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _partof($1, $2), $3);
$_$;


ALTER FUNCTION public.is_partition_of(name, name, text) OWNER TO postgres;

--
-- Name: is_partition_of(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partition_of(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _partof($1, $2, $3, $4),
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should be a partition of '
        || quote_ident($3) || '.' || quote_ident($4)
    );
$_$;


ALTER FUNCTION public.is_partition_of(name, name, name, name) OWNER TO postgres;

--
-- Name: is_partition_of(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partition_of(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _partof($1, $2, $3, $4), $5);
$_$;


ALTER FUNCTION public.is_partition_of(name, name, name, name, text) OWNER TO postgres;

--
-- Name: is_partitioned(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partitioned(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _rexists('p', $1),
        'Table ' || quote_ident($1) || ' should be partitioned'
    );
$_$;


ALTER FUNCTION public.is_partitioned(name) OWNER TO postgres;

--
-- Name: is_partitioned(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partitioned(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _rexists('p', $1, $2),
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should be partitioned'
    );
$_$;


ALTER FUNCTION public.is_partitioned(name, name) OWNER TO postgres;

--
-- Name: is_partitioned(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partitioned(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists('p', $1), $2);
$_$;


ALTER FUNCTION public.is_partitioned(name, text) OWNER TO postgres;

--
-- Name: is_partitioned(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_partitioned(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _rexists('p', $1, $2), $3);
$_$;


ALTER FUNCTION public.is_partitioned(name, name, text) OWNER TO postgres;

--
-- Name: is_procedure(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, _type_func('p', $1),
        'Function ' || quote_ident($1) || '() should be a procedure'
    );
$_$;


ALTER FUNCTION public.is_procedure(name) OWNER TO postgres;

--
-- Name: is_procedure(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, _type_func('p', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be a procedure'
    );
$_$;


ALTER FUNCTION public.is_procedure(name, name[]) OWNER TO postgres;

--
-- Name: is_procedure(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, _type_func('p', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should be a procedure'
    );
$_$;


ALTER FUNCTION public.is_procedure(name, name) OWNER TO postgres;

--
-- Name: is_procedure(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _type_func('p', $1), $2 );
$_$;


ALTER FUNCTION public.is_procedure(name, text) OWNER TO postgres;

--
-- Name: is_procedure(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _type_func('p', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_procedure(name, name[], text) OWNER TO postgres;

--
-- Name: is_procedure(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, _type_func('p', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be a procedure'
    );
$_$;


ALTER FUNCTION public.is_procedure(name, name, name[]) OWNER TO postgres;

--
-- Name: is_procedure(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _type_func('p', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_procedure(name, name, text) OWNER TO postgres;

--
-- Name: is_procedure(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_procedure(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _type_func( 'p', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_procedure(name, name, name[], text) OWNER TO postgres;

--
-- Name: is_strict(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( _strict($1), 'Function ' || quote_ident($1) || '() should be strict' );
$_$;


ALTER FUNCTION public.is_strict(name) OWNER TO postgres;

--
-- Name: is_strict(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _strict($1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be strict'
    );
$_$;


ALTER FUNCTION public.is_strict(name, name[]) OWNER TO postgres;

--
-- Name: is_strict(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _strict($1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should be strict'
    );
$_$;


ALTER FUNCTION public.is_strict(name, name) OWNER TO postgres;

--
-- Name: is_strict(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _strict($1), $2 );
$_$;


ALTER FUNCTION public.is_strict(name, text) OWNER TO postgres;

--
-- Name: is_strict(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _strict($1, $2), $3 );
$_$;


ALTER FUNCTION public.is_strict(name, name[], text) OWNER TO postgres;

--
-- Name: is_strict(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        _strict($1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be strict'
    );
$_$;


ALTER FUNCTION public.is_strict(name, name, name[]) OWNER TO postgres;

--
-- Name: is_strict(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _strict($1, $2), $3 );
$_$;


ALTER FUNCTION public.is_strict(name, name, text) OWNER TO postgres;

--
-- Name: is_strict(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_strict(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _strict($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_strict(name, name, name[], text) OWNER TO postgres;

--
-- Name: is_superuser(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_superuser(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT is_superuser( $1, 'User ' || quote_ident($1) || ' should be a super user' );
$_$;


ALTER FUNCTION public.is_superuser(name) OWNER TO postgres;

--
-- Name: is_superuser(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_superuser(name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    is_super boolean := _is_super($1);
BEGIN
    IF is_super IS NULL THEN
        RETURN fail( $2 ) || E'\n' || diag( '    User ' || quote_ident($1) || ' does not exist') ;
    END IF;
    RETURN ok( is_super, $2 );
END;
$_$;


ALTER FUNCTION public.is_superuser(name, text) OWNER TO postgres;

--
-- Name: is_window(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, _type_func('w', $1),
        'Function ' || quote_ident($1) || '() should be a window function'
    );
$_$;


ALTER FUNCTION public.is_window(name) OWNER TO postgres;

--
-- Name: is_window(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, _type_func('w', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be a window function'
    );
$_$;


ALTER FUNCTION public.is_window(name, name[]) OWNER TO postgres;

--
-- Name: is_window(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, _type_func('w', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should be a window function'
    );
$_$;


ALTER FUNCTION public.is_window(name, name) OWNER TO postgres;

--
-- Name: is_window(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _type_func('w', $1), $2 );
$_$;


ALTER FUNCTION public.is_window(name, text) OWNER TO postgres;

--
-- Name: is_window(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _type_func('w', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_window(name, name[], text) OWNER TO postgres;

--
-- Name: is_window(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, _type_func('w', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be a window function'
    );
$_$;


ALTER FUNCTION public.is_window(name, name, name[]) OWNER TO postgres;

--
-- Name: is_window(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _type_func('w', $1, $2), $3 );
$_$;


ALTER FUNCTION public.is_window(name, name, text) OWNER TO postgres;

--
-- Name: is_window(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_window(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _type_func( 'w', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.is_window(name, name, name[], text) OWNER TO postgres;

--
-- Name: isa_ok(anyelement, regtype); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isa_ok(anyelement, regtype) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isa_ok($1, $2, 'the value');
$_$;


ALTER FUNCTION public.isa_ok(anyelement, regtype) OWNER TO postgres;

--
-- Name: isa_ok(anyelement, regtype, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isa_ok(anyelement, regtype, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    typeof regtype := pg_typeof($1);
BEGIN
    IF typeof = $2 THEN RETURN ok(true, $3 || ' isa ' || $2 ); END IF;
    RETURN ok(false, $3 || ' isa ' || $2 ) || E'\n' ||
        diag('    ' || $3 || ' isn''t a "' || $2 || '" it''s a "' || typeof || '"');
END;
$_$;


ALTER FUNCTION public.isa_ok(anyelement, regtype, text) OWNER TO postgres;

--
-- Name: isnt(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt(anyelement, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt( $1, $2, NULL);
$_$;


ALTER FUNCTION public.isnt(anyelement, anyelement) OWNER TO postgres;

--
-- Name: isnt(anyelement, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt(anyelement, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    result BOOLEAN;
    output TEXT;
BEGIN
    result := $1 IS DISTINCT FROM $2;
    output := ok( result, $3 );
    RETURN output || CASE result WHEN TRUE THEN '' ELSE E'\n' || diag(
           '        have: ' || COALESCE( $1::text, 'NULL' ) ||
        E'\n        want: anything else'
    ) END;
END;
$_$;


ALTER FUNCTION public.isnt(anyelement, anyelement, text) OWNER TO postgres;

--
-- Name: isnt_aggregate(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, NOT _type_func('a', $1),
        'Function ' || quote_ident($1) || '() should not be an aggregate function'
    );
$_$;


ALTER FUNCTION public.isnt_aggregate(name) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, NOT _type_func('a', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not be an aggregate function'
    );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, name[]) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, NOT _type_func('a', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not be an aggregate function'
    );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, name) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, NOT _type_func('a', $1), $2 );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, text) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, NOT _type_func('a', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, NOT _type_func('a', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not be an aggregate function'
    );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, name, name[]) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, NOT _type_func('a', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, name, text) OWNER TO postgres;

--
-- Name: isnt_aggregate(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_aggregate(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, NOT _type_func('a', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.isnt_aggregate(name, name, name[], text) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT  _ancestor_of( $1, $2, NULL ),
        'Table ' || quote_ident( $1 ) || ' should not be an ancestor of ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT  _ancestor_of( $1, $2, $3 ),
        'Table ' || quote_ident( $1 ) || ' should not be ancestor ' || $3 || ' of ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, integer) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT  _ancestor_of( $1, $2, NULL ), $3 );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, text) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT  _ancestor_of( $1, $2, $3 ), $4 );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, integer, text) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT  _ancestor_of( $1, $2, $3, $4, NULL ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should not be an ancestor of '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, name, name) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT  _ancestor_of( $1, $2, $3, $4, $5 ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should not be ancestor ' || $5 || ' for '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, name, name, integer) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT  _ancestor_of( $1, $2, $3, $4, NULL ), $5 );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, name, name, text) OWNER TO postgres;

--
-- Name: isnt_ancestor_of(name, name, name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_ancestor_of(name, name, name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT  _ancestor_of( $1, $2, $3, $4, $5 ), $6 );
$_$;


ALTER FUNCTION public.isnt_ancestor_of(name, name, name, name, integer, text) OWNER TO postgres;

--
-- Name: isnt_definer(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _definer($1), 'Function ' || quote_ident($1) || '() should not be security definer' );
$_$;


ALTER FUNCTION public.isnt_definer(name) OWNER TO postgres;

--
-- Name: isnt_definer(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _definer($1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not be security definer'
    );
$_$;


ALTER FUNCTION public.isnt_definer(name, name[]) OWNER TO postgres;

--
-- Name: isnt_definer(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _definer($1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not be security definer'
    );
$_$;


ALTER FUNCTION public.isnt_definer(name, name) OWNER TO postgres;

--
-- Name: isnt_definer(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, NOT _definer($1), $2 );
$_$;


ALTER FUNCTION public.isnt_definer(name, text) OWNER TO postgres;

--
-- Name: isnt_definer(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, NOT _definer($1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_definer(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_definer(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _definer($1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not be security definer'
    );
$_$;


ALTER FUNCTION public.isnt_definer(name, name, name[]) OWNER TO postgres;

--
-- Name: isnt_definer(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, NOT _definer($1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_definer(name, name, text) OWNER TO postgres;

--
-- Name: isnt_definer(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_definer(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, NOT _definer($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.isnt_definer(name, name, name[], text) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
       NOT  _ancestor_of( $2, $1, NULL ),
        'Table ' || quote_ident( $1 ) || ' should not be a descendent of ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
       NOT  _ancestor_of( $2, $1, $3 ),
        'Table ' || quote_ident( $1 ) || ' should not be descendent ' || $3 || ' from ' || quote_ident( $2)
    );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, integer) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(NOT  _ancestor_of( $2, $1, NULL ), $3 );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, text) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(NOT  _ancestor_of( $2, $1, $3 ), $4 );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, integer, text) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
       NOT  _ancestor_of( $3, $4, $1, $2, NULL ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should not be a descendent of '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, name, name) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, name, name, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
       NOT  _ancestor_of( $3, $4, $1, $2, $5 ),
        'Table ' || quote_ident( $1 ) || '.' || quote_ident( $2 )
        || ' should not be descendent ' || $5 || ' from '
        || quote_ident( $3 ) || '.' || quote_ident( $4 )
    );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, name, name, integer) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(NOT  _ancestor_of( $3, $4, $1, $2, NULL ), $5 );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, name, name, text) OWNER TO postgres;

--
-- Name: isnt_descendent_of(name, name, name, name, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_descendent_of(name, name, name, name, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(NOT  _ancestor_of( $3, $4, $1, $2, $5 ), $6 );
$_$;


ALTER FUNCTION public.isnt_descendent_of(name, name, name, name, integer, text) OWNER TO postgres;

--
-- Name: isnt_empty(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_empty(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt_empty( $1, NULL );
$_$;


ALTER FUNCTION public.isnt_empty(text) OWNER TO postgres;

--
-- Name: isnt_empty(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_empty(text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    res  BOOLEAN := FALSE;
    rec  RECORD;
BEGIN
    -- Find extra records.
    FOR rec in EXECUTE _query($1) LOOP
        res := TRUE;
        EXIT;
    END LOOP;

    RETURN ok(res, $2);
END;
$_$;


ALTER FUNCTION public.isnt_empty(text, text) OWNER TO postgres;

--
-- Name: isnt_member_of(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_member_of(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt_member_of( $1, $2, 'Should not have members of role ' || quote_ident($1) );
$_$;


ALTER FUNCTION public.isnt_member_of(name, name[]) OWNER TO postgres;

--
-- Name: isnt_member_of(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_member_of(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt_member_of( $1, ARRAY[$2] );
$_$;


ALTER FUNCTION public.isnt_member_of(name, name) OWNER TO postgres;

--
-- Name: isnt_member_of(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_member_of(name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    extra text[];
BEGIN
    IF NOT _has_role($1) THEN
        RETURN fail( $3 ) || E'\n' || diag (
            '    Role ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    SELECT ARRAY(
        SELECT quote_ident($2[i])
          FROM generate_series(1, array_upper($2, 1)) s(i)
          LEFT JOIN pg_catalog.pg_roles r ON rolname = $2[i]
         WHERE r.oid = ANY ( _grolist($1) )
         ORDER BY s.i
    ) INTO extra;
    IF extra[1] IS NULL THEN
        RETURN ok( true, $3 );
    END IF;
    RETURN ok( false, $3 ) || E'\n' || diag(
        '    Members, who should not be in ' || quote_ident($1) || E' role:\n        ' ||
        array_to_string( extra, E'\n        ')
    );
END;
$_$;


ALTER FUNCTION public.isnt_member_of(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_member_of(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_member_of(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt_member_of( $1, ARRAY[$2], $3 );
$_$;


ALTER FUNCTION public.isnt_member_of(name, name, text) OWNER TO postgres;

--
-- Name: isnt_normal_function(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, NOT _type_func('f', $1),
        'Function ' || quote_ident($1) || '() should not be a normal function'
    );
$_$;


ALTER FUNCTION public.isnt_normal_function(name) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2,
        NOT _type_func('f', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not be a normal function'
    );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, name[]) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, NOT _type_func('f', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not be a normal function'
    );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, name) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, NOT _type_func('f', $1), $2 );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, text) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, NOT _type_func('f', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, NOT _type_func('f', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not be a normal function'
    );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, name, name[]) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, NOT _type_func('f', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, name, text) OWNER TO postgres;

--
-- Name: isnt_normal_function(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_normal_function(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, NOT _type_func('f', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.isnt_normal_function(name, name, name[], text) OWNER TO postgres;

--
-- Name: isnt_partitioned(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_partitioned(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _rexists('p', $1),
        'Table ' || quote_ident($1) || ' should not be partitioned'
    );
$_$;


ALTER FUNCTION public.isnt_partitioned(name) OWNER TO postgres;

--
-- Name: isnt_partitioned(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_partitioned(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _rexists('p', $1, $2),
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should not be partitioned'
    );
$_$;


ALTER FUNCTION public.isnt_partitioned(name, name) OWNER TO postgres;

--
-- Name: isnt_partitioned(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_partitioned(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists('p', $1), $2);
$_$;


ALTER FUNCTION public.isnt_partitioned(name, text) OWNER TO postgres;

--
-- Name: isnt_partitioned(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_partitioned(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _rexists('p', $1, $2), $3);
$_$;


ALTER FUNCTION public.isnt_partitioned(name, name, text) OWNER TO postgres;

--
-- Name: isnt_procedure(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, NOT _type_func('p', $1),
        'Function ' || quote_ident($1) || '() should not be a procedure'
    );
$_$;


ALTER FUNCTION public.isnt_procedure(name) OWNER TO postgres;

--
-- Name: isnt_procedure(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, NOT _type_func('p', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not be a procedure'
    );
$_$;


ALTER FUNCTION public.isnt_procedure(name, name[]) OWNER TO postgres;

--
-- Name: isnt_procedure(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2,  NOT _type_func('p', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not be a procedure'
    );
$_$;


ALTER FUNCTION public.isnt_procedure(name, name) OWNER TO postgres;

--
-- Name: isnt_procedure(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, NOT _type_func('p', $1), $2 );
$_$;


ALTER FUNCTION public.isnt_procedure(name, text) OWNER TO postgres;

--
-- Name: isnt_procedure(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, NOT _type_func('p', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_procedure(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_procedure(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, NOT _type_func('p', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not be a procedure'
    );
$_$;


ALTER FUNCTION public.isnt_procedure(name, name, name[]) OWNER TO postgres;

--
-- Name: isnt_procedure(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, NOT _type_func('p', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_procedure(name, name, text) OWNER TO postgres;

--
-- Name: isnt_procedure(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_procedure(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, NOT _type_func('p', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.isnt_procedure(name, name, name[], text) OWNER TO postgres;

--
-- Name: isnt_strict(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( NOT _strict($1), 'Function ' || quote_ident($1) || '() should not be strict' );
$_$;


ALTER FUNCTION public.isnt_strict(name) OWNER TO postgres;

--
-- Name: isnt_strict(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _strict($1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not be strict'
    );
$_$;


ALTER FUNCTION public.isnt_strict(name, name[]) OWNER TO postgres;

--
-- Name: isnt_strict(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _strict($1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not be strict'
    );
$_$;


ALTER FUNCTION public.isnt_strict(name, name) OWNER TO postgres;

--
-- Name: isnt_strict(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, NOT _strict($1), $2 );
$_$;


ALTER FUNCTION public.isnt_strict(name, text) OWNER TO postgres;

--
-- Name: isnt_strict(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, NOT _strict($1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_strict(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_strict(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok(
        NOT _strict($1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not be strict'
    );
$_$;


ALTER FUNCTION public.isnt_strict(name, name, name[]) OWNER TO postgres;

--
-- Name: isnt_strict(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, NOT _strict($1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_strict(name, name, text) OWNER TO postgres;

--
-- Name: isnt_strict(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_strict(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, NOT _strict($1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.isnt_strict(name, name, name[], text) OWNER TO postgres;

--
-- Name: isnt_superuser(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_superuser(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT isnt_superuser( $1, 'User ' || quote_ident($1) || ' should not be a super user' );
$_$;


ALTER FUNCTION public.isnt_superuser(name) OWNER TO postgres;

--
-- Name: isnt_superuser(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_superuser(name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    is_super boolean := _is_super($1);
BEGIN
    IF is_super IS NULL THEN
        RETURN fail( $2 ) || E'\n' || diag( '    User ' || quote_ident($1) || ' does not exist') ;
    END IF;
    RETURN ok( NOT is_super, $2 );
END;
$_$;


ALTER FUNCTION public.isnt_superuser(name, text) OWNER TO postgres;

--
-- Name: isnt_window(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, NOT _type_func('w', $1),
        'Function ' || quote_ident($1) || '() should not be a window function'
    );
$_$;


ALTER FUNCTION public.isnt_window(name) OWNER TO postgres;

--
-- Name: isnt_window(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        NULL, $1, $2, NOT _type_func('w', $1, $2),
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should not be a window function'
    );
$_$;


ALTER FUNCTION public.isnt_window(name, name[]) OWNER TO postgres;

--
-- Name: isnt_window(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, NOT _type_func('w', $1, $2),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '() should not be a window function'
    );
$_$;


ALTER FUNCTION public.isnt_window(name, name) OWNER TO postgres;

--
-- Name: isnt_window(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, NOT _type_func('w', $1), $2 );
$_$;


ALTER FUNCTION public.isnt_window(name, text) OWNER TO postgres;

--
-- Name: isnt_window(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, NOT _type_func('w', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_window(name, name[], text) OWNER TO postgres;

--
-- Name: isnt_window(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(
        $1, $2, $3, NOT _type_func('w', $1, $2, $3),
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should not be a window function'
    );
$_$;


ALTER FUNCTION public.isnt_window(name, name, name[]) OWNER TO postgres;

--
-- Name: isnt_window(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, NOT _type_func('w', $1, $2), $3 );
$_$;


ALTER FUNCTION public.isnt_window(name, name, text) OWNER TO postgres;

--
-- Name: isnt_window(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isnt_window(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, NOT _type_func('w', $1, $2, $3), $4 );
$_$;


ALTER FUNCTION public.isnt_window(name, name, name[], text) OWNER TO postgres;

--
-- Name: language_is_trusted(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.language_is_trusted(name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT language_is_trusted($1, 'Procedural language ' || quote_ident($1) || ' should be trusted' );
$_$;


ALTER FUNCTION public.language_is_trusted(name) OWNER TO postgres;

--
-- Name: language_is_trusted(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.language_is_trusted(name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    is_trusted boolean := _is_trusted($1);
BEGIN
    IF is_trusted IS NULL THEN
        RETURN fail( $2 ) || E'\n' || diag( '    Procedural language ' || quote_ident($1) || ' does not exist') ;
    END IF;
    RETURN ok( is_trusted, $2 );
END;
$_$;


ALTER FUNCTION public.language_is_trusted(name, text) OWNER TO postgres;

--
-- Name: language_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.language_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT language_owner_is(
        $1, $2,
        'Language ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.language_owner_is(name, name) OWNER TO postgres;

--
-- Name: language_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.language_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_language_owner($1);
BEGIN
    -- Make sure the language exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Language ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.language_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: language_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.language_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT language_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on language ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.language_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: language_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.language_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_lang_privs( $2, quote_ident($1) );
BEGIN
    IF grants[1] = 'undefined_language' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Language ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.language_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: languages_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.languages_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT languages_are( $1, 'There should be the correct procedural languages' );
$_$;


ALTER FUNCTION public.languages_are(name[]) OWNER TO postgres;

--
-- Name: languages_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.languages_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'languages',
        ARRAY(
            SELECT lanname
              FROM pg_catalog.pg_language
             WHERE lanispl
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT lanname
              FROM pg_catalog.pg_language
             WHERE lanispl
        ),
        $2
    );
$_$;


ALTER FUNCTION public.languages_are(name[], text) OWNER TO postgres;

--
-- Name: lives_ok(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lives_ok(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT lives_ok( $1, NULL );
$_$;


ALTER FUNCTION public.lives_ok(text) OWNER TO postgres;

--
-- Name: lives_ok(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lives_ok(text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    code  TEXT := _query($1);
    descr ALIAS FOR $2;
    detail  text;
    hint    text;
    context text;
    schname text;
    tabname text;
    colname text;
    chkname text;
    typname text;
BEGIN
    EXECUTE code;
    RETURN ok( TRUE, descr );
EXCEPTION WHEN OTHERS OR ASSERT_FAILURE THEN
    -- There should have been no exception.
    GET STACKED DIAGNOSTICS
        detail  = PG_EXCEPTION_DETAIL,
        hint    = PG_EXCEPTION_HINT,
        context = PG_EXCEPTION_CONTEXT,
        schname = SCHEMA_NAME,
        tabname = TABLE_NAME,
        colname = COLUMN_NAME,
        chkname = CONSTRAINT_NAME,
        typname = PG_DATATYPE_NAME;
    RETURN ok( FALSE, descr ) || E'\n' || diag(
           '    died: ' || _error_diag(SQLSTATE, SQLERRM, detail, hint, context, schname, tabname, colname, chkname, typname)
    );
END;
$_$;


ALTER FUNCTION public.lives_ok(text, text) OWNER TO postgres;

--
-- Name: matches(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.matches(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~ $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.matches(anyelement, text) OWNER TO postgres;

--
-- Name: matches(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.matches(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _alike( $1 ~ $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.matches(anyelement, text, text) OWNER TO postgres;

--
-- Name: materialized_view_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_view_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT materialized_view_owner_is(
        $1, $2,
        'Materialized view ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.materialized_view_owner_is(name, name) OWNER TO postgres;

--
-- Name: materialized_view_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_view_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT materialized_view_owner_is(
        $1, $2, $3,
        'Materialized view ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.materialized_view_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: materialized_view_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_view_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('m'::char, $1);
BEGIN
    -- Make sure the materialized view exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Materialized view ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.materialized_view_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: materialized_view_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_view_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('m'::char, $1, $2);
BEGIN
    -- Make sure the materialized view exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Materialized view ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.materialized_view_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: materialized_views_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_views_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'Materialized views', _extras('m', $1), _missing('m', $1),
        'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct materialized views'
    );
$_$;


ALTER FUNCTION public.materialized_views_are(name[]) OWNER TO postgres;

--
-- Name: materialized_views_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_views_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'Materialized views', _extras('m', $1), _missing('m', $1), $2);
$_$;


ALTER FUNCTION public.materialized_views_are(name[], text) OWNER TO postgres;

--
-- Name: materialized_views_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_views_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'Materialized views', _extras('m', $1, $2), _missing('m', $1, $2),
        'Schema ' || quote_ident($1) || ' should have the correct materialized views'
    );
$_$;


ALTER FUNCTION public.materialized_views_are(name, name[]) OWNER TO postgres;

--
-- Name: materialized_views_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.materialized_views_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'Materialized views', _extras('m', $1, $2), _missing('m', $1, $2), $3);
$_$;


ALTER FUNCTION public.materialized_views_are(name, name[], text) OWNER TO postgres;

--
-- Name: no_plan(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.no_plan() RETURNS SETOF boolean
    LANGUAGE plpgsql STRICT
    AS $$
BEGIN
    PERFORM plan(0);
    RETURN;
END;
$$;


ALTER FUNCTION public.no_plan() OWNER TO postgres;

--
-- Name: num_failed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.num_failed() RETURNS integer
    LANGUAGE sql STRICT
    AS $$
    SELECT _get('failed');
$$;


ALTER FUNCTION public.num_failed() OWNER TO postgres;

--
-- Name: ok(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ok(boolean) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( $1, NULL );
$_$;


ALTER FUNCTION public.ok(boolean) OWNER TO postgres;

--
-- Name: ok(boolean, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ok(boolean, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
   aok      ALIAS FOR $1;
   descr    text := $2;
   test_num INTEGER;
   todo_why TEXT;
   ok       BOOL;
BEGIN
   todo_why := _todo();
   ok       := CASE
       WHEN aok = TRUE THEN aok
       WHEN todo_why IS NULL THEN COALESCE(aok, false)
       ELSE TRUE
    END;
    IF _get('plan') IS NULL THEN
        RAISE EXCEPTION 'You tried to run a test without a plan! Gotta have a plan';
    END IF;

    test_num := add_result(
        ok,
        COALESCE(aok, false),
        descr,
        CASE WHEN todo_why IS NULL THEN '' ELSE 'todo' END,
        COALESCE(todo_why, '')
    );

    RETURN (CASE aok WHEN TRUE THEN '' ELSE 'not ' END)
           || 'ok ' || _set( 'curr_test', test_num )
           || CASE descr WHEN '' THEN '' ELSE COALESCE( ' - ' || substr(diag( descr ), 3), '' ) END
           || COALESCE( ' ' || diag( 'TODO ' || todo_why ), '')
           || CASE aok WHEN TRUE THEN '' ELSE E'\n' ||
                diag('Failed ' ||
                CASE WHEN todo_why IS NULL THEN '' ELSE '(TODO) ' END ||
                'test ' || test_num ||
                CASE descr WHEN '' THEN '' ELSE COALESCE(': "' || descr || '"', '') END ) ||
                CASE WHEN aok IS NULL THEN E'\n' || diag('    (test result was NULL)') ELSE '' END
           END;
END;
$_$;


ALTER FUNCTION public.ok(boolean, text) OWNER TO postgres;

--
-- Name: opclass_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclass_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT opclass_owner_is(
        $1, $2,
        'Operator class ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.opclass_owner_is(name, name) OWNER TO postgres;

--
-- Name: opclass_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclass_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT opclass_owner_is(
        $1, $2, $3,
        'Operator class ' || quote_ident($1) || '.' || quote_ident($2) ||
        ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.opclass_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: opclass_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclass_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_opclass_owner($1);
BEGIN
    -- Make sure the opclass exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Operator class ' || quote_ident($1) || ' not found'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.opclass_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: opclass_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclass_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_opclass_owner($1, $2);
BEGIN
    -- Make sure the opclass exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Operator class ' || quote_ident($1) || '.' || quote_ident($2)
            || ' not found'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.opclass_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: opclasses_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclasses_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT opclasses_are( $1, 'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct operator classes' );
$_$;


ALTER FUNCTION public.opclasses_are(name[]) OWNER TO postgres;

--
-- Name: opclasses_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclasses_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'operator classes',
        ARRAY(
            SELECT oc.opcname
              FROM pg_catalog.pg_opclass oc
              JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_opclass_is_visible(oc.oid)
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
               FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT oc.opcname
              FROM pg_catalog.pg_opclass oc
              JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_opclass_is_visible(oc.oid)
        ),
        $2
    );
$_$;


ALTER FUNCTION public.opclasses_are(name[], text) OWNER TO postgres;

--
-- Name: opclasses_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclasses_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT opclasses_are( $1, $2, 'Schema ' || quote_ident($1) || ' should have the correct operator classes' );
$_$;


ALTER FUNCTION public.opclasses_are(name, name[]) OWNER TO postgres;

--
-- Name: opclasses_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.opclasses_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'operator classes',
        ARRAY(
            SELECT oc.opcname
              FROM pg_catalog.pg_opclass oc
              JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
             WHERE n.nspname  = $1
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
               FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT oc.opcname
              FROM pg_catalog.pg_opclass oc
              JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
             WHERE n.nspname  = $1
        ),
        $3
    );
$_$;


ALTER FUNCTION public.opclasses_are(name, name[], text) OWNER TO postgres;

--
-- Name: operators_are(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.operators_are(text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT operators_are($1, 'There should be the correct operators')
$_$;


ALTER FUNCTION public.operators_are(text[]) OWNER TO postgres;

--
-- Name: operators_are(text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.operators_are(text[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _areni(
        'operators',
        ARRAY(
            SELECT display_oper(o.oprname, o.oid) || ' RETURNS ' || o.oprresult::regtype
              FROM pg_catalog.pg_operator o
              JOIN pg_catalog.pg_namespace n ON o.oprnamespace = n.oid
             WHERE pg_catalog.pg_operator_is_visible(o.oid)
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT display_oper(o.oprname, o.oid) || ' RETURNS ' || o.oprresult::regtype
              FROM pg_catalog.pg_operator o
              JOIN pg_catalog.pg_namespace n ON o.oprnamespace = n.oid
             WHERE pg_catalog.pg_operator_is_visible(o.oid)
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        ),
        $2
    );
$_$;


ALTER FUNCTION public.operators_are(text[], text) OWNER TO postgres;

--
-- Name: operators_are(name, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.operators_are(name, text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT operators_are($1, $2, 'Schema ' || quote_ident($1) || ' should have the correct operators' );
$_$;


ALTER FUNCTION public.operators_are(name, text[]) OWNER TO postgres;

--
-- Name: operators_are(name, text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.operators_are(name, text[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _areni(
        'operators',
        ARRAY(
            SELECT display_oper(o.oprname, o.oid) || ' RETURNS ' || o.oprresult::regtype
              FROM pg_catalog.pg_operator o
              JOIN pg_catalog.pg_namespace n ON o.oprnamespace = n.oid
             WHERE n.nspname = $1
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT display_oper(o.oprname, o.oid) || ' RETURNS ' || o.oprresult::regtype
              FROM pg_catalog.pg_operator o
              JOIN pg_catalog.pg_namespace n ON o.oprnamespace = n.oid
             WHERE n.nspname = $1
        ),
        $3
    );
$_$;


ALTER FUNCTION public.operators_are(name, text[], text) OWNER TO postgres;

--
-- Name: os_name(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.os_name() RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$SELECT 'win32'::text;$$;


ALTER FUNCTION public.os_name() OWNER TO postgres;

--
-- Name: partitions_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.partitions_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT partitions_are(
        $1, $2,
        'Table ' || quote_ident($1) || ' should have the correct partitions'
    );
$_$;


ALTER FUNCTION public.partitions_are(name, name[]) OWNER TO postgres;

--
-- Name: partitions_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.partitions_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'partitions',
        ARRAY(SELECT _parts($1) EXCEPT SELECT unnest($2)),
        ARRAY(SELECT unnest($2) EXCEPT SELECT _parts($1)),
        $3
    );
$_$;


ALTER FUNCTION public.partitions_are(name, name[], text) OWNER TO postgres;

--
-- Name: partitions_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.partitions_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT partitions_are(
        $1, $2, $3,
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct partitions'
    );
$_$;


ALTER FUNCTION public.partitions_are(name, name, name[]) OWNER TO postgres;

--
-- Name: partitions_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.partitions_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'partitions',
        ARRAY(SELECT _parts($1, $2) EXCEPT SELECT unnest($3)),
        ARRAY(SELECT unnest($3) EXCEPT SELECT _parts($1, $2)),
        $4
    );
$_$;


ALTER FUNCTION public.partitions_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: pass(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pass() RETURNS text
    LANGUAGE sql
    AS $$
    SELECT ok( TRUE, NULL );
$$;


ALTER FUNCTION public.pass() OWNER TO postgres;

--
-- Name: pass(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pass(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( TRUE, $1 );
$_$;


ALTER FUNCTION public.pass(text) OWNER TO postgres;

--
-- Name: performs_ok(text, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.performs_ok(text, numeric) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT performs_ok(
        $1, $2, 'Should run in less than ' || $2 || ' ms'
    );
$_$;


ALTER FUNCTION public.performs_ok(text, numeric) OWNER TO postgres;

--
-- Name: performs_ok(text, numeric, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.performs_ok(text, numeric, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    query     TEXT := _query($1);
    max_time  ALIAS FOR $2;
    descr     ALIAS FOR $3;
    starts_at TEXT;
    act_time  NUMERIC;
BEGIN
    starts_at := timeofday();
    EXECUTE query;
    act_time := extract( millisecond from timeofday()::timestamptz - starts_at::timestamptz);
    IF act_time < max_time THEN RETURN ok(TRUE, descr); END IF;
    RETURN ok( FALSE, descr ) || E'\n' || diag(
           '      runtime: ' || act_time || ' ms' ||
        E'\n      exceeds: ' || max_time || ' ms'
    );
END;
$_$;


ALTER FUNCTION public.performs_ok(text, numeric, text) OWNER TO postgres;

--
-- Name: performs_within(text, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.performs_within(text, numeric, numeric) RETURNS text
    LANGUAGE sql
    AS $_$
SELECT performs_within(
          $1, $2, $3, 10,
          'Should run within ' || $2 || ' +/- ' || $3 || ' ms');
$_$;


ALTER FUNCTION public.performs_within(text, numeric, numeric) OWNER TO postgres;

--
-- Name: performs_within(text, numeric, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.performs_within(text, numeric, numeric, integer) RETURNS text
    LANGUAGE sql
    AS $_$
SELECT performs_within(
          $1, $2, $3, $4,
          'Should run within ' || $2 || ' +/- ' || $3 || ' ms');
$_$;


ALTER FUNCTION public.performs_within(text, numeric, numeric, integer) OWNER TO postgres;

--
-- Name: performs_within(text, numeric, numeric, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.performs_within(text, numeric, numeric, text) RETURNS text
    LANGUAGE sql
    AS $_$
SELECT performs_within(
          $1, $2, $3, 10, $4
        );
$_$;


ALTER FUNCTION public.performs_within(text, numeric, numeric, text) OWNER TO postgres;

--
-- Name: performs_within(text, numeric, numeric, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.performs_within(text, numeric, numeric, integer, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    query          TEXT := _query($1);
    expected_avg   ALIAS FOR $2;
    within         ALIAS FOR $3;
    iterations     ALIAS FOR $4;
    descr          ALIAS FOR $5;
    avg_time       NUMERIC;
BEGIN
  SELECT avg(a_time) FROM _time_trials(query, iterations, 0.8) t1 INTO avg_time;
  IF abs(avg_time - expected_avg) < within THEN RETURN ok(TRUE, descr); END IF;
  RETURN ok(FALSE, descr) || E'\n' || diag(' average runtime: ' || avg_time || ' ms'
     || E'\n desired average: ' || expected_avg || ' +/- ' || within || ' ms'
    );
END;
$_$;


ALTER FUNCTION public.performs_within(text, numeric, numeric, integer, text) OWNER TO postgres;

--
-- Name: pg_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_version() RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$SELECT current_setting('server_version')$$;


ALTER FUNCTION public.pg_version() OWNER TO postgres;

--
-- Name: pg_version_num(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_version_num() RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT current_setting('server_version_num')::integer;
$$;


ALTER FUNCTION public.pg_version_num() OWNER TO postgres;

--
-- Name: plan(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.plan(integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
    rcount INTEGER;
BEGIN
    BEGIN
        EXECUTE '
            CREATE TEMP SEQUENCE __tcache___id_seq;
            CREATE TEMP TABLE __tcache__ (
                id    INTEGER NOT NULL DEFAULT nextval(''__tcache___id_seq''),
                label TEXT    NOT NULL,
                value INTEGER NOT NULL,
                note  TEXT    NOT NULL DEFAULT ''''
            );
            CREATE UNIQUE INDEX __tcache___key ON __tcache__(id);
            GRANT ALL ON TABLE __tcache__ TO PUBLIC;
            GRANT ALL ON TABLE __tcache___id_seq TO PUBLIC;

            CREATE TEMP SEQUENCE __tresults___numb_seq;
            GRANT ALL ON TABLE __tresults___numb_seq TO PUBLIC;
        ';

    EXCEPTION WHEN duplicate_table THEN
        -- Raise an exception if there's already a plan.
        EXECUTE 'SELECT TRUE FROM __tcache__ WHERE label = ''plan''';
      GET DIAGNOSTICS rcount = ROW_COUNT;
        IF rcount > 0 THEN
           RAISE EXCEPTION 'You tried to plan twice!';
        END IF;
    END;

    -- Save the plan and return.
    PERFORM _set('plan', $1 );
    PERFORM _set('failed', 0 );
    RETURN '1..' || $1;
END;
$_$;


ALTER FUNCTION public.plan(integer) OWNER TO postgres;

--
-- Name: policies_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policies_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT policies_are( $1, $2, 'Table ' || quote_ident($1) || ' should have the correct policies' );
$_$;


ALTER FUNCTION public.policies_are(name, name[]) OWNER TO postgres;

--
-- Name: policies_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policies_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'policies',
        ARRAY(
            SELECT p.polname
              FROM pg_catalog.pg_policy p
              JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             WHERE c.relname = $1
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT p.polname
              FROM pg_catalog.pg_policy p
              JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        ),
        $3
    );
$_$;


ALTER FUNCTION public.policies_are(name, name[], text) OWNER TO postgres;

--
-- Name: policies_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policies_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT policies_are( $1, $2, $3, 'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct policies' );
$_$;


ALTER FUNCTION public.policies_are(name, name, name[]) OWNER TO postgres;

--
-- Name: policies_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policies_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'policies',
        ARRAY(
            SELECT p.polname
              FROM pg_catalog.pg_policy p
              JOIN pg_catalog.pg_class c     ON c.oid = p.polrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = $1
               AND c.relname = $2
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
        ),
        ARRAY(
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT p.polname
              FROM pg_catalog.pg_policy p
              JOIN pg_catalog.pg_class c     ON c.oid = p.polrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = $1
               AND c.relname = $2
        ),
        $4
    );
$_$;


ALTER FUNCTION public.policies_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: policy_cmd_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_cmd_is(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT policy_cmd_is(
        $1, $2, $3,
        'Policy ' || quote_ident($2)
        || ' for table ' || quote_ident($1)
        || ' should apply to ' || upper($3) || ' command'
    );
$_$;


ALTER FUNCTION public.policy_cmd_is(name, name, text) OWNER TO postgres;

--
-- Name: policy_cmd_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_cmd_is(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT policy_cmd_is(
        $1, $2, $3, $4,
        'Policy ' || quote_ident($3)
        || ' for table ' || quote_ident($1) || '.' || quote_ident($2)
        || ' should apply to ' || upper($4) || ' command'
    );
$_$;


ALTER FUNCTION public.policy_cmd_is(name, name, name, text) OWNER TO postgres;

--
-- Name: policy_cmd_is(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_cmd_is(name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cmd text;
BEGIN
    SELECT
      CASE pp.polcmd WHEN 'r' THEN 'SELECT'
                     WHEN 'a' THEN 'INSERT'
                     WHEN 'w' THEN 'UPDATE'
                     WHEN 'd' THEN 'DELETE'
                     ELSE 'ALL'
       END
      FROM pg_catalog.pg_policy AS pp
      JOIN pg_catalog.pg_class AS pc ON pc.oid = pp.polrelid
      JOIN pg_catalog.pg_namespace AS pn ON pn.oid = pc.relnamespace
     WHERE pc.relname = $1
       AND pp.polname = $2
       AND pn.nspname NOT IN ('pg_catalog', 'information_schema')
      INTO cmd;

    RETURN is( cmd, upper($3), $4 );
END;
$_$;


ALTER FUNCTION public.policy_cmd_is(name, name, text, text) OWNER TO postgres;

--
-- Name: policy_cmd_is(name, name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_cmd_is(name, name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cmd text;
BEGIN
    SELECT
      CASE pp.polcmd WHEN 'r' THEN 'SELECT'
                     WHEN 'a' THEN 'INSERT'
                     WHEN 'w' THEN 'UPDATE'
                     WHEN 'd' THEN 'DELETE'
                     ELSE 'ALL'
       END
      FROM pg_catalog.pg_policy AS pp
      JOIN pg_catalog.pg_class AS pc ON pc.oid = pp.polrelid
      JOIN pg_catalog.pg_namespace AS pn ON pn.oid = pc.relnamespace
     WHERE pn.nspname = $1
       AND pc.relname = $2
       AND pp.polname = $3
      INTO cmd;

    RETURN is( cmd, upper($4), $5 );
END;
$_$;


ALTER FUNCTION public.policy_cmd_is(name, name, name, text, text) OWNER TO postgres;

--
-- Name: policy_roles_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_roles_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT policy_roles_are( $1, $2, $3, 'Policy ' || quote_ident($2) || ' for table ' || quote_ident($1) || ' should have the correct roles' );
$_$;


ALTER FUNCTION public.policy_roles_are(name, name, name[]) OWNER TO postgres;

--
-- Name: policy_roles_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_roles_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'policy roles',
        ARRAY(
            SELECT pr.rolname
              FROM pg_catalog.pg_policy AS pp
              JOIN pg_catalog.pg_roles AS pr ON pr.oid = ANY (pp.polroles)
              JOIN pg_catalog.pg_class AS pc ON pc.oid = pp.polrelid
              JOIN pg_catalog.pg_namespace AS pn ON pn.oid = pc.relnamespace
             WHERE pc.relname = $1
               AND pp.polname = $2
               AND pn.nspname NOT IN ('pg_catalog', 'information_schema')
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
        ),
        ARRAY(
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT pr.rolname
              FROM pg_catalog.pg_policy AS pp
              JOIN pg_catalog.pg_roles AS pr ON pr.oid = ANY (pp.polroles)
              JOIN pg_catalog.pg_class AS pc ON pc.oid = pp.polrelid
              JOIN pg_catalog.pg_namespace AS pn ON pn.oid = pc.relnamespace
             WHERE pc.relname = $1
               AND pp.polname = $2
               AND pn.nspname NOT IN ('pg_catalog', 'information_schema')
        ),
        $4
    );
$_$;


ALTER FUNCTION public.policy_roles_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: policy_roles_are(name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_roles_are(name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT policy_roles_are( $1, $2, $3, $4, 'Policy ' || quote_ident($3) || ' for table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct roles' );
$_$;


ALTER FUNCTION public.policy_roles_are(name, name, name, name[]) OWNER TO postgres;

--
-- Name: policy_roles_are(name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.policy_roles_are(name, name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'policy roles',
        ARRAY(
            SELECT pr.rolname
              FROM pg_catalog.pg_policy AS pp
              JOIN pg_catalog.pg_roles AS pr ON pr.oid = ANY (pp.polroles)
              JOIN pg_catalog.pg_class AS pc ON pc.oid = pp.polrelid
              JOIN pg_catalog.pg_namespace AS pn ON pn.oid = pc.relnamespace
             WHERE pn.nspname = $1
               AND pc.relname = $2
               AND pp.polname = $3
            EXCEPT
            SELECT $4[i]
              FROM generate_series(1, array_upper($4, 1)) s(i)
        ),
        ARRAY(
            SELECT $4[i]
              FROM generate_series(1, array_upper($4, 1)) s(i)
            EXCEPT
            SELECT pr.rolname
              FROM pg_catalog.pg_policy AS pp
              JOIN pg_catalog.pg_roles AS pr ON pr.oid = ANY (pp.polroles)
              JOIN pg_catalog.pg_class AS pc ON pc.oid = pp.polrelid
              JOIN pg_catalog.pg_namespace AS pn ON pn.oid = pc.relnamespace
             WHERE pn.nspname = $1
               AND pc.relname = $2
               AND pp.polname = $3
        ),
        $5
    );
$_$;


ALTER FUNCTION public.policy_roles_are(name, name, name, name[], text) OWNER TO postgres;

--
-- Name: pos_to_tile_id(integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pos_to_tile_id(zoom_level integer, lat double precision, lng double precision) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
	tile_x INT;
	tile_y INT;
	x_id BIGINT;
	y_id BIGINT;
BEGIN
	tile_x := FLOOR((LEAST(lng+180.0,360.0)/360.0)*(POWER(2.0, zoom_level)));
	tile_y := FLOOR((LEAST(lat+90.0,180.0)/180.0)*(POWER(2.0, zoom_level)));
	IF lng >= 180.0 THEN
		tile_x := tile_x-1;
	END IF;
	IF lat>=90.0 THEN
		tile_y := tile_y-1;
	END IF;
	x_id := tile_x::BIGINT;
	y_id := tile_y::BIGINT;
	
	x_id := (x_id | (x_id << 16)) & x'0000FFFF0000FFFF'::BIGINT;
	x_id := (x_id | (x_id << 8))  & x'00FF00FF00FF00FF'::BIGINT;
	x_id := (x_id | (x_id << 4))  & x'0F0F0F0F0F0F0F0F'::BIGINT;
	x_id := (x_id | (x_id << 2))  & x'3333333333333333'::BIGINT;
	x_id := (x_id | (x_id << 1))  & x'5555555555555555'::BIGINT;
	
	y_id := (y_id | (y_id << 16)) & x'0000FFFF0000FFFF'::BIGINT;
	y_id := (y_id | (y_id << 8))  & x'00FF00FF00FF00FF'::BIGINT;
	y_id := (y_id | (y_id << 4))  & x'0F0F0F0F0F0F0F0F'::BIGINT;
	y_id := (y_id | (y_id << 2))  & x'3333333333333333'::BIGINT;
	y_id := (y_id | (y_id << 1))  & x'5555555555555555'::BIGINT;
	
	RETURN ((1::BIGINT << (2 * zoom_level)) | (y_id << 1) | x_id);
END;
$$;


ALTER FUNCTION public.pos_to_tile_id(zoom_level integer, lat double precision, lng double precision) OWNER TO postgres;

--
-- Name: reconstruct_geom(text, public.geometry_dump[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reconstruct_geom(geom_type text, geom_dump public.geometry_dump[]) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN (SELECT 
    CASE geom_type
        WHEN 'ST_LineString' THEN ST_MakeLine(d.geom ORDER BY d.path)
        WHEN 'ST_Polygon'    THEN ST_MakePolygon(ST_MakeLine(d.geom ORDER BY d.path))
        WHEN 'ST_MultiPoint' THEN ST_Collect(d.geom ORDER BY d.path)
        ELSE ST_Collect(d.geom)
    END
	FROM UNNEST(geom_dump) AS d);
END;
$$;


ALTER FUNCTION public.reconstruct_geom(geom_type text, geom_dump public.geometry_dump[]) OWNER TO postgres;

--
-- Name: relation_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.relation_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT relation_owner_is(
        $1, $2,
        'Relation ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.relation_owner_is(name, name) OWNER TO postgres;

--
-- Name: relation_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.relation_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT relation_owner_is(
        $1, $2, $3,
        'Relation ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.relation_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: relation_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.relation_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner($1);
BEGIN
    -- Make sure the relation exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Relation ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.relation_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: relation_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.relation_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner($1, $2);
BEGIN
    -- Make sure the relation exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Relation ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.relation_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: results_eq(refcursor, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(refcursor, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_eq( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_eq(refcursor, anyarray) OWNER TO postgres;

--
-- Name: results_eq(refcursor, refcursor); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(refcursor, refcursor) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_eq( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_eq(refcursor, refcursor) OWNER TO postgres;

--
-- Name: results_eq(refcursor, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(refcursor, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_eq( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_eq(refcursor, text) OWNER TO postgres;

--
-- Name: results_eq(text, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(text, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_eq( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_eq(text, anyarray) OWNER TO postgres;

--
-- Name: results_eq(text, refcursor); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(text, refcursor) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_eq( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_eq(text, refcursor) OWNER TO postgres;

--
-- Name: results_eq(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_eq( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_eq(text, text) OWNER TO postgres;

--
-- Name: results_eq(refcursor, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(refcursor, anyarray, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_eq($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_eq(refcursor, anyarray, text) OWNER TO postgres;

--
-- Name: results_eq(refcursor, refcursor, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(refcursor, refcursor, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have       ALIAS FOR $1;
    want       ALIAS FOR $2;
    have_rec   RECORD;
    want_rec   RECORD;
    have_found BOOLEAN;
    want_found BOOLEAN;
    rownum     INTEGER := 1;
    err_msg    text := 'details not available in pg <= 9.1';
BEGIN
    FETCH have INTO have_rec;
    have_found := FOUND;
    FETCH want INTO want_rec;
    want_found := FOUND;
    WHILE have_found OR want_found LOOP
        IF have_rec IS DISTINCT FROM want_rec OR have_found <> want_found THEN
            RETURN ok( false, $3 ) || E'\n' || diag(
                '    Results differ beginning at row ' || rownum || E':\n' ||
                '        have: ' || CASE WHEN have_found THEN have_rec::text ELSE 'NULL' END || E'\n' ||
                '        want: ' || CASE WHEN want_found THEN want_rec::text ELSE 'NULL' END
            );
        END IF;
        rownum = rownum + 1;
        FETCH have INTO have_rec;
        have_found := FOUND;
        FETCH want INTO want_rec;
        want_found := FOUND;
    END LOOP;

    RETURN ok( true, $3 );
EXCEPTION
    WHEN datatype_mismatch THEN
        GET STACKED DIAGNOSTICS err_msg = MESSAGE_TEXT;
        RETURN ok( false, $3 ) || E'\n' || diag(
            E'    Number of columns or their types differ between the queries' ||
            CASE WHEN have_rec::TEXT = want_rec::text THEN '' ELSE E':\n' ||
                '        have: ' || CASE WHEN have_found THEN have_rec::text ELSE 'NULL' END || E'\n' ||
                '        want: ' || CASE WHEN want_found THEN want_rec::text ELSE 'NULL' END
            END || E'\n        ERROR: ' || err_msg
        );
END;
$_$;


ALTER FUNCTION public.results_eq(refcursor, refcursor, text) OWNER TO postgres;

--
-- Name: results_eq(refcursor, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(refcursor, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR EXECUTE _query($2);
    res := results_eq($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_eq(refcursor, text, text) OWNER TO postgres;

--
-- Name: results_eq(text, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(text, anyarray, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_eq(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_eq(text, anyarray, text) OWNER TO postgres;

--
-- Name: results_eq(text, refcursor, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(text, refcursor, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    res := results_eq(have, $2, $3);
    CLOSE have;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_eq(text, refcursor, text) OWNER TO postgres;

--
-- Name: results_eq(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_eq(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR EXECUTE _query($2);
    res := results_eq(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_eq(text, text, text) OWNER TO postgres;

--
-- Name: results_ne(refcursor, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(refcursor, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_ne( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_ne(refcursor, anyarray) OWNER TO postgres;

--
-- Name: results_ne(refcursor, refcursor); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(refcursor, refcursor) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_ne( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_ne(refcursor, refcursor) OWNER TO postgres;

--
-- Name: results_ne(refcursor, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(refcursor, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_ne( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_ne(refcursor, text) OWNER TO postgres;

--
-- Name: results_ne(text, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(text, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_ne( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_ne(text, anyarray) OWNER TO postgres;

--
-- Name: results_ne(text, refcursor); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(text, refcursor) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_ne( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_ne(text, refcursor) OWNER TO postgres;

--
-- Name: results_ne(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT results_ne( $1, $2, NULL::text );
$_$;


ALTER FUNCTION public.results_ne(text, text) OWNER TO postgres;

--
-- Name: results_ne(refcursor, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(refcursor, anyarray, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_ne($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_ne(refcursor, anyarray, text) OWNER TO postgres;

--
-- Name: results_ne(refcursor, refcursor, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(refcursor, refcursor, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have       ALIAS FOR $1;
    want       ALIAS FOR $2;
    have_rec   RECORD;
    want_rec   RECORD;
    have_found BOOLEAN;
    want_found BOOLEAN;
    err_msg    text := 'details not available in pg <= 9.1';
BEGIN
    FETCH have INTO have_rec;
    have_found := FOUND;
    FETCH want INTO want_rec;
    want_found := FOUND;
    WHILE have_found OR want_found LOOP
        IF have_rec IS DISTINCT FROM want_rec OR have_found <> want_found THEN
            RETURN ok( true, $3 );
        ELSE
            FETCH have INTO have_rec;
            have_found := FOUND;
            FETCH want INTO want_rec;
            want_found := FOUND;
        END IF;
    END LOOP;
    RETURN ok( false, $3 );
EXCEPTION
    WHEN datatype_mismatch THEN
        GET STACKED DIAGNOSTICS err_msg = MESSAGE_TEXT;
        RETURN ok( false, $3 ) || E'\n' || diag(
            E'    Number of columns or their types differ between the queries' ||
            CASE WHEN have_rec::TEXT = want_rec::text THEN '' ELSE E':\n' ||
                '        have: ' || CASE WHEN have_found THEN have_rec::text ELSE 'NULL' END || E'\n' ||
                '        want: ' || CASE WHEN want_found THEN want_rec::text ELSE 'NULL' END
            END || E'\n        ERROR: ' || err_msg
        );
END;
$_$;


ALTER FUNCTION public.results_ne(refcursor, refcursor, text) OWNER TO postgres;

--
-- Name: results_ne(refcursor, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(refcursor, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN want FOR EXECUTE _query($2);
    res := results_ne($1, want, $3);
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_ne(refcursor, text, text) OWNER TO postgres;

--
-- Name: results_ne(text, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(text, anyarray, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR SELECT $2[i]
    FROM generate_series(array_lower($2, 1), array_upper($2, 1)) s(i);
    res := results_ne(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_ne(text, anyarray, text) OWNER TO postgres;

--
-- Name: results_ne(text, refcursor, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(text, refcursor, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    res := results_ne(have, $2, $3);
    CLOSE have;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_ne(text, refcursor, text) OWNER TO postgres;

--
-- Name: results_ne(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.results_ne(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    have REFCURSOR;
    want REFCURSOR;
    res  TEXT;
BEGIN
    OPEN have FOR EXECUTE _query($1);
    OPEN want FOR EXECUTE _query($2);
    res := results_ne(have, want, $3);
    CLOSE have;
    CLOSE want;
    RETURN res;
END;
$_$;


ALTER FUNCTION public.results_ne(text, text, text) OWNER TO postgres;

--
-- Name: roles_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.roles_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT roles_are( $1, 'There should be the correct roles' );
$_$;


ALTER FUNCTION public.roles_are(name[]) OWNER TO postgres;

--
-- Name: roles_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.roles_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'roles',
        ARRAY(
            SELECT rolname
              FROM pg_catalog.pg_roles
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT rolname
              FROM pg_catalog.pg_roles
        ),
        $2
    );
$_$;


ALTER FUNCTION public.roles_are(name[], text) OWNER TO postgres;

--
-- Name: row_eq(text, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.row_eq(text, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT row_eq($1, $2, NULL );
$_$;


ALTER FUNCTION public.row_eq(text, anyelement) OWNER TO postgres;

--
-- Name: row_eq(text, anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.row_eq(text, anyelement, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    rec    RECORD;
BEGIN
    EXECUTE _query($1) INTO rec;
    IF NOT rec IS DISTINCT FROM $2 THEN RETURN ok(true, $3); END IF;
    RETURN ok(false, $3 ) || E'\n' || diag(
           '        have: ' || CASE WHEN rec IS NULL THEN 'NULL' ELSE rec::text END ||
        E'\n        want: ' || CASE WHEN $2  IS NULL THEN 'NULL' ELSE $2::text  END
    );
END;
$_$;


ALTER FUNCTION public.row_eq(text, anyelement, text) OWNER TO postgres;

--
-- Name: rule_is_instead(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_instead(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT rule_is_instead($1, $2, 'Rule ' || quote_ident($2) || ' on relation ' || quote_ident($1) || ' should be an INSTEAD rule' );
$_$;


ALTER FUNCTION public.rule_is_instead(name, name) OWNER TO postgres;

--
-- Name: rule_is_instead(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_instead(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT rule_is_instead( $1, $2, $3, 'Rule ' || quote_ident($3) || ' on relation ' || quote_ident($1) || '.' || quote_ident($2) || ' should be an INSTEAD rule' );
$_$;


ALTER FUNCTION public.rule_is_instead(name, name, name) OWNER TO postgres;

--
-- Name: rule_is_instead(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_instead(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    is_it boolean := _is_instead($1, $2);
BEGIN
    IF is_it IS NOT NULL THEN RETURN ok( is_it, $3 ); END IF;
    RETURN ok( FALSE, $3 ) || E'\n' || diag(
        '    Rule ' || quote_ident($2) || ' does not exist'
    );
END;
$_$;


ALTER FUNCTION public.rule_is_instead(name, name, text) OWNER TO postgres;

--
-- Name: rule_is_instead(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_instead(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    is_it boolean := _is_instead($1, $2, $3);
BEGIN
    IF is_it IS NOT NULL THEN RETURN ok( is_it, $4 ); END IF;
    RETURN ok( FALSE, $4 ) || E'\n' || diag(
        '    Rule ' || quote_ident($3) || ' does not exist'
    );
END;
$_$;


ALTER FUNCTION public.rule_is_instead(name, name, name, text) OWNER TO postgres;

--
-- Name: rule_is_on(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_on(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT rule_is_on(
        $1, $2, $3,
        'Rule ' || quote_ident($2) || ' should be on '
        || _expand_on(_contract_on($3)::char) || ' to ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.rule_is_on(name, name, text) OWNER TO postgres;

--
-- Name: rule_is_on(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_on(name, name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT rule_is_on(
        $1, $2, $3, $4,
        'Rule ' || quote_ident($3) || ' should be on ' || _expand_on(_contract_on($4)::char)
        || ' to ' || quote_ident($1) || '.' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.rule_is_on(name, name, name, text) OWNER TO postgres;

--
-- Name: rule_is_on(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_on(name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want char := _contract_on($3);
    have char := _rule_on($1, $2);
BEGIN
    IF have IS NOT NULL THEN
        RETURN is( _expand_on(have), _expand_on(want), $4 );
    END IF;

    RETURN ok( false, $4 ) || E'\n' || diag(
        '    Rule ' || quote_ident($2) || ' does not exist on '
        || quote_ident($1)
    );
END;
$_$;


ALTER FUNCTION public.rule_is_on(name, name, text, text) OWNER TO postgres;

--
-- Name: rule_is_on(name, name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rule_is_on(name, name, name, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    want char := _contract_on($4);
    have char := _rule_on($1, $2, $3);
BEGIN
    IF have IS NOT NULL THEN
        RETURN is( _expand_on(have), _expand_on(want), $5 );
    END IF;

    RETURN ok( false, $5 ) || E'\n' || diag(
        '    Rule ' || quote_ident($3) || ' does not exist on '
        || quote_ident($1) || '.' || quote_ident($2)
    );
END;
$_$;


ALTER FUNCTION public.rule_is_on(name, name, name, text, text) OWNER TO postgres;

--
-- Name: rules_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rules_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT rules_are( $1, $2, 'Relation ' || quote_ident($1) || ' should have the correct rules' );
$_$;


ALTER FUNCTION public.rules_are(name, name[]) OWNER TO postgres;

--
-- Name: rules_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rules_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'rules',
        ARRAY(
            SELECT r.rulename
              FROM pg_catalog.pg_rewrite r
              JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
              JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
             WHERE c.relname = $1
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_table_is_visible(c.oid)
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT r.rulename
              FROM pg_catalog.pg_rewrite r
              JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
              JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
               AND c.relname = $1
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND pg_catalog.pg_table_is_visible(c.oid)
        ),
        $3
    );
$_$;


ALTER FUNCTION public.rules_are(name, name[], text) OWNER TO postgres;

--
-- Name: rules_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rules_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT rules_are( $1, $2, $3, 'Relation ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct rules' );
$_$;


ALTER FUNCTION public.rules_are(name, name, name[]) OWNER TO postgres;

--
-- Name: rules_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rules_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'rules',
        ARRAY(
            SELECT r.rulename
              FROM pg_catalog.pg_rewrite r
              JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
              JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
             WHERE c.relname = $2
               AND n.nspname = $1
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
        ),
        ARRAY(
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT r.rulename
              FROM pg_catalog.pg_rewrite r
              JOIN pg_catalog.pg_class c     ON c.oid = r.ev_class
              JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
             WHERE c.relname = $2
               AND n.nspname = $1
        ),
        $4
    );
$_$;


ALTER FUNCTION public.rules_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: runtests(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.runtests() RETURNS SETOF text
    LANGUAGE sql
    AS $$
    SELECT * FROM runtests( '^test' );
$$;


ALTER FUNCTION public.runtests() OWNER TO postgres;

--
-- Name: runtests(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.runtests(name) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM runtests( $1, '^test' );
$_$;


ALTER FUNCTION public.runtests(name) OWNER TO postgres;

--
-- Name: runtests(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.runtests(text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM _runner(
        findfuncs( '^startup' ),
        findfuncs( '^shutdown' ),
        findfuncs( '^setup' ),
        findfuncs( '^teardown' ),
        findfuncs( $1, '^(startup|shutdown|setup|teardown)' )
    );
$_$;


ALTER FUNCTION public.runtests(text) OWNER TO postgres;

--
-- Name: runtests(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.runtests(name, text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
    SELECT * FROM _runner(
        findfuncs( $1, '^startup' ),
        findfuncs( $1, '^shutdown' ),
        findfuncs( $1, '^setup' ),
        findfuncs( $1, '^teardown' ),
        findfuncs( $1, $2, '^(startup|shutdown|setup|teardown)' )
    );
$_$;


ALTER FUNCTION public.runtests(name, text) OWNER TO postgres;

--
-- Name: schema_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schema_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT schema_owner_is(
        $1, $2,
        'Schema ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.schema_owner_is(name, name) OWNER TO postgres;

--
-- Name: schema_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schema_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_schema_owner($1);
BEGIN
    -- Make sure the schema exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Schema ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.schema_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: schema_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schema_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT schema_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on schema ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.schema_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: schema_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schema_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_schema_privs( $2, $1::TEXT );
BEGIN
    IF grants[1] = 'invalid_schema_name' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Schema ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.schema_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: schemas_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schemas_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT schemas_are( $1, 'There should be the correct schemas' );
$_$;


ALTER FUNCTION public.schemas_are(name[]) OWNER TO postgres;

--
-- Name: schemas_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schemas_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'schemas',
        ARRAY(
            SELECT nspname
              FROM pg_catalog.pg_namespace
             WHERE nspname NOT LIKE 'pg\_%'
               AND nspname <> 'information_schema'
             EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT nspname
              FROM pg_catalog.pg_namespace
             WHERE nspname NOT LIKE 'pg\_%'
               AND nspname <> 'information_schema'
        ),
        $2
    );
$_$;


ALTER FUNCTION public.schemas_are(name[], text) OWNER TO postgres;

--
-- Name: select_tiles_intersecting_geom(bigint[], public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_tiles_intersecting_geom(tile_ids bigint[], geom public.geometry) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	results BIGINT[];
BEGIN
	SELECT ARRAY_AGG(tile_id) INTO results FROM UNNEST(tile_ids) AS t(tile_id) WHERE ST_Intersects(geom, ST_SetSRID(get_tile_bbox(tile_id)::geometry, 4326));
	RETURN results;
END;
$$;


ALTER FUNCTION public.select_tiles_intersecting_geom(tile_ids bigint[], geom public.geometry) OWNER TO postgres;

--
-- Name: sequence_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT sequence_owner_is(
        $1, $2,
        'Sequence ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.sequence_owner_is(name, name) OWNER TO postgres;

--
-- Name: sequence_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT sequence_owner_is(
        $1, $2, $3,
        'Sequence ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.sequence_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: sequence_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('S'::char, $1);
BEGIN
    -- Make sure the sequence exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Sequence ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.sequence_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: sequence_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('S'::char, $1, $2);
BEGIN
    -- Make sure the sequence exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Sequence ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.sequence_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: sequence_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT sequence_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on sequence ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.sequence_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: sequence_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_sequence_privs( $2, quote_ident($1) );
BEGIN
    IF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Sequence ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.sequence_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: sequence_privs_are(name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_privs_are(name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT sequence_privs_are(
        $1, $2, $3, $4,
        'Role ' || quote_ident($3) || ' should be granted '
            || CASE WHEN $4[1] IS NULL THEN 'no privileges' ELSE array_to_string($4, ', ') END
            || ' on sequence '|| quote_ident($1) || '.' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.sequence_privs_are(name, name, name, name[]) OWNER TO postgres;

--
-- Name: sequence_privs_are(name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequence_privs_are(name, name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_sequence_privs( $3, quote_ident($1) || '.' || quote_ident($2) );
BEGIN
    IF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Sequence ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Role ' || quote_ident($3) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $4, $5);
END;
$_$;


ALTER FUNCTION public.sequence_privs_are(name, name, name, name[], text) OWNER TO postgres;

--
-- Name: sequences_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequences_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'sequences', _extras('S', $1), _missing('S', $1),
        'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct sequences'
    );
$_$;


ALTER FUNCTION public.sequences_are(name[]) OWNER TO postgres;

--
-- Name: sequences_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequences_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'sequences', _extras('S', $1), _missing('S', $1), $2);
$_$;


ALTER FUNCTION public.sequences_are(name[], text) OWNER TO postgres;

--
-- Name: sequences_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequences_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'sequences', _extras('S', $1, $2), _missing('S', $1, $2),
        'Schema ' || quote_ident($1) || ' should have the correct sequences'
    );
$_$;


ALTER FUNCTION public.sequences_are(name, name[]) OWNER TO postgres;

--
-- Name: sequences_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sequences_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'sequences', _extras('S', $1, $2), _missing('S', $1, $2), $3);
$_$;


ALTER FUNCTION public.sequences_are(name, name[], text) OWNER TO postgres;

--
-- Name: server_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.server_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT server_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on server ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.server_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: server_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.server_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_server_privs( $2, $1::TEXT );
BEGIN
    IF grants[1] = 'undefined_server' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Server ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.server_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: set_eq(text, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_eq(text, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::text, '' );
$_$;


ALTER FUNCTION public.set_eq(text, anyarray) OWNER TO postgres;

--
-- Name: set_eq(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_eq(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::text, '' );
$_$;


ALTER FUNCTION public.set_eq(text, text) OWNER TO postgres;

--
-- Name: set_eq(text, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_eq(text, anyarray, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, '' );
$_$;


ALTER FUNCTION public.set_eq(text, anyarray, text) OWNER TO postgres;

--
-- Name: set_eq(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_eq(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, '' );
$_$;


ALTER FUNCTION public.set_eq(text, text, text) OWNER TO postgres;

--
-- Name: set_has(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_has(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'EXCEPT', 'Missing' );
$_$;


ALTER FUNCTION public.set_has(text, text) OWNER TO postgres;

--
-- Name: set_has(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_has(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, 'EXCEPT', 'Missing' );
$_$;


ALTER FUNCTION public.set_has(text, text, text) OWNER TO postgres;

--
-- Name: set_hasnt(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_hasnt(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, NULL::TEXT, 'INTERSECT', 'Extra' );
$_$;


ALTER FUNCTION public.set_hasnt(text, text) OWNER TO postgres;

--
-- Name: set_hasnt(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_hasnt(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relcomp( $1, $2, $3, 'INTERSECT', 'Extra' );
$_$;


ALTER FUNCTION public.set_hasnt(text, text, text) OWNER TO postgres;

--
-- Name: set_ne(text, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ne(text, anyarray) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, NULL::text, '' );
$_$;


ALTER FUNCTION public.set_ne(text, anyarray) OWNER TO postgres;

--
-- Name: set_ne(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ne(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, NULL::text, '' );
$_$;


ALTER FUNCTION public.set_ne(text, text) OWNER TO postgres;

--
-- Name: set_ne(text, anyarray, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ne(text, anyarray, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, $3, '' );
$_$;


ALTER FUNCTION public.set_ne(text, anyarray, text) OWNER TO postgres;

--
-- Name: set_ne(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ne(text, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _relne( $1, $2, $3, '' );
$_$;


ALTER FUNCTION public.set_ne(text, text, text) OWNER TO postgres;

--
-- Name: shift_ways_nodes_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.shift_ways_nodes_sequence() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Shift sequence_id up by 1 for all existing nodes in the same way_id 
    -- that are at or after the new sequence_id
    UPDATE WaysNodes
    SET sequence_id = sequence_id + 1
    WHERE way_id = NEW.way_id 
      AND sequence_id >= NEW.sequence_id;

    -- Proceed with inserting the NEW row as requested
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.shift_ways_nodes_sequence() OWNER TO postgres;

--
-- Name: simple_wrap(public.geometry, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.simple_wrap(geom public.geometry, wrap numeric, move numeric) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
BEGIN
	return reconstruct_geom(
				ST_GeometryType(geom),
				ARRAY(
				    SELECT ROW(
				        p.path, 
				        ST_SetSRID(
				            ST_MakePoint(
				                CASE 
				                    WHEN ST_X(p.geom) < wrap THEN ST_X(p.geom) + move
				                    WHEN ST_X(p.geom) > wrap THEN ST_X(p.geom) - move
				                    ELSE ST_X(p.geom)
				                END,
				                ST_Y(p.geom)
				            ),
				            ST_SRID(p.geom)
				        )
				    )::geometry_dump
				    FROM ST_DumpPoints(geom) p
				)
			);
END;
$$;


ALTER FUNCTION public.simple_wrap(geom public.geometry, wrap numeric, move numeric) OWNER TO postgres;

--
-- Name: skip(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.skip(integer) RETURNS text
    LANGUAGE sql
    AS $_$SELECT skip(NULL, $1)$_$;


ALTER FUNCTION public.skip(integer) OWNER TO postgres;

--
-- Name: skip(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.skip(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT ok( TRUE ) || ' ' || diag( 'SKIP' || COALESCE(' ' || $1, '') );
$_$;


ALTER FUNCTION public.skip(text) OWNER TO postgres;

--
-- Name: skip(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.skip(integer, text) RETURNS text
    LANGUAGE sql
    AS $_$SELECT skip($2, $1)$_$;


ALTER FUNCTION public.skip(integer, text) OWNER TO postgres;

--
-- Name: skip(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.skip(why text, how_many integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    output TEXT[];
BEGIN
    output := '{}';
    FOR i IN 1..how_many LOOP
        output = array_append(
            output,
            ok( TRUE ) || ' ' || diag( 'SKIP' || COALESCE( ' ' || why, '') )
        );
    END LOOP;
    RETURN array_to_string(output, E'\n');
END;
$$;


ALTER FUNCTION public.skip(why text, how_many integer) OWNER TO postgres;

--
-- Name: table_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT table_owner_is(
        $1, $2,
        'Table ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.table_owner_is(name, name) OWNER TO postgres;

--
-- Name: table_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT table_owner_is(
        $1, $2, $3,
        'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.table_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: table_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('{r,p}'::char[], $1);
BEGIN
    -- Make sure the table exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Table ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.table_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: table_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('{r,p}'::char[], $1, $2);
BEGIN
    -- Make sure the table exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.table_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: table_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT table_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on table ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.table_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: table_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_table_privs( $2, quote_ident($1) );
BEGIN
    IF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.table_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: table_privs_are(name, name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_privs_are(name, name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT table_privs_are(
        $1, $2, $3, $4,
        'Role ' || quote_ident($3) || ' should be granted '
            || CASE WHEN $4[1] IS NULL THEN 'no privileges' ELSE array_to_string($4, ', ') END
            || ' on table ' || quote_ident($1) || '.' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.table_privs_are(name, name, name, name[]) OWNER TO postgres;

--
-- Name: table_privs_are(name, name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_privs_are(name, name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_table_privs( $3, quote_ident($1) || '.' || quote_ident($2) );
BEGIN
    IF grants[1] = 'undefined_table' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Table ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $5) || E'\n' || diag(
            '    Role ' || quote_ident($3) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $4, $5);
END;
$_$;


ALTER FUNCTION public.table_privs_are(name, name, name, name[], text) OWNER TO postgres;

--
-- Name: tables_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tables_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'tables', _extras('{r,p}'::char[], $1), _missing('{r,p}'::char[], $1),
        'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct tables'
    );
$_$;


ALTER FUNCTION public.tables_are(name[]) OWNER TO postgres;

--
-- Name: tables_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tables_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'tables', _extras('{r,p}'::char[], $1), _missing('{r,p}'::char[], $1), $2);
$_$;


ALTER FUNCTION public.tables_are(name[], text) OWNER TO postgres;

--
-- Name: tables_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tables_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'tables', _extras('{r,p}'::char[], $1, $2), _missing('{r,p}'::char[], $1, $2),
        'Schema ' || quote_ident($1) || ' should have the correct tables'
    );
$_$;


ALTER FUNCTION public.tables_are(name, name[]) OWNER TO postgres;

--
-- Name: tables_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tables_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'tables', _extras('{r,p}'::char[], $1, $2), _missing('{r,p}'::char[], $1, $2), $3);
$_$;


ALTER FUNCTION public.tables_are(name, name[], text) OWNER TO postgres;

--
-- Name: tablespace_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tablespace_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT tablespace_owner_is(
        $1, $2,
        'Tablespace ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.tablespace_owner_is(name, name) OWNER TO postgres;

--
-- Name: tablespace_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tablespace_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_tablespace_owner($1);
BEGIN
    -- Make sure the tablespace exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Tablespace ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.tablespace_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: tablespace_privs_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tablespace_privs_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT tablespace_privs_are(
        $1, $2, $3,
        'Role ' || quote_ident($2) || ' should be granted '
            || CASE WHEN $3[1] IS NULL THEN 'no privileges' ELSE array_to_string($3, ', ') END
            || ' on tablespace ' || quote_ident($1)
    );
$_$;


ALTER FUNCTION public.tablespace_privs_are(name, name, name[]) OWNER TO postgres;

--
-- Name: tablespace_privs_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tablespace_privs_are(name, name, name[], text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    grants TEXT[] := _get_tablespaceprivs( $2, $1::TEXT );
BEGIN
    IF grants[1] = 'undefined_tablespace' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Tablespace ' || quote_ident($1) || ' does not exist'
        );
    ELSIF grants[1] = 'undefined_role' THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            '    Role ' || quote_ident($2) || ' does not exist'
        );
    END IF;
    RETURN _assets_are('privileges', grants, $3, $4);
END;
$_$;


ALTER FUNCTION public.tablespace_privs_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: tablespaces_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tablespaces_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT tablespaces_are( $1, 'There should be the correct tablespaces' );
$_$;


ALTER FUNCTION public.tablespaces_are(name[]) OWNER TO postgres;

--
-- Name: tablespaces_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tablespaces_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'tablespaces',
        ARRAY(
            SELECT spcname
              FROM pg_catalog.pg_tablespace
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
               FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT spcname
              FROM pg_catalog.pg_tablespace
        ),
        $2
    );
$_$;


ALTER FUNCTION public.tablespaces_are(name[], text) OWNER TO postgres;

--
-- Name: throws_ilike(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ilike(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_ilike($1, $2, 'Should throw exception like ' || quote_literal($2) );
$_$;


ALTER FUNCTION public.throws_ilike(text, text) OWNER TO postgres;

--
-- Name: throws_ilike(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ilike(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE _query($1);
    RETURN ok( FALSE, $3 ) || E'\n' || diag( '    no exception thrown' );
EXCEPTION WHEN OTHERS THEN
    return _tlike( SQLERRM ~~* $2, SQLERRM, $2, $3 );
END;
$_$;


ALTER FUNCTION public.throws_ilike(text, text, text) OWNER TO postgres;

--
-- Name: throws_imatching(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_imatching(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_imatching($1, $2, 'Should throw exception matching ' || quote_literal($2) );
$_$;


ALTER FUNCTION public.throws_imatching(text, text) OWNER TO postgres;

--
-- Name: throws_imatching(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_imatching(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE _query($1);
    RETURN ok( FALSE, $3 ) || E'\n' || diag( '    no exception thrown' );
EXCEPTION WHEN OTHERS THEN
    return _tlike( SQLERRM ~* $2, SQLERRM, $2, $3 );
END;
$_$;


ALTER FUNCTION public.throws_imatching(text, text, text) OWNER TO postgres;

--
-- Name: throws_like(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_like(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_like($1, $2, 'Should throw exception like ' || quote_literal($2) );
$_$;


ALTER FUNCTION public.throws_like(text, text) OWNER TO postgres;

--
-- Name: throws_like(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_like(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE _query($1);
    RETURN ok( FALSE, $3 ) || E'\n' || diag( '    no exception thrown' );
EXCEPTION WHEN OTHERS THEN
    return _tlike( SQLERRM ~~ $2, SQLERRM, $2, $3 );
END;
$_$;


ALTER FUNCTION public.throws_like(text, text, text) OWNER TO postgres;

--
-- Name: throws_matching(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_matching(text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_matching($1, $2, 'Should throw exception matching ' || quote_literal($2) );
$_$;


ALTER FUNCTION public.throws_matching(text, text) OWNER TO postgres;

--
-- Name: throws_matching(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_matching(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    EXECUTE _query($1);
    RETURN ok( FALSE, $3 ) || E'\n' || diag( '    no exception thrown' );
EXCEPTION WHEN OTHERS THEN
    return _tlike( SQLERRM ~ $2, SQLERRM, $2, $3 );
END;
$_$;


ALTER FUNCTION public.throws_matching(text, text, text) OWNER TO postgres;

--
-- Name: throws_ok(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_ok( $1, NULL, NULL, NULL );
$_$;


ALTER FUNCTION public.throws_ok(text) OWNER TO postgres;

--
-- Name: throws_ok(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text, integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_ok( $1, $2::char(5), NULL, NULL );
$_$;


ALTER FUNCTION public.throws_ok(text, integer) OWNER TO postgres;

--
-- Name: throws_ok(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF octet_length($2) = 5 THEN
        RETURN throws_ok( $1, $2::char(5), NULL, NULL );
    ELSE
        RETURN throws_ok( $1, NULL, $2, NULL );
    END IF;
END;
$_$;


ALTER FUNCTION public.throws_ok(text, text) OWNER TO postgres;

--
-- Name: throws_ok(text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text, integer, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_ok( $1, $2::char(5), $3, NULL );
$_$;


ALTER FUNCTION public.throws_ok(text, integer, text) OWNER TO postgres;

--
-- Name: throws_ok(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF octet_length($2) = 5 THEN
        RETURN throws_ok( $1, $2::char(5), $3, NULL );
    ELSE
        RETURN throws_ok( $1, NULL, $2, $3 );
    END IF;
END;
$_$;


ALTER FUNCTION public.throws_ok(text, text, text) OWNER TO postgres;

--
-- Name: throws_ok(text, character, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text, character, text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    query     TEXT := _query($1);
    errcode   ALIAS FOR $2;
    errmsg    ALIAS FOR $3;
    desctext  ALIAS FOR $4;
    descr     TEXT;
BEGIN
    descr := COALESCE(
          desctext,
          'threw ' || errcode || ': ' || errmsg,
          'threw ' || errcode,
          'threw ' || errmsg,
          'threw an exception'
    );
    EXECUTE query;
    RETURN ok( FALSE, descr ) || E'\n' || diag(
           '      caught: no exception' ||
        E'\n      wanted: ' || COALESCE( errcode, 'an exception' )
    );
EXCEPTION WHEN OTHERS OR ASSERT_FAILURE THEN
    IF (errcode IS NULL OR SQLSTATE = errcode)
        AND ( errmsg IS NULL OR SQLERRM = errmsg)
    THEN
        -- The expected errcode and/or message was thrown.
        RETURN ok( TRUE, descr );
    ELSE
        -- This was not the expected errcode or errmsg.
        RETURN ok( FALSE, descr ) || E'\n' || diag(
               '      caught: ' || SQLSTATE || ': ' || SQLERRM ||
            E'\n      wanted: ' || COALESCE( errcode, 'an exception' ) ||
            COALESCE( ': ' || errmsg, '')
        );
    END IF;
END;
$_$;


ALTER FUNCTION public.throws_ok(text, character, text, text) OWNER TO postgres;

--
-- Name: throws_ok(text, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.throws_ok(text, integer, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT throws_ok( $1, $2::char(5), $3, $4 );
$_$;


ALTER FUNCTION public.throws_ok(text, integer, text, text) OWNER TO postgres;

--
-- Name: todo(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo(how_many integer) RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM _add('todo', COALESCE(how_many, 1), '');
    RETURN;
END;
$$;


ALTER FUNCTION public.todo(how_many integer) OWNER TO postgres;

--
-- Name: todo(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo(why text) RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM _add('todo', 1, COALESCE(why, ''));
    RETURN;
END;
$$;


ALTER FUNCTION public.todo(why text) OWNER TO postgres;

--
-- Name: todo(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo(how_many integer, why text) RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM _add('todo', COALESCE(how_many, 1), COALESCE(why, ''));
    RETURN;
END;
$$;


ALTER FUNCTION public.todo(how_many integer, why text) OWNER TO postgres;

--
-- Name: todo(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo(why text, how_many integer) RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM _add('todo', COALESCE(how_many, 1), COALESCE(why, ''));
    RETURN;
END;
$$;


ALTER FUNCTION public.todo(why text, how_many integer) OWNER TO postgres;

--
-- Name: todo_end(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo_end() RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    id integer;
BEGIN
    id := _get_latest( 'todo', -1 );
    IF id IS NULL THEN
        RAISE EXCEPTION 'todo_end() called without todo_start()';
    END IF;
    EXECUTE 'DELETE FROM __tcache__ WHERE id = ' || id;
    RETURN;
END;
$$;


ALTER FUNCTION public.todo_end() OWNER TO postgres;

--
-- Name: todo_start(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo_start() RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM _add('todo', -1, '');
    RETURN;
END;
$$;


ALTER FUNCTION public.todo_start() OWNER TO postgres;

--
-- Name: todo_start(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.todo_start(text) RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $_$
BEGIN
    PERFORM _add('todo', -1, COALESCE($1, ''));
    RETURN;
END;
$_$;


ALTER FUNCTION public.todo_start(text) OWNER TO postgres;

--
-- Name: trigger_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT trigger_is(
        $1, $2, $3,
        'Trigger ' || quote_ident($2) || ' should call ' || quote_ident($3) || '()'
    );
$_$;


ALTER FUNCTION public.trigger_is(name, name, name) OWNER TO postgres;

--
-- Name: trigger_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    pname text;
BEGIN
    SELECT p.proname
      FROM pg_catalog.pg_trigger t
      JOIN pg_catalog.pg_class ct ON ct.oid = t.tgrelid
      JOIN pg_catalog.pg_proc p   ON p.oid = t.tgfoid
     WHERE ct.relname = $1
       AND t.tgname   = $2
       AND pg_catalog.pg_table_is_visible(ct.oid)
      INTO pname;

    RETURN is( pname, $3::text, $4 );
END;
$_$;


ALTER FUNCTION public.trigger_is(name, name, name, text) OWNER TO postgres;

--
-- Name: trigger_is(name, name, name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_is(name, name, name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT trigger_is(
        $1, $2, $3, $4, $5,
        'Trigger ' || quote_ident($3) || ' should call ' || quote_ident($4) || '.' || quote_ident($5) || '()'
    );
$_$;


ALTER FUNCTION public.trigger_is(name, name, name, name, name) OWNER TO postgres;

--
-- Name: trigger_is(name, name, name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_is(name, name, name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    pname text;
BEGIN
    SELECT quote_ident(ni.nspname) || '.' || quote_ident(p.proname)
      FROM pg_catalog.pg_trigger t
      JOIN pg_catalog.pg_class ct     ON ct.oid = t.tgrelid
      JOIN pg_catalog.pg_namespace nt ON nt.oid = ct.relnamespace
      JOIN pg_catalog.pg_proc p       ON p.oid = t.tgfoid
      JOIN pg_catalog.pg_namespace ni ON ni.oid = p.pronamespace
     WHERE nt.nspname = $1
       AND ct.relname = $2
       AND t.tgname   = $3
      INTO pname;

    RETURN is( pname, quote_ident($4) || '.' || quote_ident($5), $6 );
END;
$_$;


ALTER FUNCTION public.trigger_is(name, name, name, name, name, text) OWNER TO postgres;

--
-- Name: triggers_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.triggers_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT triggers_are( $1, $2, 'Table ' || quote_ident($1) || ' should have the correct triggers' );
$_$;


ALTER FUNCTION public.triggers_are(name, name[]) OWNER TO postgres;

--
-- Name: triggers_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.triggers_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'triggers',
        ARRAY(
            SELECT t.tgname
              FROM pg_catalog.pg_trigger t
              JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             WHERE c.relname = $1
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND NOT t.tgisinternal
            EXCEPT
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
        ),
        ARRAY(
            SELECT $2[i]
              FROM generate_series(1, array_upper($2, 1)) s(i)
            EXCEPT
            SELECT t.tgname
              FROM pg_catalog.pg_trigger t
              JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
               AND n.nspname NOT IN ('pg_catalog', 'information_schema')
               AND NOT t.tgisinternal
        ),
        $3
    );
$_$;


ALTER FUNCTION public.triggers_are(name, name[], text) OWNER TO postgres;

--
-- Name: triggers_are(name, name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.triggers_are(name, name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT triggers_are( $1, $2, $3, 'Table ' || quote_ident($1) || '.' || quote_ident($2) || ' should have the correct triggers' );
$_$;


ALTER FUNCTION public.triggers_are(name, name, name[]) OWNER TO postgres;

--
-- Name: triggers_are(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.triggers_are(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'triggers',
        ARRAY(
            SELECT t.tgname
              FROM pg_catalog.pg_trigger t
              JOIN pg_catalog.pg_class c     ON c.oid = t.tgrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = $1
               AND c.relname = $2
               AND NOT t.tgisinternal
            EXCEPT
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
        ),
        ARRAY(
            SELECT $3[i]
              FROM generate_series(1, array_upper($3, 1)) s(i)
            EXCEPT
            SELECT t.tgname
              FROM pg_catalog.pg_trigger t
              JOIN pg_catalog.pg_class c     ON c.oid = t.tgrelid
              JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = $1
               AND c.relname = $2
               AND NOT t.tgisinternal
        ),
        $4
    );
$_$;


ALTER FUNCTION public.triggers_are(name, name, name[], text) OWNER TO postgres;

--
-- Name: type_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.type_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT type_owner_is(
        $1, $2,
        'Type ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.type_owner_is(name, name) OWNER TO postgres;

--
-- Name: type_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.type_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT type_owner_is(
        $1, $2, $3,
        'Type ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.type_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: type_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.type_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_type_owner($1);
BEGIN
    -- Make sure the type exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    Type ' || quote_ident($1) || ' not found'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.type_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: type_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.type_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_type_owner($1, $2);
BEGIN
    -- Make sure the type exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    Type ' || quote_ident($1) || '.' || quote_ident($2) || ' not found'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.type_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: types_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.types_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, 'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct types', NULL );
$_$;


ALTER FUNCTION public.types_are(name[]) OWNER TO postgres;

--
-- Name: types_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.types_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, NULL );
$_$;


ALTER FUNCTION public.types_are(name[], text) OWNER TO postgres;

--
-- Name: types_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.types_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, 'Schema ' || quote_ident($1) || ' should have the correct types', NULL );
$_$;


ALTER FUNCTION public.types_are(name, name[]) OWNER TO postgres;

--
-- Name: types_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.types_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _types_are( $1, $2, $3, NULL );
$_$;


ALTER FUNCTION public.types_are(name, name[], text) OWNER TO postgres;

--
-- Name: unalike(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unalike(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~~ $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.unalike(anyelement, text) OWNER TO postgres;

--
-- Name: unalike(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unalike(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~~ $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.unalike(anyelement, text, text) OWNER TO postgres;

--
-- Name: unialike(anyelement, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unialike(anyelement, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~~* $2, $1, $2, NULL );
$_$;


ALTER FUNCTION public.unialike(anyelement, text) OWNER TO postgres;

--
-- Name: unialike(anyelement, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unialike(anyelement, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _unalike( $1 !~~* $2, $1, $2, $3 );
$_$;


ALTER FUNCTION public.unialike(anyelement, text, text) OWNER TO postgres;

--
-- Name: update_traversal_on_node_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_traversal_on_node_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    node_count INT;
    zoom_lvl INT;
    old_tiles BIGINT[];
    new_tiles BIGINT[];
    common_tiles BIGINT[];
    current_shape GEOMETRY[];
    curr_geom GEOMETRY;
    intersecting_old BIGINT[];
    old_neighbour_geom GEOMETRY;
    new_neighbour_geom GEOMETRY;
BEGIN
    -- Count current nodes for the way
    SELECT COUNT(*) INTO node_count 
    FROM WaysNodes 
    WHERE way_id = NEW.way_id;

    -- Branch 1: Way Nodes Count > 2
    IF node_count > 2 THEN
        -- 2. Get ways zoom level
        zoom_lvl := get_way_zoom_level(NEW.way_id);

        -- 3 & 4. Get tiles for new and old neighbor line segments
        new_tiles := get_tiles_of_neighbour_line(NEW.node_id, NEW.way_id, NEW.sequence_id, zoom_lvl, TRUE);
		old_tiles := get_tiles_of_neighbour_line(NEW.node_id, NEW.way_id, NEW.sequence_id, zoom_lvl, FALSE);

        -- 5. Get common tiles between new and old
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            INTERSECT
            SELECT UNNEST(new_tiles)
        ) INTO common_tiles;

        -- 6. old tiles = old - common
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO old_tiles;

        -- 7. new tiles = new - common
        SELECT ARRAY(
            SELECT UNNEST(new_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO new_tiles;

        -- 9. old tiles = old - select_tiles_intersecting_line
		
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            -- Fetch updated full way geometry pieces
            SELECT ARRAY_AGG(g) INTO current_shape 
            FROM UNNEST(get_way_split
				(
					(
	                SELECT ST_SetSRID(ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id), 4326)
	                FROM WaysNodes wn
	                JOIN Nodes n ON n.id = wn.node_id
	                WHERE wn.way_id = NEW.way_id
            		)
				)
			) AS g;

            -- Find old candidate tiles that still intersect current geometry pieces
            intersecting_old := ARRAY[]::BIGINT[];
            FOREACH curr_geom IN ARRAY current_shape LOOP
                intersecting_old := ARRAY_CAT(
                    intersecting_old, 
                    select_tiles_intersecting_geom(old_tiles, curr_geom)
                );
            END LOOP;

            -- Exclude still-intersecting tiles from old_tiles removal list
            SELECT ARRAY(
                SELECT UNNEST(old_tiles)
                EXCEPT
                SELECT UNNEST(intersecting_old)
            ) INTO old_tiles;
        END IF;

        -- 10. Remove old tiles
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            DELETE FROM Traversal 
            WHERE way_id = NEW.way_id AND tile_id = ANY(old_tiles);
        END IF;

        -- 11. Insert new tiles
        IF ARRAY_LENGTH(new_tiles, 1) > 0 THEN
            INSERT INTO Traversal (way_id, tile_id)
            SELECT NEW.way_id, t.tile_id 
            FROM UNNEST(new_tiles) AS t(tile_id)
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;

    -- Branch 2: Way Nodes Count <= 2
    ELSE
        -- 12. Check if Way Node Count = 2
        IF node_count = 2 THEN
            -- Reconstruct total way line geometry
            SELECT ARRAY_AGG(g) INTO current_shape
            FROM UNNEST(get_way_split
				(
					(
		                SELECT ST_SetSRID(ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id), 4326)
		                FROM WaysNodes wn
		                JOIN Nodes n ON n.id = wn.node_id
		                WHERE wn.way_id = NEW.way_id
            		)
				)
			) AS g;

            -- 14. Get zoom level for given geometry
            zoom_lvl := get_zoom_level_for_geom(current_shape);

            -- 15. Remove all way traversal
            DELETE FROM Traversal WHERE way_id = NEW.way_id;

            -- 16. Select tiles intersecting line
            new_tiles := get_tiles_intersecting_line(current_shape, zoom_lvl);

            -- 17. Insert new tiles
            IF ARRAY_LENGTH(new_tiles, 1) > 0 THEN
                INSERT INTO Traversal (way_id, tile_id)
                SELECT NEW.way_id, t.tile_id 
                FROM UNNEST(new_tiles) AS t(tile_id)
                ON CONFLICT (way_id, tile_id) DO NOTHING;
            END IF;

        -- 18. Way Node Count = 1 (Insert tile_id from node)
        ELSE
            INSERT INTO Traversal (way_id, tile_id)
            SELECT NEW.way_id, n.tile_id
            FROM WaysNodes wn
            JOIN Nodes n ON n.id = wn.node_id
            WHERE wn.way_id = NEW.way_id
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_traversal_on_node_add() OWNER TO postgres;

--
-- Name: update_traversals_on_node_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_traversals_on_node_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    node_count INT;
    current_zoom_level INT;
    new_split_shape GEOMETRY[];
    old_split_shape GEOMETRY[];
    old_full_geom GEOMETRY;
    new_full_geom GEOMETRY;
    old_tiles BIGINT[];
    new_tiles BIGINT[];
    common_tiles BIGINT[];
    still_intersecting_tiles BIGINT[];
BEGIN
    -- Count remaining nodes for the way (after the OLD node deletion)
    SELECT COUNT(*) INTO node_count 
    FROM WaysNodes 
    WHERE way_id = OLD.way_id;

    -- 1. Check if way node count > 1
    IF node_count > 1 THEN
        -- Determine target zoom level for the way
        current_zoom_level := get_way_zoom_level(OLD.way_id);

        -- 5. Build current/new way geometry (without OLD node) and split across antimeridian
        SELECT ST_SetSRID(ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id), 4326)
        INTO new_full_geom
        FROM WaysNodes wn
        JOIN Nodes n ON n.id = wn.node_id
        WHERE wn.way_id = OLD.way_id;

        new_split_shape := get_way_split(new_full_geom);
        new_tiles := get_tiles_intersecting_line(new_split_shape, current_zoom_level);

        -- 6. Reconstruct old way geometry (including the deleted OLD node)
        SELECT ST_SetSRID(ST_MakeLine(
            CASE 
                WHEN wn.node_id = OLD.node_id THEN OLD.geom::geometry
                ELSE n.geom::geometry
            END 
            ORDER BY wn.sequence_id
        ), 4326)
        INTO old_full_geom
        FROM (
            SELECT way_id, node_id, sequence_id FROM WaysNodes WHERE way_id = OLD.way_id
            UNION ALL
            SELECT OLD.way_id, OLD.node_id, OLD.sequence_id
        ) wn
        JOIN Nodes n ON n.id = wn.node_id OR wn.node_id = OLD.node_id;

        old_split_shape := get_way_split(old_full_geom);

        -- 7. Get tiles intersecting the old line
        old_tiles := get_tiles_intersecting_line(old_split_shape, current_zoom_level);

        -- 9. Get common tiles between new and old lines
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            INTERSECT
            SELECT UNNEST(new_tiles)
        ) INTO common_tiles;

        -- 10. old tiles = old - common
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO old_tiles;

        -- 11. new tiles = new - common
        SELECT ARRAY(
            SELECT UNNEST(new_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO new_tiles;

        -- 12. Filter old tiles that are still intersected by the remaining geometry
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            still_intersecting_tiles := select_tiles_intersecting_geom(old_tiles, ST_Collect(new_split_shape));

            SELECT ARRAY(
                SELECT UNNEST(old_tiles)
                EXCEPT
                SELECT UNNEST(still_intersecting_tiles)
            ) INTO old_tiles;
        END IF;

        -- 13. Remove old tiles
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            DELETE FROM Traversal 
            WHERE way_id = OLD.way_id 
              AND tile_id = ANY(old_tiles);
        END IF;

        -- 14. Insert new tiles
        IF ARRAY_LENGTH(new_tiles, 1) > 0 THEN
            INSERT INTO Traversal(way_id, tile_id)
            SELECT OLD.way_id, t.tile_id
            FROM UNNEST(new_tiles) AS t(tile_id)
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;

    ELSE
        -- 4. Node count <= 1: remove all traversals for the line
        DELETE FROM Traversal WHERE way_id = OLD.way_id;

        -- 2. Check if way node count = 1
        IF node_count = 1 THEN
            -- 3. Insert single remaining node tile_id as traversal
            INSERT INTO Traversal(way_id, tile_id)
            SELECT OLD.way_id, n.tile_id
            FROM WaysNodes wn
            JOIN Nodes n ON n.id = wn.node_id
            WHERE wn.way_id = OLD.way_id
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.update_traversals_on_node_delete() OWNER TO postgres;

--
-- Name: update_traversals_on_node_edit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_traversals_on_node_edit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    elem RECORD;
    current_zoom_level INT;
    old_line GEOMETRY[];
    old_tiles BIGINT[];
    new_tiles BIGINT[];
    common_tiles BIGINT[];
    full_way_geom GEOMETRY;
    current_split_shape GEOMETRY[];
    still_intersecting_tiles BIGINT[];
BEGIN
    -- 1. Get all ways (and sequence_ids) associated with this edited node
    FOR elem IN 
        SELECT way_id, sequence_id 
        FROM WaysNodes 
        WHERE node_id = NEW.id 
    LOOP
        -- 3. Get way zoom level
        current_zoom_level := get_way_zoom_level(elem.way_id);

        -- 4. new tiles = get tiles for current line (including NEW node geometry)
        new_tiles := get_tiles_of_neighbour_line(NEW.id, elem.way_id, elem.sequence_id, current_zoom_level, TRUE);

        -- 5. old line = get nearest nodes line using OLD node geometry
        old_line := get_nearest_nodes_line(NEW.id, elem.way_id, elem.sequence_id, OLD.geom::geometry);

        -- 5.1. get tiles for old_line
        old_tiles := get_tiles_intersecting_line(old_line, current_zoom_level);

        -- 6. Get common tiles for new and old line
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            INTERSECT
            SELECT UNNEST(new_tiles)
        ) INTO common_tiles;

        -- 7. old tiles = old - common
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO old_tiles;

        -- 8. new tiles = new - common
        SELECT ARRAY(
            SELECT UNNEST(new_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO new_tiles;

        -- 9. old tiles = old - select_tiles_intersecting_line
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            -- Reconstruct total full way geometry
            SELECT ST_SetSRID(ST_MakeLine(n.geom::GEOMETRY ORDER BY wn.sequence_id), 4326)
            INTO full_way_geom
            FROM WaysNodes wn
            JOIN Nodes n ON n.id = wn.node_id
            WHERE wn.way_id = elem.way_id;

            -- Split geometry across antimeridian
            current_split_shape := get_way_split(full_way_geom);

            -- Filter out old candidate tiles that are still intersected by any piece of the current geometry
            still_intersecting_tiles := select_tiles_intersecting_geom(old_tiles, ST_Collect(current_split_shape));

            SELECT ARRAY(
                SELECT UNNEST(old_tiles)
                EXCEPT
                SELECT UNNEST(still_intersecting_tiles)
            ) INTO old_tiles;
        END IF;

        -- 10. Remove old tiles
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            DELETE FROM Traversal 
            WHERE way_id = elem.way_id 
              AND tile_id = ANY(old_tiles);
        END IF;

        -- 11. Insert new tiles
        IF ARRAY_LENGTH(new_tiles, 1) > 0 THEN
            INSERT INTO Traversal(way_id, tile_id) 
            SELECT elem.way_id, t.tile_id 
            FROM UNNEST(new_tiles) AS t(tile_id) 
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;

    END LOOP;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_traversals_on_node_edit() OWNER TO postgres;

--
-- Name: update_traversals_on_ways_nodes_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_traversals_on_ways_nodes_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    node_count INT;
    current_zoom_level INT;
    new_split_shape GEOMETRY[];
    new_full_geom GEOMETRY;
    old_tiles BIGINT[];
    new_tiles BIGINT[];
    common_tiles BIGINT[];
    still_intersecting_tiles BIGINT[];
BEGIN
    -- Count remaining nodes for the way (after the OLD node deletion)
    SELECT COUNT(*) INTO node_count 
    FROM WaysNodes 
    WHERE way_id = OLD.way_id;


    -- 1. Check if way node count > 1
    IF node_count > 1 THEN
        -- Determine target zoom level for the way
        current_zoom_level := get_way_zoom_level(OLD.way_id);

        -- 5. Build current/new way geometry (without OLD node) and split across antimeridian
        SELECT ST_SetSRID(ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id), 4326)
        INTO new_full_geom
        FROM WaysNodes wn
        JOIN Nodes n ON n.id = wn.node_id
        WHERE wn.way_id = OLD.way_id;

        new_split_shape := get_way_split(new_full_geom);
        new_tiles := get_tiles_intersecting_line(new_split_shape, current_zoom_level);

        -- 7. Get tiles intersecting the old line
        old_tiles := (SELECT ARRAY_AGG(t.tile_id) FROM Traversal t WHERE t.way_id = OLD.way_id);

        -- 9. Get common tiles between new and old lines
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            INTERSECT
            SELECT UNNEST(new_tiles)
        ) INTO common_tiles;

        -- 10. old tiles = old - common
        SELECT ARRAY(
            SELECT UNNEST(old_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO old_tiles;

        -- 11. new tiles = new - common
        SELECT ARRAY(
            SELECT UNNEST(new_tiles)
            EXCEPT
            SELECT UNNEST(common_tiles)
        ) INTO new_tiles;

        -- 12. Filter old tiles that are still intersected by the remaining geometry
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            still_intersecting_tiles := select_tiles_intersecting_geom(old_tiles, ST_Collect(new_split_shape));

            SELECT ARRAY(
                SELECT UNNEST(old_tiles)
                EXCEPT
                SELECT UNNEST(still_intersecting_tiles)
            ) INTO old_tiles;
        END IF;

        -- 13. Remove old tiles
        IF ARRAY_LENGTH(old_tiles, 1) > 0 THEN
            DELETE FROM Traversal 
            WHERE way_id = OLD.way_id 
              AND tile_id = ANY(old_tiles);
        END IF;

        -- 14. Insert new tiles
        IF ARRAY_LENGTH(new_tiles, 1) > 0 THEN
            INSERT INTO Traversal(way_id, tile_id)
            SELECT OLD.way_id, t.tile_id
            FROM UNNEST(new_tiles) AS t(tile_id)
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;

    ELSE
        -- 4. Node count <= 1: remove all traversals for the line
        DELETE FROM Traversal WHERE way_id = OLD.way_id;

        -- 2. Check if way node count = 1
        IF node_count = 1 THEN
            -- 3. Insert single remaining node tile_id as traversal
            INSERT INTO Traversal(way_id, tile_id)
            SELECT OLD.way_id, n.tile_id
            FROM WaysNodes wn
            JOIN Nodes n ON n.id = wn.node_id
            WHERE wn.way_id = OLD.way_id
            ON CONFLICT (way_id, tile_id) DO NOTHING;
        END IF;
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.update_traversals_on_ways_nodes_delete() OWNER TO postgres;

--
-- Name: users_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.users_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT users_are( $1, 'There should be the correct users' );
$_$;


ALTER FUNCTION public.users_are(name[]) OWNER TO postgres;

--
-- Name: users_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.users_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'users',
        ARRAY(
            SELECT usename
              FROM pg_catalog.pg_user
            EXCEPT
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
        ),
        ARRAY(
            SELECT $1[i]
              FROM generate_series(1, array_upper($1, 1)) s(i)
            EXCEPT
            SELECT usename
              FROM pg_catalog.pg_user
        ),
        $2
    );
$_$;


ALTER FUNCTION public.users_are(name[], text) OWNER TO postgres;

--
-- Name: view_owner_is(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.view_owner_is(name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT view_owner_is(
        $1, $2,
        'View ' || quote_ident($1) || ' should be owned by ' || quote_ident($2)
    );
$_$;


ALTER FUNCTION public.view_owner_is(name, name) OWNER TO postgres;

--
-- Name: view_owner_is(name, name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.view_owner_is(name, name, name) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT view_owner_is(
        $1, $2, $3,
        'View ' || quote_ident($1) || '.' || quote_ident($2) || ' should be owned by ' || quote_ident($3)
    );
$_$;


ALTER FUNCTION public.view_owner_is(name, name, name) OWNER TO postgres;

--
-- Name: view_owner_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.view_owner_is(name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('v'::char, $1);
BEGIN
    -- Make sure the view exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $3) || E'\n' || diag(
            E'    View ' || quote_ident($1) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $2, $3);
END;
$_$;


ALTER FUNCTION public.view_owner_is(name, name, text) OWNER TO postgres;

--
-- Name: view_owner_is(name, name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.view_owner_is(name, name, name, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    owner NAME := _get_rel_owner('v'::char, $1, $2);
BEGIN
    -- Make sure the view exists.
    IF owner IS NULL THEN
        RETURN ok(FALSE, $4) || E'\n' || diag(
            E'    View ' || quote_ident($1) || '.' || quote_ident($2) || ' does not exist'
        );
    END IF;

    RETURN is(owner, $3, $4);
END;
$_$;


ALTER FUNCTION public.view_owner_is(name, name, name, text) OWNER TO postgres;

--
-- Name: views_are(name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.views_are(name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'views', _extras('v', $1), _missing('v', $1),
        'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct views'
    );
$_$;


ALTER FUNCTION public.views_are(name[]) OWNER TO postgres;

--
-- Name: views_are(name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.views_are(name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'views', _extras('v', $1), _missing('v', $1), $2);
$_$;


ALTER FUNCTION public.views_are(name[], text) OWNER TO postgres;

--
-- Name: views_are(name, name[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.views_are(name, name[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are(
        'views', _extras('v', $1, $2), _missing('v', $1, $2),
        'Schema ' || quote_ident($1) || ' should have the correct views'
    );
$_$;


ALTER FUNCTION public.views_are(name, name[]) OWNER TO postgres;

--
-- Name: views_are(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.views_are(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _are( 'views', _extras('v', $1, $2), _missing('v', $1, $2), $3);
$_$;


ALTER FUNCTION public.views_are(name, name[], text) OWNER TO postgres;

--
-- Name: volatility_is(name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT volatility_is(
        $1, $2,
        'Function ' || quote_ident($1) || '() should be ' || _refine_vol($2)
    );
$_$;


ALTER FUNCTION public.volatility_is(name, text) OWNER TO postgres;

--
-- Name: volatility_is(name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT volatility_is(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '(' ||
        array_to_string($2, ', ') || ') should be ' || _refine_vol($3)
    );
$_$;


ALTER FUNCTION public.volatility_is(name, name[], text) OWNER TO postgres;

--
-- Name: volatility_is(name, name, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT volatility_is(
        $1, $2, $3,
        'Function ' || quote_ident($1) || '.' || quote_ident($2)
        || '() should be ' || _refine_vol($3)
    );
$_$;


ALTER FUNCTION public.volatility_is(name, name, text) OWNER TO postgres;

--
-- Name: volatility_is(name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, _vol($1), _refine_vol($2), $3 );
$_$;


ALTER FUNCTION public.volatility_is(name, text, text) OWNER TO postgres;

--
-- Name: volatility_is(name, name[], text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, name[], text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare(NULL, $1, $2, _vol($1, $2), _refine_vol($3), $4 );
$_$;


ALTER FUNCTION public.volatility_is(name, name[], text, text) OWNER TO postgres;

--
-- Name: volatility_is(name, name, name[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, name, name[], text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT volatility_is(
        $1, $2, $3, $4,
        'Function ' || quote_ident($1) || '.' || quote_ident($2) || '(' ||
        array_to_string($3, ', ') || ') should be ' || _refine_vol($4)
    );
$_$;


ALTER FUNCTION public.volatility_is(name, name, name[], text) OWNER TO postgres;

--
-- Name: volatility_is(name, name, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, name, text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, _vol($1, $2), _refine_vol($3), $4 );
$_$;


ALTER FUNCTION public.volatility_is(name, name, text, text) OWNER TO postgres;

--
-- Name: volatility_is(name, name, name[], text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volatility_is(name, name, name[], text, text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT _func_compare($1, $2, $3, _vol($1, $2, $3), _refine_vol($4), $5 );
$_$;


ALTER FUNCTION public.volatility_is(name, name, name[], text, text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: maptype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.maptype (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.maptype OWNER TO postgres;

--
-- Name: maptypetags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.maptypetags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    map_type_id uuid NOT NULL,
    k character varying(50) NOT NULL,
    v character varying(50)
);


ALTER TABLE public.maptypetags OWNER TO postgres;

--
-- Name: nodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    geom public.geography(Point,4326) NOT NULL,
    tile_id bigint
);


ALTER TABLE public.nodes OWNER TO postgres;

--
-- Name: nodestags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nodestags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    k character varying(50) NOT NULL,
    v character varying(50) NOT NULL,
    node_id uuid NOT NULL
);


ALTER TABLE public.nodestags OWNER TO postgres;

--
-- Name: pg_all_foreign_keys; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_all_foreign_keys AS
 SELECT n1.nspname AS fk_schema_name,
    c1.relname AS fk_table_name,
    k1.conname AS fk_constraint_name,
    c1.oid AS fk_table_oid,
    public._pg_sv_column_array(k1.conrelid, k1.conkey) AS fk_columns,
    n2.nspname AS pk_schema_name,
    c2.relname AS pk_table_name,
    k2.conname AS pk_constraint_name,
    c2.oid AS pk_table_oid,
    ci.relname AS pk_index_name,
    public._pg_sv_column_array(k1.confrelid, k1.confkey) AS pk_columns,
        CASE k1.confmatchtype
            WHEN 'f'::"char" THEN 'FULL'::text
            WHEN 'p'::"char" THEN 'PARTIAL'::text
            WHEN 'u'::"char" THEN 'NONE'::text
            ELSE NULL::text
        END AS match_type,
        CASE k1.confdeltype
            WHEN 'a'::"char" THEN 'NO ACTION'::text
            WHEN 'c'::"char" THEN 'CASCADE'::text
            WHEN 'd'::"char" THEN 'SET DEFAULT'::text
            WHEN 'n'::"char" THEN 'SET NULL'::text
            WHEN 'r'::"char" THEN 'RESTRICT'::text
            ELSE NULL::text
        END AS on_delete,
        CASE k1.confupdtype
            WHEN 'a'::"char" THEN 'NO ACTION'::text
            WHEN 'c'::"char" THEN 'CASCADE'::text
            WHEN 'd'::"char" THEN 'SET DEFAULT'::text
            WHEN 'n'::"char" THEN 'SET NULL'::text
            WHEN 'r'::"char" THEN 'RESTRICT'::text
            ELSE NULL::text
        END AS on_update,
    k1.condeferrable AS is_deferrable,
    k1.condeferred AS is_deferred
   FROM ((((((((pg_constraint k1
     JOIN pg_namespace n1 ON ((n1.oid = k1.connamespace)))
     JOIN pg_class c1 ON ((c1.oid = k1.conrelid)))
     JOIN pg_class c2 ON ((c2.oid = k1.confrelid)))
     JOIN pg_namespace n2 ON ((n2.oid = c2.relnamespace)))
     JOIN pg_depend d ON (((d.classid = ('pg_constraint'::regclass)::oid) AND (d.objid = k1.oid) AND (d.objsubid = 0) AND (d.deptype = 'n'::"char") AND (d.refclassid = ('pg_class'::regclass)::oid) AND (d.refobjsubid = 0))))
     JOIN pg_class ci ON (((ci.oid = d.refobjid) AND (ci.relkind = 'i'::"char"))))
     LEFT JOIN pg_depend d2 ON (((d2.classid = ('pg_class'::regclass)::oid) AND (d2.objid = ci.oid) AND (d2.objsubid = 0) AND (d2.deptype = 'i'::"char") AND (d2.refclassid = ('pg_constraint'::regclass)::oid) AND (d2.refobjsubid = 0))))
     LEFT JOIN pg_constraint k2 ON (((k2.oid = d2.refobjid) AND (k2.contype = ANY (ARRAY['p'::"char", 'u'::"char"])))))
  WHERE ((k1.conrelid <> (0)::oid) AND (k1.confrelid <> (0)::oid) AND (k1.contype = 'f'::"char") AND public._pg_sv_table_accessible(n1.oid, c1.oid));


ALTER VIEW public.pg_all_foreign_keys OWNER TO postgres;

--
-- Name: relations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.relations OWNER TO postgres;

--
-- Name: relationselements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relationselements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    relation_id uuid NOT NULL,
    way_id uuid NOT NULL,
    type boolean DEFAULT true NOT NULL
);


ALTER TABLE public.relationselements OWNER TO postgres;

--
-- Name: relationstags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relationstags (
    id uuid DEFAULT gen_random_uuid() CONSTRAINT relationtags_id_not_null NOT NULL,
    k character varying(50) CONSTRAINT relationtags_k_not_null NOT NULL,
    v character varying(50) CONSTRAINT relationtags_v_not_null NOT NULL,
    relation_id uuid CONSTRAINT relationtags_relation_id_not_null NOT NULL
);


ALTER TABLE public.relationstags OWNER TO postgres;

--
-- Name: tap_funky; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.tap_funky AS
 SELECT p.oid,
    n.nspname AS schema,
    p.proname AS name,
    pg_get_userbyid(p.proowner) AS owner,
    array_to_string((p.proargtypes)::regtype[], ','::text) AS args,
    (
        CASE p.proretset
            WHEN true THEN 'setof '::text
            ELSE ''::text
        END || (p.prorettype)::regtype) AS returns,
    p.prolang AS langoid,
    p.proisstrict AS is_strict,
    public._prokind(p.oid) AS kind,
    p.prosecdef AS is_definer,
    p.proretset AS returns_set,
    (p.provolatile)::character(1) AS volatility,
    pg_function_is_visible(p.oid) AS is_visible
   FROM (pg_proc p
     JOIN pg_namespace n ON ((p.pronamespace = n.oid)));


ALTER VIEW public.tap_funky OWNER TO postgres;

--
-- Name: traversal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.traversal (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    way_id uuid NOT NULL,
    tile_id bigint NOT NULL
);


ALTER TABLE public.traversal OWNER TO postgres;

--
-- Name: ways; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ways (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.ways OWNER TO postgres;

--
-- Name: waysnodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.waysnodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    way_id uuid NOT NULL,
    node_id uuid NOT NULL,
    sequence_id integer NOT NULL
);


ALTER TABLE public.waysnodes OWNER TO postgres;

--
-- Name: waystags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.waystags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    k character varying(50) NOT NULL,
    v character varying(50) NOT NULL,
    way_id uuid CONSTRAINT waystags_relation_id_not_null NOT NULL
);


ALTER TABLE public.waystags OWNER TO postgres;

--
-- Data for Name: maptype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.maptype (id, name) FROM stdin;
\.


--
-- Data for Name: maptypetags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.maptypetags (id, map_type_id, k, v) FROM stdin;
\.


--
-- Data for Name: nodes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nodes (id, name, geom, tile_id) FROM stdin;
\.


--
-- Data for Name: nodestags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nodestags (id, k, v, node_id) FROM stdin;
\.


--
-- Data for Name: relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.relations (id, name) FROM stdin;
\.


--
-- Data for Name: relationselements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.relationselements (id, relation_id, way_id, type) FROM stdin;
\.


--
-- Data for Name: relationstags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.relationstags (id, k, v, relation_id) FROM stdin;
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: traversal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.traversal (id, way_id, tile_id) FROM stdin;
\.


--
-- Data for Name: ways; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ways (id, name) FROM stdin;
\.


--
-- Data for Name: waysnodes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.waysnodes (id, way_id, node_id, sequence_id) FROM stdin;
\.


--
-- Data for Name: waystags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.waystags (id, k, v, way_id) FROM stdin;
\.


--
-- Name: maptype maptype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maptype
    ADD CONSTRAINT maptype_pkey PRIMARY KEY (id);


--
-- Name: maptypetags maptypetags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maptypetags
    ADD CONSTRAINT maptypetags_pkey PRIMARY KEY (id);


--
-- Name: nodes nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (id);


--
-- Name: nodestags nodestags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nodestags
    ADD CONSTRAINT nodestags_pkey PRIMARY KEY (id);


--
-- Name: relations relations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (id);


--
-- Name: relationselements relationselements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationselements
    ADD CONSTRAINT relationselements_pkey PRIMARY KEY (id);


--
-- Name: relationstags relationtags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationstags
    ADD CONSTRAINT relationtags_pkey PRIMARY KEY (id);


--
-- Name: traversal traversal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traversal
    ADD CONSTRAINT traversal_pkey PRIMARY KEY (id);


--
-- Name: traversal unique_way_tile; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traversal
    ADD CONSTRAINT unique_way_tile UNIQUE (way_id, tile_id);


--
-- Name: ways ways_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_pkey PRIMARY KEY (id);


--
-- Name: waysnodes waysnodes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waysnodes
    ADD CONSTRAINT waysnodes_pkey PRIMARY KEY (id);


--
-- Name: waystags waystags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waystags
    ADD CONSTRAINT waystags_pkey PRIMARY KEY (id);


--
-- Name: nodes trg_update_point_tile_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_point_tile_id BEFORE INSERT OR UPDATE ON public.nodes FOR EACH ROW EXECUTE FUNCTION public.add_point_tile_id();


--
-- Name: waysnodes trigger_01_shift_ways_nodes_sequence; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_01_shift_ways_nodes_sequence BEFORE INSERT ON public.waysnodes FOR EACH ROW EXECUTE FUNCTION public.shift_ways_nodes_sequence();


--
-- Name: waysnodes trigger_update_traversal_on_node_add; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_traversal_on_node_add AFTER INSERT ON public.waysnodes FOR EACH ROW EXECUTE FUNCTION public.update_traversal_on_node_add();


--
-- Name: waysnodes trigger_update_traversals_on_ways_nodes_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_traversals_on_ways_nodes_delete AFTER DELETE ON public.waysnodes FOR EACH ROW EXECUTE FUNCTION public.update_traversals_on_ways_nodes_delete();


--
-- Name: nodes update_traversal_on_node_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_traversal_on_node_update AFTER UPDATE ON public.nodes FOR EACH ROW EXECUTE FUNCTION public.update_traversals_on_node_edit();


--
-- Name: maptypetags maptypetags_map_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maptypetags
    ADD CONSTRAINT maptypetags_map_type_id_fkey FOREIGN KEY (map_type_id) REFERENCES public.maptype(id);


--
-- Name: nodestags nodestags_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nodestags
    ADD CONSTRAINT nodestags_node_id_fkey FOREIGN KEY (node_id) REFERENCES public.nodes(id);


--
-- Name: relationselements relationselements_relation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationselements
    ADD CONSTRAINT relationselements_relation_id_fkey FOREIGN KEY (relation_id) REFERENCES public.relations(id);


--
-- Name: relationselements relationselements_way_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationselements
    ADD CONSTRAINT relationselements_way_id_fkey FOREIGN KEY (way_id) REFERENCES public.ways(id);


--
-- Name: relationstags relationtags_relation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationstags
    ADD CONSTRAINT relationtags_relation_id_fkey FOREIGN KEY (relation_id) REFERENCES public.relations(id);


--
-- Name: traversal traversal_way_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traversal
    ADD CONSTRAINT traversal_way_id_fkey FOREIGN KEY (way_id) REFERENCES public.ways(id) ON DELETE CASCADE;


--
-- Name: waysnodes waysnodes_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waysnodes
    ADD CONSTRAINT waysnodes_node_id_fkey FOREIGN KEY (node_id) REFERENCES public.nodes(id) ON DELETE CASCADE;


--
-- Name: waysnodes waysnodes_way_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waysnodes
    ADD CONSTRAINT waysnodes_way_id_fkey FOREIGN KEY (way_id) REFERENCES public.ways(id) ON DELETE CASCADE;


--
-- Name: waystags waystags_relation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waystags
    ADD CONSTRAINT waystags_relation_id_fkey FOREIGN KEY (way_id) REFERENCES public.ways(id);


--
-- Name: TABLE pg_all_foreign_keys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.pg_all_foreign_keys TO PUBLIC;


--
-- Name: TABLE tap_funky; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.tap_funky TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict 6kdCfDYx6TCJayLuejtPwscHyp7ZoXfpMzpYrsPtllKrmAfe6WbQagCKMfj3OyC

