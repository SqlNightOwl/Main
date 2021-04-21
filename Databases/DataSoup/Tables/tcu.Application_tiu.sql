use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.Application_tiu
on	tcu.Application
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	tcu.Application
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.Application	o
	join	deleted			d
			on	o.Application = d.Application
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	tcu.Application
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.Application	o
	join	inserted		i
			on	o.Application = i.Application
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO