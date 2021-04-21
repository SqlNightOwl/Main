use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[SingleServiceFeeNotification_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[SingleServiceFeeNotification_process]
GO
setuser N'osi'
GO
CREATE procedure osi.SingleServiceFeeNotification_process
	@RunId		int	
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/10/2008
Purpose  :	Exports and delivers the Single Service Fee notification files.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(500)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@lastColumn	int
,	@message	varchar(1000)
,	@period		char(7)
,	@recipients	varchar(1000)
,	@result		int
,	@subject	varchar(255)
,	@type		varchar(10)

set	@period	= convert(char(7), dateadd(month, -1, getdate()) , 121);
set	@result	= 1;	--	fail if it's not the correct date.

select	@actionCmd	= db_name() + '.' + f.FileName
	,	@actionFile	= p.SQLFolder + replace(f.TargetFile, '.[PERIOD]', '')
	,	@archFile	= p.SQLFolder + 'archive\' + replace(f.TargetFile, '[PERIOD]', @period)
	,	@message	= p.MessageBody
	,	@recipients	= p.MessageRecipient
	,	@type		= left(f.TargetFile, charindex('List', f.TargetFile) - 1)
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId		= @ProcessId
		--	for this process, ApplFrequency containts the day that the process should run
and		f.ApplFrequency	= (	select	day(BeginOn) from tcu.ProcessSchedule
							where	ProcessId	= @ProcessId
							and		ScheduleId	= @ScheduleId );

if len(isnull(@actionCmd, '')) > 0
begin
	--	determine what the last column of the queried columns is...
	select	@lastColumn = column_id from sys.columns
	where	[object_id] =	object_id(ltrim(@actionCmd))
	and		name		!=	'RowType';	--	this column is skipped

	--	build a sql string for the command...
	select	@actionCmd	=	case column_id
							when 1 then 'select ' + name + ', '
							when @lastColumn then name + ' from '
							else name + ', '
							end + @actionCmd
	from	sys.columns
	where	[object_id]	=	object_id(ltrim(@actionCmd))
	and		name		!=	'RowType'	--	this column is skipped
	order by column_id desc;

	set @actionCmd = @actionCmd + ' order by RowType, AcctNbr';

	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	exported the file so send it to the recipients
	if @result = 0 and len(@detail) = 0
	begin
		--	fix up the subject and  message...
		select	@message	= replace(replace(@message
								, '#TYPE#'	, @type)
								, '#PERIOD#', @period)
			,	@subject	=  'Single Service Fee - ' + @type + 's'
		--	send the email...
		exec tcu.Email_send	@subject		= @subject
						,	@message		= @message
						,	@sendTo			= @recipients
						,	@asHtml			= 1
						,	@attachedFiles	= @actionFile;

		--	adjust the schedule to the next month...
		update	tcu.ProcessSchedule
		set		BeginOn		= dateadd(month, 1, BeginOn)
			,	EndOn		= dateadd(month, 1, BeginOn)
		where	ProcessId	= @ProcessId
		and		ScheduleId	= @ScheduleId
		and		BeginOn		= convert(char(10), getdate(), 121);

		--	move the file to the archive...
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @actionFile
									,	@TargetFile	= @archFile
									,	@overWrite	= 1
									,	@output		= @detail output;
		--	report any errors....
		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 3;	--	warning
		end;
	end;
	else	--	report any errors...
	begin
		set	@result = 3;	--	warning
	end;
end;

--	if there was a failure or an action command was produced then record it...
if @result != 0 or len(@detail) > 0 or len(isnull(@actionCmd, '')) > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId = @ScheduleId
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