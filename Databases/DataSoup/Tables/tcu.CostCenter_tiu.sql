use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.CostCenter_tiu
on	tcu.CostCenter
for insert, update
as

set nocount on;

declare
	@now	datetime
,	@user	varchar(25)

select	@now	= getdate()
	,	@user	= tcu.fn_UserAudit();

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn = d.CreatedOn
		,	CreatedBy = d.CreatedBy
	from	tcu.CostCenter	o
	join	deleted			d
			on	o.CostCenter = d.CostCenter;
end;

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn = @now
		,	UpdatedBy = @user
	from	tcu.CostCenter	o
	join	inserted		i
			on	o.CostCenter = i.CostCenter;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO