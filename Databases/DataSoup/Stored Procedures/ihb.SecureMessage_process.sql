use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[SecureMessage_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[SecureMessage_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.SecureMessage_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/19/2008
Purpose  :	Load new SecureMessage files and inserts/updates a the messages and 
			archives the files.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/09/2009	Paul Hunter		Changed to read directly from the IHB database.
01/08/2010	Paul Hunter		Added record retention policy.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@createdOn	datetime
,	@detail		varchar(4000)
,	@result		int
,	@retainMsg	int
,	@rows		int;

declare	@case	table
	(	CaseId			int				not null
	,	AgentName		varchar(60)		not null
	,	MemberNumber	bigint			not null
	,	MemberName		varchar(65)		not null
	,	OpenedOn		datetime		not null
	,	ClosedOn		datetime		null
	,	Subject			varchar(255)	not null
	,	Status			varchar(32)		not null
	,	DateCreated		datetime		not null
	);

set	@retainMsg = -cast(tcu.fn_ProcessParameter(@ProcessId, 'Message Retention') as int)

--	initiaqlize the variables...
select	@createdOn	= max(CreatedOn)
	,	@detail		= ''
	,	@result		= 0
from	ihb.SecureMessage;

--	collect all the messages since the last run...
insert	@case
select	CaseNumber
	,	SupportUserFullName
	,	cast(MemberNumber as bigint)
	,	MemberName
	,	CaseOpenedAt
	,	CaseClosedAt
	,	Subject
	,	Status
	,	DateCreated
from	VOYAGER.tcu_Workspace.dbo.SupportCaseHistory_v
where	DateCreated	> @createdOn

select	@rows	= @@rowcount
	,	@result	= @@error
	,	@detail	= 'Error retrieving cases. ~ '

if	@rows	> 0
and @result	= 0
begin
	--	update existing cases...
	update	m
	set		AgentName		= l.AgentName
		,	ClosedOn		= l.ClosedOn
		,	MessageCount	= m.MessageCount + 1
		,	Status			= l.Status
		,	UpdatedOn		= getdate()
	from	ihb.SecureMessage	m
	join(	select	c.CaseId
				,	c.AgentName
				,	c.ClosedOn
				,	c.Status
			from	@case	c
			join(	select	CaseId, max(OpenedOn) as OpenedOn
					from	@case group by CaseId
				)	m	on	c.CaseId	= m.CaseId
						and	c.OpenedOn	= m.OpenedOn
		)	l	on	m.CaseId = l.CaseId;

	set @result = isnull(nullif(@result, 0), @@error);
	set	@detail	= @detail + 'Error update existing cases. ~ '

	--	add new cases...
	insert	ihb.SecureMessage
		(	CaseId
		,	AgentName
		,	MemberNumber
		,	MemberName
		,	OpenedOn
		,	ClosedOn
		,	Subject
		,	Status
		,	MessageCount
		,	CreatedOn
		)
	select	c.CaseId
		,	max(c.AgentName)
		,	max(c.MemberNumber)
		,	max(c.MemberName)
		,	min(c.OpenedOn)
		,	max(c.ClosedOn)
		,	case
			when count(1) > 1
			and	 left(max(c.Subject), 4) != 'RE: ' then 'RE: '
			else '' end + max(c.Subject)
		,	max(c.Status)
		,	1					--	MessageCount
		,	max(c.DateCreated)
	from	@case			c
	left join
		ihb.SecureMessage	m
			on	c.CaseId = m.CaseId
	where	m.CaseId is null
	group by c.CaseId
	order by c.CaseId;

	set @result = isnull(nullif(@result, 0), @@error);
	set	@detail	= @detail + 'Error inserting new cases.'

end;

--	cleanup the results before saving it in the log...
if @result = 0
	set @detail = object_name(@@procid);
else
	set	@result	= 1;	--	failure

--	remove old data...
delete	ihb.SecureMessage
where	CreatedOn < dateadd(day, @retainMsg, getdate());

exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @detail
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO