use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[PurgeActivity_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[PurgeActivity_process]
GO
setuser N'osi'
GO
CREATE procedure osi.PurgeActivity_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
,	@FromDate	datetime	= null
,	@ToDate		datetime	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	12/19/2008
Purpose  :	Exports OSI Activity of Org/Pers recrods marked for purge to a common
			file/folder location for loading to LaserFische.  A user may specifiy
			overrides for the standard date range (current month) if desired.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@dateBegin	char(10)
,	@dateEnd	char(10)
,	@detail		varchar(4000)
,	@result		int

--	initilaize the variables...
select	@actionCmd	= 'exec ' + db_name() + '.osi.PurgeActivity_report @BeginOn = ''%1'', @EndOn = ''%2'';'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@archFile	= tcu.fn_OSIFolder() + convert(char(8), getdate(), 112) + '\online\' + f.FileName
	,	@dateBegin	= convert(char(10), isnull(@FromDate, tcu.fn_FirstDayOfMonth(null)), 121)
	,	@dateEnd	= convert(char(10), isnull(@ToDate	, tcu.fn_LastDayOfMonth(null)) , 121)
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId	= p.ProcessId
where	f.ProcessId = @ProcessId

--	add the date parameters to the procedure
set	@actionCmd = replace(replace(@actionCmd, '%1', @dateBegin), '%2', @dateEnd)

--	export the data...
exec @result = tcu.File_bcp	@action		= 'queryout'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -T'
						,	@output		= @detail output;

--	report any errors...
if @result != 0 or len(@detail) > 0
begin
	set	@result	= 1;	--	failure
end
else
begin
	--	build a "bogus" action cmd in case of errors...
	set	@actionCmd = 'move /Y ' + @actionFile + ' ' + @archFile

	--	move the file to the archive location...
	exec @result = tcu.File_action	@action		= 'move'
								,	@sourceFile	= @actionFile
								,	@targetFile	= @archFile
								,	@overWrite	= 1
								,	@output		= @detail output; 

	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result	= 1;	--	failure
	end
end

PROC_EXIT:
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @actionCmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO