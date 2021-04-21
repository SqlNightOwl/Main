use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'risk'
GO
CREATE trigger risk.Scan_tiu
on	risk.Scan
for insert, update
as

set nocount on;

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedBy	= d.CreatedBy
		,	CreatedOn	= d.CreatedOn
	from	risk.Scan	o
	join	deleted		d
			on	o.ScanId = d.ScanId;
end;

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	risk.Scan	o
	join	inserted	i
			on	o.ScanId = i.ScanId;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO