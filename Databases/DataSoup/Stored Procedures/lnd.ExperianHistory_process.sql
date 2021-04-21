use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[ExperianHistory_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[ExperianHistory_process]
GO
setuser N'lnd'
GO
CREATE procedure lnd.ExperianHistory_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/19/2008
Purpose  :	Transfers the new Experian scores from the load table to the permanent
			ExperianHistory table.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/23/2008	Paul Hunter		Removed Process update code to disable the process
							as this is a feature of the Process_run based on a
							ProcessCategory of "On Demand".
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int

--	initialize the parameters
select	@actionCmd	= db_name() + '.lnd.ExperianHistory_load'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@archFile	= p.SQLFolder + 'archive\'
					+ replace(f.FileName, '.', '-' + convert(char(10), getdate(), 121) + '.')
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	p.ProcessId = @ProcessId;

--	clear the old data...
truncate table lnd.ExperianHistory_load;

--	load the file...
exec @result = tcu.File_bcp	@action		= 'in'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -T -F2'
						,	@output		= @detail output;

--	if no errors occured then make it permanent
if @result = 0 and len(@detail) = 0
begin
	--	zero pad the TaxId's
	update	lnd.ExperianHistory_load
	set		TaxId = tcu.fn_ZeroPad(TaxId, 9);
	
	--	load the scores as an average in case there are multiples
	insert	lnd.ExperianHistory
		(	TaxId
		,	ScoreOn
		,	FICOScore
		,	MDSScore
		)
	select	TaxId
		,	ScoreOn		= convert(char(10), getdate(), 121)
		,	FICOScore	= avg(FICOScore)
		,	MDSScore	= avg(MDSScore)
	from	lnd.ExperianHistory_load
	group by TaxId
	order by TaxId;

	--	throw out the old data...
	truncate table lnd.ExperianHistory_load;

	--	archive the file
	exec @result = tcu.File_action	@action		= 'move'
								,	@sourceFile	= @actionFile
								,	@targetFile	= @archFile
								,	@overWrite	= 1
								,	@output		= @detail output;
	--	report file movement errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 3;	--	warning
	end;
end;
else	--	report BCP errors...
begin
	set	@result = 3;	--	warning
end;

--	clear the new data...
truncate table lnd.ExperianHistory_load;

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

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO