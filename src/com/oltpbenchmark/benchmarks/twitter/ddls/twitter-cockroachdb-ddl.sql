-- DDL Script converted from Mysql Twitter dump

DROP TABLE IF EXISTS user_profiles CASCADE;
CREATE TABLE user_profiles (
  uid int NOT NULL DEFAULT '0',
  name varchar(255) DEFAULT NULL,
  email varchar(255) DEFAULT NULL,
  partitionid int DEFAULT NULL,
  partitionid2 smallint DEFAULT NULL,
  followers int DEFAULT NULL,
  PRIMARY KEY (uid),
INDEX IDX_USER_FOLLOWERS (followers),
INDEX IDX_USER_PARTITION (partitionid)
);

DROP TABLE IF EXISTS followers;
CREATE TABLE followers (
  f1 int NOT NULL DEFAULT '0' REFERENCES user_profiles (uid),
  f2 int NOT NULL DEFAULT '0' REFERENCES user_profiles (uid),
  index (f2),
  PRIMARY KEY (f1,f2)
);

DROP TABLE IF EXISTS follows;
CREATE TABLE follows (
  f1 int NOT NULL REFERENCES user_profiles (uid),
  f2 int NOT NULL REFERENCES user_profiles (uid),
  index (f2),
  PRIMARY KEY (f1,f2)
);

DROP TABLE IF EXISTS tweets;
CREATE TABLE tweets (
  id serial,
  uid int NOT NULL REFERENCES user_profiles (uid),
  text char(140) NOT NULL,
  createdate timestamp DEFAULT NULL,
  index (uid),
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS added_tweets;
CREATE TABLE added_tweets (
  id serial,
  uid int NOT NULL REFERENCES user_profiles (uid),
  text char(140) NOT NULL,
  createdate timestamp DEFAULT NULL,
  PRIMARY KEY (id),
INDEX IDX_ADDED_TWEETS_UID (uid)
);
