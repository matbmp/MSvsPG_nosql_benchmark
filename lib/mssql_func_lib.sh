#!/bin/bash

################################################################################
# Copyright EnterpriseDB Cooperation
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in
#      the documentation and/or other materials provided with the
#      distribution.
#    * Neither the name of PostgreSQL nor the names of its contributors
#      may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#  Author: Vibhor Kumar
#  E-mail ID: vibhor.aim@gmail.com

################################################################################
# source common lib
################################################################################
source $DIRECTORY/lib/common_func_lib.sh

################################################################################
# function: pg_json_insert_maker
################################################################################
function mssql_json_insert_maker ()
{
   typeset -r COLLECTION_NAME="$1"
   typeset -r NO_OF_ROWS="$2"
   typeset -r JSON_FILENAME="$3"

   process_log "preparing mssql INSERTs."
   rm -rf ${JSON_FILENAME}
   NO_OF_LOOPS=$((${NO_OF_ROWS}/11 + 1 ))
   echo "SET QUOTED_IDENTIFIER ON;
   " >> ${JSON_FILENAME}
   for ((i=0;i<${NO_OF_LOOPS};i++))
   do
       json_seed_data $i | \
        sed "s/^/INSERT INTO ${COLLECTION_NAME} VALUES(\'/"| \
        sed "s/$/\');/" >>${JSON_FILENAME}
   done
   echo " GO" >> ${JSON_FILENAME}
}

################################################################################
# run_sql_file: send SQL from a file to database
################################################################################
function run_mssql_file ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_FILE="$6"

   
   ${MSSQL} -H ${F_MSHOST} \
           -d ${F_DBNAME} \
           -U ${F_MSUSER} \
           -P ${F_MSPASSWORD} \
           -i ${F_FILE}
}
################################################################################
# run_sql: send SQL to database
################################################################################
function run_mssql ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_SQL="$6"

   ${MSSQL} -H ${F_MSHOST} \
           -d ${F_DBNAME} \
           -U ${F_MSUSER} \
           -P ${F_MSPASSWORD} \
           -Q "${F_SQL}"
}

function run_mssql_opt ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_OPT="$6"
   typeset -r F_SQL="$7"

   ${MSSQL} -H ${F_MSHOST} \
           -d ${F_DBNAME} \
           -U ${F_MSUSER} \
           -P ${F_MSPASSWORD} \
	   ${F_OPT} \
           -Q "${F_SQL}"
}


################################################################################
# function: remove_pgdb (remove postgresql database)
################################################################################
function remove_ms_db ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_SQL="DROP DATABASE IF EXISTS ${F_DBNAME};"

   process_log "droping database ${F_DBNAME} if exists."
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "master" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL}"
}

################################################################################
# function: create_pgdb (create postgresql database)
################################################################################
function create_ms_db ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_SQL="CREATE DATABASE ${F_DBNAME};"

   process_log "creating database ${F_DBNAME}."
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "master" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL}"
}

################################################################################
# function: relation_size (calculate postgresql relation size)
################################################################################
function ms_relation_size ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_RELATION="$6"
   typeset -r F_SQL="SELECT CAST((SUM(a.used_pages) * 1024) AS NUMERIC(36, 0)) FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.Name = '${F_RELATION}'
GO"

   process_log "calculating MSSQL collection size."
   output=$(run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
	   "${F_MSPASSWORD}" "${F_SQL}")
   roz=$(echo ${output} | egrep -o '[0-9]+' | cut -f1 -d' ')
   roz=$(echo $roz | cut -f1 -d' ')
   echo "$roz"
}

################################################################################
# function: check if database exists
################################################################################
function if_msdbexists ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"

   typeset -r F_SQL="SELECT COUNT(1)
                     FROM INFORMATION_SCHEMA.TABLES
                        WHERE TABLE_NAME='${F_DBNAME}';
			GO"
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL}"
   process_log "msexist= ${output}"
   echo ${output}
}

################################################################################
# function: mk_pgjson_collection create json table in PG
################################################################################
function mk_ms_json_collection ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL1="DROP TABLE IF EXISTS ${F_TABLE};
   			GO"
   typeset -r F_SQL2="	CREATE TABLE ${F_TABLE} (
   			data NVARCHAR(MAX)
			);
			GO"

  process_log "creating ${F_TABLE} collection in MSSQL."
  run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL1}"
  run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL2}"
}

################################################################################
# function: pg_create_index create json table in PG
################################################################################
function ms_create_index_collection ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL="	ALTER TABLE ${F_TABLE}
			ADD brand AS JSON_VALUE(data, '$.brand');
			ALTER TABLE ${F_TABLE}
			ADD name AS JSON_VALUE(data, '$.name');
			ALTER TABLE ${F_TABLE}
			ADD type AS JSON_VALUE(data, '$.type');
			SET QUOTED_IDENTIFIER ON;
			CREATE INDEX ${F_TABLE}_idx ON ${F_TABLE}(brand, name, type);
   			GO"

   process_log "creating index on MSSQL collections."
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL}"
}

################################################################################
# function: delete_json_data delete json data in PG
################################################################################
function delete_json_data ()
{

   typeset -r F_PGHOST="$1"
   typeset -r F_PGPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_PGUSER="$4"
   typeset -r F_PGPASSWORD="$5"
   typeset -r F_COLLECTION="$6"

   process_log "droping json object in postgresql."
   run_sql "${F_PGHOST}" "${F_PGPORT}" "${F_DBNAME}" "${F_PGUSER}" \
           "${F_PGPASSWORD}" \
           "TRUNCATE TABLE ${F_COLLECTION};" >/dev/null
}

################################################################################
# function: pg_copy_benchmark
################################################################################
function ms_copy_benchmark ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_JSONFILE="$7"
   typeset -r F_COPY="	BULK INSERT json_tables FROM '$PWD/${F_JSONFILE}';
   			GO"

   #DBEXISTS=$(if_msdbexists "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" \
   #                      "${F_MSUSER}" "${F_MSPASSWORD}")
   process_log "loading data in mssql using ${F_JSONFILE}."
   start_time=$(get_timestamp_nano)
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_COPY}" \
	   >/dev/null
   end_time=$(get_timestamp_nano)
   total_time="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   echo "${total_time}"

}

################################################################################
# function: benchmark postgresql inserts
################################################################################
function ms_inserts_benchmark ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_INSERTS="$PWD/$7"

   process_log "inserting data in mssql using ${F_INSERTS}."
   start_time=$(get_timestamp_nano)
   run_mssql_file "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_INSERTS}" \
	   >> /dev/null
   end_time=$(get_timestamp_nano)
   total_time="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   echo "${total_time}"
}

################################################################################
# function: benchmark postgresql select
################################################################################
function ms_select_benchmark ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_SELECT1="SELECT data
                         FROM ${F_COLLECTION}
                           WHERE  JSON_VALUE(data, '$.brand') = 'ACME'; GO"
   typeset -r F_SELECT2="SELECT data
                         FROM ${F_COLLECTION}
                           WHERE  JSON_VALUE(data, '$.name') = 'Phone Service Basic Plan'; GO"
   typeset -r F_SELECT3="SELECT data
                         FROM ${F_COLLECTION}
                          WHERE  JSON_VALUE(data, '$.name') = 'AC3 Case Red'; GO"
   typeset -r F_SELECT4="SELECT data
                          FROM ${F_COLLECTION}
                            WHERE  JSON_VALUE(data, '$.type') = 'service'; GO"
   local START end_time

   process_log "testing FIRST SELECT in mssql."
   start_time=$(get_timestamp_nano)
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SELECT1}" >/dev/null || exit_on_error "failed to execute SELECT 1."
   end_time=$(get_timestamp_nano)
   total_time1="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing SECOND SELECT in mssql."
   start_time=$(get_timestamp_nano)
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SELECT2}" >/dev/null || exit_on_error "failed to execute SELECT 2."
   end_time=$(get_timestamp_nano)
   total_time2="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing THIRD SELECT in mssql."
   start_time=$(get_timestamp_nano)
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SELECT3}" >/dev/null || exit_on_error "failed to execute SELECT 3."
   end_time=$(get_timestamp_nano)
   total_time3="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing FOURTH SELECT in mssql."
   start_time=$(get_timestamp_nano)
   run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SELECT4}" >/dev/null || exit_on_error "failed to execute SELECT 4."
   end_time=$(get_timestamp_nano)
   total_time4="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   AVG=$(( ($total_time1 + $total_time2 + $total_time3 + $total_time4 )/4 ))

   echo "${AVG}"
}

################################################################################
# function: mk_pgjson_collection create json table in PG
################################################################################
function analyze_collections ()
{
   typeset -r F_PGHOST="$1"
   typeset -r F_PGPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_PGUSER="$4"
   typeset -r F_PGPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL="VACUUM FREEZE ANALYZE ${F_TABLE};"

   process_log "performing analyze in postgreSQL."
   run_sql "${F_PGHOST}" "${F_PGPORT}" "${F_DBNAME}" "${F_PGUSER}" \
           "${F_PGPASSWORD}" "${F_SQL}" \
            >/dev/null 2>/dev/null
}

################################################################################
# function: mk_pgjson_collection create json table in PG
################################################################################
function mssql_version ()
{
   typeset -r F_MSHOST="$1"
   typeset -r F_MSPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MSUSER="$4"
   typeset -r F_MSPASSWORD="$5"
   typeset -r F_SQL="SELECT @@VERSION GO"

   output=$(run_mssql "${F_MSHOST}" "${F_MSPORT}" "${F_DBNAME}" "${F_MSUSER}" \
           "${F_MSPASSWORD}" "${F_SQL}")
   version=$(echo $output | grep -o ' - [0-9\.]* ' | cut -f3 -d' ')

   echo "${version}"

}

##############################################################################
# function mk_ms_json_collection
##############################################################################
function mssql_dropping ()
{
  typeset -r F_MSHOST="$1"
  typeset -r F_MSPORT="$2"
  typeset -r F_DBNAME="$3"
  typeset -r F_MSUSER="$4"
  typeset -r F_MSPASSWORD="$5"
  typeset -r F_TABLE="$6"
  typeset -r F_SQL1="	DROP TABLE IF EXISTS ${F_TABLE};
  			GO"	
  process_log "${F_TABLE} dropped in MSSQL."
  run_mssql "${F_MSHOST}" "${F_MSPORT}" "master" "${F_MSUSER}" \	"${F_MSPASSWORD}" "${F_SQL1}"
}

