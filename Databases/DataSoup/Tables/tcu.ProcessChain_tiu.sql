use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.ProcessChain_tiu
on	tcu.ProcessChain
for	insert, update
as

set nocount on

--	On Demand Processes may not be Chained!
if exists (	select	top 1 ProcessId from tcu.Process
			where (	ProcessId in (select ScheduledProcessId	from inserted)
				or	ProcessId in (select ChainedProcessId	from inserted)	)
			and		ProcessCategory = 'On Demand' )
begin
	rollback transaction
	return
end

--	maintain the Created By/On values
if update(CreatedBy)
or update(CreatedOn)
begin
	update	o
	set		CreatedBy	= d.CreatedBy
		,	CreatedOn	= d.CreatedOn
	from	tcu.ProcessChain	o
	join	deleted			d
			on	o.ScheduledProcessId	= d.ScheduledProcessId
			and	o.ChainedProcessId		= d.ChainedProcessId
end

--	maintain the Updated By/On values
if not update(UpdatedBy)
or not update(UpdatedOn)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	tcu.ProcessChain	o
	join	inserted		i
			on	o.ScheduledProcessId	= i.ScheduledProcessId
			and	o.ChainedProcessId		= i.ChainedProcessId
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO