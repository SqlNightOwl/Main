use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.Dictionary_tiu
on	tcu.Dictionary
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	tcu.Dictionary
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.Dictionary	o
	join	deleted			d
			on	o.Application	= d.Application
			and	o.Name			= d.Name
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	tcu.Dictionary
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.Dictionary	o
	join	inserted		i
			on	o.Application	= i.Application
			and	o.Name			= i.Name
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO