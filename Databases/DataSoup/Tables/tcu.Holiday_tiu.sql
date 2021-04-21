use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.Holiday_tiu
on	tcu.Holiday
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.Holiday	o
	join	deleted		d
			on	o.Holiday = d.Holiday
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.Holiday	o
	join	inserted	i
			on	o.Holiday = i.Holiday
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO