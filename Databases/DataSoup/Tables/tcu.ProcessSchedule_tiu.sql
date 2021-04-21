use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
create trigger tcu.ProcessSchedule_tiu
on	tcu.ProcessSchedule
for insert, update
as

set nocount on;

declare @user varchar(255)

--	On Demand Processes may not have disabled Schedules!
if exists ( select	top 1 ProcessId from tcu.Process
			where	ProcessId in (select ProcessId from inserted where IsEnabled = 0)
			and		ProcessCategory = 'On Demand'	)
begin
	rollback transaction;
	return;
end;

set @user = tcu.fn_UserAudit();

/*
**	this part of the trigger maintains a systematic ProcessSchedule description
*/
if update(Attempts)
or update(BeginOn)
or update(EndOn)
or update(EndTime)
or update(Frequency)
or update(IsEnabled)
or update(StartTime)
or update(UsePriorDay)
or update(UseNewestFile)
begin
	update	o
	set		ProcessSchedule	=	case when i.IsEnabled = 1 and p.IsEnabled = 1 then '' else '** DISABLED - ' end
							+	case i.Frequency
								when 1 then 'Continuously'
								when 124 then 'Weekdays'
								else tcu.fn_Frequency(i.Frequency)
								end
							+	' between '
							+	case convert(char(5), i.StartTime, 8)
								when '00:00' then 'midnight'
								when '12:00' then 'noon'
								else lower(ltrim(right(cast(i.StartTime as varchar), 7)))
								end
							+	' and '
							+	case convert(char(5), i.EndTime, 8)
								when '00:00' then 'midnight'
								when '12:00' then 'noon'
								else lower(ltrim(right(cast(i.EndTime as varchar), 7)))
								end
							+	case i.Attempts
								when 0 then '' 
								when 1 then ' making 1 attempt'
								else replace(' making | attempts', '|', i.Attempts)
								end
							+	case i.UsePriorDay
								when 1 then ' from the prior day''s folder'
								else ''
								end
							+	case i.UseNewestFile
								when 1 then ' using the newest file'
								else ''
								end
							+	case
								when p.SkipCompanyHolidays = 0 and p.SkipFederalHolidays = 0 then ''
								when p.SkipCompanyHolidays = 1 and p.SkipFederalHolidays = 1 then ' skipping both Federal and Texans holidays'
								when p.SkipCompanyHolidays = 1 then ' skipping Texans holidays'
								when p.SkipFederalHolidays = 1 then ' skipping Federal holidays'
								end
							+	case
								when i.BeginOn is null then ''
								when i.BeginOn = i.EndOn then ' on ' + convert(char(10), i.BeginOn, 101)
								else ' beginning ' + convert(char(10), i.BeginOn, 101)
								end
							+	case
								when i.EndOn is null then ''
								when i.BeginOn = i.EndOn then ''
								else ' and ending '	+ convert(char(10), i.EndOn, 101)
								end
							+	'.'
		,	Attempts		=	case i.Frequency when 1 then 225 else i.Attempts end 
		,	UpdatedOn		=	getdate()
		,	UpdatedBy		=	@user
	from	tcu.ProcessSchedule	o
	join	tcu.Process			p
			on	o.ProcessId		= p.ProcessId
	join	inserted			i
			on	o.ProcessId		= i.ProcessId
			and	o.ScheduleId	= i.ScheduleId;
end;

/*
**	this part of the trigger maintains the Update On & By information
*/
if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= @user
	from	tcu.ProcessSchedule	o
	join	inserted			i
			on	o.ProcessId	 = i.ProcessId
			and	o.ScheduleId = i.ScheduleId;
end;

/*
**	this part of the trigger maintains the Created On & By information
*/
if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.ProcessSchedule	o
	join	deleted				d
			on	o.ProcessId	 = d.ProcessId
			and	o.ScheduleId = d.ScheduleId;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO