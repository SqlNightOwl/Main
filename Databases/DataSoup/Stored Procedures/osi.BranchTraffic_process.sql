use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[BranchTraffic_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[BranchTraffic_process]
GO
setuser N'osi'
GO
CREATE procedure osi.BranchTraffic_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
,	@forceLoad	bit			= 0
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/21/2008
Purpose  :	Retruns summarized Branch Traffic data for the specified month.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/15/2009	Paul Hunter		Changed to use the RPT2 linked server.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@chkEnd		datetime
,	@chkStart	datetime
,	@cmd		varchar(255)
,	@message	varchar(255)
,	@result		int;

--	bracket the begin/end dates for what should be loaded...
set @chkEnd		= tcu.fn_LastDayOfMonth(dateadd(month, -1, getdate()));
set @chkStart	= tcu.fn_FirstDayOfMonth(dateadd(month, -1, getdate()));
set	@cmd		= '';
set	@forceLoad	= isnull(@forceLoad, 0);
set	@result		= 0;

--	check to see that the data hasn't already been loaded
if not exists (	select	top 1 PostedOn from osi.BranchTraffic
				where (	PostedOn between @chkStart and @chkEnd and day(getdate()) = 1)
					or	@forceLoad = 1	)
begin
	--	if forceLoad then delete any existing data...
	if @forceLoad = 1
		delete	osi.BranchTraffic
		where	PostedOn between @chkStart and @chkEnd;

	--	this is a psudo-command for the real command below and is used for error reporting...
	set	@cmd = 'insert osi.BranchTraffic ([cols]) select [cols] from openquery(OSI, "select [cols] from texans.BranchTraffic_vw")';

	insert	osi.BranchTraffic
		(	PostedOn
		,	BranchNbr
		,	CategoryCd
		,	Items
		,	Amount	)
	select	PostDate
		,	LocOrgNbr
		,	RtxnTypCatCd
		,	Daily_Count
		,	Daily_Amount
	from	openquery(RPT2, '
			select	PostDate
				,	LocOrgNbr
				,	RtxnTypCatCd
				,	Daily_Count
				,	Daily_Amount
			from	texans.BranchTraffic_vw');

	--	check the error status
	if @@error = 0
	begin
		set	@message = 'The BranchTraffic data has been sucessfully loaded from OSI for '
					 + datename(month, @chkEnd) + ' ' + cast(year(@chkEnd) as varchar) + '.';
		set	@result	 = 0;	--	success
	end;
	else
	begin
		set	@message = 'An unexpected error occured while loading the BranchTraffic data from OSI for ' 
					 + datename(month, @chkEnd) + ' ' + cast(year(@chkEnd) as varchar) + '.';
		set	@result	 = 1;	--	failure
	end;
end;
else
begin
	--	the data wasn't loaded for one of the reasons listed below...
	set	@message = 'The BranchTraffic data from OSI for '
				 + datename(month, @chkEnd) + ' ' + cast(year(@chkEnd) as varchar) + ' was not loaded because:'
				 + '<li>it may have already been loaded'
				 + '<li>it''s not the first day of the month'
				 + '<li>it''s not the first day of the month and the forceLoad flag wasn''t provided';
	set	@result	 = 3;	--	warning
end;

--	record the results...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @cmd
					,	@Message	= @message;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO