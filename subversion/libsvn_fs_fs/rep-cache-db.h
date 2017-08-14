/* This file is automatically generated from rep-cache-db.sql and .dist_sandbox/subversion-1.8.19/subversion/libsvn_fs_fs/token-map.h.
 * Do not edit this file -- edit the source and rerun gen-make.py */

#define STMT_CREATE_SCHEMA 0
#define STMT_0_INFO {"STMT_CREATE_SCHEMA", NULL}
#define STMT_0 \
  "CREATE TABLE rep_cache ( " \
  "  hash TEXT NOT NULL PRIMARY KEY, " \
  "  revision INTEGER NOT NULL, " \
  "  offset INTEGER NOT NULL, " \
  "  size INTEGER NOT NULL, " \
  "  expanded_size INTEGER NOT NULL " \
  "  ); " \
  "PRAGMA USER_VERSION = 1; " \
  ""

#define STMT_GET_REP 1
#define STMT_1_INFO {"STMT_GET_REP", NULL}
#define STMT_1 \
  "SELECT revision, offset, size, expanded_size " \
  "FROM rep_cache " \
  "WHERE hash = ?1 " \
  ""

#define STMT_SET_REP 2
#define STMT_2_INFO {"STMT_SET_REP", NULL}
#define STMT_2 \
  "INSERT OR FAIL INTO rep_cache (hash, revision, offset, size, expanded_size) " \
  "VALUES (?1, ?2, ?3, ?4, ?5) " \
  ""

#define STMT_GET_REPS_FOR_RANGE 3
#define STMT_3_INFO {"STMT_GET_REPS_FOR_RANGE", NULL}
#define STMT_3 \
  "SELECT hash, revision, offset, size, expanded_size " \
  "FROM rep_cache " \
  "WHERE revision >= ?1 AND revision <= ?2 " \
  ""

#define STMT_GET_MAX_REV 4
#define STMT_4_INFO {"STMT_GET_MAX_REV", NULL}
#define STMT_4 \
  "SELECT MAX(revision) " \
  "FROM rep_cache " \
  ""

#define STMT_DEL_REPS_YOUNGER_THAN_REV 5
#define STMT_5_INFO {"STMT_DEL_REPS_YOUNGER_THAN_REV", NULL}
#define STMT_5 \
  "DELETE FROM rep_cache " \
  "WHERE revision > ?1 " \
  ""

#define STMT_LOCK_REP 6
#define STMT_6_INFO {"STMT_LOCK_REP", NULL}
#define STMT_6 \
  "BEGIN TRANSACTION; " \
  "INSERT INTO rep_cache VALUES ('dummy', 0, 0, 0, 0) " \
  ""

#define REP_CACHE_DB_SQL_DECLARE_STATEMENTS(varname) \
  static const char * const varname[] = { \
    STMT_0, \
    STMT_1, \
    STMT_2, \
    STMT_3, \
    STMT_4, \
    STMT_5, \
    STMT_6, \
    NULL \
  }

#define REP_CACHE_DB_SQL_DECLARE_STATEMENT_INFO(varname) \
  static const char * const varname[][2] = { \
    STMT_0_INFO, \
    STMT_1_INFO, \
    STMT_2_INFO, \
    STMT_3_INFO, \
    STMT_4_INFO, \
    STMT_5_INFO, \
    STMT_6_INFO, \
    {NULL, NULL} \
  }
