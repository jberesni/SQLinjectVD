--------------------------------------------------------
-- script to provide sql injection test stubs
-- (includes simple execution auditing)
--------------------------------------------------------
-- NOTE: run this script under SYS as SYSDBA
--------------------------------------------------------

--------------------------------------------------------
-- table to audit executions of the foo stubs
--------------------------------------------------------
drop table foo_audit;
create table foo_audit
as
   select
         SYS_CONTEXT('USERENV','INSTANCE') as inst_id
        ,DBID
        ,sysdate          as test_time
        ,to_number('1')   as test_id
        ,S.*
     from
         sys.v_$session      S
        ,sys.v_$database     D
    where
         sid = (select sid from v$mystat where rownum=1);

-------------------------------------------------------
-- these functions are stubs for sql injection tests
-------------------------------------------------------
create or replace 
procedure BAR(id_in in NUMBER := null)
is
PRAGMA AUTONOMOUS_TRANSACTION;
begin
   insert into foo_audit
   select
         SYS_CONTEXT('USERENV','INSTANCE') as inst_id
        ,DBID
        ,sysdate          as test_time
        ,id_in            as test_id
        ,S.*
     from
         sys.v_$session      S
        ,sys.v_$database     D
    where
         sid = (select sid from v$mystat where rownum=1);

   commit;
end;
/

create or replace 
function FOO(id_in in NUMBER := null) return varchar2
is
begin
   bar(id_in);
   return to_char(null);
end FOO;
/

create or replace function 
FOOZERO (id_in in NUMBER := null) return number
is
begin
   bar(id_in);
   return 0;
end FOOZERO;
/

grant execute on sys.foo to public;
grant execute on sys.bar to public;
grant execute on sys.foozero to public;

create or replace public synonym foo for sys.foo;
create or replace public synonym bar for sys.bar;
create or replace public synonym foozero for sys.foozero;

----------------------------------------------------------
-- execute some simple tests
----------------------------------------------------------
select NVL(FOO(2),'foo is null') from dual;
begin bar(200); end;
/
select FOOZERO(20)+20 from dual;

select test_time, test_id, username from foo_audit;
delete from foo_audit;
commit;

