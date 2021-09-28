/* Creating a custom data collector set (Data Collector is a component of SQL Server that collects capacity planning and performance data over time).
Advantages of usage: low overhead data collection, persistence of diagnostics data, data retention, rich reporting, easy extensibility, central repository for several SQL Server instances.
/*

--Create a custom data collector set
DECLARE @collection_set_id_1 INT
DECLARE @collection_set_uid_2 uniqueidentifier

--create the main data collector set object
--step 1
EXEC msdb.dbo.sp_syscollector_create_collection_set
	@name=N'Cache Usage Report', --name of the data collector set
	@collection_mode=0, --0=cached 1 = non-cached
	@description=N'Cache Usage Report', 
	@logging_level=1,
	@days_until_expiration=14, --data rentention in the MDW
	@schedule_name=N'CollectorSchedule_Every_6h', 
	@collection_set_id=@collection_set_id_1 OUTPUT, 
	@collection_set_uid=@collection_set_uid_2 OUTPUT

--step 2
DECLARE @collector_type_uid_3 uniqueidentifier
SELECT @collector_type_uid_3 = collector_type_uid fROM [msdb].[dbo].[syscollector_collector_types] 
WHERE name = N'Generic T-SQL Query Collector Type';

--step 3
DECLARE @collection_item_id_4 INT
EXEC msdb.dbo.sp_syscollector_create_collection_item
	@name=N'Cache Usage Report', 
	@parameters=N'<ns:TSQLQueryCollector xmlns:ns="DataCollectorType"><Query><Value>

        SELECT objtype AS ''Cached Object Type'',
        COUNT(*) as ''Number of Plans'',
        SUM(cast(size_in_bytes as BIGINT))/1048576 as ''Plan Cache SIze (MB)'',
        avg(usecounts) as ''Avg Use Counts''
        from sys.dm_exec_cached_plans
        group by objtype
        order by objtype
         
        </Value><OutputTable>Cache_Usage_Report</OutputTable></Query></ns:TSQLQueryCollector>',
	@collection_item_id=@collection_item_id_4 OUTPUT, 
	@frequency=15, --how often this collection item will run
	@collection_set_id=@collection_set_id_1, 
	@collector_type_uid=@collector_type_uid_3



