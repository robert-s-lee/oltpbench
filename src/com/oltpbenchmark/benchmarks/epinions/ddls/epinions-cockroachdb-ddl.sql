-- PostgreSQL DDL

DROP TABLE IF EXISTS useracct cascade;
CREATE TABLE useracct (
  u_id int NOT NULL,
  name varchar(128) DEFAULT NULL,
  PRIMARY KEY (u_id)
);

DROP TABLE IF EXISTS item cascade;
CREATE TABLE item (
  i_id int NOT NULL,
  title varchar(20) DEFAULT NULL,
  PRIMARY KEY (i_id)
);

DROP TABLE IF EXISTS review;
CREATE TABLE review (
  a_id int NOT NULL,
  u_id int NOT NULL REFERENCES useracct (u_id),
  i_id int NOT NULL REFERENCES item (i_id),
  rating int DEFAULT NULL,
  rank int DEFAULT NULL,
INDEX IDX_RATING_UID (u_id),
INDEX IDX_RATING_AID (a_id),
INDEX IDX_RATING_IID (i_id) 
);

DROP TABLE IF EXISTS review_rating;
CREATE TABLE review_rating (
  u_id int NOT NULL REFERENCES useracct (u_id),
  a_id int NOT NULL,
  rating int NOT NULL,
  status int NOT NULL,
  creation_date timestamp DEFAULT NULL,
  last_mod_date timestamp DEFAULT NULL,
  type int DEFAULT NULL,
  vertical_id int DEFAULT NULL,
INDEX IDX_REVIEW_RATING_UID (u_id),
INDEX IDX_REVIEW_RATING_AID (a_id)
);

DROP TABLE IF EXISTS trust;
CREATE TABLE trust (
  source_u_id int NOT NULL REFERENCES useracct (u_id),
  target_u_id int NOT NULL REFERENCES useracct (u_id),
  trust int NOT NULL,
  creation_date timestamp DEFAULT NULL,
INDEX IDX_TRUST_SID (source_u_id),
INDEX IDX_TRUST_TID (target_u_id)
);
