#!/usr/bin/ksh
#######################################################################################
#
# Script     : dbanalyze_tables.sh
# Purpose    : Statistics collection
# Created By : Baskaran
# Created    : 22 APR 2022
#
# Change History:
# ==============
#
# Modified By           Date Modified           Remarks
# ===========           =============           =======
#
#######################################################################################
# Which HOME?
 export ORACLE_HOME=/app/oracle3/product/12.2.0

# Which SID?
 export ORACLE_SID=rwso

# Who gets the alert?
 export RECIPIENT='oracle.amk@st.com'

# Other Variables
 export LD_LIBRARY_PATH=$ORACLE_HOME/lib
 export HOST=`hostname`
 export PATH=$ORACLE_HOME/bin:$PATH
 export NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss'
 export SUBJECT="Statistics ALERTS on ${HOST} OK"
 export LOG=/tmp

COMMAND=$0
# exit if I am already running
# RUNNING=`ps --no-headers -C${COMMAND} | wc -l`
RUNNING=`ps -ef | grep -i $0 | grep -v grep | wc -l`
echo "Running" $RUNNING
if [ ${RUNNING} -gt 3 ]; then
  echo "Previous ${COMMAND} is still running."
  exit 1
fi

$ORACLE_HOME/bin/sqlplus -s /nolog <<!

connect / as sysdba

SET TRIMSPOOL ON
SET LINESIZE 32767
SET TRIMOUT ON
SET WRAP OFF
SET TERMOUT OFF
SET PAGESIZE 0
SET FEEDBACK OFF

spool /tmp/$$.sql

SELECT 'EXECUTE DBMS_STATS.GATHER_TABLE_STATS(ownname => '||''''||owner||''''||', tabname => '||''''||table_name||''''||',cascade => TRUE, ESTIMATE_PERCENT => DBMS_STATS.AUTO_SAMPLE_SIZE, DEGREE => DBMS_STATS.AUTO_DEGREE);' from dba_tables where OWNER in ('RWSO') AND PARTITIONED <> 'YES' order by PARTITIONED;

SELECT 'EXECUTE DBMS_STATS.GATHER_TABLE_STATS(ownname => '||''''||owner||''''||', tabname => '||''''||table_name||''''||',cascade => TRUE, ESTIMATE_PERCENT => DBMS_STATS.AUTO_SAMPLE_SIZE, DEGREE => DBMS_STATS.AUTO_DEGREE,'||' method_opt=>'||''''||'FOR ALL COLUMNS SIZE AUTO'||''''||','||'granularity =>'||''''||'GLOBAL AND PARTITION'||''''||');' v from dba_tables where OWNER in ('RWSO') AND PARTITIONED <> 'NO' order by PARTITIONED;

spool off
@ /tmp/$$.sql
exit
!
#mailx  -s " `id -un`  rwso analyse finished running on serve $HOST at `date` " $MAILTO < /tmp/$$.sql
rm -f /tmp/$$.sql
