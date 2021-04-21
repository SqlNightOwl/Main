use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.ProcessLog_tiu
on	tcu.ProcessLog
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
	from	tcu.ProcessLog	o
	join	deleted			d
			on	o.ProcessId = d.ProcessId
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO