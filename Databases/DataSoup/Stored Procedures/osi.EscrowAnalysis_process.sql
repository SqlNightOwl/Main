use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowAnalysis_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[EscrowAnalysis_process]
GO
setuser N'osi'
GO
CREATE procedure osi.EscrowAnalysis_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/04/2008
Purpose  :	Loads the Escrow Analysis file and adds the Address and Phone number
			and removed any "printer control" codes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@address	varchar(255)
,	@beginOn	datetime
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@ftpFolder	varchar(255)
,	@result		int
,	@start		int
,	@switches	varchar(255)

declare	@statement table
	(	EndRow		int	not null primary key
	,	StartRow	int not null default (0)
	);

--	initialize the processing variables...
select	@actionCmd	= db_name() + '.osi.EscrowAnalysis'
	,	@actionFile	= l.FileSpec
	,	@fileName	= l.FileName
	,	@ftpFolder	= p.FTPFolder
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + p.FormatFile ) + '" -T'
	,	@address	= tcu.fn_ProcessParameter(p.ProcessId, 'Mortgage Servicing')
	,	@detail		= ''
	,	@result		= 0
	,	@start		= 1
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
join	tcu.ProcessOSILog_v		l
		on	l.ProcessId = f.ProcessId
		and	l.RunId		= @RunId
where	l.ProcessId = @ProcessId;

--	cleanup the old data and refresh the indexes...
truncate table osi.EscrowAnalysis;
alter index all on osi.EscrowAnalysis rebuild;

--	the OSI batch should have already completed so load the file...
exec @result = tcu.File_bcp	@action		= 'in'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= @switches
						,	@output		= @detail output;

--	report any errors...
if @result != 0 or len(@detail) > 0
begin
	set	@result = 1;	--	failure
end;
else if exists ( select top 1 * from osi.EscrowAnalysis )
begin
	--	remove printer codes...
	delete	osi.EscrowAnalysis
	where	ltrim(Record) like '..%';

	--	determine the last row of every statement page [char(12) = Form Feed]...
	insert	@statement
		(	EndRow )
	select	Row - 1
	from	osi.EscrowAnalysis
	where	Record like '%' + char(12) + '%';

	--	update the last record to be the last row of the table...
	update	@statement
	set		EndRow	= EndRow + 1
	where	EndRow	= (select max(EndRow) from @statement);

	--	update the starting rows for all statement page...
	while exists (	select	top 1 StartRow from @statement
					where	StartRow = 0	)
	begin
		--	set the start row...
		update	@statement
		set		StartRow	= @start
		where	EndRow		= (select min(EndRow) from @statement where StartRow = 0);

		--	advance to the next "page"...
		select	@start	= min(EndRow) + 1
		from	@statement
		where	EndRow	= (select max(EndRow) from @statement where StartRow > 0);
	end;

	--	update the records to append the header...
	update	ea
	set		Record	=	case isnull(h.Row, 0)
						when 0 then ea.Record
						else rtrim(isnull(ea.Record, '')) + h.Value
						end
	from	osi.EscrowAnalysis	ea
	join	@statement			s
			on	ea.Row	between s.StartRow
							and s.EndRow
	left join
			tcu.fn_Split(@address, '|')	h
			on	(ea.Row - s.StartRow) = h.Row - 1;

	--	reset the cmd and file to produce the output...
	select	@actionCmd	= 'select Record from ' + @actionCmd + ' order by Row'
		,	@actionFile	= @ftpFolder + @fileName
		,	@switches	= '-c -T';

	--	export the results...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;
	
	if @result = 0 and len(@detail) = 0
	begin
		--	no errors, so adjust the schedule for next year...
		set @beginOn = tcu.fn_FirstDayOfMonth(dateadd(month, -(month(getdate()) - 1), getdate()))

		update	tcu.ProcessSchedule
		set		BeginOn		= @beginOn
			,	EndOn		= dateadd(day, 30, @beginOn)
		where	ProcessId	= @ProcessId
		and		ScheduleId	= @ScheduleId;
	end;
	else
	begin
		--	report any errors...
		set	@result = 1;	--	failure
	end;
end;
else	--	nothing got loaded...
begin
	select	@detail	= 'The Escrow Analysis file ' + @actionFile
					+ ' either could not be loaded or contained no records.'
		,	@result	= 3;	--	warning
end;

--	record any errors...
if @result != 0 or len(@detail) > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end;
else
begin
	--	no need to hang onto the data...
	truncate table osi.EscrowAnalysis;
	alter index all on osi.EscrowAnalysis rebuild;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO