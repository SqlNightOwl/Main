use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'risk'
GO
CREATE trigger risk.ScanDetail_tiu
on	risk.ScanDetail
for insert, update
as

set nocount on;

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedBy	= d.CreatedBy
		,	CreatedOn	= d.CreatedOn
	from	risk.ScanDetail	o
	join	deleted			d
			on	o.ScanId		= d.ScanId
			and	o.ScanDetailId	= d.ScanDetailId;
end;

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	risk.ScanDetail	o
	join	inserted		i
			on	o.ScanId		= i.ScanId
			and	o.ScanDetailId	= i.ScanDetailId;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO