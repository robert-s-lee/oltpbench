DROP TABLE IF EXISTS linktable;
DROP TABLE IF EXISTS counttable;
DROP TABLE IF EXISTS nodetable;

CREATE TABLE linktable (
  id1 bigint NOT NULL,
  id2 bigint NOT NULL,
  link_type bigint NOT NULL,
  visibility smallint NOT NULL,
  data bytea NOT NULL,
  time bigint NOT NULL,
  version int NOT NULL,
  PRIMARY KEY (id1,id2,link_type)
);
create index id1_type on linktable (id1,link_type,visibility,time,version,data);

CREATE TABLE counttable (
  id bigint NOT NULL,
  link_type bigint  NOT NULL,
  "count" int NOT NULL,
  time bigint NOT NULL,
  version bigint NOT NULL,
  PRIMARY KEY (id,link_type)
);

CREATE TABLE nodetable (
  id serial NOT NULL,
  type int NOT NULL,
  version bigint NOT NULL,
  time int NOT NULL,
  data bytea NOT NULL,
  PRIMARY KEY(id)
);

