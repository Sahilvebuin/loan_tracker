--
-- PostgreSQL database dump
--

-- Dumped from database version 12.22 (Ubuntu 12.22-2.pgdg20.04+1)
-- Dumped by pg_dump version 17.5 (Ubuntu 17.5-1.pgdg20.04+1)

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: emi_deductions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emi_deductions (
    id bigint NOT NULL,
    amount numeric(15,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    due_on date NOT NULL,
    loan_id integer NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: emi_deductions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emi_deductions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emi_deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emi_deductions_id_seq OWNED BY public.emi_deductions.id;


--
-- Name: loan_audit_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_audit_entries (
    id bigint NOT NULL,
    loan_id bigint,
    auditable_type character varying NOT NULL,
    auditable_id bigint NOT NULL,
    action character varying NOT NULL,
    old_values jsonb DEFAULT '{}'::jsonb NOT NULL,
    new_values jsonb DEFAULT '{}'::jsonb NOT NULL,
    reason text,
    user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_audit_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_audit_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_audit_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_audit_entries_id_seq OWNED BY public.loan_audit_entries.id;


--
-- Name: loan_borrowers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_borrowers (
    id bigint NOT NULL,
    loan_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying DEFAULT 'primary'::character varying NOT NULL,
    ownership_percent numeric(5,2) DEFAULT 100.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_borrowers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_borrowers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_borrowers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_borrowers_id_seq OWNED BY public.loan_borrowers.id;


--
-- Name: loan_calculator_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_calculator_presets (
    id bigint NOT NULL,
    amount_slider_max integer,
    annual_interest_rate numeric(6,3),
    created_at timestamp(6) without time zone NOT NULL,
    key character varying NOT NULL,
    principal numeric(15,2),
    term_months integer,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_calculator_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_calculator_presets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_calculator_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_calculator_presets_id_seq OWNED BY public.loan_calculator_presets.id;


--
-- Name: loan_emi_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_emi_schedules (
    id bigint NOT NULL,
    loan_id bigint NOT NULL,
    installment_no integer NOT NULL,
    due_on date NOT NULL,
    opening_principal numeric(15,2) NOT NULL,
    scheduled_emi numeric(15,2) NOT NULL,
    interest_amount numeric(15,2) NOT NULL,
    principal_amount numeric(15,2) NOT NULL,
    closing_principal numeric(15,2) NOT NULL,
    applicable_interest_rate numeric(6,4) NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    paid_on date,
    actual_paid_amount numeric(15,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_emi_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_emi_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_emi_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_emi_schedules_id_seq OWNED BY public.loan_emi_schedules.id;


--
-- Name: loan_interest_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_interest_rates (
    id bigint NOT NULL,
    loan_id bigint NOT NULL,
    interest_rate numeric(6,4) NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    remarks text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    emi_amount numeric(15,2),
    opening_principal numeric(15,2),
    remaining_months integer
);


--
-- Name: loan_interest_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_interest_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_interest_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_interest_rates_id_seq OWNED BY public.loan_interest_rates.id;


--
-- Name: loan_monthly_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_monthly_snapshots (
    id bigint NOT NULL,
    loan_id bigint NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    opening_balance numeric(15,2) NOT NULL,
    emi_paid numeric(15,2) DEFAULT 0.0 NOT NULL,
    principal_paid numeric(15,2) DEFAULT 0.0 NOT NULL,
    interest_paid numeric(15,2) DEFAULT 0.0 NOT NULL,
    prepayment numeric(15,2) DEFAULT 0.0 NOT NULL,
    charges numeric(15,2) DEFAULT 0.0 NOT NULL,
    total_paid numeric(15,2) DEFAULT 0.0 NOT NULL,
    closing_balance numeric(15,2) NOT NULL,
    interest_rate numeric(6,4),
    remaining_months integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_monthly_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_monthly_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_monthly_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_monthly_snapshots_id_seq OWNED BY public.loan_monthly_snapshots.id;


--
-- Name: loan_payment_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_payment_allocations (
    id bigint NOT NULL,
    loan_payment_id bigint NOT NULL,
    user_id bigint NOT NULL,
    amount numeric(15,2) NOT NULL,
    ownership_percent numeric(5,2),
    contribution_percent numeric(5,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_payment_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_payment_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_payment_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_payment_allocations_id_seq OWNED BY public.loan_payment_allocations.id;


--
-- Name: loan_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_payments (
    id bigint NOT NULL,
    loan_id bigint NOT NULL,
    loan_emi_schedule_id bigint,
    paid_on date NOT NULL,
    amount numeric(15,2) NOT NULL,
    principal_amount numeric(15,2) DEFAULT 0.0 NOT NULL,
    interest_amount numeric(15,2) DEFAULT 0.0 NOT NULL,
    charges_amount numeric(15,2) DEFAULT 0.0 NOT NULL,
    payment_type character varying NOT NULL,
    reference_number character varying,
    notes text,
    balance_before numeric(15,2),
    balance_after numeric(15,2),
    status character varying DEFAULT 'posted'::character varying NOT NULL,
    reversed_payment_id bigint,
    prepayment_id bigint,
    emi_deduction_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loan_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_payments_id_seq OWNED BY public.loan_payments.id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans (
    id bigint NOT NULL,
    annual_interest_rate numeric(5,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    notes text,
    principal numeric(15,2) NOT NULL,
    start_date date NOT NULL,
    term_months integer NOT NULL,
    title character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id integer NOT NULL,
    loan_type character varying,
    lender_name character varying,
    account_number character varying,
    sanctioned_amount numeric(15,2),
    disbursed_amount numeric(15,2),
    interest_rate_type character varying DEFAULT 'fixed'::character varying NOT NULL,
    emi_start_date date,
    emi_amount numeric(15,2),
    emi_due_day integer DEFAULT 15 NOT NULL,
    processing_fee numeric(15,2) DEFAULT 0.0 NOT NULL,
    insurance_amount numeric(15,2) DEFAULT 0.0 NOT NULL,
    other_initial_charges numeric(15,2) DEFAULT 0.0 NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    closed_on date
);


--
-- Name: loans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loans_id_seq OWNED BY public.loans.id;


--
-- Name: prepayments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prepayments (
    id bigint NOT NULL,
    amount numeric(15,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    loan_id integer NOT NULL,
    notes text,
    paid_on date NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    principal_reduction numeric(15,2),
    charges numeric(15,2) DEFAULT 0.0,
    balance_before numeric(15,2),
    balance_after numeric(15,2),
    reference_number character varying,
    reason character varying
);


--
-- Name: prepayments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prepayments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prepayments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prepayments_id_seq OWNED BY public.prepayments.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    account_balance numeric(15,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying NOT NULL,
    name character varying NOT NULL,
    password_digest character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: emi_deductions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emi_deductions ALTER COLUMN id SET DEFAULT nextval('public.emi_deductions_id_seq'::regclass);


--
-- Name: loan_audit_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_audit_entries ALTER COLUMN id SET DEFAULT nextval('public.loan_audit_entries_id_seq'::regclass);


--
-- Name: loan_borrowers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_borrowers ALTER COLUMN id SET DEFAULT nextval('public.loan_borrowers_id_seq'::regclass);


--
-- Name: loan_calculator_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_calculator_presets ALTER COLUMN id SET DEFAULT nextval('public.loan_calculator_presets_id_seq'::regclass);


--
-- Name: loan_emi_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_emi_schedules ALTER COLUMN id SET DEFAULT nextval('public.loan_emi_schedules_id_seq'::regclass);


--
-- Name: loan_interest_rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_interest_rates ALTER COLUMN id SET DEFAULT nextval('public.loan_interest_rates_id_seq'::regclass);


--
-- Name: loan_monthly_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_monthly_snapshots ALTER COLUMN id SET DEFAULT nextval('public.loan_monthly_snapshots_id_seq'::regclass);


--
-- Name: loan_payment_allocations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payment_allocations ALTER COLUMN id SET DEFAULT nextval('public.loan_payment_allocations_id_seq'::regclass);


--
-- Name: loan_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments ALTER COLUMN id SET DEFAULT nextval('public.loan_payments_id_seq'::regclass);


--
-- Name: loans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans ALTER COLUMN id SET DEFAULT nextval('public.loans_id_seq'::regclass);


--
-- Name: prepayments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prepayments ALTER COLUMN id SET DEFAULT nextval('public.prepayments_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	development	2026-04-15 05:16:12.993261	2026-04-15 05:16:12.993267
schema_sha1	b8eb83fa73bbece6aae3ae0dce860da49419309f	2026-04-15 05:16:13.000073	2026-04-15 05:16:13.000075
\.


--
-- Data for Name: emi_deductions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.emi_deductions (id, amount, created_at, due_on, loan_id, updated_at) FROM stdin;
181	25960.46	2026-11-12 09:34:59.262566	2026-04-15	13	2026-11-12 09:34:59.262566
182	25960.46	2026-11-12 09:34:59.292246	2026-05-15	13	2026-11-12 09:34:59.292246
183	25960.46	2026-11-12 09:34:59.313732	2026-06-15	13	2026-11-12 09:34:59.313732
184	25960.46	2026-11-12 09:34:59.337531	2026-07-15	13	2026-11-12 09:34:59.337531
185	25960.46	2026-11-12 09:34:59.367737	2026-08-15	13	2026-11-12 09:34:59.367737
186	25960.46	2026-11-12 09:34:59.389961	2026-09-15	13	2026-11-12 09:34:59.389961
187	25960.46	2026-11-12 09:34:59.416406	2026-10-15	13	2026-11-12 09:34:59.416406
188	25960.46	2026-11-12 09:35:01.27651	2026-04-15	14	2026-11-12 09:35:01.27651
189	25960.46	2026-11-12 09:35:01.295439	2026-05-15	14	2026-11-12 09:35:01.295439
190	25960.46	2026-11-12 09:35:01.3153	2026-06-15	14	2026-11-12 09:35:01.3153
191	25960.46	2026-11-12 09:35:01.334451	2026-07-15	14	2026-11-12 09:35:01.334451
192	25960.46	2026-11-12 09:35:01.355702	2026-08-15	14	2026-11-12 09:35:01.355702
193	25960.46	2026-11-12 09:35:01.376873	2026-09-15	14	2026-11-12 09:35:01.376873
194	25960.46	2026-11-12 09:35:01.398734	2026-10-15	14	2026-11-12 09:35:01.398734
195	4705.63	2026-11-12 09:35:03.205306	2026-04-15	15	2026-11-12 09:35:03.205306
196	4705.63	2026-11-12 09:35:03.228658	2026-05-15	15	2026-11-12 09:35:03.228658
197	4705.63	2026-11-12 09:35:03.249434	2026-06-15	15	2026-11-12 09:35:03.249434
198	4705.63	2026-11-12 09:35:03.272029	2026-07-15	15	2026-11-12 09:35:03.272029
199	4705.63	2026-11-12 09:35:03.293005	2026-08-15	15	2026-11-12 09:35:03.293005
200	4705.63	2026-11-12 09:35:03.31416	2026-09-15	15	2026-11-12 09:35:03.31416
201	4705.63	2026-11-12 09:35:03.336543	2026-10-15	15	2026-11-12 09:35:03.336543
202	4705.63	2026-11-12 09:35:05.174659	2026-04-15	16	2026-11-12 09:35:05.174659
203	4705.63	2026-11-12 09:35:05.19339	2026-05-15	16	2026-11-12 09:35:05.19339
204	4705.63	2026-11-12 09:35:05.214576	2026-06-15	16	2026-11-12 09:35:05.214576
205	4705.63	2026-11-12 09:35:05.235702	2026-07-15	16	2026-11-12 09:35:05.235702
206	4705.63	2026-11-12 09:35:05.255474	2026-08-15	16	2026-11-12 09:35:05.255474
207	4705.63	2026-11-12 09:35:05.27592	2026-09-15	16	2026-11-12 09:35:05.27592
208	4705.63	2026-11-12 09:35:05.30717	2026-10-15	16	2026-11-12 09:35:05.30717
\.


--
-- Data for Name: loan_audit_entries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_audit_entries (id, loan_id, auditable_type, auditable_id, action, old_values, new_values, reason, user_id, created_at, updated_at) FROM stdin;
1	15	LoanPayment	25	create	{}	{"amount": "50000.0", "paid_on": "2026-09-17", "payment_type": "prepayment", "balance_after": "433862.99", "interest_amount": "0.0", "principal_amount": "50000.0"}	\N	3	2026-09-17 12:44:14.884249	2026-09-17 12:44:14.884249
2	15	LoanPayment	25	reverse	{"amount": "50000.0", "status": "posted", "balance_after": "433862.99", "principal_amount": "50000.0"}	{"status": "reversed"}	Test prepayment removed (manual cleanup)	3	2026-09-30 06:21:47.166318	2026-09-30 06:21:47.166318
3	13	LoanPayment	152	create	{}	{"amount": "25960.46", "paid_on": "2026-10-15", "payment_type": "emi", "balance_after": "2573110.11", "interest_amount": "16571.04", "principal_amount": "9389.42"}	\N	\N	2026-10-21 08:01:29.94376	2026-10-21 08:01:29.94376
4	14	LoanPayment	153	create	{}	{"amount": "25960.46", "paid_on": "2026-10-15", "payment_type": "emi", "balance_after": "2573110.11", "interest_amount": "16571.04", "principal_amount": "9389.42"}	\N	\N	2026-10-21 08:01:30.069431	2026-10-21 08:01:30.069431
5	15	LoanPayment	154	create	{}	{"amount": "4705.63", "paid_on": "2026-10-15", "payment_type": "emi", "balance_after": "482201.57", "interest_amount": "3044.3", "principal_amount": "1661.33"}	\N	\N	2026-10-21 08:01:30.152424	2026-10-21 08:01:30.152424
6	16	LoanPayment	155	create	{}	{"amount": "4705.63", "paid_on": "2026-10-15", "payment_type": "emi", "balance_after": "482201.66", "interest_amount": "3044.3", "principal_amount": "1661.33"}	\N	\N	2026-10-21 08:01:30.227935	2026-10-21 08:01:30.227935
\.


--
-- Data for Name: loan_borrowers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_borrowers (id, loan_id, user_id, role, ownership_percent, created_at, updated_at) FROM stdin;
1	13	3	primary	100.00	2026-09-17 10:24:52.016656	2026-09-17 10:24:52.016656
2	14	4	primary	100.00	2026-09-17 10:24:52.016656	2026-09-17 10:24:52.016656
3	15	3	primary	100.00	2026-09-17 10:24:52.016656	2026-09-17 10:24:52.016656
4	16	4	primary	100.00	2026-09-17 10:24:52.016656	2026-09-17 10:24:52.016656
\.


--
-- Data for Name: loan_calculator_presets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_calculator_presets (id, amount_slider_max, annual_interest_rate, created_at, key, principal, term_months, updated_at) FROM stdin;
3	20000000	7.950	2026-06-15 09:25:29.420889	home	2637592.17	165	2026-11-12 09:33:26.979707
4	5000000	7.800	2026-06-15 09:25:29.431395	additional	493615.07	172	2026-11-12 09:33:26.986119
\.


--
-- Data for Name: loan_emi_schedules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_emi_schedules (id, loan_id, installment_no, due_on, opening_principal, scheduled_emi, interest_amount, principal_amount, closing_principal, applicable_interest_rate, status, paid_on, actual_paid_amount, created_at, updated_at) FROM stdin;
5003	16	151	2038-10-15	93556.75	4790.00	608.12	4181.88	89374.87	7.8000	pending	\N	\N	2026-11-12 09:35:06.567153	2026-11-12 09:35:06.567153
5004	16	152	2038-11-15	89374.87	4790.00	580.94	4209.06	85165.80	7.8000	pending	\N	\N	2026-11-12 09:35:06.582246	2026-11-12 09:35:06.582246
5005	16	153	2038-12-15	85165.80	4790.00	553.58	4236.42	80929.38	7.8000	pending	\N	\N	2026-11-12 09:35:06.609898	2026-11-12 09:35:06.609898
5006	16	154	2039-01-15	80929.38	4790.00	526.04	4263.96	76665.42	7.8000	pending	\N	\N	2026-11-12 09:35:06.634954	2026-11-12 09:35:06.634954
5007	16	155	2039-02-15	76665.42	4790.00	498.33	4291.67	72373.75	7.8000	pending	\N	\N	2026-11-12 09:35:06.642591	2026-11-12 09:35:06.642591
5008	16	156	2039-03-15	72373.75	4790.00	470.43	4319.57	68054.18	7.8000	pending	\N	\N	2026-11-12 09:35:06.649353	2026-11-12 09:35:06.649353
5009	16	157	2039-04-15	68054.18	4790.00	442.35	4347.65	63706.53	7.8000	pending	\N	\N	2026-11-12 09:35:06.657513	2026-11-12 09:35:06.657513
5010	16	158	2039-05-15	63706.53	4790.00	414.09	4375.91	59330.62	7.8000	pending	\N	\N	2026-11-12 09:35:06.663471	2026-11-12 09:35:06.663471
5011	16	159	2039-06-15	59330.62	4790.00	385.65	4404.35	54926.27	7.8000	pending	\N	\N	2026-11-12 09:35:06.670919	2026-11-12 09:35:06.670919
5012	16	160	2039-07-15	54926.27	4790.00	357.02	4432.98	50493.29	7.8000	pending	\N	\N	2026-11-12 09:35:06.677204	2026-11-12 09:35:06.677204
5013	16	161	2039-08-15	50493.29	4790.00	328.21	4461.79	46031.50	7.8000	pending	\N	\N	2026-11-12 09:35:06.683451	2026-11-12 09:35:06.683451
5014	16	162	2039-09-15	46031.50	4790.00	299.20	4490.80	41540.70	7.8000	pending	\N	\N	2026-11-12 09:35:06.692184	2026-11-12 09:35:06.692184
5015	16	163	2039-10-15	41540.70	4790.00	270.01	4519.99	37020.72	7.8000	pending	\N	\N	2026-11-12 09:35:06.69776	2026-11-12 09:35:06.69776
5016	16	164	2039-11-15	37020.72	4790.00	240.63	4549.37	32471.35	7.8000	pending	\N	\N	2026-11-12 09:35:06.704671	2026-11-12 09:35:06.704671
5017	16	165	2039-12-15	32471.35	4790.00	211.06	4578.94	27892.42	7.8000	pending	\N	\N	2026-11-12 09:35:06.711538	2026-11-12 09:35:06.711538
5018	16	166	2040-01-15	27892.42	4790.00	181.30	4608.70	23283.72	7.8000	pending	\N	\N	2026-11-12 09:35:06.717378	2026-11-12 09:35:06.717378
5019	16	167	2040-02-15	23283.72	4790.00	151.34	4638.66	18645.06	7.8000	pending	\N	\N	2026-11-12 09:35:06.724452	2026-11-12 09:35:06.724452
5020	16	168	2040-03-15	18645.06	4790.00	121.19	4668.81	13976.25	7.8000	pending	\N	\N	2026-11-12 09:35:06.729501	2026-11-12 09:35:06.729501
5021	16	169	2040-04-15	13976.25	4790.00	90.85	4699.15	9277.10	7.8000	pending	\N	\N	2026-11-12 09:35:06.735695	2026-11-12 09:35:06.735695
5022	16	170	2040-05-15	9277.10	4790.00	60.30	4729.70	4547.40	7.8000	pending	\N	\N	2026-11-12 09:35:06.741453	2026-11-12 09:35:06.741453
5023	16	171	2040-06-15	4547.40	4576.96	29.56	4547.40	0.00	7.8000	pending	\N	\N	2026-11-12 09:35:06.749519	2026-11-12 09:35:06.749519
4350	13	1	2026-04-15	2637592.17	25960.46	16924.55	9035.91	2628556.26	7.7000	paid	2026-04-15	25960.46	2026-11-12 09:34:59.78542	2026-11-12 09:34:59.78542
4351	13	2	2026-05-15	2628556.26	25960.46	16866.57	9093.89	2619462.36	7.7000	paid	2026-05-15	25960.46	2026-11-12 09:34:59.79178	2026-11-12 09:34:59.79178
4352	13	3	2026-06-15	2619462.36	25960.46	16808.22	9152.25	2610310.11	7.7000	paid	2026-06-15	25960.46	2026-11-12 09:34:59.797266	2026-11-12 09:34:59.797266
4353	13	4	2026-07-15	2610310.11	25960.46	16749.49	9210.97	2601099.14	7.7000	paid	2026-07-15	25960.46	2026-11-12 09:34:59.803627	2026-11-12 09:34:59.803627
4354	13	5	2026-08-15	2601099.14	25960.46	16690.39	9270.08	2591829.06	7.7000	paid	2026-08-15	25960.46	2026-11-12 09:34:59.809516	2026-11-12 09:34:59.809516
4355	13	6	2026-09-15	2591829.06	25960.46	16630.90	9329.56	2582499.50	7.7000	paid	2026-09-15	25960.46	2026-11-12 09:34:59.8207	2026-11-12 09:34:59.8207
4356	13	7	2026-10-15	2582499.50	25960.46	16571.04	9389.43	2573110.07	7.7000	paid	2026-10-15	25960.46	2026-11-12 09:34:59.827337	2026-11-12 09:34:59.827337
4357	13	8	2026-11-15	2572312.50	26310.00	17041.57	9268.43	2563044.07	7.9500	pending	\N	\N	2026-11-12 09:34:59.834963	2026-11-12 09:34:59.834963
4358	13	9	2026-12-15	2563044.07	26310.00	16980.17	9329.83	2553714.24	7.9500	pending	\N	\N	2026-11-12 09:34:59.840809	2026-11-12 09:34:59.840809
4359	13	10	2027-01-15	2553714.24	26310.00	16918.36	9391.64	2544322.59	7.9500	pending	\N	\N	2026-11-12 09:34:59.845786	2026-11-12 09:34:59.845786
4360	13	11	2027-02-15	2544322.59	26310.00	16856.14	9453.86	2534868.73	7.9500	pending	\N	\N	2026-11-12 09:34:59.851974	2026-11-12 09:34:59.851974
4361	13	12	2027-03-15	2534868.73	26310.00	16793.51	9516.49	2525352.24	7.9500	pending	\N	\N	2026-11-12 09:34:59.85804	2026-11-12 09:34:59.85804
4362	13	13	2027-04-15	2525352.24	26310.00	16730.46	9579.54	2515772.70	7.9500	pending	\N	\N	2026-11-12 09:34:59.863483	2026-11-12 09:34:59.863483
4363	13	14	2027-05-15	2515772.70	26310.00	16666.99	9643.01	2506129.69	7.9500	pending	\N	\N	2026-11-12 09:34:59.870428	2026-11-12 09:34:59.870428
4364	13	15	2027-06-15	2506129.69	26310.00	16603.11	9706.89	2496422.80	7.9500	pending	\N	\N	2026-11-12 09:34:59.88205	2026-11-12 09:34:59.88205
4365	13	16	2027-07-15	2496422.80	26310.00	16538.80	9771.20	2486651.60	7.9500	pending	\N	\N	2026-11-12 09:34:59.889785	2026-11-12 09:34:59.889785
4366	13	17	2027-08-15	2486651.60	26310.00	16474.07	9835.93	2476815.67	7.9500	pending	\N	\N	2026-11-12 09:34:59.896876	2026-11-12 09:34:59.896876
4367	13	18	2027-09-15	2476815.67	26310.00	16408.90	9901.10	2466914.57	7.9500	pending	\N	\N	2026-11-12 09:34:59.903466	2026-11-12 09:34:59.903466
4368	13	19	2027-10-15	2466914.57	26310.00	16343.31	9966.69	2456947.88	7.9500	pending	\N	\N	2026-11-12 09:34:59.909765	2026-11-12 09:34:59.909765
4369	13	20	2027-11-15	2456947.88	26310.00	16277.28	10032.72	2446915.16	7.9500	pending	\N	\N	2026-11-12 09:34:59.918735	2026-11-12 09:34:59.918735
4370	13	21	2027-12-15	2446915.16	26310.00	16210.81	10099.19	2436815.97	7.9500	pending	\N	\N	2026-11-12 09:34:59.925626	2026-11-12 09:34:59.925626
4371	13	22	2028-01-15	2436815.97	26310.00	16143.91	10166.09	2426649.88	7.9500	pending	\N	\N	2026-11-12 09:34:59.931574	2026-11-12 09:34:59.931574
4372	13	23	2028-02-15	2426649.88	26310.00	16076.56	10233.44	2416416.43	7.9500	pending	\N	\N	2026-11-12 09:34:59.938493	2026-11-12 09:34:59.938493
4373	13	24	2028-03-15	2416416.43	26310.00	16008.76	10301.24	2406115.19	7.9500	pending	\N	\N	2026-11-12 09:34:59.947501	2026-11-12 09:34:59.947501
4374	13	25	2028-04-15	2406115.19	26310.00	15940.51	10369.49	2395745.71	7.9500	pending	\N	\N	2026-11-12 09:34:59.954121	2026-11-12 09:34:59.954121
4375	13	26	2028-05-15	2395745.71	26310.00	15871.82	10438.18	2385307.52	7.9500	pending	\N	\N	2026-11-12 09:34:59.961145	2026-11-12 09:34:59.961145
4376	13	27	2028-06-15	2385307.52	26310.00	15802.66	10507.34	2374800.18	7.9500	pending	\N	\N	2026-11-12 09:34:59.96711	2026-11-12 09:34:59.96711
4377	13	28	2028-07-15	2374800.18	26310.00	15733.05	10576.95	2364223.23	7.9500	pending	\N	\N	2026-11-12 09:34:59.973549	2026-11-12 09:34:59.973549
4378	13	29	2028-08-15	2364223.23	26310.00	15662.98	10647.02	2353576.21	7.9500	pending	\N	\N	2026-11-12 09:34:59.979828	2026-11-12 09:34:59.979828
4379	13	30	2028-09-15	2353576.21	26310.00	15592.44	10717.56	2342858.66	7.9500	pending	\N	\N	2026-11-12 09:34:59.985808	2026-11-12 09:34:59.985808
4380	13	31	2028-10-15	2342858.66	26310.00	15521.44	10788.56	2332070.09	7.9500	pending	\N	\N	2026-11-12 09:34:59.991614	2026-11-12 09:34:59.991614
4381	13	32	2028-11-15	2332070.09	26310.00	15449.96	10860.04	2321210.06	7.9500	pending	\N	\N	2026-11-12 09:34:59.999358	2026-11-12 09:34:59.999358
4382	13	33	2028-12-15	2321210.06	26310.00	15378.02	10931.98	2310278.07	7.9500	pending	\N	\N	2026-11-12 09:35:00.009875	2026-11-12 09:35:00.009875
4383	13	34	2029-01-15	2310278.07	26310.00	15305.59	11004.41	2299273.67	7.9500	pending	\N	\N	2026-11-12 09:35:00.016219	2026-11-12 09:35:00.016219
4384	13	35	2029-02-15	2299273.67	26310.00	15232.69	11077.31	2288196.36	7.9500	pending	\N	\N	2026-11-12 09:35:00.024365	2026-11-12 09:35:00.024365
4385	13	36	2029-03-15	2288196.36	26310.00	15159.30	11150.70	2277045.66	7.9500	pending	\N	\N	2026-11-12 09:35:00.029649	2026-11-12 09:35:00.029649
4386	13	37	2029-04-15	2277045.66	26310.00	15085.43	11224.57	2265821.08	7.9500	pending	\N	\N	2026-11-12 09:35:00.036398	2026-11-12 09:35:00.036398
4387	13	38	2029-05-15	2265821.08	26310.00	15011.06	11298.94	2254522.15	7.9500	pending	\N	\N	2026-11-12 09:35:00.043512	2026-11-12 09:35:00.043512
4388	13	39	2029-06-15	2254522.15	26310.00	14936.21	11373.79	2243148.36	7.9500	pending	\N	\N	2026-11-12 09:35:00.049205	2026-11-12 09:35:00.049205
4389	13	40	2029-07-15	2243148.36	26310.00	14860.86	11449.14	2231699.22	7.9500	pending	\N	\N	2026-11-12 09:35:00.055546	2026-11-12 09:35:00.055546
4390	13	41	2029-08-15	2231699.22	26310.00	14785.01	11524.99	2220174.22	7.9500	pending	\N	\N	2026-11-12 09:35:00.063119	2026-11-12 09:35:00.063119
4391	13	42	2029-09-15	2220174.22	26310.00	14708.65	11601.35	2208572.88	7.9500	pending	\N	\N	2026-11-12 09:35:00.069042	2026-11-12 09:35:00.069042
4392	13	43	2029-10-15	2208572.88	26310.00	14631.80	11678.20	2196894.67	7.9500	pending	\N	\N	2026-11-12 09:35:00.075185	2026-11-12 09:35:00.075185
4393	13	44	2029-11-15	2196894.67	26310.00	14554.43	11755.57	2185139.10	7.9500	pending	\N	\N	2026-11-12 09:35:00.081633	2026-11-12 09:35:00.081633
4394	13	45	2029-12-15	2185139.10	26310.00	14476.55	11833.45	2173305.65	7.9500	pending	\N	\N	2026-11-12 09:35:00.087973	2026-11-12 09:35:00.087973
4395	13	46	2030-01-15	2173305.65	26310.00	14398.15	11911.85	2161393.80	7.9500	pending	\N	\N	2026-11-12 09:35:00.093864	2026-11-12 09:35:00.093864
4396	13	47	2030-02-15	2161393.80	26310.00	14319.23	11990.77	2149403.03	7.9500	pending	\N	\N	2026-11-12 09:35:00.099939	2026-11-12 09:35:00.099939
4397	13	48	2030-03-15	2149403.03	26310.00	14239.80	12070.20	2137332.82	7.9500	pending	\N	\N	2026-11-12 09:35:00.106396	2026-11-12 09:35:00.106396
4398	13	49	2030-04-15	2137332.82	26310.00	14159.83	12150.17	2125182.65	7.9500	pending	\N	\N	2026-11-12 09:35:00.111802	2026-11-12 09:35:00.111802
4399	13	50	2030-05-15	2125182.65	26310.00	14079.34	12230.66	2112951.99	7.9500	pending	\N	\N	2026-11-12 09:35:00.120092	2026-11-12 09:35:00.120092
4400	13	51	2030-06-15	2112951.99	26310.00	13998.31	12311.69	2100640.30	7.9500	pending	\N	\N	2026-11-12 09:35:00.125732	2026-11-12 09:35:00.125732
4401	13	52	2030-07-15	2100640.30	26310.00	13916.74	12393.26	2088247.04	7.9500	pending	\N	\N	2026-11-12 09:35:00.132411	2026-11-12 09:35:00.132411
4402	13	53	2030-08-15	2088247.04	26310.00	13834.64	12475.36	2075771.68	7.9500	pending	\N	\N	2026-11-12 09:35:00.138685	2026-11-12 09:35:00.138685
4403	13	54	2030-09-15	2075771.68	26310.00	13751.99	12558.01	2063213.66	7.9500	pending	\N	\N	2026-11-12 09:35:00.144298	2026-11-12 09:35:00.144298
4404	13	55	2030-10-15	2063213.66	26310.00	13668.79	12641.21	2050572.45	7.9500	pending	\N	\N	2026-11-12 09:35:00.149523	2026-11-12 09:35:00.149523
4405	13	56	2030-11-15	2050572.45	26310.00	13585.04	12724.96	2037847.50	7.9500	pending	\N	\N	2026-11-12 09:35:00.159	2026-11-12 09:35:00.159
4406	13	57	2030-12-15	2037847.50	26310.00	13500.74	12809.26	2025038.24	7.9500	pending	\N	\N	2026-11-12 09:35:00.164233	2026-11-12 09:35:00.164233
4407	13	58	2031-01-15	2025038.24	26310.00	13415.88	12894.12	2012144.11	7.9500	pending	\N	\N	2026-11-12 09:35:00.1718	2026-11-12 09:35:00.1718
4408	13	59	2031-02-15	2012144.11	26310.00	13330.45	12979.55	1999164.57	7.9500	pending	\N	\N	2026-11-12 09:35:00.179325	2026-11-12 09:35:00.179325
4409	13	60	2031-03-15	1999164.57	26310.00	13244.47	13065.53	1986099.03	7.9500	pending	\N	\N	2026-11-12 09:35:00.187171	2026-11-12 09:35:00.187171
4410	13	61	2031-04-15	1986099.03	26310.00	13157.91	13152.09	1972946.94	7.9500	pending	\N	\N	2026-11-12 09:35:00.193755	2026-11-12 09:35:00.193755
4411	13	62	2031-05-15	1972946.94	26310.00	13070.77	13239.23	1959707.71	7.9500	pending	\N	\N	2026-11-12 09:35:00.198908	2026-11-12 09:35:00.198908
4412	13	63	2031-06-15	1959707.71	26310.00	12983.06	13326.94	1946380.78	7.9500	pending	\N	\N	2026-11-12 09:35:00.205316	2026-11-12 09:35:00.205316
4413	13	64	2031-07-15	1946380.78	26310.00	12894.77	13415.23	1932965.55	7.9500	pending	\N	\N	2026-11-12 09:35:00.211168	2026-11-12 09:35:00.211168
4414	13	65	2031-08-15	1932965.55	26310.00	12805.90	13504.10	1919461.45	7.9500	pending	\N	\N	2026-11-12 09:35:00.216953	2026-11-12 09:35:00.216953
4415	13	66	2031-09-15	1919461.45	26310.00	12716.43	13593.57	1905867.88	7.9500	pending	\N	\N	2026-11-12 09:35:00.222994	2026-11-12 09:35:00.222994
4416	13	67	2031-10-15	1905867.88	26310.00	12626.37	13683.63	1892184.25	7.9500	pending	\N	\N	2026-11-12 09:35:00.229949	2026-11-12 09:35:00.229949
4417	13	68	2031-11-15	1892184.25	26310.00	12535.72	13774.28	1878409.97	7.9500	pending	\N	\N	2026-11-12 09:35:00.237138	2026-11-12 09:35:00.237138
4418	13	69	2031-12-15	1878409.97	26310.00	12444.47	13865.53	1864544.44	7.9500	pending	\N	\N	2026-11-12 09:35:00.242645	2026-11-12 09:35:00.242645
4419	13	70	2032-01-15	1864544.44	26310.00	12352.61	13957.39	1850587.05	7.9500	pending	\N	\N	2026-11-12 09:35:00.249028	2026-11-12 09:35:00.249028
4420	13	71	2032-02-15	1850587.05	26310.00	12260.14	14049.86	1836537.19	7.9500	pending	\N	\N	2026-11-12 09:35:00.255581	2026-11-12 09:35:00.255581
4421	13	72	2032-03-15	1836537.19	26310.00	12167.06	14142.94	1822394.24	7.9500	pending	\N	\N	2026-11-12 09:35:00.260969	2026-11-12 09:35:00.260969
4422	13	73	2032-04-15	1822394.24	26310.00	12073.36	14236.64	1808157.61	7.9500	pending	\N	\N	2026-11-12 09:35:00.267728	2026-11-12 09:35:00.267728
4423	13	74	2032-05-15	1808157.61	26310.00	11979.04	14330.96	1793826.65	7.9500	pending	\N	\N	2026-11-12 09:35:00.275257	2026-11-12 09:35:00.275257
4424	13	75	2032-06-15	1793826.65	26310.00	11884.10	14425.90	1779400.75	7.9500	pending	\N	\N	2026-11-12 09:35:00.280201	2026-11-12 09:35:00.280201
4425	13	76	2032-07-15	1779400.75	26310.00	11788.53	14521.47	1764879.28	7.9500	pending	\N	\N	2026-11-12 09:35:00.289434	2026-11-12 09:35:00.289434
4426	13	77	2032-08-15	1764879.28	26310.00	11692.33	14617.67	1750261.61	7.9500	pending	\N	\N	2026-11-12 09:35:00.295061	2026-11-12 09:35:00.295061
4427	13	78	2032-09-15	1750261.61	26310.00	11595.48	14714.52	1735547.09	7.9500	pending	\N	\N	2026-11-12 09:35:00.303467	2026-11-12 09:35:00.303467
4428	13	79	2032-10-15	1735547.09	26310.00	11498.00	14812.00	1720735.09	7.9500	pending	\N	\N	2026-11-12 09:35:00.309631	2026-11-12 09:35:00.309631
4429	13	80	2032-11-15	1720735.09	26310.00	11399.87	14910.13	1705824.96	7.9500	pending	\N	\N	2026-11-12 09:35:00.31445	2026-11-12 09:35:00.31445
4430	13	81	2032-12-15	1705824.96	26310.00	11301.09	15008.91	1690816.05	7.9500	pending	\N	\N	2026-11-12 09:35:00.321881	2026-11-12 09:35:00.321881
4431	13	82	2033-01-15	1690816.05	26310.00	11201.66	15108.34	1675707.71	7.9500	pending	\N	\N	2026-11-12 09:35:00.327019	2026-11-12 09:35:00.327019
4432	13	83	2033-02-15	1675707.71	26310.00	11101.56	15208.44	1660499.27	7.9500	pending	\N	\N	2026-11-12 09:35:00.331951	2026-11-12 09:35:00.331951
4433	13	84	2033-03-15	1660499.27	26310.00	11000.81	15309.19	1645190.08	7.9500	pending	\N	\N	2026-11-12 09:35:00.339702	2026-11-12 09:35:00.339702
4434	13	85	2033-04-15	1645190.08	26310.00	10899.38	15410.62	1629779.46	7.9500	pending	\N	\N	2026-11-12 09:35:00.345271	2026-11-12 09:35:00.345271
4435	13	86	2033-05-15	1629779.46	26310.00	10797.29	15512.71	1614266.75	7.9500	pending	\N	\N	2026-11-12 09:35:00.35131	2026-11-12 09:35:00.35131
4436	13	87	2033-06-15	1614266.75	26310.00	10694.52	15615.48	1598651.27	7.9500	pending	\N	\N	2026-11-12 09:35:00.358757	2026-11-12 09:35:00.358757
4437	13	88	2033-07-15	1598651.27	26310.00	10591.06	15718.94	1582932.33	7.9500	pending	\N	\N	2026-11-12 09:35:00.364867	2026-11-12 09:35:00.364867
4438	13	89	2033-08-15	1582932.33	26310.00	10486.93	15823.07	1567109.26	7.9500	pending	\N	\N	2026-11-12 09:35:00.371871	2026-11-12 09:35:00.371871
4439	13	90	2033-09-15	1567109.26	26310.00	10382.10	15927.90	1551181.36	7.9500	pending	\N	\N	2026-11-12 09:35:00.377253	2026-11-12 09:35:00.377253
4440	13	91	2033-10-15	1551181.36	26310.00	10276.58	16033.42	1535147.94	7.9500	pending	\N	\N	2026-11-12 09:35:00.38258	2026-11-12 09:35:00.38258
4441	13	92	2033-11-15	1535147.94	26310.00	10170.36	16139.64	1519008.29	7.9500	pending	\N	\N	2026-11-12 09:35:00.389087	2026-11-12 09:35:00.389087
4442	13	93	2033-12-15	1519008.29	26310.00	10063.43	16246.57	1502761.72	7.9500	pending	\N	\N	2026-11-12 09:35:00.396653	2026-11-12 09:35:00.396653
4443	13	94	2034-01-15	1502761.72	26310.00	9955.80	16354.20	1486407.52	7.9500	pending	\N	\N	2026-11-12 09:35:00.403451	2026-11-12 09:35:00.403451
4444	13	95	2034-02-15	1486407.52	26310.00	9847.45	16462.55	1469944.97	7.9500	pending	\N	\N	2026-11-12 09:35:00.410794	2026-11-12 09:35:00.410794
4445	13	96	2034-03-15	1469944.97	26310.00	9738.39	16571.61	1453373.35	7.9500	pending	\N	\N	2026-11-12 09:35:00.41623	2026-11-12 09:35:00.41623
4446	13	97	2034-04-15	1453373.35	26310.00	9628.60	16681.40	1436691.95	7.9500	pending	\N	\N	2026-11-12 09:35:00.423426	2026-11-12 09:35:00.423426
4447	13	98	2034-05-15	1436691.95	26310.00	9518.08	16791.92	1419900.03	7.9500	pending	\N	\N	2026-11-12 09:35:00.429407	2026-11-12 09:35:00.429407
4448	13	99	2034-06-15	1419900.03	26310.00	9406.84	16903.16	1402996.87	7.9500	pending	\N	\N	2026-11-12 09:35:00.435622	2026-11-12 09:35:00.435622
4449	13	100	2034-07-15	1402996.87	26310.00	9294.85	17015.15	1385981.73	7.9500	pending	\N	\N	2026-11-12 09:35:00.4416	2026-11-12 09:35:00.4416
4450	13	101	2034-08-15	1385981.73	26310.00	9182.13	17127.87	1368853.86	7.9500	pending	\N	\N	2026-11-12 09:35:00.448965	2026-11-12 09:35:00.448965
4451	13	102	2034-09-15	1368853.86	26310.00	9068.66	17241.34	1351612.51	7.9500	pending	\N	\N	2026-11-12 09:35:00.455817	2026-11-12 09:35:00.455817
4452	13	103	2034-10-15	1351612.51	26310.00	8954.43	17355.57	1334256.94	7.9500	pending	\N	\N	2026-11-12 09:35:00.462772	2026-11-12 09:35:00.462772
4453	13	104	2034-11-15	1334256.94	26310.00	8839.45	17470.55	1316786.40	7.9500	pending	\N	\N	2026-11-12 09:35:00.468869	2026-11-12 09:35:00.468869
4454	13	105	2034-12-15	1316786.40	26310.00	8723.71	17586.29	1299200.11	7.9500	pending	\N	\N	2026-11-12 09:35:00.475122	2026-11-12 09:35:00.475122
4455	13	106	2035-01-15	1299200.11	26310.00	8607.20	17702.80	1281497.31	7.9500	pending	\N	\N	2026-11-12 09:35:00.481291	2026-11-12 09:35:00.481291
4456	13	107	2035-02-15	1281497.31	26310.00	8489.92	17820.08	1263677.23	7.9500	pending	\N	\N	2026-11-12 09:35:00.487647	2026-11-12 09:35:00.487647
4457	13	108	2035-03-15	1263677.23	26310.00	8371.86	17938.14	1245739.09	7.9500	pending	\N	\N	2026-11-12 09:35:00.493358	2026-11-12 09:35:00.493358
4458	13	109	2035-04-15	1245739.09	26310.00	8253.02	18056.98	1227682.11	7.9500	pending	\N	\N	2026-11-12 09:35:00.500408	2026-11-12 09:35:00.500408
4459	13	110	2035-05-15	1227682.11	26310.00	8133.39	18176.61	1209505.50	7.9500	pending	\N	\N	2026-11-12 09:35:00.507301	2026-11-12 09:35:00.507301
4460	13	111	2035-06-15	1209505.50	26310.00	8012.97	18297.03	1191208.48	7.9500	pending	\N	\N	2026-11-12 09:35:00.512783	2026-11-12 09:35:00.512783
4461	13	112	2035-07-15	1191208.48	26310.00	7891.76	18418.24	1172790.23	7.9500	pending	\N	\N	2026-11-12 09:35:00.519609	2026-11-12 09:35:00.519609
4462	13	113	2035-08-15	1172790.23	26310.00	7769.74	18540.26	1154249.97	7.9500	pending	\N	\N	2026-11-12 09:35:00.525503	2026-11-12 09:35:00.525503
4463	13	114	2035-09-15	1154249.97	26310.00	7646.91	18663.09	1135586.88	7.9500	pending	\N	\N	2026-11-12 09:35:00.531557	2026-11-12 09:35:00.531557
4464	13	115	2035-10-15	1135586.88	26310.00	7523.26	18786.74	1116800.14	7.9500	pending	\N	\N	2026-11-12 09:35:00.537771	2026-11-12 09:35:00.537771
4465	13	116	2035-11-15	1116800.14	26310.00	7398.80	18911.20	1097888.94	7.9500	pending	\N	\N	2026-11-12 09:35:00.543551	2026-11-12 09:35:00.543551
4466	13	117	2035-12-15	1097888.94	26310.00	7273.51	19036.49	1078852.45	7.9500	pending	\N	\N	2026-11-12 09:35:00.551331	2026-11-12 09:35:00.551331
4467	13	118	2036-01-15	1078852.45	26310.00	7147.40	19162.60	1059689.85	7.9500	pending	\N	\N	2026-11-12 09:35:00.562267	2026-11-12 09:35:00.562267
4468	13	119	2036-02-15	1059689.85	26310.00	7020.45	19289.55	1040400.30	7.9500	pending	\N	\N	2026-11-12 09:35:00.571051	2026-11-12 09:35:00.571051
4469	13	120	2036-03-15	1040400.30	26310.00	6892.65	19417.35	1020982.95	7.9500	pending	\N	\N	2026-11-12 09:35:00.580409	2026-11-12 09:35:00.580409
4470	13	121	2036-04-15	1020982.95	26310.00	6764.01	19545.99	1001436.96	7.9500	pending	\N	\N	2026-11-12 09:35:00.587042	2026-11-12 09:35:00.587042
4471	13	122	2036-05-15	1001436.96	26310.00	6634.52	19675.48	981761.48	7.9500	pending	\N	\N	2026-11-12 09:35:00.5931	2026-11-12 09:35:00.5931
4472	13	123	2036-06-15	981761.48	26310.00	6504.17	19805.83	961955.65	7.9500	pending	\N	\N	2026-11-12 09:35:00.599261	2026-11-12 09:35:00.599261
4473	13	124	2036-07-15	961955.65	26310.00	6372.96	19937.04	942018.61	7.9500	pending	\N	\N	2026-11-12 09:35:00.605652	2026-11-12 09:35:00.605652
4474	13	125	2036-08-15	942018.61	26310.00	6240.87	20069.13	921949.48	7.9500	pending	\N	\N	2026-11-12 09:35:00.611121	2026-11-12 09:35:00.611121
4475	13	126	2036-09-15	921949.48	26310.00	6107.92	20202.08	901747.40	7.9500	pending	\N	\N	2026-11-12 09:35:00.619521	2026-11-12 09:35:00.619521
4476	13	127	2036-10-15	901747.40	26310.00	5974.08	20335.92	881411.47	7.9500	pending	\N	\N	2026-11-12 09:35:00.625496	2026-11-12 09:35:00.625496
4477	13	128	2036-11-15	881411.47	26310.00	5839.35	20470.65	860940.82	7.9500	pending	\N	\N	2026-11-12 09:35:00.631812	2026-11-12 09:35:00.631812
4478	13	129	2036-12-15	860940.82	26310.00	5703.73	20606.27	840334.56	7.9500	pending	\N	\N	2026-11-12 09:35:00.638277	2026-11-12 09:35:00.638277
4479	13	130	2037-01-15	840334.56	26310.00	5567.22	20742.78	819591.77	7.9500	pending	\N	\N	2026-11-12 09:35:00.644554	2026-11-12 09:35:00.644554
4480	13	131	2037-02-15	819591.77	26310.00	5429.80	20880.20	798711.57	7.9500	pending	\N	\N	2026-11-12 09:35:00.651205	2026-11-12 09:35:00.651205
4481	13	132	2037-03-15	798711.57	26310.00	5291.46	21018.54	777693.03	7.9500	pending	\N	\N	2026-11-12 09:35:00.657397	2026-11-12 09:35:00.657397
4482	13	133	2037-04-15	777693.03	26310.00	5152.22	21157.78	756535.25	7.9500	pending	\N	\N	2026-11-12 09:35:00.66268	2026-11-12 09:35:00.66268
4483	13	134	2037-05-15	756535.25	26310.00	5012.05	21297.95	735237.29	7.9500	pending	\N	\N	2026-11-12 09:35:00.670713	2026-11-12 09:35:00.670713
4484	13	135	2037-06-15	735237.29	26310.00	4870.95	21439.05	713798.24	7.9500	pending	\N	\N	2026-11-12 09:35:00.677534	2026-11-12 09:35:00.677534
4485	13	136	2037-07-15	713798.24	26310.00	4728.91	21581.09	692217.15	7.9500	pending	\N	\N	2026-11-12 09:35:00.684589	2026-11-12 09:35:00.684589
4486	13	137	2037-08-15	692217.15	26310.00	4585.94	21724.06	670493.09	7.9500	pending	\N	\N	2026-11-12 09:35:00.690748	2026-11-12 09:35:00.690748
4487	13	138	2037-09-15	670493.09	26310.00	4442.02	21867.98	648625.11	7.9500	pending	\N	\N	2026-11-12 09:35:00.696092	2026-11-12 09:35:00.696092
4488	13	139	2037-10-15	648625.11	26310.00	4297.14	22012.86	626612.25	7.9500	pending	\N	\N	2026-11-12 09:35:00.702565	2026-11-12 09:35:00.702565
4489	13	140	2037-11-15	626612.25	26310.00	4151.31	22158.69	604453.56	7.9500	pending	\N	\N	2026-11-12 09:35:00.708476	2026-11-12 09:35:00.708476
4490	13	141	2037-12-15	604453.56	26310.00	4004.50	22305.50	582148.06	7.9500	pending	\N	\N	2026-11-12 09:35:00.713484	2026-11-12 09:35:00.713484
4491	13	142	2038-01-15	582148.06	26310.00	3856.73	22453.27	559694.79	7.9500	pending	\N	\N	2026-11-12 09:35:00.722068	2026-11-12 09:35:00.722068
4492	13	143	2038-02-15	559694.79	26310.00	3707.98	22602.02	537092.77	7.9500	pending	\N	\N	2026-11-12 09:35:00.727538	2026-11-12 09:35:00.727538
4493	13	144	2038-03-15	537092.77	26310.00	3558.24	22751.76	514341.01	7.9500	pending	\N	\N	2026-11-12 09:35:00.733545	2026-11-12 09:35:00.733545
4494	13	145	2038-04-15	514341.01	26310.00	3407.51	22902.49	491438.52	7.9500	pending	\N	\N	2026-11-12 09:35:00.740014	2026-11-12 09:35:00.740014
4495	13	146	2038-05-15	491438.52	26310.00	3255.78	23054.22	468384.30	7.9500	pending	\N	\N	2026-11-12 09:35:00.745336	2026-11-12 09:35:00.745336
4496	13	147	2038-06-15	468384.30	26310.00	3103.05	23206.95	445177.35	7.9500	pending	\N	\N	2026-11-12 09:35:00.753	2026-11-12 09:35:00.753
4497	13	148	2038-07-15	445177.35	26310.00	2949.30	23360.70	421816.65	7.9500	pending	\N	\N	2026-11-12 09:35:00.759369	2026-11-12 09:35:00.759369
4498	13	149	2038-08-15	421816.65	26310.00	2794.54	23515.46	398301.18	7.9500	pending	\N	\N	2026-11-12 09:35:00.764293	2026-11-12 09:35:00.764293
4499	13	150	2038-09-15	398301.18	26310.00	2638.75	23671.25	374629.93	7.9500	pending	\N	\N	2026-11-12 09:35:00.772751	2026-11-12 09:35:00.772751
4500	13	151	2038-10-15	374629.93	26310.00	2481.92	23828.08	350801.85	7.9500	pending	\N	\N	2026-11-12 09:35:00.77801	2026-11-12 09:35:00.77801
4501	13	152	2038-11-15	350801.85	26310.00	2324.06	23985.94	326815.91	7.9500	pending	\N	\N	2026-11-12 09:35:00.787439	2026-11-12 09:35:00.787439
4502	13	153	2038-12-15	326815.91	26310.00	2165.16	24144.84	302671.07	7.9500	pending	\N	\N	2026-11-12 09:35:00.793599	2026-11-12 09:35:00.793599
4503	13	154	2039-01-15	302671.07	26310.00	2005.20	24304.80	278366.26	7.9500	pending	\N	\N	2026-11-12 09:35:00.799274	2026-11-12 09:35:00.799274
4504	13	155	2039-02-15	278366.26	26310.00	1844.18	24465.82	253900.44	7.9500	pending	\N	\N	2026-11-12 09:35:00.806258	2026-11-12 09:35:00.806258
4505	13	156	2039-03-15	253900.44	26310.00	1682.09	24627.91	229272.53	7.9500	pending	\N	\N	2026-11-12 09:35:00.812433	2026-11-12 09:35:00.812433
4506	13	157	2039-04-15	229272.53	26310.00	1518.93	24791.07	204481.46	7.9500	pending	\N	\N	2026-11-12 09:35:00.819592	2026-11-12 09:35:00.819592
4507	13	158	2039-05-15	204481.46	26310.00	1354.69	24955.31	179526.15	7.9500	pending	\N	\N	2026-11-12 09:35:00.827847	2026-11-12 09:35:00.827847
4508	13	159	2039-06-15	179526.15	26310.00	1189.36	25120.64	154405.51	7.9500	pending	\N	\N	2026-11-12 09:35:00.833255	2026-11-12 09:35:00.833255
4509	13	160	2039-07-15	154405.51	26310.00	1022.94	25287.06	129118.45	7.9500	pending	\N	\N	2026-11-12 09:35:00.840264	2026-11-12 09:35:00.840264
4510	13	161	2039-08-15	129118.45	26310.00	855.41	25454.59	103663.86	7.9500	pending	\N	\N	2026-11-12 09:35:00.846057	2026-11-12 09:35:00.846057
4511	13	162	2039-09-15	103663.86	26310.00	686.77	25623.23	78040.63	7.9500	pending	\N	\N	2026-11-12 09:35:00.85388	2026-11-12 09:35:00.85388
4512	13	163	2039-10-15	78040.63	26310.00	517.02	25792.98	52247.65	7.9500	pending	\N	\N	2026-11-12 09:35:00.860183	2026-11-12 09:35:00.860183
4513	13	164	2039-11-15	52247.65	26310.00	346.14	25963.86	26283.79	7.9500	pending	\N	\N	2026-11-12 09:35:00.866025	2026-11-12 09:35:00.866025
4514	13	165	2039-12-15	26283.79	26310.00	174.13	26135.87	147.92	7.9500	pending	\N	\N	2026-11-12 09:35:00.872499	2026-11-12 09:35:00.872499
4515	13	166	2040-01-15	147.92	148.90	0.98	147.92	0.00	7.9500	pending	\N	\N	2026-11-12 09:35:00.880195	2026-11-12 09:35:00.880195
4516	14	1	2026-04-15	2637592.17	25960.46	16924.55	9035.91	2628556.26	7.7000	paid	2026-04-15	25960.46	2026-11-12 09:35:01.739114	2026-11-12 09:35:01.739114
4517	14	2	2026-05-15	2628556.26	25960.46	16866.57	9093.89	2619462.36	7.7000	paid	2026-05-15	25960.46	2026-11-12 09:35:01.746043	2026-11-12 09:35:01.746043
4518	14	3	2026-06-15	2619462.36	25960.46	16808.22	9152.25	2610310.11	7.7000	paid	2026-06-15	25960.46	2026-11-12 09:35:01.751616	2026-11-12 09:35:01.751616
4519	14	4	2026-07-15	2610310.11	25960.46	16749.49	9210.97	2601099.14	7.7000	paid	2026-07-15	25960.46	2026-11-12 09:35:01.75759	2026-11-12 09:35:01.75759
4520	14	5	2026-08-15	2601099.14	25960.46	16690.39	9270.08	2591829.06	7.7000	paid	2026-08-15	25960.46	2026-11-12 09:35:01.763334	2026-11-12 09:35:01.763334
4521	14	6	2026-09-15	2591829.06	25960.46	16630.90	9329.56	2582499.50	7.7000	paid	2026-09-15	25960.46	2026-11-12 09:35:01.770109	2026-11-12 09:35:01.770109
4522	14	7	2026-10-15	2582499.50	25960.46	16571.04	9389.43	2573110.07	7.7000	paid	2026-10-15	25960.46	2026-11-12 09:35:01.776087	2026-11-12 09:35:01.776087
4523	14	8	2026-11-15	2572312.50	26310.00	17041.57	9268.43	2563044.07	7.9500	pending	\N	\N	2026-11-12 09:35:01.782364	2026-11-12 09:35:01.782364
4524	14	9	2026-12-15	2563044.07	26310.00	16980.17	9329.83	2553714.24	7.9500	pending	\N	\N	2026-11-12 09:35:01.788808	2026-11-12 09:35:01.788808
4525	14	10	2027-01-15	2553714.24	26310.00	16918.36	9391.64	2544322.59	7.9500	pending	\N	\N	2026-11-12 09:35:01.794098	2026-11-12 09:35:01.794098
4526	14	11	2027-02-15	2544322.59	26310.00	16856.14	9453.86	2534868.73	7.9500	pending	\N	\N	2026-11-12 09:35:01.801805	2026-11-12 09:35:01.801805
4527	14	12	2027-03-15	2534868.73	26310.00	16793.51	9516.49	2525352.24	7.9500	pending	\N	\N	2026-11-12 09:35:01.808012	2026-11-12 09:35:01.808012
4528	14	13	2027-04-15	2525352.24	26310.00	16730.46	9579.54	2515772.70	7.9500	pending	\N	\N	2026-11-12 09:35:01.812988	2026-11-12 09:35:01.812988
4529	14	14	2027-05-15	2515772.70	26310.00	16666.99	9643.01	2506129.69	7.9500	pending	\N	\N	2026-11-12 09:35:01.820786	2026-11-12 09:35:01.820786
4530	14	15	2027-06-15	2506129.69	26310.00	16603.11	9706.89	2496422.80	7.9500	pending	\N	\N	2026-11-12 09:35:01.826174	2026-11-12 09:35:01.826174
4531	14	16	2027-07-15	2496422.80	26310.00	16538.80	9771.20	2486651.60	7.9500	pending	\N	\N	2026-11-12 09:35:01.831337	2026-11-12 09:35:01.831337
4532	14	17	2027-08-15	2486651.60	26310.00	16474.07	9835.93	2476815.67	7.9500	pending	\N	\N	2026-11-12 09:35:01.839093	2026-11-12 09:35:01.839093
4533	14	18	2027-09-15	2476815.67	26310.00	16408.90	9901.10	2466914.57	7.9500	pending	\N	\N	2026-11-12 09:35:01.844823	2026-11-12 09:35:01.844823
4534	14	19	2027-10-15	2466914.57	26310.00	16343.31	9966.69	2456947.88	7.9500	pending	\N	\N	2026-11-12 09:35:01.851555	2026-11-12 09:35:01.851555
4535	14	20	2027-11-15	2456947.88	26310.00	16277.28	10032.72	2446915.16	7.9500	pending	\N	\N	2026-11-12 09:35:01.859209	2026-11-12 09:35:01.859209
4536	14	21	2027-12-15	2446915.16	26310.00	16210.81	10099.19	2436815.97	7.9500	pending	\N	\N	2026-11-12 09:35:01.864637	2026-11-12 09:35:01.864637
4537	14	22	2028-01-15	2436815.97	26310.00	16143.91	10166.09	2426649.88	7.9500	pending	\N	\N	2026-11-12 09:35:01.872111	2026-11-12 09:35:01.872111
4538	14	23	2028-02-15	2426649.88	26310.00	16076.56	10233.44	2416416.43	7.9500	pending	\N	\N	2026-11-12 09:35:01.877703	2026-11-12 09:35:01.877703
4539	14	24	2028-03-15	2416416.43	26310.00	16008.76	10301.24	2406115.19	7.9500	pending	\N	\N	2026-11-12 09:35:01.883176	2026-11-12 09:35:01.883176
4540	14	25	2028-04-15	2406115.19	26310.00	15940.51	10369.49	2395745.71	7.9500	pending	\N	\N	2026-11-12 09:35:01.890151	2026-11-12 09:35:01.890151
4541	14	26	2028-05-15	2395745.71	26310.00	15871.82	10438.18	2385307.52	7.9500	pending	\N	\N	2026-11-12 09:35:01.895344	2026-11-12 09:35:01.895344
4542	14	27	2028-06-15	2385307.52	26310.00	15802.66	10507.34	2374800.18	7.9500	pending	\N	\N	2026-11-12 09:35:01.901101	2026-11-12 09:35:01.901101
4543	14	28	2028-07-15	2374800.18	26310.00	15733.05	10576.95	2364223.23	7.9500	pending	\N	\N	2026-11-12 09:35:01.90752	2026-11-12 09:35:01.90752
4544	14	29	2028-08-15	2364223.23	26310.00	15662.98	10647.02	2353576.21	7.9500	pending	\N	\N	2026-11-12 09:35:01.914423	2026-11-12 09:35:01.914423
4545	14	30	2028-09-15	2353576.21	26310.00	15592.44	10717.56	2342858.66	7.9500	pending	\N	\N	2026-11-12 09:35:01.920553	2026-11-12 09:35:01.920553
4546	14	31	2028-10-15	2342858.66	26310.00	15521.44	10788.56	2332070.09	7.9500	pending	\N	\N	2026-11-12 09:35:01.926668	2026-11-12 09:35:01.926668
4547	14	32	2028-11-15	2332070.09	26310.00	15449.96	10860.04	2321210.06	7.9500	pending	\N	\N	2026-11-12 09:35:01.931623	2026-11-12 09:35:01.931623
4548	14	33	2028-12-15	2321210.06	26310.00	15378.02	10931.98	2310278.07	7.9500	pending	\N	\N	2026-11-12 09:35:01.938073	2026-11-12 09:35:01.938073
4549	14	34	2029-01-15	2310278.07	26310.00	15305.59	11004.41	2299273.67	7.9500	pending	\N	\N	2026-11-12 09:35:01.943938	2026-11-12 09:35:01.943938
4550	14	35	2029-02-15	2299273.67	26310.00	15232.69	11077.31	2288196.36	7.9500	pending	\N	\N	2026-11-12 09:35:01.949108	2026-11-12 09:35:01.949108
4551	14	36	2029-03-15	2288196.36	26310.00	15159.30	11150.70	2277045.66	7.9500	pending	\N	\N	2026-11-12 09:35:01.955392	2026-11-12 09:35:01.955392
4552	14	37	2029-04-15	2277045.66	26310.00	15085.43	11224.57	2265821.08	7.9500	pending	\N	\N	2026-11-12 09:35:01.960641	2026-11-12 09:35:01.960641
4553	14	38	2029-05-15	2265821.08	26310.00	15011.06	11298.94	2254522.15	7.9500	pending	\N	\N	2026-11-12 09:35:01.968132	2026-11-12 09:35:01.968132
4554	14	39	2029-06-15	2254522.15	26310.00	14936.21	11373.79	2243148.36	7.9500	pending	\N	\N	2026-11-12 09:35:01.974187	2026-11-12 09:35:01.974187
4555	14	40	2029-07-15	2243148.36	26310.00	14860.86	11449.14	2231699.22	7.9500	pending	\N	\N	2026-11-12 09:35:01.980311	2026-11-12 09:35:01.980311
4556	14	41	2029-08-15	2231699.22	26310.00	14785.01	11524.99	2220174.22	7.9500	pending	\N	\N	2026-11-12 09:35:01.986462	2026-11-12 09:35:01.986462
4557	14	42	2029-09-15	2220174.22	26310.00	14708.65	11601.35	2208572.88	7.9500	pending	\N	\N	2026-11-12 09:35:01.992552	2026-11-12 09:35:01.992552
4558	14	43	2029-10-15	2208572.88	26310.00	14631.80	11678.20	2196894.67	7.9500	pending	\N	\N	2026-11-12 09:35:01.99853	2026-11-12 09:35:01.99853
4559	14	44	2029-11-15	2196894.67	26310.00	14554.43	11755.57	2185139.10	7.9500	pending	\N	\N	2026-11-12 09:35:02.004872	2026-11-12 09:35:02.004872
4560	14	45	2029-12-15	2185139.10	26310.00	14476.55	11833.45	2173305.65	7.9500	pending	\N	\N	2026-11-12 09:35:02.010234	2026-11-12 09:35:02.010234
4561	14	46	2030-01-15	2173305.65	26310.00	14398.15	11911.85	2161393.80	7.9500	pending	\N	\N	2026-11-12 09:35:02.017007	2026-11-12 09:35:02.017007
4562	14	47	2030-02-15	2161393.80	26310.00	14319.23	11990.77	2149403.03	7.9500	pending	\N	\N	2026-11-12 09:35:02.023153	2026-11-12 09:35:02.023153
4563	14	48	2030-03-15	2149403.03	26310.00	14239.80	12070.20	2137332.82	7.9500	pending	\N	\N	2026-11-12 09:35:02.028328	2026-11-12 09:35:02.028328
4564	14	49	2030-04-15	2137332.82	26310.00	14159.83	12150.17	2125182.65	7.9500	pending	\N	\N	2026-11-12 09:35:02.034936	2026-11-12 09:35:02.034936
4565	14	50	2030-05-15	2125182.65	26310.00	14079.34	12230.66	2112951.99	7.9500	pending	\N	\N	2026-11-12 09:35:02.040915	2026-11-12 09:35:02.040915
4566	14	51	2030-06-15	2112951.99	26310.00	13998.31	12311.69	2100640.30	7.9500	pending	\N	\N	2026-11-12 09:35:02.047754	2026-11-12 09:35:02.047754
4567	14	52	2030-07-15	2100640.30	26310.00	13916.74	12393.26	2088247.04	7.9500	pending	\N	\N	2026-11-12 09:35:02.055458	2026-11-12 09:35:02.055458
4568	14	53	2030-08-15	2088247.04	26310.00	13834.64	12475.36	2075771.68	7.9500	pending	\N	\N	2026-11-12 09:35:02.061122	2026-11-12 09:35:02.061122
4569	14	54	2030-09-15	2075771.68	26310.00	13751.99	12558.01	2063213.66	7.9500	pending	\N	\N	2026-11-12 09:35:02.066064	2026-11-12 09:35:02.066064
4570	14	55	2030-10-15	2063213.66	26310.00	13668.79	12641.21	2050572.45	7.9500	pending	\N	\N	2026-11-12 09:35:02.074322	2026-11-12 09:35:02.074322
4571	14	56	2030-11-15	2050572.45	26310.00	13585.04	12724.96	2037847.50	7.9500	pending	\N	\N	2026-11-12 09:35:02.07941	2026-11-12 09:35:02.07941
4572	14	57	2030-12-15	2037847.50	26310.00	13500.74	12809.26	2025038.24	7.9500	pending	\N	\N	2026-11-12 09:35:02.086138	2026-11-12 09:35:02.086138
4573	14	58	2031-01-15	2025038.24	26310.00	13415.88	12894.12	2012144.11	7.9500	pending	\N	\N	2026-11-12 09:35:02.09183	2026-11-12 09:35:02.09183
4574	14	59	2031-02-15	2012144.11	26310.00	13330.45	12979.55	1999164.57	7.9500	pending	\N	\N	2026-11-12 09:35:02.097373	2026-11-12 09:35:02.097373
4575	14	60	2031-03-15	1999164.57	26310.00	13244.47	13065.53	1986099.03	7.9500	pending	\N	\N	2026-11-12 09:35:02.103979	2026-11-12 09:35:02.103979
4576	14	61	2031-04-15	1986099.03	26310.00	13157.91	13152.09	1972946.94	7.9500	pending	\N	\N	2026-11-12 09:35:02.109931	2026-11-12 09:35:02.109931
4577	14	62	2031-05-15	1972946.94	26310.00	13070.77	13239.23	1959707.71	7.9500	pending	\N	\N	2026-11-12 09:35:02.114669	2026-11-12 09:35:02.114669
4578	14	63	2031-06-15	1959707.71	26310.00	12983.06	13326.94	1946380.78	7.9500	pending	\N	\N	2026-11-12 09:35:02.122096	2026-11-12 09:35:02.122096
4579	14	64	2031-07-15	1946380.78	26310.00	12894.77	13415.23	1932965.55	7.9500	pending	\N	\N	2026-11-12 09:35:02.127487	2026-11-12 09:35:02.127487
4580	14	65	2031-08-15	1932965.55	26310.00	12805.90	13504.10	1919461.45	7.9500	pending	\N	\N	2026-11-12 09:35:02.13247	2026-11-12 09:35:02.13247
4581	14	66	2031-09-15	1919461.45	26310.00	12716.43	13593.57	1905867.88	7.9500	pending	\N	\N	2026-11-12 09:35:02.139348	2026-11-12 09:35:02.139348
4582	14	67	2031-10-15	1905867.88	26310.00	12626.37	13683.63	1892184.25	7.9500	pending	\N	\N	2026-11-12 09:35:02.145509	2026-11-12 09:35:02.145509
4583	14	68	2031-11-15	1892184.25	26310.00	12535.72	13774.28	1878409.97	7.9500	pending	\N	\N	2026-11-12 09:35:02.154379	2026-11-12 09:35:02.154379
4584	14	69	2031-12-15	1878409.97	26310.00	12444.47	13865.53	1864544.44	7.9500	pending	\N	\N	2026-11-12 09:35:02.160099	2026-11-12 09:35:02.160099
4585	14	70	2032-01-15	1864544.44	26310.00	12352.61	13957.39	1850587.05	7.9500	pending	\N	\N	2026-11-12 09:35:02.165373	2026-11-12 09:35:02.165373
4586	14	71	2032-02-15	1850587.05	26310.00	12260.14	14049.86	1836537.19	7.9500	pending	\N	\N	2026-11-12 09:35:02.173727	2026-11-12 09:35:02.173727
4587	14	72	2032-03-15	1836537.19	26310.00	12167.06	14142.94	1822394.24	7.9500	pending	\N	\N	2026-11-12 09:35:02.183807	2026-11-12 09:35:02.183807
4588	14	73	2032-04-15	1822394.24	26310.00	12073.36	14236.64	1808157.61	7.9500	pending	\N	\N	2026-11-12 09:35:02.189564	2026-11-12 09:35:02.189564
4589	14	74	2032-05-15	1808157.61	26310.00	11979.04	14330.96	1793826.65	7.9500	pending	\N	\N	2026-11-12 09:35:02.196807	2026-11-12 09:35:02.196807
4590	14	75	2032-06-15	1793826.65	26310.00	11884.10	14425.90	1779400.75	7.9500	pending	\N	\N	2026-11-12 09:35:02.203828	2026-11-12 09:35:02.203828
4591	14	76	2032-07-15	1779400.75	26310.00	11788.53	14521.47	1764879.28	7.9500	pending	\N	\N	2026-11-12 09:35:02.209884	2026-11-12 09:35:02.209884
4592	14	77	2032-08-15	1764879.28	26310.00	11692.33	14617.67	1750261.61	7.9500	pending	\N	\N	2026-11-12 09:35:02.216139	2026-11-12 09:35:02.216139
4593	14	78	2032-09-15	1750261.61	26310.00	11595.48	14714.52	1735547.09	7.9500	pending	\N	\N	2026-11-12 09:35:02.222167	2026-11-12 09:35:02.222167
4594	14	79	2032-10-15	1735547.09	26310.00	11498.00	14812.00	1720735.09	7.9500	pending	\N	\N	2026-11-12 09:35:02.227099	2026-11-12 09:35:02.227099
4595	14	80	2032-11-15	1720735.09	26310.00	11399.87	14910.13	1705824.96	7.9500	pending	\N	\N	2026-11-12 09:35:02.233697	2026-11-12 09:35:02.233697
4596	14	81	2032-12-15	1705824.96	26310.00	11301.09	15008.91	1690816.05	7.9500	pending	\N	\N	2026-11-12 09:35:02.239829	2026-11-12 09:35:02.239829
4597	14	82	2033-01-15	1690816.05	26310.00	11201.66	15108.34	1675707.71	7.9500	pending	\N	\N	2026-11-12 09:35:02.244896	2026-11-12 09:35:02.244896
4598	14	83	2033-02-15	1675707.71	26310.00	11101.56	15208.44	1660499.27	7.9500	pending	\N	\N	2026-11-12 09:35:02.252104	2026-11-12 09:35:02.252104
4599	14	84	2033-03-15	1660499.27	26310.00	11000.81	15309.19	1645190.08	7.9500	pending	\N	\N	2026-11-12 09:35:02.257791	2026-11-12 09:35:02.257791
4600	14	85	2033-04-15	1645190.08	26310.00	10899.38	15410.62	1629779.46	7.9500	pending	\N	\N	2026-11-12 09:35:02.263404	2026-11-12 09:35:02.263404
4601	14	86	2033-05-15	1629779.46	26310.00	10797.29	15512.71	1614266.75	7.9500	pending	\N	\N	2026-11-12 09:35:02.269243	2026-11-12 09:35:02.269243
4602	14	87	2033-06-15	1614266.75	26310.00	10694.52	15615.48	1598651.27	7.9500	pending	\N	\N	2026-11-12 09:35:02.276033	2026-11-12 09:35:02.276033
4603	14	88	2033-07-15	1598651.27	26310.00	10591.06	15718.94	1582932.33	7.9500	pending	\N	\N	2026-11-12 09:35:02.28269	2026-11-12 09:35:02.28269
4604	14	89	2033-08-15	1582932.33	26310.00	10486.93	15823.07	1567109.26	7.9500	pending	\N	\N	2026-11-12 09:35:02.291357	2026-11-12 09:35:02.291357
4605	14	90	2033-09-15	1567109.26	26310.00	10382.10	15927.90	1551181.36	7.9500	pending	\N	\N	2026-11-12 09:35:02.296157	2026-11-12 09:35:02.296157
4606	14	91	2033-10-15	1551181.36	26310.00	10276.58	16033.42	1535147.94	7.9500	pending	\N	\N	2026-11-12 09:35:02.302716	2026-11-12 09:35:02.302716
4607	14	92	2033-11-15	1535147.94	26310.00	10170.36	16139.64	1519008.29	7.9500	pending	\N	\N	2026-11-12 09:35:02.308085	2026-11-12 09:35:02.308085
4608	14	93	2033-12-15	1519008.29	26310.00	10063.43	16246.57	1502761.72	7.9500	pending	\N	\N	2026-11-12 09:35:02.313276	2026-11-12 09:35:02.313276
4609	14	94	2034-01-15	1502761.72	26310.00	9955.80	16354.20	1486407.52	7.9500	pending	\N	\N	2026-11-12 09:35:02.319645	2026-11-12 09:35:02.319645
4610	14	95	2034-02-15	1486407.52	26310.00	9847.45	16462.55	1469944.97	7.9500	pending	\N	\N	2026-11-12 09:35:02.325482	2026-11-12 09:35:02.325482
4611	14	96	2034-03-15	1469944.97	26310.00	9738.39	16571.61	1453373.35	7.9500	pending	\N	\N	2026-11-12 09:35:02.330552	2026-11-12 09:35:02.330552
4612	14	97	2034-04-15	1453373.35	26310.00	9628.60	16681.40	1436691.95	7.9500	pending	\N	\N	2026-11-12 09:35:02.338265	2026-11-12 09:35:02.338265
4613	14	98	2034-05-15	1436691.95	26310.00	9518.08	16791.92	1419900.03	7.9500	pending	\N	\N	2026-11-12 09:35:02.344146	2026-11-12 09:35:02.344146
4614	14	99	2034-06-15	1419900.03	26310.00	9406.84	16903.16	1402996.87	7.9500	pending	\N	\N	2026-11-12 09:35:02.34991	2026-11-12 09:35:02.34991
4615	14	100	2034-07-15	1402996.87	26310.00	9294.85	17015.15	1385981.73	7.9500	pending	\N	\N	2026-11-12 09:35:02.356176	2026-11-12 09:35:02.356176
4616	14	101	2034-08-15	1385981.73	26310.00	9182.13	17127.87	1368853.86	7.9500	pending	\N	\N	2026-11-12 09:35:02.364326	2026-11-12 09:35:02.364326
4617	14	102	2034-09-15	1368853.86	26310.00	9068.66	17241.34	1351612.51	7.9500	pending	\N	\N	2026-11-12 09:35:02.373495	2026-11-12 09:35:02.373495
4618	14	103	2034-10-15	1351612.51	26310.00	8954.43	17355.57	1334256.94	7.9500	pending	\N	\N	2026-11-12 09:35:02.37852	2026-11-12 09:35:02.37852
4619	14	104	2034-11-15	1334256.94	26310.00	8839.45	17470.55	1316786.40	7.9500	pending	\N	\N	2026-11-12 09:35:02.383461	2026-11-12 09:35:02.383461
4620	14	105	2034-12-15	1316786.40	26310.00	8723.71	17586.29	1299200.11	7.9500	pending	\N	\N	2026-11-12 09:35:02.391846	2026-11-12 09:35:02.391846
4621	14	106	2035-01-15	1299200.11	26310.00	8607.20	17702.80	1281497.31	7.9500	pending	\N	\N	2026-11-12 09:35:02.39716	2026-11-12 09:35:02.39716
4622	14	107	2035-02-15	1281497.31	26310.00	8489.92	17820.08	1263677.23	7.9500	pending	\N	\N	2026-11-12 09:35:02.40711	2026-11-12 09:35:02.40711
4623	14	108	2035-03-15	1263677.23	26310.00	8371.86	17938.14	1245739.09	7.9500	pending	\N	\N	2026-11-12 09:35:02.414498	2026-11-12 09:35:02.414498
4624	14	109	2035-04-15	1245739.09	26310.00	8253.02	18056.98	1227682.11	7.9500	pending	\N	\N	2026-11-12 09:35:02.424011	2026-11-12 09:35:02.424011
4625	14	110	2035-05-15	1227682.11	26310.00	8133.39	18176.61	1209505.50	7.9500	pending	\N	\N	2026-11-12 09:35:02.430004	2026-11-12 09:35:02.430004
4626	14	111	2035-06-15	1209505.50	26310.00	8012.97	18297.03	1191208.48	7.9500	pending	\N	\N	2026-11-12 09:35:02.43763	2026-11-12 09:35:02.43763
4627	14	112	2035-07-15	1191208.48	26310.00	7891.76	18418.24	1172790.23	7.9500	pending	\N	\N	2026-11-12 09:35:02.443473	2026-11-12 09:35:02.443473
4628	14	113	2035-08-15	1172790.23	26310.00	7769.74	18540.26	1154249.97	7.9500	pending	\N	\N	2026-11-12 09:35:02.451393	2026-11-12 09:35:02.451393
4629	14	114	2035-09-15	1154249.97	26310.00	7646.91	18663.09	1135586.88	7.9500	pending	\N	\N	2026-11-12 09:35:02.458984	2026-11-12 09:35:02.458984
4630	14	115	2035-10-15	1135586.88	26310.00	7523.26	18786.74	1116800.14	7.9500	pending	\N	\N	2026-11-12 09:35:02.463921	2026-11-12 09:35:02.463921
4631	14	116	2035-11-15	1116800.14	26310.00	7398.80	18911.20	1097888.94	7.9500	pending	\N	\N	2026-11-12 09:35:02.471781	2026-11-12 09:35:02.471781
4632	14	117	2035-12-15	1097888.94	26310.00	7273.51	19036.49	1078852.45	7.9500	pending	\N	\N	2026-11-12 09:35:02.477099	2026-11-12 09:35:02.477099
4633	14	118	2036-01-15	1078852.45	26310.00	7147.40	19162.60	1059689.85	7.9500	pending	\N	\N	2026-11-12 09:35:02.482684	2026-11-12 09:35:02.482684
4634	14	119	2036-02-15	1059689.85	26310.00	7020.45	19289.55	1040400.30	7.9500	pending	\N	\N	2026-11-12 09:35:02.490992	2026-11-12 09:35:02.490992
4635	14	120	2036-03-15	1040400.30	26310.00	6892.65	19417.35	1020982.95	7.9500	pending	\N	\N	2026-11-12 09:35:02.497615	2026-11-12 09:35:02.497615
4636	14	121	2036-04-15	1020982.95	26310.00	6764.01	19545.99	1001436.96	7.9500	pending	\N	\N	2026-11-12 09:35:02.505454	2026-11-12 09:35:02.505454
4637	14	122	2036-05-15	1001436.96	26310.00	6634.52	19675.48	981761.48	7.9500	pending	\N	\N	2026-11-12 09:35:02.511311	2026-11-12 09:35:02.511311
4638	14	123	2036-06-15	981761.48	26310.00	6504.17	19805.83	961955.65	7.9500	pending	\N	\N	2026-11-12 09:35:02.51731	2026-11-12 09:35:02.51731
4639	14	124	2036-07-15	961955.65	26310.00	6372.96	19937.04	942018.61	7.9500	pending	\N	\N	2026-11-12 09:35:02.524868	2026-11-12 09:35:02.524868
4640	14	125	2036-08-15	942018.61	26310.00	6240.87	20069.13	921949.48	7.9500	pending	\N	\N	2026-11-12 09:35:02.529968	2026-11-12 09:35:02.529968
4641	14	126	2036-09-15	921949.48	26310.00	6107.92	20202.08	901747.40	7.9500	pending	\N	\N	2026-11-12 09:35:02.537882	2026-11-12 09:35:02.537882
4642	14	127	2036-10-15	901747.40	26310.00	5974.08	20335.92	881411.47	7.9500	pending	\N	\N	2026-11-12 09:35:02.544905	2026-11-12 09:35:02.544905
4643	14	128	2036-11-15	881411.47	26310.00	5839.35	20470.65	860940.82	7.9500	pending	\N	\N	2026-11-12 09:35:02.552071	2026-11-12 09:35:02.552071
4644	14	129	2036-12-15	860940.82	26310.00	5703.73	20606.27	840334.56	7.9500	pending	\N	\N	2026-11-12 09:35:02.55947	2026-11-12 09:35:02.55947
4645	14	130	2037-01-15	840334.56	26310.00	5567.22	20742.78	819591.77	7.9500	pending	\N	\N	2026-11-12 09:35:02.564966	2026-11-12 09:35:02.564966
4646	14	131	2037-02-15	819591.77	26310.00	5429.80	20880.20	798711.57	7.9500	pending	\N	\N	2026-11-12 09:35:02.573355	2026-11-12 09:35:02.573355
4647	14	132	2037-03-15	798711.57	26310.00	5291.46	21018.54	777693.03	7.9500	pending	\N	\N	2026-11-12 09:35:02.580023	2026-11-12 09:35:02.580023
4648	14	133	2037-04-15	777693.03	26310.00	5152.22	21157.78	756535.25	7.9500	pending	\N	\N	2026-11-12 09:35:02.585992	2026-11-12 09:35:02.585992
4649	14	134	2037-05-15	756535.25	26310.00	5012.05	21297.95	735237.29	7.9500	pending	\N	\N	2026-11-12 09:35:02.592857	2026-11-12 09:35:02.592857
4650	14	135	2037-06-15	735237.29	26310.00	4870.95	21439.05	713798.24	7.9500	pending	\N	\N	2026-11-12 09:35:02.598118	2026-11-12 09:35:02.598118
4651	14	136	2037-07-15	713798.24	26310.00	4728.91	21581.09	692217.15	7.9500	pending	\N	\N	2026-11-12 09:35:02.604616	2026-11-12 09:35:02.604616
4652	14	137	2037-08-15	692217.15	26310.00	4585.94	21724.06	670493.09	7.9500	pending	\N	\N	2026-11-12 09:35:02.611797	2026-11-12 09:35:02.611797
4653	14	138	2037-09-15	670493.09	26310.00	4442.02	21867.98	648625.11	7.9500	pending	\N	\N	2026-11-12 09:35:02.617866	2026-11-12 09:35:02.617866
4654	14	139	2037-10-15	648625.11	26310.00	4297.14	22012.86	626612.25	7.9500	pending	\N	\N	2026-11-12 09:35:02.624331	2026-11-12 09:35:02.624331
4655	14	140	2037-11-15	626612.25	26310.00	4151.31	22158.69	604453.56	7.9500	pending	\N	\N	2026-11-12 09:35:02.630549	2026-11-12 09:35:02.630549
4656	14	141	2037-12-15	604453.56	26310.00	4004.50	22305.50	582148.06	7.9500	pending	\N	\N	2026-11-12 09:35:02.637602	2026-11-12 09:35:02.637602
4657	14	142	2038-01-15	582148.06	26310.00	3856.73	22453.27	559694.79	7.9500	pending	\N	\N	2026-11-12 09:35:02.644686	2026-11-12 09:35:02.644686
4658	14	143	2038-02-15	559694.79	26310.00	3707.98	22602.02	537092.77	7.9500	pending	\N	\N	2026-11-12 09:35:02.650762	2026-11-12 09:35:02.650762
4659	14	144	2038-03-15	537092.77	26310.00	3558.24	22751.76	514341.01	7.9500	pending	\N	\N	2026-11-12 09:35:02.656963	2026-11-12 09:35:02.656963
4660	14	145	2038-04-15	514341.01	26310.00	3407.51	22902.49	491438.52	7.9500	pending	\N	\N	2026-11-12 09:35:02.663868	2026-11-12 09:35:02.663868
4661	14	146	2038-05-15	491438.52	26310.00	3255.78	23054.22	468384.30	7.9500	pending	\N	\N	2026-11-12 09:35:02.670684	2026-11-12 09:35:02.670684
4662	14	147	2038-06-15	468384.30	26310.00	3103.05	23206.95	445177.35	7.9500	pending	\N	\N	2026-11-12 09:35:02.676642	2026-11-12 09:35:02.676642
4663	14	148	2038-07-15	445177.35	26310.00	2949.30	23360.70	421816.65	7.9500	pending	\N	\N	2026-11-12 09:35:02.682705	2026-11-12 09:35:02.682705
4664	14	149	2038-08-15	421816.65	26310.00	2794.54	23515.46	398301.18	7.9500	pending	\N	\N	2026-11-12 09:35:02.688636	2026-11-12 09:35:02.688636
4665	14	150	2038-09-15	398301.18	26310.00	2638.75	23671.25	374629.93	7.9500	pending	\N	\N	2026-11-12 09:35:02.695543	2026-11-12 09:35:02.695543
4666	14	151	2038-10-15	374629.93	26310.00	2481.92	23828.08	350801.85	7.9500	pending	\N	\N	2026-11-12 09:35:02.701478	2026-11-12 09:35:02.701478
4667	14	152	2038-11-15	350801.85	26310.00	2324.06	23985.94	326815.91	7.9500	pending	\N	\N	2026-11-12 09:35:02.70762	2026-11-12 09:35:02.70762
4668	14	153	2038-12-15	326815.91	26310.00	2165.16	24144.84	302671.07	7.9500	pending	\N	\N	2026-11-12 09:35:02.714657	2026-11-12 09:35:02.714657
4669	14	154	2039-01-15	302671.07	26310.00	2005.20	24304.80	278366.26	7.9500	pending	\N	\N	2026-11-12 09:35:02.721885	2026-11-12 09:35:02.721885
4670	14	155	2039-02-15	278366.26	26310.00	1844.18	24465.82	253900.44	7.9500	pending	\N	\N	2026-11-12 09:35:02.727578	2026-11-12 09:35:02.727578
4671	14	156	2039-03-15	253900.44	26310.00	1682.09	24627.91	229272.53	7.9500	pending	\N	\N	2026-11-12 09:35:02.734058	2026-11-12 09:35:02.734058
4672	14	157	2039-04-15	229272.53	26310.00	1518.93	24791.07	204481.46	7.9500	pending	\N	\N	2026-11-12 09:35:02.740756	2026-11-12 09:35:02.740756
4673	14	158	2039-05-15	204481.46	26310.00	1354.69	24955.31	179526.15	7.9500	pending	\N	\N	2026-11-12 09:35:02.746996	2026-11-12 09:35:02.746996
4674	14	159	2039-06-15	179526.15	26310.00	1189.36	25120.64	154405.51	7.9500	pending	\N	\N	2026-11-12 09:35:02.753885	2026-11-12 09:35:02.753885
4675	14	160	2039-07-15	154405.51	26310.00	1022.94	25287.06	129118.45	7.9500	pending	\N	\N	2026-11-12 09:35:02.759941	2026-11-12 09:35:02.759941
4676	14	161	2039-08-15	129118.45	26310.00	855.41	25454.59	103663.86	7.9500	pending	\N	\N	2026-11-12 09:35:02.768283	2026-11-12 09:35:02.768283
4677	14	162	2039-09-15	103663.86	26310.00	686.77	25623.23	78040.63	7.9500	pending	\N	\N	2026-11-12 09:35:02.775258	2026-11-12 09:35:02.775258
4678	14	163	2039-10-15	78040.63	26310.00	517.02	25792.98	52247.65	7.9500	pending	\N	\N	2026-11-12 09:35:02.783705	2026-11-12 09:35:02.783705
4679	14	164	2039-11-15	52247.65	26310.00	346.14	25963.86	26283.79	7.9500	pending	\N	\N	2026-11-12 09:35:02.791644	2026-11-12 09:35:02.791644
4680	14	165	2039-12-15	26283.79	26310.00	174.13	26135.87	147.92	7.9500	pending	\N	\N	2026-11-12 09:35:02.797452	2026-11-12 09:35:02.797452
4681	14	166	2040-01-15	147.92	148.90	0.98	147.92	0.00	7.9500	pending	\N	\N	2026-11-12 09:35:02.805559	2026-11-12 09:35:02.805559
4682	15	1	2026-04-15	493615.07	4705.63	3105.66	1599.97	492015.10	7.5500	paid	2026-04-15	4705.63	2026-11-12 09:35:03.69309	2026-11-12 09:35:03.69309
4683	15	2	2026-05-15	492015.10	4705.63	3095.60	1610.03	490405.07	7.5500	paid	2026-05-15	4705.63	2026-11-12 09:35:03.697825	2026-11-12 09:35:03.697825
4684	15	3	2026-06-15	490405.07	4705.63	3085.47	1620.16	488784.91	7.5500	paid	2026-06-15	4705.63	2026-11-12 09:35:03.703622	2026-11-12 09:35:03.703622
4685	15	4	2026-07-15	488784.91	4705.63	3075.27	1630.36	487154.55	7.5500	paid	2026-07-15	4705.63	2026-11-12 09:35:03.710318	2026-11-12 09:35:03.710318
4686	15	5	2026-08-15	487154.55	4705.63	3065.01	1640.61	485513.94	7.5500	paid	2026-08-15	4705.63	2026-11-12 09:35:03.716226	2026-11-12 09:35:03.716226
4687	15	6	2026-09-15	485513.94	4705.63	3054.69	1650.94	483863.00	7.5500	paid	2026-09-15	4705.63	2026-11-12 09:35:03.722971	2026-11-12 09:35:03.722971
4688	15	7	2026-10-15	483863.00	4705.63	3044.30	1661.32	482201.68	7.5500	paid	2026-10-15	4705.63	2026-11-12 09:35:03.728787	2026-11-12 09:35:03.728787
4689	15	8	2026-11-15	482188.50	4790.00	3134.23	1655.77	480532.73	7.8000	pending	\N	\N	2026-11-12 09:35:03.734332	2026-11-12 09:35:03.734332
4690	15	9	2026-12-15	480532.73	4790.00	3123.46	1666.54	478866.19	7.8000	pending	\N	\N	2026-11-12 09:35:03.740853	2026-11-12 09:35:03.740853
4691	15	10	2027-01-15	478866.19	4790.00	3112.63	1677.37	477188.82	7.8000	pending	\N	\N	2026-11-12 09:35:03.746641	2026-11-12 09:35:03.746641
4692	15	11	2027-02-15	477188.82	4790.00	3101.73	1688.27	475500.55	7.8000	pending	\N	\N	2026-11-12 09:35:03.753123	2026-11-12 09:35:03.753123
4693	15	12	2027-03-15	475500.55	4790.00	3090.75	1699.25	473801.30	7.8000	pending	\N	\N	2026-11-12 09:35:03.759558	2026-11-12 09:35:03.759558
4694	15	13	2027-04-15	473801.30	4790.00	3079.71	1710.29	472091.01	7.8000	pending	\N	\N	2026-11-12 09:35:03.767707	2026-11-12 09:35:03.767707
4695	15	14	2027-05-15	472091.01	4790.00	3068.59	1721.41	470369.60	7.8000	pending	\N	\N	2026-11-12 09:35:03.774117	2026-11-12 09:35:03.774117
4696	15	15	2027-06-15	470369.60	4790.00	3057.40	1732.60	468637.00	7.8000	pending	\N	\N	2026-11-12 09:35:03.779503	2026-11-12 09:35:03.779503
4697	15	16	2027-07-15	468637.00	4790.00	3046.14	1743.86	466893.14	7.8000	pending	\N	\N	2026-11-12 09:35:03.787702	2026-11-12 09:35:03.787702
4698	15	17	2027-08-15	466893.14	4790.00	3034.81	1755.19	465137.95	7.8000	pending	\N	\N	2026-11-12 09:35:03.795409	2026-11-12 09:35:03.795409
4699	15	18	2027-09-15	465137.95	4790.00	3023.40	1766.60	463371.34	7.8000	pending	\N	\N	2026-11-12 09:35:03.802971	2026-11-12 09:35:03.802971
4700	15	19	2027-10-15	463371.34	4790.00	3011.91	1778.09	461593.26	7.8000	pending	\N	\N	2026-11-12 09:35:03.809555	2026-11-12 09:35:03.809555
4701	15	20	2027-11-15	461593.26	4790.00	3000.36	1789.64	459803.61	7.8000	pending	\N	\N	2026-11-12 09:35:03.814791	2026-11-12 09:35:03.814791
4702	15	21	2027-12-15	459803.61	4790.00	2988.72	1801.28	458002.34	7.8000	pending	\N	\N	2026-11-12 09:35:03.821775	2026-11-12 09:35:03.821775
4703	15	22	2028-01-15	458002.34	4790.00	2977.02	1812.98	456189.35	7.8000	pending	\N	\N	2026-11-12 09:35:03.828639	2026-11-12 09:35:03.828639
4704	15	23	2028-02-15	456189.35	4790.00	2965.23	1824.77	454364.58	7.8000	pending	\N	\N	2026-11-12 09:35:03.835812	2026-11-12 09:35:03.835812
4705	15	24	2028-03-15	454364.58	4790.00	2953.37	1836.63	452527.95	7.8000	pending	\N	\N	2026-11-12 09:35:03.842576	2026-11-12 09:35:03.842576
4706	15	25	2028-04-15	452527.95	4790.00	2941.43	1848.57	450679.38	7.8000	pending	\N	\N	2026-11-12 09:35:03.847683	2026-11-12 09:35:03.847683
4707	15	26	2028-05-15	450679.38	4790.00	2929.42	1860.58	448818.80	7.8000	pending	\N	\N	2026-11-12 09:35:03.85439	2026-11-12 09:35:03.85439
4708	15	27	2028-06-15	448818.80	4790.00	2917.32	1872.68	446946.12	7.8000	pending	\N	\N	2026-11-12 09:35:03.861221	2026-11-12 09:35:03.861221
4709	15	28	2028-07-15	446946.12	4790.00	2905.15	1884.85	445061.27	7.8000	pending	\N	\N	2026-11-12 09:35:03.867072	2026-11-12 09:35:03.867072
4710	15	29	2028-08-15	445061.27	4790.00	2892.90	1897.10	443164.17	7.8000	pending	\N	\N	2026-11-12 09:35:03.873461	2026-11-12 09:35:03.873461
4711	15	30	2028-09-15	443164.17	4790.00	2880.57	1909.43	441254.74	7.8000	pending	\N	\N	2026-11-12 09:35:03.878925	2026-11-12 09:35:03.878925
4712	15	31	2028-10-15	441254.74	4790.00	2868.16	1921.84	439332.89	7.8000	pending	\N	\N	2026-11-12 09:35:03.88686	2026-11-12 09:35:03.88686
4713	15	32	2028-11-15	439332.89	4790.00	2855.66	1934.34	437398.56	7.8000	pending	\N	\N	2026-11-12 09:35:03.893095	2026-11-12 09:35:03.893095
4714	15	33	2028-12-15	437398.56	4790.00	2843.09	1946.91	435451.65	7.8000	pending	\N	\N	2026-11-12 09:35:03.899211	2026-11-12 09:35:03.899211
4715	15	34	2029-01-15	435451.65	4790.00	2830.44	1959.56	433492.08	7.8000	pending	\N	\N	2026-11-12 09:35:03.905472	2026-11-12 09:35:03.905472
4716	15	35	2029-02-15	433492.08	4790.00	2817.70	1972.30	431519.78	7.8000	pending	\N	\N	2026-11-12 09:35:03.911419	2026-11-12 09:35:03.911419
4717	15	36	2029-03-15	431519.78	4790.00	2804.88	1985.12	429534.66	7.8000	pending	\N	\N	2026-11-12 09:35:03.917221	2026-11-12 09:35:03.917221
4718	15	37	2029-04-15	429534.66	4790.00	2791.98	1998.02	427536.64	7.8000	pending	\N	\N	2026-11-12 09:35:03.923418	2026-11-12 09:35:03.923418
4719	15	38	2029-05-15	427536.64	4790.00	2778.99	2011.01	425525.62	7.8000	pending	\N	\N	2026-11-12 09:35:03.92856	2026-11-12 09:35:03.92856
4720	15	39	2029-06-15	425525.62	4790.00	2765.92	2024.08	423501.54	7.8000	pending	\N	\N	2026-11-12 09:35:03.936282	2026-11-12 09:35:03.936282
4721	15	40	2029-07-15	423501.54	4790.00	2752.76	2037.24	421464.30	7.8000	pending	\N	\N	2026-11-12 09:35:03.943455	2026-11-12 09:35:03.943455
4722	15	41	2029-08-15	421464.30	4790.00	2739.52	2050.48	419413.82	7.8000	pending	\N	\N	2026-11-12 09:35:03.950116	2026-11-12 09:35:03.950116
4723	15	42	2029-09-15	419413.82	4790.00	2726.19	2063.81	417350.01	7.8000	pending	\N	\N	2026-11-12 09:35:03.957106	2026-11-12 09:35:03.957106
4724	15	43	2029-10-15	417350.01	4790.00	2712.78	2077.22	415272.78	7.8000	pending	\N	\N	2026-11-12 09:35:03.962711	2026-11-12 09:35:03.962711
4725	15	44	2029-11-15	415272.78	4790.00	2699.27	2090.73	413182.06	7.8000	pending	\N	\N	2026-11-12 09:35:03.969504	2026-11-12 09:35:03.969504
4726	15	45	2029-12-15	413182.06	4790.00	2685.68	2104.32	411077.74	7.8000	pending	\N	\N	2026-11-12 09:35:03.975516	2026-11-12 09:35:03.975516
4727	15	46	2030-01-15	411077.74	4790.00	2672.01	2117.99	408959.75	7.8000	pending	\N	\N	2026-11-12 09:35:03.981103	2026-11-12 09:35:03.981103
4728	15	47	2030-02-15	408959.75	4790.00	2658.24	2131.76	406827.98	7.8000	pending	\N	\N	2026-11-12 09:35:03.987051	2026-11-12 09:35:03.987051
4729	15	48	2030-03-15	406827.98	4790.00	2644.38	2145.62	404682.37	7.8000	pending	\N	\N	2026-11-12 09:35:03.995002	2026-11-12 09:35:03.995002
4730	15	49	2030-04-15	404682.37	4790.00	2630.44	2159.56	402522.80	7.8000	pending	\N	\N	2026-11-12 09:35:04.000458	2026-11-12 09:35:04.000458
4731	15	50	2030-05-15	402522.80	4790.00	2616.40	2173.60	400349.20	7.8000	pending	\N	\N	2026-11-12 09:35:04.007669	2026-11-12 09:35:04.007669
4732	15	51	2030-06-15	400349.20	4790.00	2602.27	2187.73	398161.47	7.8000	pending	\N	\N	2026-11-12 09:35:04.013337	2026-11-12 09:35:04.013337
4733	15	52	2030-07-15	398161.47	4790.00	2588.05	2201.95	395959.52	7.8000	pending	\N	\N	2026-11-12 09:35:04.020989	2026-11-12 09:35:04.020989
4734	15	53	2030-08-15	395959.52	4790.00	2573.74	2216.26	393743.26	7.8000	pending	\N	\N	2026-11-12 09:35:04.027384	2026-11-12 09:35:04.027384
4735	15	54	2030-09-15	393743.26	4790.00	2559.33	2230.67	391512.59	7.8000	pending	\N	\N	2026-11-12 09:35:04.032803	2026-11-12 09:35:04.032803
4736	15	55	2030-10-15	391512.59	4790.00	2544.83	2245.17	389267.42	7.8000	pending	\N	\N	2026-11-12 09:35:04.039192	2026-11-12 09:35:04.039192
4737	15	56	2030-11-15	389267.42	4790.00	2530.24	2259.76	387007.66	7.8000	pending	\N	\N	2026-11-12 09:35:04.046346	2026-11-12 09:35:04.046346
4738	15	57	2030-12-15	387007.66	4790.00	2515.55	2274.45	384733.21	7.8000	pending	\N	\N	2026-11-12 09:35:04.052757	2026-11-12 09:35:04.052757
4739	15	58	2031-01-15	384733.21	4790.00	2500.77	2289.23	382443.97	7.8000	pending	\N	\N	2026-11-12 09:35:04.059905	2026-11-12 09:35:04.059905
4740	15	59	2031-02-15	382443.97	4790.00	2485.89	2304.11	380139.86	7.8000	pending	\N	\N	2026-11-12 09:35:04.065148	2026-11-12 09:35:04.065148
4741	15	60	2031-03-15	380139.86	4790.00	2470.91	2319.09	377820.77	7.8000	pending	\N	\N	2026-11-12 09:35:04.071041	2026-11-12 09:35:04.071041
4742	15	61	2031-04-15	377820.77	4790.00	2455.83	2334.17	375486.60	7.8000	pending	\N	\N	2026-11-12 09:35:04.077265	2026-11-12 09:35:04.077265
4743	15	62	2031-05-15	375486.60	4790.00	2440.66	2349.34	373137.27	7.8000	pending	\N	\N	2026-11-12 09:35:04.082455	2026-11-12 09:35:04.082455
4744	15	63	2031-06-15	373137.27	4790.00	2425.39	2364.61	370772.66	7.8000	pending	\N	\N	2026-11-12 09:35:04.088343	2026-11-12 09:35:04.088343
4745	15	64	2031-07-15	370772.66	4790.00	2410.02	2379.98	368392.68	7.8000	pending	\N	\N	2026-11-12 09:35:04.094439	2026-11-12 09:35:04.094439
4746	15	65	2031-08-15	368392.68	4790.00	2394.55	2395.45	365997.23	7.8000	pending	\N	\N	2026-11-12 09:35:04.103442	2026-11-12 09:35:04.103442
4747	15	66	2031-09-15	365997.23	4790.00	2378.98	2411.02	363586.21	7.8000	pending	\N	\N	2026-11-12 09:35:04.111084	2026-11-12 09:35:04.111084
4748	15	67	2031-10-15	363586.21	4790.00	2363.31	2426.69	361159.53	7.8000	pending	\N	\N	2026-11-12 09:35:04.119087	2026-11-12 09:35:04.119087
4749	15	68	2031-11-15	361159.53	4790.00	2347.54	2442.46	358717.06	7.8000	pending	\N	\N	2026-11-12 09:35:04.124858	2026-11-12 09:35:04.124858
4750	15	69	2031-12-15	358717.06	4790.00	2331.66	2458.34	356258.72	7.8000	pending	\N	\N	2026-11-12 09:35:04.130588	2026-11-12 09:35:04.130588
4751	15	70	2032-01-15	356258.72	4790.00	2315.68	2474.32	353784.40	7.8000	pending	\N	\N	2026-11-12 09:35:04.137233	2026-11-12 09:35:04.137233
4752	15	71	2032-02-15	353784.40	4790.00	2299.60	2490.40	351294.00	7.8000	pending	\N	\N	2026-11-12 09:35:04.143343	2026-11-12 09:35:04.143343
4753	15	72	2032-03-15	351294.00	4790.00	2283.41	2506.59	348787.41	7.8000	pending	\N	\N	2026-11-12 09:35:04.148177	2026-11-12 09:35:04.148177
4754	15	73	2032-04-15	348787.41	4790.00	2267.12	2522.88	346264.53	7.8000	pending	\N	\N	2026-11-12 09:35:04.156156	2026-11-12 09:35:04.156156
4755	15	74	2032-05-15	346264.53	4790.00	2250.72	2539.28	343725.25	7.8000	pending	\N	\N	2026-11-12 09:35:04.161666	2026-11-12 09:35:04.161666
4756	15	75	2032-06-15	343725.25	4790.00	2234.21	2555.79	341169.47	7.8000	pending	\N	\N	2026-11-12 09:35:04.169358	2026-11-12 09:35:04.169358
4757	15	76	2032-07-15	341169.47	4790.00	2217.60	2572.40	338597.07	7.8000	pending	\N	\N	2026-11-12 09:35:04.17507	2026-11-12 09:35:04.17507
4758	15	77	2032-08-15	338597.07	4790.00	2200.88	2589.12	336007.95	7.8000	pending	\N	\N	2026-11-12 09:35:04.179959	2026-11-12 09:35:04.179959
4759	15	78	2032-09-15	336007.95	4790.00	2184.05	2605.95	333402.00	7.8000	pending	\N	\N	2026-11-12 09:35:04.186537	2026-11-12 09:35:04.186537
4760	15	79	2032-10-15	333402.00	4790.00	2167.11	2622.89	330779.11	7.8000	pending	\N	\N	2026-11-12 09:35:04.192051	2026-11-12 09:35:04.192051
4761	15	80	2032-11-15	330779.11	4790.00	2150.06	2639.94	328139.18	7.8000	pending	\N	\N	2026-11-12 09:35:04.197051	2026-11-12 09:35:04.197051
4762	15	81	2032-12-15	328139.18	4790.00	2132.90	2657.10	325482.08	7.8000	pending	\N	\N	2026-11-12 09:35:04.204446	2026-11-12 09:35:04.204446
4763	15	82	2033-01-15	325482.08	4790.00	2115.63	2674.37	322807.72	7.8000	pending	\N	\N	2026-11-12 09:35:04.210376	2026-11-12 09:35:04.210376
4764	15	83	2033-02-15	322807.72	4790.00	2098.25	2691.75	320115.97	7.8000	pending	\N	\N	2026-11-12 09:35:04.215427	2026-11-12 09:35:04.215427
4765	15	84	2033-03-15	320115.97	4790.00	2080.75	2709.25	317406.72	7.8000	pending	\N	\N	2026-11-12 09:35:04.222312	2026-11-12 09:35:04.222312
4766	15	85	2033-04-15	317406.72	4790.00	2063.14	2726.86	314679.86	7.8000	pending	\N	\N	2026-11-12 09:35:04.22741	2026-11-12 09:35:04.22741
4767	15	86	2033-05-15	314679.86	4790.00	2045.42	2744.58	311935.28	7.8000	pending	\N	\N	2026-11-12 09:35:04.233447	2026-11-12 09:35:04.233447
4768	15	87	2033-06-15	311935.28	4790.00	2027.58	2762.42	309172.86	7.8000	pending	\N	\N	2026-11-12 09:35:04.240185	2026-11-12 09:35:04.240185
4769	15	88	2033-07-15	309172.86	4790.00	2009.62	2780.38	306392.49	7.8000	pending	\N	\N	2026-11-12 09:35:04.245561	2026-11-12 09:35:04.245561
4770	15	89	2033-08-15	306392.49	4790.00	1991.55	2798.45	303594.04	7.8000	pending	\N	\N	2026-11-12 09:35:04.252513	2026-11-12 09:35:04.252513
4771	15	90	2033-09-15	303594.04	4790.00	1973.36	2816.64	300777.40	7.8000	pending	\N	\N	2026-11-12 09:35:04.260293	2026-11-12 09:35:04.260293
4772	15	91	2033-10-15	300777.40	4790.00	1955.05	2834.95	297942.45	7.8000	pending	\N	\N	2026-11-12 09:35:04.272688	2026-11-12 09:35:04.272688
4773	15	92	2033-11-15	297942.45	4790.00	1936.63	2853.37	295089.08	7.8000	pending	\N	\N	2026-11-12 09:35:04.27982	2026-11-12 09:35:04.27982
4774	15	93	2033-12-15	295089.08	4790.00	1918.08	2871.92	292217.16	7.8000	pending	\N	\N	2026-11-12 09:35:04.289071	2026-11-12 09:35:04.289071
4775	15	94	2034-01-15	292217.16	4790.00	1899.41	2890.59	289326.57	7.8000	pending	\N	\N	2026-11-12 09:35:04.295295	2026-11-12 09:35:04.295295
4776	15	95	2034-02-15	289326.57	4790.00	1880.62	2909.38	286417.19	7.8000	pending	\N	\N	2026-11-12 09:35:04.302515	2026-11-12 09:35:04.302515
4777	15	96	2034-03-15	286417.19	4790.00	1861.71	2928.29	283488.90	7.8000	pending	\N	\N	2026-11-12 09:35:04.308315	2026-11-12 09:35:04.308315
4778	15	97	2034-04-15	283488.90	4790.00	1842.68	2947.32	280541.58	7.8000	pending	\N	\N	2026-11-12 09:35:04.313587	2026-11-12 09:35:04.313587
4779	15	98	2034-05-15	280541.58	4790.00	1823.52	2966.48	277575.10	7.8000	pending	\N	\N	2026-11-12 09:35:04.322389	2026-11-12 09:35:04.322389
4780	15	99	2034-06-15	277575.10	4790.00	1804.24	2985.76	274589.34	7.8000	pending	\N	\N	2026-11-12 09:35:04.327413	2026-11-12 09:35:04.327413
4781	15	100	2034-07-15	274589.34	4790.00	1784.83	3005.17	271584.17	7.8000	pending	\N	\N	2026-11-12 09:35:04.333913	2026-11-12 09:35:04.333913
4782	15	101	2034-08-15	271584.17	4790.00	1765.30	3024.70	268559.47	7.8000	pending	\N	\N	2026-11-12 09:35:04.340235	2026-11-12 09:35:04.340235
4783	15	102	2034-09-15	268559.47	4790.00	1745.64	3044.36	265515.10	7.8000	pending	\N	\N	2026-11-12 09:35:04.345666	2026-11-12 09:35:04.345666
4784	15	103	2034-10-15	265515.10	4790.00	1725.85	3064.15	262450.95	7.8000	pending	\N	\N	2026-11-12 09:35:04.351532	2026-11-12 09:35:04.351532
4785	15	104	2034-11-15	262450.95	4790.00	1705.93	3084.07	259366.88	7.8000	pending	\N	\N	2026-11-12 09:35:04.357924	2026-11-12 09:35:04.357924
4786	15	105	2034-12-15	259366.88	4790.00	1685.88	3104.12	256262.77	7.8000	pending	\N	\N	2026-11-12 09:35:04.363285	2026-11-12 09:35:04.363285
4787	15	106	2035-01-15	256262.77	4790.00	1665.71	3124.29	253138.47	7.8000	pending	\N	\N	2026-11-12 09:35:04.371862	2026-11-12 09:35:04.371862
4788	15	107	2035-02-15	253138.47	4790.00	1645.40	3144.60	249993.87	7.8000	pending	\N	\N	2026-11-12 09:35:04.378047	2026-11-12 09:35:04.378047
4789	15	108	2035-03-15	249993.87	4790.00	1624.96	3165.04	246828.83	7.8000	pending	\N	\N	2026-11-12 09:35:04.385264	2026-11-12 09:35:04.385264
4790	15	109	2035-04-15	246828.83	4790.00	1604.39	3185.61	243643.22	7.8000	pending	\N	\N	2026-11-12 09:35:04.391434	2026-11-12 09:35:04.391434
4791	15	110	2035-05-15	243643.22	4790.00	1583.68	3206.32	240436.90	7.8000	pending	\N	\N	2026-11-12 09:35:04.397114	2026-11-12 09:35:04.397114
4792	15	111	2035-06-15	240436.90	4790.00	1562.84	3227.16	237209.74	7.8000	pending	\N	\N	2026-11-12 09:35:04.403617	2026-11-12 09:35:04.403617
4793	15	112	2035-07-15	237209.74	4790.00	1541.86	3248.14	233961.61	7.8000	pending	\N	\N	2026-11-12 09:35:04.409567	2026-11-12 09:35:04.409567
4794	15	113	2035-08-15	233961.61	4790.00	1520.75	3269.25	230692.36	7.8000	pending	\N	\N	2026-11-12 09:35:04.414407	2026-11-12 09:35:04.414407
4795	15	114	2035-09-15	230692.36	4790.00	1499.50	3290.50	227401.86	7.8000	pending	\N	\N	2026-11-12 09:35:04.422325	2026-11-12 09:35:04.422325
4796	15	115	2035-10-15	227401.86	4790.00	1478.11	3311.89	224089.97	7.8000	pending	\N	\N	2026-11-12 09:35:04.42779	2026-11-12 09:35:04.42779
4797	15	116	2035-11-15	224089.97	4790.00	1456.58	3333.42	220756.55	7.8000	pending	\N	\N	2026-11-12 09:35:04.433501	2026-11-12 09:35:04.433501
4798	15	117	2035-12-15	220756.55	4790.00	1434.92	3355.08	217401.47	7.8000	pending	\N	\N	2026-11-12 09:35:04.439514	2026-11-12 09:35:04.439514
4799	15	118	2036-01-15	217401.47	4790.00	1413.11	3376.89	214024.58	7.8000	pending	\N	\N	2026-11-12 09:35:04.44421	2026-11-12 09:35:04.44421
4800	15	119	2036-02-15	214024.58	4790.00	1391.16	3398.84	210625.74	7.8000	pending	\N	\N	2026-11-12 09:35:04.450098	2026-11-12 09:35:04.450098
4801	15	120	2036-03-15	210625.74	4790.00	1369.07	3420.93	207204.81	7.8000	pending	\N	\N	2026-11-12 09:35:04.456506	2026-11-12 09:35:04.456506
4802	15	121	2036-04-15	207204.81	4790.00	1346.83	3443.17	203761.64	7.8000	pending	\N	\N	2026-11-12 09:35:04.463202	2026-11-12 09:35:04.463202
4803	15	122	2036-05-15	203761.64	4790.00	1324.45	3465.55	200296.09	7.8000	pending	\N	\N	2026-11-12 09:35:04.473456	2026-11-12 09:35:04.473456
4804	15	123	2036-06-15	200296.09	4790.00	1301.92	3488.08	196808.01	7.8000	pending	\N	\N	2026-11-12 09:35:04.479763	2026-11-12 09:35:04.479763
4805	15	124	2036-07-15	196808.01	4790.00	1279.25	3510.75	193297.27	7.8000	pending	\N	\N	2026-11-12 09:35:04.487433	2026-11-12 09:35:04.487433
4806	15	125	2036-08-15	193297.27	4790.00	1256.43	3533.57	189763.70	7.8000	pending	\N	\N	2026-11-12 09:35:04.495295	2026-11-12 09:35:04.495295
4807	15	126	2036-09-15	189763.70	4790.00	1233.46	3556.54	186207.16	7.8000	pending	\N	\N	2026-11-12 09:35:04.501527	2026-11-12 09:35:04.501527
4808	15	127	2036-10-15	186207.16	4790.00	1210.35	3579.65	182627.51	7.8000	pending	\N	\N	2026-11-12 09:35:04.50838	2026-11-12 09:35:04.50838
4809	15	128	2036-11-15	182627.51	4790.00	1187.08	3602.92	179024.59	7.8000	pending	\N	\N	2026-11-12 09:35:04.513531	2026-11-12 09:35:04.513531
4810	15	129	2036-12-15	179024.59	4790.00	1163.66	3626.34	175398.25	7.8000	pending	\N	\N	2026-11-12 09:35:04.520764	2026-11-12 09:35:04.520764
4811	15	130	2037-01-15	175398.25	4790.00	1140.09	3649.91	171748.34	7.8000	pending	\N	\N	2026-11-12 09:35:04.528133	2026-11-12 09:35:04.528133
4812	15	131	2037-02-15	171748.34	4790.00	1116.36	3673.64	168074.70	7.8000	pending	\N	\N	2026-11-12 09:35:04.534984	2026-11-12 09:35:04.534984
4813	15	132	2037-03-15	168074.70	4790.00	1092.49	3697.51	164377.19	7.8000	pending	\N	\N	2026-11-12 09:35:04.541905	2026-11-12 09:35:04.541905
4814	15	133	2037-04-15	164377.19	4790.00	1068.45	3721.55	160655.64	7.8000	pending	\N	\N	2026-11-12 09:35:04.54763	2026-11-12 09:35:04.54763
4815	15	134	2037-05-15	160655.64	4790.00	1044.26	3745.74	156909.90	7.8000	pending	\N	\N	2026-11-12 09:35:04.554825	2026-11-12 09:35:04.554825
4816	15	135	2037-06-15	156909.90	4790.00	1019.91	3770.09	153139.81	7.8000	pending	\N	\N	2026-11-12 09:35:04.560805	2026-11-12 09:35:04.560805
4817	15	136	2037-07-15	153139.81	4790.00	995.41	3794.59	149345.22	7.8000	pending	\N	\N	2026-11-12 09:35:04.5657	2026-11-12 09:35:04.5657
4818	15	137	2037-08-15	149345.22	4790.00	970.74	3819.26	145525.97	7.8000	pending	\N	\N	2026-11-12 09:35:04.572063	2026-11-12 09:35:04.572063
4819	15	138	2037-09-15	145525.97	4790.00	945.92	3844.08	141681.89	7.8000	pending	\N	\N	2026-11-12 09:35:04.580192	2026-11-12 09:35:04.580192
4820	15	139	2037-10-15	141681.89	4790.00	920.93	3869.07	137812.82	7.8000	pending	\N	\N	2026-11-12 09:35:04.586278	2026-11-12 09:35:04.586278
4821	15	140	2037-11-15	137812.82	4790.00	895.78	3894.22	133918.60	7.8000	pending	\N	\N	2026-11-12 09:35:04.593025	2026-11-12 09:35:04.593025
4822	15	141	2037-12-15	133918.60	4790.00	870.47	3919.53	129999.07	7.8000	pending	\N	\N	2026-11-12 09:35:04.598408	2026-11-12 09:35:04.598408
4823	15	142	2038-01-15	129999.07	4790.00	844.99	3945.01	126054.07	7.8000	pending	\N	\N	2026-11-12 09:35:04.60598	2026-11-12 09:35:04.60598
4824	15	143	2038-02-15	126054.07	4790.00	819.35	3970.65	122083.42	7.8000	pending	\N	\N	2026-11-12 09:35:04.612175	2026-11-12 09:35:04.612175
4825	15	144	2038-03-15	122083.42	4790.00	793.54	3996.46	118086.96	7.8000	pending	\N	\N	2026-11-12 09:35:04.618256	2026-11-12 09:35:04.618256
4826	15	145	2038-04-15	118086.96	4790.00	767.57	4022.43	114064.52	7.8000	pending	\N	\N	2026-11-12 09:35:04.624191	2026-11-12 09:35:04.624191
4827	15	146	2038-05-15	114064.52	4790.00	741.42	4048.58	110015.94	7.8000	pending	\N	\N	2026-11-12 09:35:04.63102	2026-11-12 09:35:04.63102
4828	15	147	2038-06-15	110015.94	4790.00	715.10	4074.90	105941.05	7.8000	pending	\N	\N	2026-11-12 09:35:04.638474	2026-11-12 09:35:04.638474
4829	15	148	2038-07-15	105941.05	4790.00	688.62	4101.38	101839.66	7.8000	pending	\N	\N	2026-11-12 09:35:04.645005	2026-11-12 09:35:04.645005
4830	15	149	2038-08-15	101839.66	4790.00	661.96	4128.04	97711.62	7.8000	pending	\N	\N	2026-11-12 09:35:04.651973	2026-11-12 09:35:04.651973
4831	15	150	2038-09-15	97711.62	4790.00	635.13	4154.87	93556.75	7.8000	pending	\N	\N	2026-11-12 09:35:04.659149	2026-11-12 09:35:04.659149
4832	15	151	2038-10-15	93556.75	4790.00	608.12	4181.88	89374.87	7.8000	pending	\N	\N	2026-11-12 09:35:04.664438	2026-11-12 09:35:04.664438
4833	15	152	2038-11-15	89374.87	4790.00	580.94	4209.06	85165.80	7.8000	pending	\N	\N	2026-11-12 09:35:04.670804	2026-11-12 09:35:04.670804
4834	15	153	2038-12-15	85165.80	4790.00	553.58	4236.42	80929.38	7.8000	pending	\N	\N	2026-11-12 09:35:04.677956	2026-11-12 09:35:04.677956
4835	15	154	2039-01-15	80929.38	4790.00	526.04	4263.96	76665.42	7.8000	pending	\N	\N	2026-11-12 09:35:04.684196	2026-11-12 09:35:04.684196
4836	15	155	2039-02-15	76665.42	4790.00	498.33	4291.67	72373.75	7.8000	pending	\N	\N	2026-11-12 09:35:04.690476	2026-11-12 09:35:04.690476
4837	15	156	2039-03-15	72373.75	4790.00	470.43	4319.57	68054.18	7.8000	pending	\N	\N	2026-11-12 09:35:04.697266	2026-11-12 09:35:04.697266
4838	15	157	2039-04-15	68054.18	4790.00	442.35	4347.65	63706.53	7.8000	pending	\N	\N	2026-11-12 09:35:04.703634	2026-11-12 09:35:04.703634
4839	15	158	2039-05-15	63706.53	4790.00	414.09	4375.91	59330.62	7.8000	pending	\N	\N	2026-11-12 09:35:04.710715	2026-11-12 09:35:04.710715
4840	15	159	2039-06-15	59330.62	4790.00	385.65	4404.35	54926.27	7.8000	pending	\N	\N	2026-11-12 09:35:04.716408	2026-11-12 09:35:04.716408
4841	15	160	2039-07-15	54926.27	4790.00	357.02	4432.98	50493.29	7.8000	pending	\N	\N	2026-11-12 09:35:04.723744	2026-11-12 09:35:04.723744
4842	15	161	2039-08-15	50493.29	4790.00	328.21	4461.79	46031.50	7.8000	pending	\N	\N	2026-11-12 09:35:04.732615	2026-11-12 09:35:04.732615
4843	15	162	2039-09-15	46031.50	4790.00	299.20	4490.80	41540.70	7.8000	pending	\N	\N	2026-11-12 09:35:04.739735	2026-11-12 09:35:04.739735
4844	15	163	2039-10-15	41540.70	4790.00	270.01	4519.99	37020.72	7.8000	pending	\N	\N	2026-11-12 09:35:04.745892	2026-11-12 09:35:04.745892
4845	15	164	2039-11-15	37020.72	4790.00	240.63	4549.37	32471.35	7.8000	pending	\N	\N	2026-11-12 09:35:04.753415	2026-11-12 09:35:04.753415
4846	15	165	2039-12-15	32471.35	4790.00	211.06	4578.94	27892.42	7.8000	pending	\N	\N	2026-11-12 09:35:04.759389	2026-11-12 09:35:04.759389
4847	15	166	2040-01-15	27892.42	4790.00	181.30	4608.70	23283.72	7.8000	pending	\N	\N	2026-11-12 09:35:04.766438	2026-11-12 09:35:04.766438
4848	15	167	2040-02-15	23283.72	4790.00	151.34	4638.66	18645.06	7.8000	pending	\N	\N	2026-11-12 09:35:04.772971	2026-11-12 09:35:04.772971
4849	15	168	2040-03-15	18645.06	4790.00	121.19	4668.81	13976.25	7.8000	pending	\N	\N	2026-11-12 09:35:04.777886	2026-11-12 09:35:04.777886
4850	15	169	2040-04-15	13976.25	4790.00	90.85	4699.15	9277.10	7.8000	pending	\N	\N	2026-11-12 09:35:04.786474	2026-11-12 09:35:04.786474
4851	15	170	2040-05-15	9277.10	4790.00	60.30	4729.70	4547.40	7.8000	pending	\N	\N	2026-11-12 09:35:04.794079	2026-11-12 09:35:04.794079
4852	15	171	2040-06-15	4547.40	4576.96	29.56	4547.40	0.00	7.8000	pending	\N	\N	2026-11-12 09:35:04.802894	2026-11-12 09:35:04.802894
4853	16	1	2026-04-15	493615.07	4705.63	3105.66	1599.97	492015.10	7.5500	paid	2026-04-15	4705.63	2026-11-12 09:35:05.629489	2026-11-12 09:35:05.629489
4854	16	2	2026-05-15	492015.10	4705.63	3095.60	1610.03	490405.07	7.5500	paid	2026-05-15	4705.63	2026-11-12 09:35:05.635653	2026-11-12 09:35:05.635653
4855	16	3	2026-06-15	490405.07	4705.63	3085.47	1620.16	488784.91	7.5500	paid	2026-06-15	4705.63	2026-11-12 09:35:05.641434	2026-11-12 09:35:05.641434
4856	16	4	2026-07-15	488784.91	4705.63	3075.27	1630.36	487154.55	7.5500	paid	2026-07-15	4705.63	2026-11-12 09:35:05.647339	2026-11-12 09:35:05.647339
4857	16	5	2026-08-15	487154.55	4705.63	3065.01	1640.61	485513.94	7.5500	paid	2026-08-15	4705.63	2026-11-12 09:35:05.653408	2026-11-12 09:35:05.653408
4858	16	6	2026-09-15	485513.94	4705.63	3054.69	1650.94	483863.00	7.5500	paid	2026-09-15	4705.63	2026-11-12 09:35:05.659345	2026-11-12 09:35:05.659345
4859	16	7	2026-10-15	483863.00	4705.63	3044.30	1661.32	482201.68	7.5500	paid	2026-10-15	4705.63	2026-11-12 09:35:05.664773	2026-11-12 09:35:05.664773
4860	16	8	2026-11-15	482188.50	4790.00	3134.23	1655.77	480532.73	7.8000	pending	\N	\N	2026-11-12 09:35:05.670931	2026-11-12 09:35:05.670931
4861	16	9	2026-12-15	480532.73	4790.00	3123.46	1666.54	478866.19	7.8000	pending	\N	\N	2026-11-12 09:35:05.676254	2026-11-12 09:35:05.676254
4862	16	10	2027-01-15	478866.19	4790.00	3112.63	1677.37	477188.82	7.8000	pending	\N	\N	2026-11-12 09:35:05.683483	2026-11-12 09:35:05.683483
4863	16	11	2027-02-15	477188.82	4790.00	3101.73	1688.27	475500.55	7.8000	pending	\N	\N	2026-11-12 09:35:05.68958	2026-11-12 09:35:05.68958
4864	16	12	2027-03-15	475500.55	4790.00	3090.75	1699.25	473801.30	7.8000	pending	\N	\N	2026-11-12 09:35:05.695759	2026-11-12 09:35:05.695759
4865	16	13	2027-04-15	473801.30	4790.00	3079.71	1710.29	472091.01	7.8000	pending	\N	\N	2026-11-12 09:35:05.701848	2026-11-12 09:35:05.701848
4866	16	14	2027-05-15	472091.01	4790.00	3068.59	1721.41	470369.60	7.8000	pending	\N	\N	2026-11-12 09:35:05.708396	2026-11-12 09:35:05.708396
4867	16	15	2027-06-15	470369.60	4790.00	3057.40	1732.60	468637.00	7.8000	pending	\N	\N	2026-11-12 09:35:05.714351	2026-11-12 09:35:05.714351
4868	16	16	2027-07-15	468637.00	4790.00	3046.14	1743.86	466893.14	7.8000	pending	\N	\N	2026-11-12 09:35:05.721045	2026-11-12 09:35:05.721045
4869	16	17	2027-08-15	466893.14	4790.00	3034.81	1755.19	465137.95	7.8000	pending	\N	\N	2026-11-12 09:35:05.726389	2026-11-12 09:35:05.726389
4870	16	18	2027-09-15	465137.95	4790.00	3023.40	1766.60	463371.34	7.8000	pending	\N	\N	2026-11-12 09:35:05.732983	2026-11-12 09:35:05.732983
4871	16	19	2027-10-15	463371.34	4790.00	3011.91	1778.09	461593.26	7.8000	pending	\N	\N	2026-11-12 09:35:05.740023	2026-11-12 09:35:05.740023
4872	16	20	2027-11-15	461593.26	4790.00	3000.36	1789.64	459803.61	7.8000	pending	\N	\N	2026-11-12 09:35:05.745198	2026-11-12 09:35:05.745198
4873	16	21	2027-12-15	459803.61	4790.00	2988.72	1801.28	458002.34	7.8000	pending	\N	\N	2026-11-12 09:35:05.752093	2026-11-12 09:35:05.752093
4874	16	22	2028-01-15	458002.34	4790.00	2977.02	1812.98	456189.35	7.8000	pending	\N	\N	2026-11-12 09:35:05.758186	2026-11-12 09:35:05.758186
4875	16	23	2028-02-15	456189.35	4790.00	2965.23	1824.77	454364.58	7.8000	pending	\N	\N	2026-11-12 09:35:05.765254	2026-11-12 09:35:05.765254
4876	16	24	2028-03-15	454364.58	4790.00	2953.37	1836.63	452527.95	7.8000	pending	\N	\N	2026-11-12 09:35:05.772951	2026-11-12 09:35:05.772951
4877	16	25	2028-04-15	452527.95	4790.00	2941.43	1848.57	450679.38	7.8000	pending	\N	\N	2026-11-12 09:35:05.777922	2026-11-12 09:35:05.777922
4878	16	26	2028-05-15	450679.38	4790.00	2929.42	1860.58	448818.80	7.8000	pending	\N	\N	2026-11-12 09:35:05.783991	2026-11-12 09:35:05.783991
4879	16	27	2028-06-15	448818.80	4790.00	2917.32	1872.68	446946.12	7.8000	pending	\N	\N	2026-11-12 09:35:05.792259	2026-11-12 09:35:05.792259
4880	16	28	2028-07-15	446946.12	4790.00	2905.15	1884.85	445061.27	7.8000	pending	\N	\N	2026-11-12 09:35:05.79767	2026-11-12 09:35:05.79767
4881	16	29	2028-08-15	445061.27	4790.00	2892.90	1897.10	443164.17	7.8000	pending	\N	\N	2026-11-12 09:35:05.805411	2026-11-12 09:35:05.805411
4882	16	30	2028-09-15	443164.17	4790.00	2880.57	1909.43	441254.74	7.8000	pending	\N	\N	2026-11-12 09:35:05.811288	2026-11-12 09:35:05.811288
4883	16	31	2028-10-15	441254.74	4790.00	2868.16	1921.84	439332.89	7.8000	pending	\N	\N	2026-11-12 09:35:05.817098	2026-11-12 09:35:05.817098
4884	16	32	2028-11-15	439332.89	4790.00	2855.66	1934.34	437398.56	7.8000	pending	\N	\N	2026-11-12 09:35:05.824424	2026-11-12 09:35:05.824424
4885	16	33	2028-12-15	437398.56	4790.00	2843.09	1946.91	435451.65	7.8000	pending	\N	\N	2026-11-12 09:35:05.82959	2026-11-12 09:35:05.82959
4886	16	34	2029-01-15	435451.65	4790.00	2830.44	1959.56	433492.08	7.8000	pending	\N	\N	2026-11-12 09:35:05.836681	2026-11-12 09:35:05.836681
4887	16	35	2029-02-15	433492.08	4790.00	2817.70	1972.30	431519.78	7.8000	pending	\N	\N	2026-11-12 09:35:05.843837	2026-11-12 09:35:05.843837
4888	16	36	2029-03-15	431519.78	4790.00	2804.88	1985.12	429534.66	7.8000	pending	\N	\N	2026-11-12 09:35:05.849832	2026-11-12 09:35:05.849832
4889	16	37	2029-04-15	429534.66	4790.00	2791.98	1998.02	427536.64	7.8000	pending	\N	\N	2026-11-12 09:35:05.856306	2026-11-12 09:35:05.856306
4890	16	38	2029-05-15	427536.64	4790.00	2778.99	2011.01	425525.62	7.8000	pending	\N	\N	2026-11-12 09:35:05.862352	2026-11-12 09:35:05.862352
4891	16	39	2029-06-15	425525.62	4790.00	2765.92	2024.08	423501.54	7.8000	pending	\N	\N	2026-11-12 09:35:05.869192	2026-11-12 09:35:05.869192
4892	16	40	2029-07-15	423501.54	4790.00	2752.76	2037.24	421464.30	7.8000	pending	\N	\N	2026-11-12 09:35:05.8769	2026-11-12 09:35:05.8769
4893	16	41	2029-08-15	421464.30	4790.00	2739.52	2050.48	419413.82	7.8000	pending	\N	\N	2026-11-12 09:35:05.884611	2026-11-12 09:35:05.884611
4894	16	42	2029-09-15	419413.82	4790.00	2726.19	2063.81	417350.01	7.8000	pending	\N	\N	2026-11-12 09:35:05.890594	2026-11-12 09:35:05.890594
4895	16	43	2029-10-15	417350.01	4790.00	2712.78	2077.22	415272.78	7.8000	pending	\N	\N	2026-11-12 09:35:05.895633	2026-11-12 09:35:05.895633
4896	16	44	2029-11-15	415272.78	4790.00	2699.27	2090.73	413182.06	7.8000	pending	\N	\N	2026-11-12 09:35:05.903951	2026-11-12 09:35:05.903951
4897	16	45	2029-12-15	413182.06	4790.00	2685.68	2104.32	411077.74	7.8000	pending	\N	\N	2026-11-12 09:35:05.909677	2026-11-12 09:35:05.909677
4898	16	46	2030-01-15	411077.74	4790.00	2672.01	2117.99	408959.75	7.8000	pending	\N	\N	2026-11-12 09:35:05.915715	2026-11-12 09:35:05.915715
4899	16	47	2030-02-15	408959.75	4790.00	2658.24	2131.76	406827.98	7.8000	pending	\N	\N	2026-11-12 09:35:05.923189	2026-11-12 09:35:05.923189
4900	16	48	2030-03-15	406827.98	4790.00	2644.38	2145.62	404682.37	7.8000	pending	\N	\N	2026-11-12 09:35:05.928862	2026-11-12 09:35:05.928862
4901	16	49	2030-04-15	404682.37	4790.00	2630.44	2159.56	402522.80	7.8000	pending	\N	\N	2026-11-12 09:35:05.936305	2026-11-12 09:35:05.936305
4902	16	50	2030-05-15	402522.80	4790.00	2616.40	2173.60	400349.20	7.8000	pending	\N	\N	2026-11-12 09:35:05.94182	2026-11-12 09:35:05.94182
4903	16	51	2030-06-15	400349.20	4790.00	2602.27	2187.73	398161.47	7.8000	pending	\N	\N	2026-11-12 09:35:05.946589	2026-11-12 09:35:05.946589
4904	16	52	2030-07-15	398161.47	4790.00	2588.05	2201.95	395959.52	7.8000	pending	\N	\N	2026-11-12 09:35:05.954872	2026-11-12 09:35:05.954872
4905	16	53	2030-08-15	395959.52	4790.00	2573.74	2216.26	393743.26	7.8000	pending	\N	\N	2026-11-12 09:35:05.960225	2026-11-12 09:35:05.960225
4906	16	54	2030-09-15	393743.26	4790.00	2559.33	2230.67	391512.59	7.8000	pending	\N	\N	2026-11-12 09:35:05.965775	2026-11-12 09:35:05.965775
4907	16	55	2030-10-15	391512.59	4790.00	2544.83	2245.17	389267.42	7.8000	pending	\N	\N	2026-11-12 09:35:05.972082	2026-11-12 09:35:05.972082
4908	16	56	2030-11-15	389267.42	4790.00	2530.24	2259.76	387007.66	7.8000	pending	\N	\N	2026-11-12 09:35:05.977142	2026-11-12 09:35:05.977142
4909	16	57	2030-12-15	387007.66	4790.00	2515.55	2274.45	384733.21	7.8000	pending	\N	\N	2026-11-12 09:35:05.982669	2026-11-12 09:35:05.982669
4910	16	58	2031-01-15	384733.21	4790.00	2500.77	2289.23	382443.97	7.8000	pending	\N	\N	2026-11-12 09:35:05.988695	2026-11-12 09:35:05.988695
4911	16	59	2031-02-15	382443.97	4790.00	2485.89	2304.11	380139.86	7.8000	pending	\N	\N	2026-11-12 09:35:05.993711	2026-11-12 09:35:05.993711
4912	16	60	2031-03-15	380139.86	4790.00	2470.91	2319.09	377820.77	7.8000	pending	\N	\N	2026-11-12 09:35:06.000584	2026-11-12 09:35:06.000584
4913	16	61	2031-04-15	377820.77	4790.00	2455.83	2334.17	375486.60	7.8000	pending	\N	\N	2026-11-12 09:35:06.006939	2026-11-12 09:35:06.006939
4914	16	62	2031-05-15	375486.60	4790.00	2440.66	2349.34	373137.27	7.8000	pending	\N	\N	2026-11-12 09:35:06.011844	2026-11-12 09:35:06.011844
4915	16	63	2031-06-15	373137.27	4790.00	2425.39	2364.61	370772.66	7.8000	pending	\N	\N	2026-11-12 09:35:06.019413	2026-11-12 09:35:06.019413
4916	16	64	2031-07-15	370772.66	4790.00	2410.02	2379.98	368392.68	7.8000	pending	\N	\N	2026-11-12 09:35:06.024953	2026-11-12 09:35:06.024953
4917	16	65	2031-08-15	368392.68	4790.00	2394.55	2395.45	365997.23	7.8000	pending	\N	\N	2026-11-12 09:35:06.030071	2026-11-12 09:35:06.030071
4918	16	66	2031-09-15	365997.23	4790.00	2378.98	2411.02	363586.21	7.8000	pending	\N	\N	2026-11-12 09:35:06.03718	2026-11-12 09:35:06.03718
4919	16	67	2031-10-15	363586.21	4790.00	2363.31	2426.69	361159.53	7.8000	pending	\N	\N	2026-11-12 09:35:06.043408	2026-11-12 09:35:06.043408
4920	16	68	2031-11-15	361159.53	4790.00	2347.54	2442.46	358717.06	7.8000	pending	\N	\N	2026-11-12 09:35:06.04885	2026-11-12 09:35:06.04885
4921	16	69	2031-12-15	358717.06	4790.00	2331.66	2458.34	356258.72	7.8000	pending	\N	\N	2026-11-12 09:35:06.05722	2026-11-12 09:35:06.05722
4922	16	70	2032-01-15	356258.72	4790.00	2315.68	2474.32	353784.40	7.8000	pending	\N	\N	2026-11-12 09:35:06.062391	2026-11-12 09:35:06.062391
4923	16	71	2032-02-15	353784.40	4790.00	2299.60	2490.40	351294.00	7.8000	pending	\N	\N	2026-11-12 09:35:06.070037	2026-11-12 09:35:06.070037
4924	16	72	2032-03-15	351294.00	4790.00	2283.41	2506.59	348787.41	7.8000	pending	\N	\N	2026-11-12 09:35:06.075516	2026-11-12 09:35:06.075516
4925	16	73	2032-04-15	348787.41	4790.00	2267.12	2522.88	346264.53	7.8000	pending	\N	\N	2026-11-12 09:35:06.080436	2026-11-12 09:35:06.080436
4926	16	74	2032-05-15	346264.53	4790.00	2250.72	2539.28	343725.25	7.8000	pending	\N	\N	2026-11-12 09:35:06.08818	2026-11-12 09:35:06.08818
4927	16	75	2032-06-15	343725.25	4790.00	2234.21	2555.79	341169.47	7.8000	pending	\N	\N	2026-11-12 09:35:06.093614	2026-11-12 09:35:06.093614
4928	16	76	2032-07-15	341169.47	4790.00	2217.60	2572.40	338597.07	7.8000	pending	\N	\N	2026-11-12 09:35:06.098817	2026-11-12 09:35:06.098817
4929	16	77	2032-08-15	338597.07	4790.00	2200.88	2589.12	336007.95	7.8000	pending	\N	\N	2026-11-12 09:35:06.107223	2026-11-12 09:35:06.107223
4930	16	78	2032-09-15	336007.95	4790.00	2184.05	2605.95	333402.00	7.8000	pending	\N	\N	2026-11-12 09:35:06.112597	2026-11-12 09:35:06.112597
4931	16	79	2032-10-15	333402.00	4790.00	2167.11	2622.89	330779.11	7.8000	pending	\N	\N	2026-11-12 09:35:06.121257	2026-11-12 09:35:06.121257
4932	16	80	2032-11-15	330779.11	4790.00	2150.06	2639.94	328139.18	7.8000	pending	\N	\N	2026-11-12 09:35:06.126929	2026-11-12 09:35:06.126929
4933	16	81	2032-12-15	328139.18	4790.00	2132.90	2657.10	325482.08	7.8000	pending	\N	\N	2026-11-12 09:35:06.132466	2026-11-12 09:35:06.132466
4934	16	82	2033-01-15	325482.08	4790.00	2115.63	2674.37	322807.72	7.8000	pending	\N	\N	2026-11-12 09:35:06.139291	2026-11-12 09:35:06.139291
4935	16	83	2033-02-15	322807.72	4790.00	2098.25	2691.75	320115.97	7.8000	pending	\N	\N	2026-11-12 09:35:06.144428	2026-11-12 09:35:06.144428
4936	16	84	2033-03-15	320115.97	4790.00	2080.75	2709.25	317406.72	7.8000	pending	\N	\N	2026-11-12 09:35:06.149405	2026-11-12 09:35:06.149405
4937	16	85	2033-04-15	317406.72	4790.00	2063.14	2726.86	314679.86	7.8000	pending	\N	\N	2026-11-12 09:35:06.157561	2026-11-12 09:35:06.157561
4938	16	86	2033-05-15	314679.86	4790.00	2045.42	2744.58	311935.28	7.8000	pending	\N	\N	2026-11-12 09:35:06.162336	2026-11-12 09:35:06.162336
4939	16	87	2033-06-15	311935.28	4790.00	2027.58	2762.42	309172.86	7.8000	pending	\N	\N	2026-11-12 09:35:06.168924	2026-11-12 09:35:06.168924
4940	16	88	2033-07-15	309172.86	4790.00	2009.62	2780.38	306392.49	7.8000	pending	\N	\N	2026-11-12 09:35:06.175316	2026-11-12 09:35:06.175316
4941	16	89	2033-08-15	306392.49	4790.00	1991.55	2798.45	303594.04	7.8000	pending	\N	\N	2026-11-12 09:35:06.181397	2026-11-12 09:35:06.181397
4942	16	90	2033-09-15	303594.04	4790.00	1973.36	2816.64	300777.40	7.8000	pending	\N	\N	2026-11-12 09:35:06.188164	2026-11-12 09:35:06.188164
4943	16	91	2033-10-15	300777.40	4790.00	1955.05	2834.95	297942.45	7.8000	pending	\N	\N	2026-11-12 09:35:06.19353	2026-11-12 09:35:06.19353
4944	16	92	2033-11-15	297942.45	4790.00	1936.63	2853.37	295089.08	7.8000	pending	\N	\N	2026-11-12 09:35:06.198974	2026-11-12 09:35:06.198974
4945	16	93	2033-12-15	295089.08	4790.00	1918.08	2871.92	292217.16	7.8000	pending	\N	\N	2026-11-12 09:35:06.207329	2026-11-12 09:35:06.207329
4946	16	94	2034-01-15	292217.16	4790.00	1899.41	2890.59	289326.57	7.8000	pending	\N	\N	2026-11-12 09:35:06.21282	2026-11-12 09:35:06.21282
4947	16	95	2034-02-15	289326.57	4790.00	1880.62	2909.38	286417.19	7.8000	pending	\N	\N	2026-11-12 09:35:06.220295	2026-11-12 09:35:06.220295
4948	16	96	2034-03-15	286417.19	4790.00	1861.71	2928.29	283488.90	7.8000	pending	\N	\N	2026-11-12 09:35:06.225918	2026-11-12 09:35:06.225918
4949	16	97	2034-04-15	283488.90	4790.00	1842.68	2947.32	280541.58	7.8000	pending	\N	\N	2026-11-12 09:35:06.231474	2026-11-12 09:35:06.231474
4950	16	98	2034-05-15	280541.58	4790.00	1823.52	2966.48	277575.10	7.8000	pending	\N	\N	2026-11-12 09:35:06.238144	2026-11-12 09:35:06.238144
4951	16	99	2034-06-15	277575.10	4790.00	1804.24	2985.76	274589.34	7.8000	pending	\N	\N	2026-11-12 09:35:06.243562	2026-11-12 09:35:06.243562
4952	16	100	2034-07-15	274589.34	4790.00	1784.83	3005.17	271584.17	7.8000	pending	\N	\N	2026-11-12 09:35:06.248549	2026-11-12 09:35:06.248549
4953	16	101	2034-08-15	271584.17	4790.00	1765.30	3024.70	268559.47	7.8000	pending	\N	\N	2026-11-12 09:35:06.256747	2026-11-12 09:35:06.256747
4954	16	102	2034-09-15	268559.47	4790.00	1745.64	3044.36	265515.10	7.8000	pending	\N	\N	2026-11-12 09:35:06.262265	2026-11-12 09:35:06.262265
4955	16	103	2034-10-15	265515.10	4790.00	1725.85	3064.15	262450.95	7.8000	pending	\N	\N	2026-11-12 09:35:06.268899	2026-11-12 09:35:06.268899
4956	16	104	2034-11-15	262450.95	4790.00	1705.93	3084.07	259366.88	7.8000	pending	\N	\N	2026-11-12 09:35:06.275322	2026-11-12 09:35:06.275322
4957	16	105	2034-12-15	259366.88	4790.00	1685.88	3104.12	256262.77	7.8000	pending	\N	\N	2026-11-12 09:35:06.281129	2026-11-12 09:35:06.281129
4958	16	106	2035-01-15	256262.77	4790.00	1665.71	3124.29	253138.47	7.8000	pending	\N	\N	2026-11-12 09:35:06.288087	2026-11-12 09:35:06.288087
4959	16	107	2035-02-15	253138.47	4790.00	1645.40	3144.60	249993.87	7.8000	pending	\N	\N	2026-11-12 09:35:06.293577	2026-11-12 09:35:06.293577
4960	16	108	2035-03-15	249993.87	4790.00	1624.96	3165.04	246828.83	7.8000	pending	\N	\N	2026-11-12 09:35:06.298669	2026-11-12 09:35:06.298669
4961	16	109	2035-04-15	246828.83	4790.00	1604.39	3185.61	243643.22	7.8000	pending	\N	\N	2026-11-12 09:35:06.307561	2026-11-12 09:35:06.307561
4962	16	110	2035-05-15	243643.22	4790.00	1583.68	3206.32	240436.90	7.8000	pending	\N	\N	2026-11-12 09:35:06.312468	2026-11-12 09:35:06.312468
4963	16	111	2035-06-15	240436.90	4790.00	1562.84	3227.16	237209.74	7.8000	pending	\N	\N	2026-11-12 09:35:06.319511	2026-11-12 09:35:06.319511
4964	16	112	2035-07-15	237209.74	4790.00	1541.86	3248.14	233961.61	7.8000	pending	\N	\N	2026-11-12 09:35:06.325334	2026-11-12 09:35:06.325334
4965	16	113	2035-08-15	233961.61	4790.00	1520.75	3269.25	230692.36	7.8000	pending	\N	\N	2026-11-12 09:35:06.330832	2026-11-12 09:35:06.330832
4966	16	114	2035-09-15	230692.36	4790.00	1499.50	3290.50	227401.86	7.8000	pending	\N	\N	2026-11-12 09:35:06.337441	2026-11-12 09:35:06.337441
4967	16	115	2035-10-15	227401.86	4790.00	1478.11	3311.89	224089.97	7.8000	pending	\N	\N	2026-11-12 09:35:06.342938	2026-11-12 09:35:06.342938
4968	16	116	2035-11-15	224089.97	4790.00	1456.58	3333.42	220756.55	7.8000	pending	\N	\N	2026-11-12 09:35:06.347779	2026-11-12 09:35:06.347779
4969	16	117	2035-12-15	220756.55	4790.00	1434.92	3355.08	217401.47	7.8000	pending	\N	\N	2026-11-12 09:35:06.355901	2026-11-12 09:35:06.355901
4970	16	118	2036-01-15	217401.47	4790.00	1413.11	3376.89	214024.58	7.8000	pending	\N	\N	2026-11-12 09:35:06.361194	2026-11-12 09:35:06.361194
4971	16	119	2036-02-15	214024.58	4790.00	1391.16	3398.84	210625.74	7.8000	pending	\N	\N	2026-11-12 09:35:06.367488	2026-11-12 09:35:06.367488
4972	16	120	2036-03-15	210625.74	4790.00	1369.07	3420.93	207204.81	7.8000	pending	\N	\N	2026-11-12 09:35:06.374279	2026-11-12 09:35:06.374279
4973	16	121	2036-04-15	207204.81	4790.00	1346.83	3443.17	203761.64	7.8000	pending	\N	\N	2026-11-12 09:35:06.380027	2026-11-12 09:35:06.380027
4974	16	122	2036-05-15	203761.64	4790.00	1324.45	3465.55	200296.09	7.8000	pending	\N	\N	2026-11-12 09:35:06.38608	2026-11-12 09:35:06.38608
4975	16	123	2036-06-15	200296.09	4790.00	1301.92	3488.08	196808.01	7.8000	pending	\N	\N	2026-11-12 09:35:06.391737	2026-11-12 09:35:06.391737
4976	16	124	2036-07-15	196808.01	4790.00	1279.25	3510.75	193297.27	7.8000	pending	\N	\N	2026-11-12 09:35:06.398197	2026-11-12 09:35:06.398197
4977	16	125	2036-08-15	193297.27	4790.00	1256.43	3533.57	189763.70	7.8000	pending	\N	\N	2026-11-12 09:35:06.405241	2026-11-12 09:35:06.405241
4978	16	126	2036-09-15	189763.70	4790.00	1233.46	3556.54	186207.16	7.8000	pending	\N	\N	2026-11-12 09:35:06.411268	2026-11-12 09:35:06.411268
4979	16	127	2036-10-15	186207.16	4790.00	1210.35	3579.65	182627.51	7.8000	pending	\N	\N	2026-11-12 09:35:06.418407	2026-11-12 09:35:06.418407
4980	16	128	2036-11-15	182627.51	4790.00	1187.08	3602.92	179024.59	7.8000	pending	\N	\N	2026-11-12 09:35:06.424608	2026-11-12 09:35:06.424608
4981	16	129	2036-12-15	179024.59	4790.00	1163.66	3626.34	175398.25	7.8000	pending	\N	\N	2026-11-12 09:35:06.4304	2026-11-12 09:35:06.4304
4982	16	130	2037-01-15	175398.25	4790.00	1140.09	3649.91	171748.34	7.8000	pending	\N	\N	2026-11-12 09:35:06.436327	2026-11-12 09:35:06.436327
4983	16	131	2037-02-15	171748.34	4790.00	1116.36	3673.64	168074.70	7.8000	pending	\N	\N	2026-11-12 09:35:06.44196	2026-11-12 09:35:06.44196
4984	16	132	2037-03-15	168074.70	4790.00	1092.49	3697.51	164377.19	7.8000	pending	\N	\N	2026-11-12 09:35:06.448686	2026-11-12 09:35:06.448686
4985	16	133	2037-04-15	164377.19	4790.00	1068.45	3721.55	160655.64	7.8000	pending	\N	\N	2026-11-12 09:35:06.45534	2026-11-12 09:35:06.45534
4986	16	134	2037-05-15	160655.64	4790.00	1044.26	3745.74	156909.90	7.8000	pending	\N	\N	2026-11-12 09:35:06.460883	2026-11-12 09:35:06.460883
4987	16	135	2037-06-15	156909.90	4790.00	1019.91	3770.09	153139.81	7.8000	pending	\N	\N	2026-11-12 09:35:06.467053	2026-11-12 09:35:06.467053
4988	16	136	2037-07-15	153139.81	4790.00	995.41	3794.59	149345.22	7.8000	pending	\N	\N	2026-11-12 09:35:06.473079	2026-11-12 09:35:06.473079
4989	16	137	2037-08-15	149345.22	4790.00	970.74	3819.26	145525.97	7.8000	pending	\N	\N	2026-11-12 09:35:06.478726	2026-11-12 09:35:06.478726
4990	16	138	2037-09-15	145525.97	4790.00	945.92	3844.08	141681.89	7.8000	pending	\N	\N	2026-11-12 09:35:06.483601	2026-11-12 09:35:06.483601
4991	16	139	2037-10-15	141681.89	4790.00	920.93	3869.07	137812.82	7.8000	pending	\N	\N	2026-11-12 09:35:06.489481	2026-11-12 09:35:06.489481
4992	16	140	2037-11-15	137812.82	4790.00	895.78	3894.22	133918.60	7.8000	pending	\N	\N	2026-11-12 09:35:06.496421	2026-11-12 09:35:06.496421
4993	16	141	2037-12-15	133918.60	4790.00	870.47	3919.53	129999.07	7.8000	pending	\N	\N	2026-11-12 09:35:06.503571	2026-11-12 09:35:06.503571
4994	16	142	2038-01-15	129999.07	4790.00	844.99	3945.01	126054.07	7.8000	pending	\N	\N	2026-11-12 09:35:06.509963	2026-11-12 09:35:06.509963
4995	16	143	2038-02-15	126054.07	4790.00	819.35	3970.65	122083.42	7.8000	pending	\N	\N	2026-11-12 09:35:06.515962	2026-11-12 09:35:06.515962
4996	16	144	2038-03-15	122083.42	4790.00	793.54	3996.46	118086.96	7.8000	pending	\N	\N	2026-11-12 09:35:06.523054	2026-11-12 09:35:06.523054
4997	16	145	2038-04-15	118086.96	4790.00	767.57	4022.43	114064.52	7.8000	pending	\N	\N	2026-11-12 09:35:06.529126	2026-11-12 09:35:06.529126
4998	16	146	2038-05-15	114064.52	4790.00	741.42	4048.58	110015.94	7.8000	pending	\N	\N	2026-11-12 09:35:06.535457	2026-11-12 09:35:06.535457
4999	16	147	2038-06-15	110015.94	4790.00	715.10	4074.90	105941.05	7.8000	pending	\N	\N	2026-11-12 09:35:06.541304	2026-11-12 09:35:06.541304
5000	16	148	2038-07-15	105941.05	4790.00	688.62	4101.38	101839.66	7.8000	pending	\N	\N	2026-11-12 09:35:06.548818	2026-11-12 09:35:06.548818
5001	16	149	2038-08-15	101839.66	4790.00	661.96	4128.04	97711.62	7.8000	pending	\N	\N	2026-11-12 09:35:06.555523	2026-11-12 09:35:06.555523
5002	16	150	2038-09-15	97711.62	4790.00	635.13	4154.87	93556.75	7.8000	pending	\N	\N	2026-11-12 09:35:06.561592	2026-11-12 09:35:06.561592
\.


--
-- Data for Name: loan_interest_rates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_interest_rates (id, loan_id, interest_rate, effective_from, effective_to, remarks, created_at, updated_at, emi_amount, opening_principal, remaining_months) FROM stdin;
19	13	7.7000	2026-04-15	2026-10-15	Initial rate	2026-11-12 09:34:59.041557	2026-11-12 09:34:59.051708	\N	\N	\N
20	13	7.9500	2026-10-16	\N	Repo rate +0.25% · bank revised: ₹51,44,625 combined @ 7.95%, EMI ₹52,620 combined, 159 months	2026-11-12 09:34:59.056854	2026-11-12 09:34:59.056854	26310.00	2572312.50	159
21	14	7.7000	2026-04-15	2026-10-15	Initial rate	2026-11-12 09:35:01.149602	2026-11-12 09:35:01.162652	\N	\N	\N
22	14	7.9500	2026-10-16	\N	Repo rate +0.25% · bank revised: ₹51,44,625 combined @ 7.95%, EMI ₹52,620 combined, 159 months	2026-11-12 09:35:01.167437	2026-11-12 09:35:01.167437	26310.00	2572312.50	159
23	15	7.5500	2026-04-15	2026-10-15	Initial rate	2026-11-12 09:35:03.057488	2026-11-12 09:35:03.075207	\N	\N	\N
24	15	7.8000	2026-10-16	\N	Repo rate +0.25% · bank revised: ₹9,64,377 combined @ 7.80%, EMI ₹9,580 combined, 164 months	2026-11-12 09:35:03.0822	2026-11-12 09:35:03.0822	4790.00	482188.50	164
25	16	7.5500	2026-04-15	2026-10-15	Initial rate	2026-11-12 09:35:05.040319	2026-11-12 09:35:05.048888	\N	\N	\N
26	16	7.8000	2026-10-16	\N	Repo rate +0.25% · bank revised: ₹9,64,377 combined @ 7.80%, EMI ₹9,580 combined, 164 months	2026-11-12 09:35:05.055332	2026-11-12 09:35:05.055332	4790.00	482188.50	164
\.


--
-- Data for Name: loan_monthly_snapshots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_monthly_snapshots (id, loan_id, year, month, opening_balance, emi_paid, principal_paid, interest_paid, prepayment, charges, total_paid, closing_balance, interest_rate, remaining_months, created_at, updated_at) FROM stdin;
245	13	2026	4	2637592.17	25960.46	9035.91	16924.55	0.00	0.00	25960.46	2628556.26	7.9500	159	2026-11-12 09:35:01.053146	2026-11-12 09:35:01.053146
246	13	2026	5	2628556.26	25960.46	9093.89	16866.57	0.00	0.00	25960.46	2619462.37	7.7000	159	2026-11-12 09:35:01.067852	2026-11-12 09:35:01.067852
247	13	2026	6	2619462.37	25960.46	9152.25	16808.22	0.00	0.00	25960.46	2610310.12	7.7000	159	2026-11-12 09:35:01.077906	2026-11-12 09:35:01.077906
248	13	2026	7	2610310.12	25960.46	9210.97	16749.49	0.00	0.00	25960.46	2601099.15	7.7000	159	2026-11-12 09:35:01.086157	2026-11-12 09:35:01.086157
249	13	2026	8	2601099.15	25960.46	9270.08	16690.39	0.00	0.00	25960.46	2591829.07	7.7000	159	2026-11-12 09:35:01.093228	2026-11-12 09:35:01.093228
250	13	2026	9	2591829.07	25960.46	9329.56	16630.90	0.00	0.00	25960.46	2582499.51	7.7000	159	2026-11-12 09:35:01.099649	2026-11-12 09:35:01.099649
251	13	2026	10	2582499.51	25960.46	9389.43	16571.04	0.00	0.00	25960.46	2573110.08	7.7000	159	2026-11-12 09:35:01.111408	2026-11-12 09:35:01.111408
252	14	2026	4	2637592.17	25960.46	9035.91	16924.55	0.00	0.00	25960.46	2628556.26	7.9500	159	2026-11-12 09:35:02.9188	2026-11-12 09:35:02.9188
253	14	2026	5	2628556.26	25960.46	9093.89	16866.57	0.00	0.00	25960.46	2619462.37	7.7000	159	2026-11-12 09:35:02.946952	2026-11-12 09:35:02.946952
254	14	2026	6	2619462.37	25960.46	9152.25	16808.22	0.00	0.00	25960.46	2610310.12	7.7000	159	2026-11-12 09:35:02.981506	2026-11-12 09:35:02.981506
255	14	2026	7	2610310.12	25960.46	9210.97	16749.49	0.00	0.00	25960.46	2601099.15	7.7000	159	2026-11-12 09:35:02.990095	2026-11-12 09:35:02.990095
256	14	2026	8	2601099.15	25960.46	9270.08	16690.39	0.00	0.00	25960.46	2591829.07	7.7000	159	2026-11-12 09:35:02.999817	2026-11-12 09:35:02.999817
257	14	2026	9	2591829.07	25960.46	9329.56	16630.90	0.00	0.00	25960.46	2582499.51	7.7000	159	2026-11-12 09:35:03.008205	2026-11-12 09:35:03.008205
258	14	2026	10	2582499.51	25960.46	9389.43	16571.04	0.00	0.00	25960.46	2573110.08	7.7000	159	2026-11-12 09:35:03.015705	2026-11-12 09:35:03.015705
259	15	2026	4	493615.07	4705.63	1599.97	3105.66	0.00	0.00	4705.63	492015.10	7.8000	164	2026-11-12 09:35:04.948338	2026-11-12 09:35:04.948338
260	15	2026	5	492015.10	4705.63	1610.03	3095.60	0.00	0.00	4705.63	490405.07	7.5500	164	2026-11-12 09:35:04.957681	2026-11-12 09:35:04.957681
261	15	2026	6	490405.07	4705.63	1620.16	3085.47	0.00	0.00	4705.63	488784.91	7.5500	164	2026-11-12 09:35:04.965422	2026-11-12 09:35:04.965422
262	15	2026	7	488784.91	4705.63	1630.36	3075.27	0.00	0.00	4705.63	487154.55	7.5500	164	2026-11-12 09:35:04.973931	2026-11-12 09:35:04.973931
263	15	2026	8	487154.55	4705.63	1640.61	3065.01	0.00	0.00	4705.63	485513.94	7.5500	164	2026-11-12 09:35:04.981748	2026-11-12 09:35:04.981748
264	15	2026	9	485513.94	4705.63	1650.94	3054.69	0.00	0.00	4705.63	483863.00	7.5500	164	2026-11-12 09:35:04.992343	2026-11-12 09:35:04.992343
265	15	2026	10	483863.00	4705.63	1661.32	3044.30	0.00	0.00	4705.63	482201.68	7.5500	164	2026-11-12 09:35:04.99959	2026-11-12 09:35:04.99959
266	16	2026	4	493615.07	4705.63	1599.97	3105.66	0.00	0.00	4705.63	492015.10	7.8000	164	2026-11-12 09:35:06.855467	2026-11-12 09:35:06.855467
267	16	2026	5	492015.10	4705.63	1610.03	3095.60	0.00	0.00	4705.63	490405.07	7.5500	164	2026-11-12 09:35:06.86215	2026-11-12 09:35:06.86215
268	16	2026	6	490405.07	4705.63	1620.16	3085.47	0.00	0.00	4705.63	488784.91	7.5500	164	2026-11-12 09:35:06.872458	2026-11-12 09:35:06.872458
269	16	2026	7	488784.91	4705.63	1630.36	3075.27	0.00	0.00	4705.63	487154.55	7.5500	164	2026-11-12 09:35:06.879876	2026-11-12 09:35:06.879876
270	16	2026	8	487154.55	4705.63	1640.61	3065.01	0.00	0.00	4705.63	485513.94	7.5500	164	2026-11-12 09:35:06.889396	2026-11-12 09:35:06.889396
271	16	2026	9	485513.94	4705.63	1650.94	3054.69	0.00	0.00	4705.63	483863.00	7.5500	164	2026-11-12 09:35:06.896725	2026-11-12 09:35:06.896725
272	16	2026	10	483863.00	4705.63	1661.32	3044.30	0.00	0.00	4705.63	482201.68	7.5500	164	2026-11-12 09:35:06.904878	2026-11-12 09:35:06.904878
\.


--
-- Data for Name: loan_payment_allocations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_payment_allocations (id, loan_payment_id, user_id, amount, ownership_percent, contribution_percent, created_at, updated_at) FROM stdin;
188	188	3	25960.46	100.00	100.00	2026-11-12 09:35:00.913126	2026-11-12 09:35:00.913126
189	189	3	25960.46	100.00	100.00	2026-11-12 09:35:00.923386	2026-11-12 09:35:00.923386
190	190	3	25960.46	100.00	100.00	2026-11-12 09:35:00.932211	2026-11-12 09:35:00.932211
191	191	3	25960.46	100.00	100.00	2026-11-12 09:35:00.945589	2026-11-12 09:35:00.945589
192	192	3	25960.46	100.00	100.00	2026-11-12 09:35:00.955459	2026-11-12 09:35:00.955459
193	193	3	25960.46	100.00	100.00	2026-11-12 09:35:00.964657	2026-11-12 09:35:00.964657
194	194	3	25960.46	100.00	100.00	2026-11-12 09:35:01.001008	2026-11-12 09:35:01.001008
195	195	4	25960.46	100.00	100.00	2026-11-12 09:35:02.844013	2026-11-12 09:35:02.844013
196	196	4	25960.46	100.00	100.00	2026-11-12 09:35:02.855368	2026-11-12 09:35:02.855368
197	197	4	25960.46	100.00	100.00	2026-11-12 09:35:02.864135	2026-11-12 09:35:02.864135
198	198	4	25960.46	100.00	100.00	2026-11-12 09:35:02.874859	2026-11-12 09:35:02.874859
199	199	4	25960.46	100.00	100.00	2026-11-12 09:35:02.883403	2026-11-12 09:35:02.883403
200	200	4	25960.46	100.00	100.00	2026-11-12 09:35:02.895891	2026-11-12 09:35:02.895891
201	201	4	25960.46	100.00	100.00	2026-11-12 09:35:02.906728	2026-11-12 09:35:02.906728
202	202	3	4705.63	100.00	100.00	2026-11-12 09:35:04.831087	2026-11-12 09:35:04.831087
203	203	3	4705.63	100.00	100.00	2026-11-12 09:35:04.84144	2026-11-12 09:35:04.84144
204	204	3	4705.63	100.00	100.00	2026-11-12 09:35:04.850179	2026-11-12 09:35:04.850179
205	205	3	4705.63	100.00	100.00	2026-11-12 09:35:04.859999	2026-11-12 09:35:04.859999
206	206	3	4705.63	100.00	100.00	2026-11-12 09:35:04.877146	2026-11-12 09:35:04.877146
207	207	3	4705.63	100.00	100.00	2026-11-12 09:35:04.925725	2026-11-12 09:35:04.925725
208	208	3	4705.63	100.00	100.00	2026-11-12 09:35:04.9359	2026-11-12 09:35:04.9359
209	209	4	4705.63	100.00	100.00	2026-11-12 09:35:06.787739	2026-11-12 09:35:06.787739
210	210	4	4705.63	100.00	100.00	2026-11-12 09:35:06.797083	2026-11-12 09:35:06.797083
211	211	4	4705.63	100.00	100.00	2026-11-12 09:35:06.806411	2026-11-12 09:35:06.806411
212	212	4	4705.63	100.00	100.00	2026-11-12 09:35:06.816754	2026-11-12 09:35:06.816754
213	213	4	4705.63	100.00	100.00	2026-11-12 09:35:06.825966	2026-11-12 09:35:06.825966
214	214	4	4705.63	100.00	100.00	2026-11-12 09:35:06.834926	2026-11-12 09:35:06.834926
215	215	4	4705.63	100.00	100.00	2026-11-12 09:35:06.844513	2026-11-12 09:35:06.844513
\.


--
-- Data for Name: loan_payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loan_payments (id, loan_id, loan_emi_schedule_id, paid_on, amount, principal_amount, interest_amount, charges_amount, payment_type, reference_number, notes, balance_before, balance_after, status, reversed_payment_id, prepayment_id, emi_deduction_id, created_at, updated_at) FROM stdin;
188	13	4350	2026-04-15	25960.46	9035.91	16924.55	0.00	emi	\N	Backfilled from emi history	2637592.17	2628556.26	posted	\N	\N	181	2026-11-12 09:35:00.905603	2026-11-12 09:35:00.905603
189	13	4351	2026-05-15	25960.46	9093.89	16866.57	0.00	emi	\N	Backfilled from emi history	2628556.26	2619462.37	posted	\N	\N	182	2026-11-12 09:35:00.916167	2026-11-12 09:35:00.916167
190	13	4352	2026-06-15	25960.46	9152.25	16808.22	0.00	emi	\N	Backfilled from emi history	2619462.37	2610310.12	posted	\N	\N	183	2026-11-12 09:35:00.926356	2026-11-12 09:35:00.926356
191	13	4353	2026-07-15	25960.46	9210.97	16749.49	0.00	emi	\N	Backfilled from emi history	2610310.12	2601099.15	posted	\N	\N	184	2026-11-12 09:35:00.936029	2026-11-12 09:35:00.936029
192	13	4354	2026-08-15	25960.46	9270.08	16690.39	0.00	emi	\N	Backfilled from emi history	2601099.15	2591829.07	posted	\N	\N	185	2026-11-12 09:35:00.948407	2026-11-12 09:35:00.948407
193	13	4355	2026-09-15	25960.46	9329.56	16630.90	0.00	emi	\N	Backfilled from emi history	2591829.07	2582499.51	posted	\N	\N	186	2026-11-12 09:35:00.959036	2026-11-12 09:35:00.959036
194	13	4356	2026-10-15	25960.46	9389.43	16571.04	0.00	emi	\N	Backfilled from emi history	2582499.51	2573110.08	posted	\N	\N	187	2026-11-12 09:35:00.968456	2026-11-12 09:35:00.968456
195	14	4516	2026-04-15	25960.46	9035.91	16924.55	0.00	emi	\N	Backfilled from emi history	2637592.17	2628556.26	posted	\N	\N	188	2026-11-12 09:35:02.836895	2026-11-12 09:35:02.836895
196	14	4517	2026-05-15	25960.46	9093.89	16866.57	0.00	emi	\N	Backfilled from emi history	2628556.26	2619462.37	posted	\N	\N	189	2026-11-12 09:35:02.846507	2026-11-12 09:35:02.846507
197	14	4518	2026-06-15	25960.46	9152.25	16808.22	0.00	emi	\N	Backfilled from emi history	2619462.37	2610310.12	posted	\N	\N	190	2026-11-12 09:35:02.858082	2026-11-12 09:35:02.858082
198	14	4519	2026-07-15	25960.46	9210.97	16749.49	0.00	emi	\N	Backfilled from emi history	2610310.12	2601099.15	posted	\N	\N	191	2026-11-12 09:35:02.867995	2026-11-12 09:35:02.867995
199	14	4520	2026-08-15	25960.46	9270.08	16690.39	0.00	emi	\N	Backfilled from emi history	2601099.15	2591829.07	posted	\N	\N	192	2026-11-12 09:35:02.877435	2026-11-12 09:35:02.877435
200	14	4521	2026-09-15	25960.46	9329.56	16630.90	0.00	emi	\N	Backfilled from emi history	2591829.07	2582499.51	posted	\N	\N	193	2026-11-12 09:35:02.887054	2026-11-12 09:35:02.887054
201	14	4522	2026-10-15	25960.46	9389.43	16571.04	0.00	emi	\N	Backfilled from emi history	2582499.51	2573110.08	posted	\N	\N	194	2026-11-12 09:35:02.898581	2026-11-12 09:35:02.898581
202	15	4682	2026-04-15	4705.63	1599.97	3105.66	0.00	emi	\N	Backfilled from emi history	493615.07	492015.10	posted	\N	\N	195	2026-11-12 09:35:04.825759	2026-11-12 09:35:04.825759
203	15	4683	2026-05-15	4705.63	1610.03	3095.60	0.00	emi	\N	Backfilled from emi history	492015.10	490405.07	posted	\N	\N	196	2026-11-12 09:35:04.83346	2026-11-12 09:35:04.83346
204	15	4684	2026-06-15	4705.63	1620.16	3085.47	0.00	emi	\N	Backfilled from emi history	490405.07	488784.91	posted	\N	\N	197	2026-11-12 09:35:04.844073	2026-11-12 09:35:04.844073
205	15	4685	2026-07-15	4705.63	1630.36	3075.27	0.00	emi	\N	Backfilled from emi history	488784.91	487154.55	posted	\N	\N	198	2026-11-12 09:35:04.853019	2026-11-12 09:35:04.853019
206	15	4686	2026-08-15	4705.63	1640.61	3065.01	0.00	emi	\N	Backfilled from emi history	487154.55	485513.94	posted	\N	\N	199	2026-11-12 09:35:04.862202	2026-11-12 09:35:04.862202
207	15	4687	2026-09-15	4705.63	1650.94	3054.69	0.00	emi	\N	Backfilled from emi history	485513.94	483863.00	posted	\N	\N	200	2026-11-12 09:35:04.888351	2026-11-12 09:35:04.888351
208	15	4688	2026-10-15	4705.63	1661.32	3044.30	0.00	emi	\N	Backfilled from emi history	483863.00	482201.68	posted	\N	\N	201	2026-11-12 09:35:04.928811	2026-11-12 09:35:04.928811
209	16	4853	2026-04-15	4705.63	1599.97	3105.66	0.00	emi	\N	Backfilled from emi history	493615.07	492015.10	posted	\N	\N	202	2026-11-12 09:35:06.779801	2026-11-12 09:35:06.779801
210	16	4854	2026-05-15	4705.63	1610.03	3095.60	0.00	emi	\N	Backfilled from emi history	492015.10	490405.07	posted	\N	\N	203	2026-11-12 09:35:06.791045	2026-11-12 09:35:06.791045
211	16	4855	2026-06-15	4705.63	1620.16	3085.47	0.00	emi	\N	Backfilled from emi history	490405.07	488784.91	posted	\N	\N	204	2026-11-12 09:35:06.799618	2026-11-12 09:35:06.799618
212	16	4856	2026-07-15	4705.63	1630.36	3075.27	0.00	emi	\N	Backfilled from emi history	488784.91	487154.55	posted	\N	\N	205	2026-11-12 09:35:06.808998	2026-11-12 09:35:06.808998
213	16	4857	2026-08-15	4705.63	1640.61	3065.01	0.00	emi	\N	Backfilled from emi history	487154.55	485513.94	posted	\N	\N	206	2026-11-12 09:35:06.819862	2026-11-12 09:35:06.819862
214	16	4858	2026-09-15	4705.63	1650.94	3054.69	0.00	emi	\N	Backfilled from emi history	485513.94	483863.00	posted	\N	\N	207	2026-11-12 09:35:06.828898	2026-11-12 09:35:06.828898
215	16	4859	2026-10-15	4705.63	1661.32	3044.30	0.00	emi	\N	Backfilled from emi history	483863.00	482201.68	posted	\N	\N	208	2026-11-12 09:35:06.837839	2026-11-12 09:35:06.837839
\.


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loans (id, annual_interest_rate, created_at, notes, principal, start_date, term_months, title, updated_at, user_id, loan_type, lender_name, account_number, sanctioned_amount, disbursed_amount, interest_rate_type, emi_start_date, emi_amount, emi_due_day, processing_fee, insurance_amount, other_initial_charges, status, closed_on) FROM stdin;
13	7.95	2026-06-15 09:25:29.279357	Home loan · ~₹26,37,592 sanctioned · EMI on 15th each month. Revised Nov 2026 (repo +0.25%): 7.95%, EMI ₹26,310 (₹52,620 combined), 159 months.	2637592.17	2026-03-16	165	Home Loan	2026-11-12 09:34:59.060735	3	home	\N	\N	2637592.17	2637592.17	fixed	2026-04-15	26310.00	15	0.00	0.00	0.00	active	\N
14	7.95	2026-06-15 09:25:29.319678	Home loan · ~₹26,37,592 sanctioned · EMI on 15th each month. Revised Nov 2026 (repo +0.25%): 7.95%, EMI ₹26,310 (₹52,620 combined), 159 months.	2637592.17	2026-03-16	165	Home Loan	2026-11-12 09:35:01.173349	4	home	\N	\N	2637592.17	2637592.17	fixed	2026-04-15	26310.00	15	0.00	0.00	0.00	active	\N
15	7.80	2026-06-15 09:25:29.360678	Additional home loan · ~₹4,93,615 sanctioned · EMI on 15th each month. Revised Nov 2026 (repo +0.25%): 7.80%, EMI ₹4,790 (₹9,580 combined), 164 months.	493615.07	2026-03-16	172	Additional Home Loan	2026-11-12 09:35:03.089513	3	additional	\N	\N	493615.07	493615.07	fixed	2026-04-15	4790.00	15	0.00	0.00	0.00	active	\N
16	7.80	2026-06-15 09:25:29.386207	Additional home loan · ~₹4,93,615 sanctioned · EMI on 15th each month. Revised Nov 2026 (repo +0.25%): 7.80%, EMI ₹4,790 (₹9,580 combined), 164 months.	493615.07	2026-03-16	172	Additional Home Loan	2026-11-12 09:35:05.059262	4	additional	\N	\N	493615.07	493615.07	fixed	2026-04-15	4790.00	15	0.00	0.00	0.00	active	\N
\.


--
-- Data for Name: prepayments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prepayments (id, amount, created_at, loan_id, notes, paid_on, updated_at, principal_reduction, charges, balance_before, balance_after, reference_number, reason) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (version) FROM stdin;
20260415120001
20260415120000
20260407080000
20260407072706
20260407072703
20260407072658
20260917101838
20260917101839
20260917101840
20260917103107
20260917110000
20261112100000
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, account_balance, created_at, email, name, password_digest, updated_at) FROM stdin;
3	9785337.37	2026-06-15 09:25:29.014176	brother1@example.com	Sahil	$2a$12$ad5rH.TawrrH6GkpK1x62u1yG8O9J72dbU2Y2UDvAPvDRHfqTLfHy	2026-11-12 09:35:03.345286
4	9785337.37	2026-06-15 09:25:29.239182	brother2@example.com	Sanket	$2a$12$CU6OK.FHLh/Kjd6I7colMutYZntlUpIw82jg06B7DN6wE9PFu2Cki	2026-11-12 09:35:05.346517
\.


--
-- Name: emi_deductions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.emi_deductions_id_seq', 208, true);


--
-- Name: loan_audit_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_audit_entries_id_seq', 10, true);


--
-- Name: loan_borrowers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_borrowers_id_seq', 4, true);


--
-- Name: loan_calculator_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_calculator_presets_id_seq', 4, true);


--
-- Name: loan_emi_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_emi_schedules_id_seq', 5023, true);


--
-- Name: loan_interest_rates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_interest_rates_id_seq', 26, true);


--
-- Name: loan_monthly_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_monthly_snapshots_id_seq', 272, true);


--
-- Name: loan_payment_allocations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_payment_allocations_id_seq', 215, true);


--
-- Name: loan_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loan_payments_id_seq', 215, true);


--
-- Name: loans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loans_id_seq', 16, true);


--
-- Name: prepayments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.prepayments_id_seq', 35, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 4, true);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: emi_deductions emi_deductions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emi_deductions
    ADD CONSTRAINT emi_deductions_pkey PRIMARY KEY (id);


--
-- Name: loan_audit_entries loan_audit_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_audit_entries
    ADD CONSTRAINT loan_audit_entries_pkey PRIMARY KEY (id);


--
-- Name: loan_borrowers loan_borrowers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_borrowers
    ADD CONSTRAINT loan_borrowers_pkey PRIMARY KEY (id);


--
-- Name: loan_calculator_presets loan_calculator_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_calculator_presets
    ADD CONSTRAINT loan_calculator_presets_pkey PRIMARY KEY (id);


--
-- Name: loan_emi_schedules loan_emi_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_emi_schedules
    ADD CONSTRAINT loan_emi_schedules_pkey PRIMARY KEY (id);


--
-- Name: loan_interest_rates loan_interest_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_interest_rates
    ADD CONSTRAINT loan_interest_rates_pkey PRIMARY KEY (id);


--
-- Name: loan_monthly_snapshots loan_monthly_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_monthly_snapshots
    ADD CONSTRAINT loan_monthly_snapshots_pkey PRIMARY KEY (id);


--
-- Name: loan_payment_allocations loan_payment_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payment_allocations
    ADD CONSTRAINT loan_payment_allocations_pkey PRIMARY KEY (id);


--
-- Name: loan_payments loan_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_pkey PRIMARY KEY (id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: prepayments prepayments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prepayments
    ADD CONSTRAINT prepayments_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_emi_deductions_on_loan_id_and_due_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_emi_deductions_on_loan_id_and_due_on ON public.emi_deductions USING btree (loan_id, due_on);


--
-- Name: index_loan_audit_entries_on_auditable_type_and_auditable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_audit_entries_on_auditable_type_and_auditable_id ON public.loan_audit_entries USING btree (auditable_type, auditable_id);


--
-- Name: index_loan_audit_entries_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_audit_entries_on_loan_id ON public.loan_audit_entries USING btree (loan_id);


--
-- Name: index_loan_audit_entries_on_loan_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_audit_entries_on_loan_id_and_created_at ON public.loan_audit_entries USING btree (loan_id, created_at);


--
-- Name: index_loan_audit_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_audit_entries_on_user_id ON public.loan_audit_entries USING btree (user_id);


--
-- Name: index_loan_borrowers_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_borrowers_on_loan_id ON public.loan_borrowers USING btree (loan_id);


--
-- Name: index_loan_borrowers_on_loan_id_and_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_borrowers_on_loan_id_and_role ON public.loan_borrowers USING btree (loan_id, role);


--
-- Name: index_loan_borrowers_on_loan_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loan_borrowers_on_loan_id_and_user_id ON public.loan_borrowers USING btree (loan_id, user_id);


--
-- Name: index_loan_borrowers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_borrowers_on_user_id ON public.loan_borrowers USING btree (user_id);


--
-- Name: index_loan_calculator_presets_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loan_calculator_presets_on_key ON public.loan_calculator_presets USING btree (key);


--
-- Name: index_loan_emi_schedules_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_emi_schedules_on_loan_id ON public.loan_emi_schedules USING btree (loan_id);


--
-- Name: index_loan_emi_schedules_on_loan_id_and_due_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loan_emi_schedules_on_loan_id_and_due_on ON public.loan_emi_schedules USING btree (loan_id, due_on);


--
-- Name: index_loan_emi_schedules_on_loan_id_and_installment_no; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loan_emi_schedules_on_loan_id_and_installment_no ON public.loan_emi_schedules USING btree (loan_id, installment_no);


--
-- Name: index_loan_emi_schedules_on_loan_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_emi_schedules_on_loan_id_and_status ON public.loan_emi_schedules USING btree (loan_id, status);


--
-- Name: index_loan_interest_rates_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_interest_rates_on_loan_id ON public.loan_interest_rates USING btree (loan_id);


--
-- Name: index_loan_interest_rates_on_loan_id_and_effective_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_interest_rates_on_loan_id_and_effective_from ON public.loan_interest_rates USING btree (loan_id, effective_from);


--
-- Name: index_loan_interest_rates_on_loan_id_and_effective_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_interest_rates_on_loan_id_and_effective_to ON public.loan_interest_rates USING btree (loan_id, effective_to);


--
-- Name: index_loan_monthly_snapshots_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_monthly_snapshots_on_loan_id ON public.loan_monthly_snapshots USING btree (loan_id);


--
-- Name: index_loan_monthly_snapshots_on_loan_id_and_year_and_month; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loan_monthly_snapshots_on_loan_id_and_year_and_month ON public.loan_monthly_snapshots USING btree (loan_id, year, month);


--
-- Name: index_loan_payment_allocations_on_loan_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payment_allocations_on_loan_payment_id ON public.loan_payment_allocations USING btree (loan_payment_id);


--
-- Name: index_loan_payment_allocations_on_payment_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loan_payment_allocations_on_payment_and_user ON public.loan_payment_allocations USING btree (loan_payment_id, user_id);


--
-- Name: index_loan_payment_allocations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payment_allocations_on_user_id ON public.loan_payment_allocations USING btree (user_id);


--
-- Name: index_loan_payments_on_emi_deduction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_emi_deduction_id ON public.loan_payments USING btree (emi_deduction_id);


--
-- Name: index_loan_payments_on_loan_emi_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_loan_emi_schedule_id ON public.loan_payments USING btree (loan_emi_schedule_id);


--
-- Name: index_loan_payments_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_loan_id ON public.loan_payments USING btree (loan_id);


--
-- Name: index_loan_payments_on_loan_id_and_paid_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_loan_id_and_paid_on ON public.loan_payments USING btree (loan_id, paid_on);


--
-- Name: index_loan_payments_on_loan_id_and_payment_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_loan_id_and_payment_type ON public.loan_payments USING btree (loan_id, payment_type);


--
-- Name: index_loan_payments_on_loan_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_loan_id_and_status ON public.loan_payments USING btree (loan_id, status);


--
-- Name: index_loan_payments_on_prepayment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_payments_on_prepayment_id ON public.loan_payments USING btree (prepayment_id);


--
-- Name: index_loans_on_loan_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_loan_type ON public.loans USING btree (loan_type);


--
-- Name: index_loans_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_status ON public.loans USING btree (status);


--
-- Name: index_loans_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_user_id ON public.loans USING btree (user_id);


--
-- Name: index_loans_on_user_id_and_account_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_loans_on_user_id_and_account_number ON public.loans USING btree (user_id, account_number) WHERE ((account_number IS NOT NULL) AND ((account_number)::text <> ''::text));


--
-- Name: index_loans_on_user_id_and_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_user_id_and_start_date ON public.loans USING btree (user_id, start_date);


--
-- Name: index_prepayments_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prepayments_on_loan_id ON public.prepayments USING btree (loan_id);


--
-- Name: index_prepayments_on_loan_id_and_paid_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prepayments_on_loan_id_and_paid_on ON public.prepayments USING btree (loan_id, paid_on);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: loan_payment_allocations fk_rails_20ae07831a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payment_allocations
    ADD CONSTRAINT fk_rails_20ae07831a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: loan_payments fk_rails_33426b71de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT fk_rails_33426b71de FOREIGN KEY (reversed_payment_id) REFERENCES public.loan_payments(id);


--
-- Name: loan_borrowers fk_rails_3461601915; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_borrowers
    ADD CONSTRAINT fk_rails_3461601915 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: loan_audit_entries fk_rails_387500ca57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_audit_entries
    ADD CONSTRAINT fk_rails_387500ca57 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: loan_audit_entries fk_rails_62f024be5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_audit_entries
    ADD CONSTRAINT fk_rails_62f024be5d FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: loan_borrowers fk_rails_6c48c48b94; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_borrowers
    ADD CONSTRAINT fk_rails_6c48c48b94 FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: loan_monthly_snapshots fk_rails_7b0a2e91b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_monthly_snapshots
    ADD CONSTRAINT fk_rails_7b0a2e91b6 FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: loan_payment_allocations fk_rails_7d3f258ef0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payment_allocations
    ADD CONSTRAINT fk_rails_7d3f258ef0 FOREIGN KEY (loan_payment_id) REFERENCES public.loan_payments(id);


--
-- Name: loan_interest_rates fk_rails_84fe39fa29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_interest_rates
    ADD CONSTRAINT fk_rails_84fe39fa29 FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: loan_payments fk_rails_8fdc6506ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT fk_rails_8fdc6506ce FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: prepayments fk_rails_9b35bee5a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prepayments
    ADD CONSTRAINT fk_rails_9b35bee5a5 FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: loan_emi_schedules fk_rails_a294f5c47d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_emi_schedules
    ADD CONSTRAINT fk_rails_a294f5c47d FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: loan_payments fk_rails_bc7eb28c71; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT fk_rails_bc7eb28c71 FOREIGN KEY (loan_emi_schedule_id) REFERENCES public.loan_emi_schedules(id);


--
-- Name: loans fk_rails_c15c911198; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT fk_rails_c15c911198 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: loan_payments fk_rails_eb7d8fca62; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT fk_rails_eb7d8fca62 FOREIGN KEY (emi_deduction_id) REFERENCES public.emi_deductions(id);


--
-- Name: loan_payments fk_rails_f4ae896b75; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT fk_rails_f4ae896b75 FOREIGN KEY (prepayment_id) REFERENCES public.prepayments(id);


--
-- Name: emi_deductions fk_rails_faae768cb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emi_deductions
    ADD CONSTRAINT fk_rails_faae768cb4 FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- PostgreSQL database dump complete
--

