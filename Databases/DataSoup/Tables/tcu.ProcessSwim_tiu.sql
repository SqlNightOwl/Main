use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.ProcessSwim_tiu
on	tcu.ProcessSwim
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
	from	tcu.ProcessSwim	o
	join	deleted			d
			on	o.ProcessId = d.ProcessId
end

--	maintain the Updated By/On values
if not update(UpdatedBy)
or not update(UpdatedOn)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	tcu.ProcessSwim	o
	join	inserted		i
			on	o.ProcessId = i.ProcessId
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO