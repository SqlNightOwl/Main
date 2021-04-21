use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.ProcessParameter_tiu
on	tcu.ProcessParameter
for	insert, update
as

set nocount on

--	maintain the Created By/On values
if update(CreatedBy)
or update(CreatedOn)
begin
	update	o
	set		CreatedBy	= d.CreatedBy
		,	CreatedOn	= d.CreatedOn
	from	tcu.ProcessParameter	o
	join	deleted					d
			on	o.ProcessId = d.ProcessId
			and	o.Parameter	= d.Parameter
end

--	maintain the Updated By/On values
if not update(UpdatedBy)
or not update(UpdatedOn)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	tcu.ProcessParameter	o
	join	inserted				i
			on	o.ProcessId = i.ProcessId
			and	o.Parameter	= i.Parameter
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO