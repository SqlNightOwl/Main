use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.Process_tiu
on	tcu.Process
for insert, update
as

set nocount on

/*
**	this part of the trigger forces the ProcessSchedule description to be rebuilt
*/
if update(SkipFederalHolidays)
or update(SkipCompanyHolidays)
or update(IsEnabled)
begin
	update	s
	set		IsEnabled = s.IsEnabled
	from	tcu.Process			o
	join	inserted			i
			on	o.ProcessId = i.ProcessId
	join	tcu.ProcessSchedule	s
			on	o.ProcessId = s.ProcessId
end

/*
**	this part of the trigger maintains the Update On & By information
*/
if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.Process	o
	join	inserted	i
			on	o.ProcessId = i.ProcessId
end

/*
**	this part of the trigger maintains the Created On & By information
*/
if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.Process	o
	join	deleted		d
			on	o.ProcessId = d.ProcessId
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO