use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServAccount_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[BankServAccount_process]
GO
setuser N'sst'
GO
CREATE procedure sst.BankServAccount_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/07/2008
Purpose  :	Process to exports the BankServ data.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int;

--	clear the old data...
truncate table sst.BankServAccount;

--	load the BankServ data
exec sst.BankServAccount_sav @overRide = 1;

--	initialize the variables
select	@actionCmd	= 'select Record from ' + db_name() 
					+ '.sst.BankServAccount_v order by AccountNumber'
	,	@actionFile	= p.ftpFolder + f.fileName
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	bind the view to the procedure for dependency checking
--	export the BankServ file
if exists (	select	top 1 * from sst.BankServAccount_v )
begin
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;
end;

--	clear the new data...
truncate table sst.BankServAccount;

--	report any any errors encountered during the export
if @result != 0 or len(@detail) > 0
begin
	set	@result = 1;
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