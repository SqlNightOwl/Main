use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'risk'
GO
CREATE trigger risk.Compromise_tiu
on	risk.Compromise
for	insert, update
as

set nocount on;

--	maintain the Created By/On values
if update(CreatedBy)
or update(CreatedOn)
begin
	update	o
	set		CreatedBy	= d.CreatedBy
		,	CreatedOn	= d.CreatedOn
	from	risk.Compromise	o
	join	deleted			d
			on	o.CompromiseId = d.CompromiseId;
end;

--	maintain the Updated By/On values
if not update(UpdatedBy)
or not update(UpdatedOn)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	risk.Compromise	o
	join	inserted		i
			on	o.CompromiseId = i.CompromiseId;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO