-- 内存利用率
select instance_total_memory_used_size*100/allocation_limit ram_ratio
from m_host_resource_utilization;

-- 当前外部连接
select count(*) conn from m_connections
where connection_type = 'Remote'
and created_by = 'Session';

-- 事务阻塞
select * from m_blocked_transactions;

-- 线程情况
select * from m_service_threads;

-- 内存消耗 or 执行时间
select top 10 t1.connection_id,
seconds_between(t1.compiled_time, current_timestamp) duration,
t1.compiled_time,
t1.used_memory_size,
substring(t1.statement_string, 1, 100) sql_str
from m_active_statements t1, m_connections t2
where t2.connection_type = 'Remote'
and t2.created_by = 'Session'
and t1.connection_id = t2.connection_id
-- order by duration desc
order by used_memory_size desc;

-- 超半小时对象锁
select * from m_object_locks
where seconds_between(acquired_time, current_timestamp) > 1800
order by acquired_time;

-- 检查点延时
select volume_id, max(start_time)
from m_savepoints
where purpose = 'NORMAL'
and state = 'DONE'
group by volume_id
having seconds_between(max(start_time, current_timestamp)) > 1800;

-- 主备数据同步情况
select replication_status stat,
replication_status_detail dtl,
site_id id,
round(seconds_between(last_savepoint_start_time, now()) / 60) saveponit_delay,
round(seconds_between(shipped_last_delta_replica_end_time, now()) / 60) delta_delay
from m_service_replication;

-- 清空表及删表统计
select count(*) no from m_executed_statements
where cast(start_time as date) = current_date
and (
	lower(statement_string) like '%truncate table%'
	or lower(statement_string) like '%drop table%'
	);

-- 用户被锁检查
select count(*) from users
where user_deactivated = 'TRUE'
and cast(deactivation_time as date) = current_date;

--全备验证
select count(*) from m_backup_catalog
where entry_type_name = 'complete data backup'
and state_name = 'successful'
and cast(sys_start_time as date) = add_days(current_date, 0);
