use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[caAccountName_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[caAccountName_process]
GO
setuser N'osi'
GO
CREATE procedure osi.caAccountName_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/09/2008
Purpose  :	Creates the AccountNames file for Akcellerant.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int

--	retrieve initialize the varialbes
select	@actionCmd	= 'select AcctNbr'
					+ ', AcctNbr2'
					+ ', ''\"'' + PersonId + ''\"'''
					+ ', ''\"'' + FirstName + ''\"'''
					+ ', ''\"'' + LastName + ''\"'' '
					+ 'from ' + db_name() + '.osi.caAccountName_v'
	,	@actionFile	= tcu.fn_UNCFileSpec(pp.Value + '\') + pf.FileName
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessParameter	pp
join	tcu.ProcessFile			pf
		on	pp.ProcessId = pf.ProcessId
where	pp.ProcessId	= @ProcessId
and		pp.Parameter	= 'File Share'

--	this binds the view to the procedure for dependancy checking
if exists (	select	top 1 * from osi.caAccountName_v )
begin
	--	execute the command and collect the results
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -t, -T'
							,	@output		= @detail	output

	--	if there was an error then report it.	
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1
		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= null
							,	@Result		= @result
							,	@Command	= @actionCmd
							,	@Message	= @detail
	end
end

return @result
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO