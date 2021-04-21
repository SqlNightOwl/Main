use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
create trigger tcu.Location_tiu
on	tcu.Location
for insert, update
as

set nocount on;

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.Location	o
	join	deleted			d
			on	o.LocationId = d.LocationId;
end;

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.Location	o
	join	inserted		i
			on	o.LocationId = i.LocationId;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO