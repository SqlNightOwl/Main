use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[CashManagementLog_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[CashManagementLog_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.CashManagementLog_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/20/2007
Purpose  :	Load and sends an email message if the BAI2 Process Check fails.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/17/2009	Paul Hunter		Changed to pull information directly from the IHB
							databases.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@batchId	int
,	@batchOn	datetime
,	@command	varchar(255)
,	@detail		varchar(4000)
,	@isComplete	bit
,	@result		int
,	@retain		int
,	@status		varchar(32)

--	initialize the parameters...
select	@retain		= RetentionPeriod
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessParameter_v
where	ProcessId	= @ProcessId;

--	delete any old records...
delete	ihb.CashManagementLog
where	BatchOn < dateadd(day, @retain, getdate());

--	setup the aciton command...
set	@command	= 'select BatchId, BatchDateTime, Completed, Status '
				+ 'from VOYAGER.Corporate.dbo.Batch '
				+ 'where FileType = ''BAI2'' order by BatchId desc;';

--	read the newest batch informaiton from the Corporate database....
select	top 1
		@batchId	= BatchId
	,	@batchOn	= BatchDateTime
	,	@isComplete	= Completed
	,	@status		= Status
from	VOYAGER.Corporate.dbo.Batch
where	FileType = 'BAI2'
order by BatchId desc;

--	insert the batch if newer than the max batch in the database
insert	ihb.CashManagementLog
	(	BatchId
	,	BatchOn
	,	IsComplete
	,	Status
	)
select	@batchId
	,	@batchOn
	,	@isComplete
	,	@status
where	@batchId > isnull(( select max(BatchId) from ihb.CashManagementLog ), 0);

--	no new batch was loaded...
if @@rowcount = 0
begin
	select	@result	= 2	--	informaiton...
		,	@detail	= 'The BAI Process verificaiton check for ' + convert(char(10), getdate(), 101)
					+ ' didn''t contain any new batch results.  '
					+ 'Please contact Tanya Patterson and alert her of this situation.';
end;

if @result != 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @command
						,	@Message	= @detail;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO