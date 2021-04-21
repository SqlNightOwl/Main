use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskRiskRating_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[eriskRiskRating_process]
GO
setuser N'risk'
GO
CREATE procedure risk.eriskRiskRating_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/30/2008
Purpose  :	Creates a SQL update script of Risk Ratings for Mortgage Loans to
			be executed against the OSI database.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@result		int
,	@sqlFolder	varchar(255);

--	initialize the variables...
select	@actionCmd	= 'select SQLScript from ' + db_name() 
					+ '.risk.eriskRiskRating_v union all select ''commit;'''
	,	@fileName	= replace(FileName, '[PERIOD]', convert(char(7), getdate(), 121))
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile				f
join	tcu.ProcessParameter_vWide	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	the folder file names are used in the success message
set	@actionFile	= @sqlFolder + @fileName;

--	export the update script...
exec @result = tcu.File_bcp	@action		= 'queryout'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -T'
						,	@output		= @detail output;
--	record the results...
if @result = 0 and len(@detail) = 0
begin
	set	@detail	= 'The Risk Rating SQL Script file was successfully created as "'
				+ @fileName + '" and was created in the <a href="' + @sqlFolder
				+ '">eRisk folder</a>.<br/>'
				+ 'The change scripts in this file must be executed prior to month end.';
end;
else
begin
	set	@result	= 1;	--	failure
end;

--	record the results...
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