DROP TABLE IF EXISTS ipblocks;
CREATE TABLE ipblocks (
  ipb_id serial,
  ipb_address varchar NOT NULL,
  ipb_user int NOT NULL DEFAULT '0',
  ipb_by int NOT NULL DEFAULT '0',
  ipb_by_text varchar NOT NULL DEFAULT '',
  ipb_reason varchar NOT NULL,
  ipb_timestamp varchar(14) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  ipb_auto smallint NOT NULL DEFAULT '0',
  ipb_anon_only smallint NOT NULL DEFAULT '0',
  ipb_create_account smallint NOT NULL DEFAULT '1',
  ipb_enable_autoblock smallint NOT NULL DEFAULT '1',
  ipb_expiry varchar(14) NOT NULL DEFAULT '',
  ipb_range_start varchar NOT NULL,
  ipb_range_end varchar NOT NULL,
  ipb_deleted smallint NOT NULL DEFAULT '0',
  ipb_block_email smallint NOT NULL DEFAULT '0',
  ipb_allow_usertalk smallint NOT NULL DEFAULT '0',
  PRIMARY KEY (ipb_id),
  UNIQUE (ipb_address,ipb_user,ipb_auto,ipb_anon_only),
INDEX IDX_IPB_USER (ipb_user),
INDEX IDX_IPB_RANGE (ipb_range_start,ipb_range_end),
INDEX IDX_IPB_TIMESTAMP (ipb_timestamp),
INDEX IDX_IPB_EXPIRY (ipb_expiry)
);

DROP TABLE IF EXISTS useracct;
CREATE TABLE useracct (
  user_id serial,
  user_name varchar(255) NOT NULL DEFAULT '',
  user_real_name varchar(255) NOT NULL DEFAULT '',
  user_password varchar(255) NOT NULL,
  user_newpassword varchar(255) NOT NULL,
  user_newpass_time varchar(14) DEFAULT NULL,
  user_email varchar(255) NOT NULL,
  user_options varchar(255) NOT NULL,
  user_touched varchar(14) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  user_token varchar(32) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  user_email_authenticated varchar(14) DEFAULT NULL,
  user_email_token varchar(32) DEFAULT NULL,
  user_email_token_expires varchar(14) DEFAULT NULL,
  user_registration varchar(14) DEFAULT NULL,
  user_editcount int DEFAULT NULL,
  PRIMARY KEY (user_id),
  UNIQUE (user_name),
INDEX IDX_USER_EMAIL_TOKEN (user_email_token)
);

DROP TABLE IF EXISTS logging;
CREATE TABLE logging (
  log_id serial,
  log_type varchar(32) NOT NULL,
  log_action varchar(32) NOT NULL,
  log_timestamp varchar(14) NOT NULL DEFAULT '19700101000000',
  log_user int NOT NULL DEFAULT '0',
  log_namespace int NOT NULL DEFAULT '0',
  log_title varchar(255) NOT NULL DEFAULT '',
  log_comment varchar(255) NOT NULL DEFAULT '',
  log_params varchar(255) NOT NULL,
  log_deleted smallint NOT NULL DEFAULT '0',
  log_user_text varchar(255) NOT NULL DEFAULT '',
  log_page int DEFAULT NULL,
  PRIMARY KEY (log_id),
INDEX IDX_LOG_TYPE_TIME (log_type,log_timestamp),
INDEX IDX_LOG_USER_TIME (log_user,log_timestamp),
INDEX IDX_LOG_PAGE_TIME (log_namespace,log_title,log_timestamp),
INDEX IDX_LOG_TIMES (log_timestamp),
INDEX IDX_LOG_USER_TYPE_TIME (log_user,log_type,log_timestamp),
INDEX IDX_LOG_PAGE_ID_TIME (log_page,log_timestamp)
);

DROP TABLE IF EXISTS page;
CREATE TABLE page (
  page_id serial,
  page_namespace int NOT NULL,
  page_title varchar NOT NULL,
  page_restrictions varchar(255) NOT NULL,
  page_counter bigint NOT NULL DEFAULT '0',
  page_is_redirect smallint NOT NULL DEFAULT '0',
  page_is_new smallint NOT NULL DEFAULT '0',
  page_random double precision NOT NULL,
  page_touched varchar(14) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  page_latest int NOT NULL,
  page_len int NOT NULL,
  PRIMARY KEY (page_id),
  UNIQUE (page_namespace,page_title),
INDEX IDX_PAGE_RANDOM (page_random),
INDEX IDX_PAGE_LEN (page_len)
);

DROP TABLE IF EXISTS page_backup;
CREATE TABLE page_backup (
  page_id serial,
  page_namespace int NOT NULL,
  page_title varchar NOT NULL,
  page_restrictions varchar(255) NOT NULL,
  page_counter bigint NOT NULL DEFAULT '0',
  page_is_redirect smallint NOT NULL DEFAULT '0',
  page_is_new smallint NOT NULL DEFAULT '0',
  page_random double precision NOT NULL,
  page_touched varchar(14) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  page_latest int NOT NULL,
  page_len int NOT NULL,
  PRIMARY KEY (page_id),
  UNIQUE (page_namespace,page_title),
INDEX IDX_PAGE_BACKUP_RANDOM (page_random),
INDEX IDX_PAGE_BACKUP_LEN (page_len)
);

DROP TABLE IF EXISTS page_restrictions;
CREATE TABLE page_restrictions (
  pr_page int NOT NULL,
  pr_type varchar(60) NOT NULL,
  pr_level varchar(60) NOT NULL,
  pr_cascade smallint NOT NULL,
  pr_user int DEFAULT NULL,
  pr_expiry varchar(14) DEFAULT NULL,
  pr_id int NOT NULL,
  PRIMARY KEY (pr_id),
  UNIQUE (pr_page,pr_type),
INDEX IDX_PR_TYPELEVEL (pr_type,pr_level),
INDEX IDX_PR_LEVEL (pr_level),
INDEX IDX_PR_CASCADE (pr_cascade)
);

DROP TABLE IF EXISTS recentchanges;
CREATE TABLE recentchanges (
  rc_id serial,
  rc_timestamp varchar(14) NOT NULL DEFAULT '',
  rc_cur_time varchar(14) NOT NULL DEFAULT '',
  rc_user int NOT NULL DEFAULT '0',
  rc_user_text varchar(255) NOT NULL,
  rc_namespace int NOT NULL DEFAULT '0',
  rc_title varchar(255) NOT NULL DEFAULT '',
  rc_comment varchar(255) NOT NULL DEFAULT '',
  rc_minor smallint NOT NULL DEFAULT '0',
  rc_bot smallint NOT NULL DEFAULT '0',
  rc_new smallint NOT NULL DEFAULT '0',
  rc_cur_id int NOT NULL DEFAULT '0',
  rc_this_oldid int NOT NULL DEFAULT '0',
  rc_last_oldid int NOT NULL DEFAULT '0',
  rc_type smallint NOT NULL DEFAULT '0',
  rc_moved_to_ns smallint NOT NULL DEFAULT '0',
  rc_moved_to_title varchar(255) NOT NULL DEFAULT '',
  rc_patrolled smallint NOT NULL DEFAULT '0',
  rc_ip varchar(40) NOT NULL DEFAULT '',
  rc_old_len int DEFAULT NULL,
  rc_new_len int DEFAULT NULL,
  rc_deleted smallint NOT NULL DEFAULT '0',
  rc_logid int NOT NULL DEFAULT '0',
  rc_log_type varchar(255) DEFAULT NULL,
  rc_log_action varchar(255) DEFAULT NULL,
  rc_params varchar(255),
  PRIMARY KEY (rc_id),
INDEX IDX_RC_TIMESTAMP (rc_timestamp),
INDEX IDX_RC_NAMESPACE_TITLE (rc_namespace,rc_title),
INDEX IDX_RC_CUR_ID (rc_cur_id),
INDEX IDX_NEW_NAME_TIMESTAMP (rc_new,rc_namespace,rc_timestamp),
INDEX IDX_RC_IP (rc_ip),
INDEX IDX_RC_NS_USERTEXT (rc_namespace,rc_user_text),
INDEX IDX_RC_USER_TEXT (rc_user_text,rc_timestamp)
);

DROP TABLE IF EXISTS revision;
CREATE TABLE revision (
  rev_id serial,
  rev_page int NOT NULL,
  rev_text_id int NOT NULL,
  rev_comment text NOT NULL,
  rev_user int NOT NULL DEFAULT '0',
  rev_user_text varchar(255) NOT NULL DEFAULT '',
  rev_timestamp varchar(14) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  rev_minor_edit smallint NOT NULL DEFAULT '0',
  rev_deleted smallint NOT NULL DEFAULT '0',
  rev_len int DEFAULT NULL,
  rev_parent_id int DEFAULT NULL,
  PRIMARY KEY (rev_id),
  UNIQUE (rev_page,rev_id),
INDEX IDX_REV_TIMESTAMP (rev_timestamp),
INDEX IDX_PAGE_TIMESTAMP (rev_page,rev_timestamp),
INDEX IDX_USER_TIMESTAMP (rev_user,rev_timestamp),
INDEX IDX_USERTEXT_TIMESTAMP (rev_user_text,rev_timestamp)
);

DROP TABLE IF EXISTS text;
CREATE TABLE text (
  old_id serial,
  old_text text NOT NULL,
  old_flags varchar(255) NOT NULL,
  old_page int DEFAULT NULL,
  PRIMARY KEY (old_id)
);


DROP TABLE IF EXISTS user_groups;
CREATE TABLE user_groups (
  ug_user int NOT NULL DEFAULT '0',
  ug_group varchar(16) NOT NULL DEFAULT '',
  UNIQUE (ug_user,ug_group),
INDEX IDX_UG_GROUP (ug_group)
);

DROP TABLE IF EXISTS value_backup;
CREATE TABLE value_backup (
  table_name varchar(255) DEFAULT NULL,
  maxid int DEFAULT NULL
);

DROP TABLE IF EXISTS watchlist;
CREATE TABLE watchlist (
  wl_user int NOT NULL,
  wl_namespace int NOT NULL DEFAULT '0',
  wl_title varchar(255) NOT NULL DEFAULT '',
  wl_notificationtimestamp varchar(14) DEFAULT NULL,
  UNIQUE (wl_user,wl_namespace,wl_title),
INDEX IDX_WL_NAMESPACE_TITLE (wl_namespace, wl_title)
);
