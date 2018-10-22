-- the order of statements need to be preserved for foreign key constraint

create table warehouse (
  w_id        integer   not null,
  w_ytd       decimal(12,2),
  w_tax       decimal(4,4),
  w_name      varchar(10),
  w_street_1  varchar(20),
  w_street_2  varchar(20),
  w_city      varchar(20),
  w_state     char(2),
  w_zip       char(9),
  constraint pk_warehouse primary key (w_id)
);

create table district (
  d_w_id       integer       not null,
  d_id         integer       not null,
  d_ytd        decimal(12,2),
  d_tax        decimal(4,4),
  d_next_o_id  integer,
  d_name       varchar(10),
  d_street_1   varchar(20),
  d_street_2   varchar(20),
  d_city       varchar(20),
  d_state      char(2),
  d_zip        char(9),
  constraint d_warehouse_fkey foreign key (d_w_id) references warehouse (w_id) ON DELETE CASCADE,
  constraint pk_district primary key (d_w_id, d_id)
) interleave in parent warehouse (d_w_id)
;

create table customer (
  c_w_id         integer        not null,
  c_d_id         integer        not null,
  c_id           integer        not null,
  c_discount     decimal(4,4),
  c_credit       char(2),
  c_last         varchar(16),
  c_first        varchar(16),
  c_credit_lim   decimal(12,2),
  c_balance      decimal(12,2),
  c_ytd_payment  decimal(12,2),
  c_payment_cnt  integer,
  c_delivery_cnt integer,
  c_street_1     varchar(20),
  c_street_2     varchar(20),
  c_city         varchar(20),
  c_state        char(2),
  c_zip          char(9),
  c_phone        char(16),
  c_since        timestamp,
  c_middle       char(2),
  c_data         varchar(500),
  constraint c_district_fkey foreign key (c_w_id, c_d_id) references district (d_w_id, d_id) ON DELETE CASCADE,
  constraint pk_customer primary key (c_w_id, c_d_id, c_id)
) interleave in parent district (c_w_id, c_d_id)
;

create index customer_idx on customer (c_w_id, c_d_id, c_last, c_first)
	interleave in parent district (c_w_id, c_d_id)
;

-- this table does not have a primay key.  Make one with hist_id
create table history (
  h_c_id   integer,
  h_c_d_id integer,
  h_c_w_id integer,
  h_d_id   integer,
  h_w_id   integer,
  h_date   timestamp,
  h_amount decimal(6,2),
  h_data   varchar(24),
  hist_id  uuid default gen_random_uuid(),
  constraint h_customer_fkey foreign key (h_c_w_id, h_c_d_id, h_c_id) references customer (c_w_id, c_d_id, c_id) ON DELETE CASCADE,
  constraint h_district_fkey foreign key (h_w_id, h_d_id) references district (d_w_id, d_id) ON DELETE CASCADE,
  index (h_w_id, h_d_id),
  index (h_c_w_id, h_c_d_id, h_c_id),
  primary key (hist_id)
);


create table oorder (
  o_w_id       integer      not null,
  o_d_id       integer      not null,
  o_id         integer      not null,
  o_c_id       integer,
  o_carrier_id integer,
  o_ol_cnt     integer,
  o_all_local  integer,
  o_entry_d    timestamp,
  constraint o_customer_fkey foreign key (o_w_id, o_d_id, o_c_id) references  customer (c_w_id, c_d_id, c_id) ON DELETE CASCADE,
  constraint pk_oorder primary key (o_w_id, o_d_id, o_id),
  index (o_w_id, o_d_id, o_c_id)
) interleave in parent district (o_w_id, o_d_id)
;

create unique index order_idx on oorder (o_w_id, o_d_id, o_carrier_id, o_id)
	interleave in parent district (o_w_id, o_d_id)
;

create table new_order (
  no_w_id  integer   not null,
  no_d_id  integer   not null,
  no_o_id  integer   not null,
  constraint no_order_fkey foreign key (no_w_id, no_d_id, no_o_id) references oorder (o_w_id, o_d_id, o_id) ON DELETE CASCADE,
  constraint pk_new_order primary key (no_w_id, no_d_id, no_o_id)
);

create table item (
  i_id     integer      not null,
  i_name   varchar(24),
  i_price  decimal(5,2),
  i_data   varchar(50),
  i_im_id  integer,
  constraint pk_item primary key (i_id)
);

create table stock (
  s_w_id       integer       not null,
  s_i_id       integer       not null,
  s_quantity   integer,
  s_ytd        integer,
  s_order_cnt  integer,
  s_remote_cnt integer,
  s_data       varchar(50),
  s_dist_01    char(24),
  s_dist_02    char(24),
  s_dist_03    char(24),
  s_dist_04    char(24),
  s_dist_05    char(24),
  s_dist_06    char(24),
  s_dist_07    char(24),
  s_dist_08    char(24),
  s_dist_09    char(24),
  s_dist_10    char(24),
  constraint s_warehouse_fkey foreign key (s_w_id) references warehouse (w_id) ON DELETE CASCADE,
  constraint s_item_fkey foreign key (s_i_id) references item (i_id) ON DELETE CASCADE,
  constraint pk_stock primary key (s_w_id, s_i_id),
  index (s_i_id)
) interleave in parent warehouse (s_w_id)
;

create table order_line (
  ol_w_id         integer   not null,
  ol_d_id         integer   not null,
  ol_o_id         integer   not null,
  ol_number       integer   not null,
  ol_i_id         integer   not null,
  ol_delivery_d   timestamp,
  ol_amount       decimal(6,2),
  ol_supply_w_id  integer,
  ol_quantity     integer,
  ol_dist_info    char(24),
  constraint ol_order_fkey foreign key (ol_w_id, ol_d_id, ol_o_id) references oorder (o_w_id, o_d_id, o_id) ON DELETE CASCADE,
  constraint ol_stock_fkey foreign key (ol_supply_w_id, ol_i_id) references stock (s_w_id, s_i_id) ON DELETE CASCADE,
  constraint pk_order_line primary key (ol_w_id, ol_d_id, ol_o_id, ol_number),
  index (ol_supply_w_id, ol_d_id),
  index (ol_supply_w_id, ol_i_id) 
) interleave in parent oorder (ol_w_id, ol_d_id, ol_o_id)
;

