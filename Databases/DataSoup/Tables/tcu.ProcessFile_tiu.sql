use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.ProcessFile_tiu
on	tcu.ProcessFile
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
	from	tcu.ProcessFile	o
	join	deleted			d
			on	o.ProcessId = d.ProcessId
			and	o.FileName	= d.FileName
end

--	maintain the Updated By/On values
if not update(UpdatedBy)
or not update(UpdatedOn)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	tcu.ProcessFile	o
	join	inserted		i
			on	o.ProcessId = i.ProcessId
			and	o.FileName	= i.FileName
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO