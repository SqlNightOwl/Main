use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[RewardsNow_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[RewardsNow_process]
GO
setuser N'osi'
GO
CREATE procedure osi.RewardsNOW_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/09/2008
Purpose  :	Handles the Rewards not processing to...
			1)	Produce a list of cards and closed cards on the first of every 
				month which are sent to FiServ.
			2)	Produce a list of Addresses on the first day of every new quarter
			3)	Load the File returned by FiServ and re-export it to be sent to
				RewardsNow.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
10/07/2008	Fijula Kuniyil	Changed the cardnumber column to account number
10/10/2008	Fijula Kuniyil	Added address file logic
02/23/2009	Paul Hunter		Added SSN1 to the first query and Primary Name/SSN
							and Joint Name to the second.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(500)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@period		char(6)
,	@result		int;

--	initialze the variables...
select	@detail	= ''
	,	@result	= 0
	,	@period	= convert(char(6), getdate(), 112);

if day(getdate()) = 1
begin
	--	build the command to export transactions from the OSI view below.
	select	@actionCmd	= 'select DDA, SSN1, ExtCardNbr, convert(char(10), LocalTxnDate, 101), cast(TxnAmt as money) '
						+ 'from openquery(OSI, ''select distinct DDA, SSN1, ExtCardNbr, LocalTxnDate, TxnAmt '
						+ 'from texans.RewardsNOW_TxnExport_vw'')'
		,	@actionFile	= p.FTPFolder + replace(f.FileName, '[PERIOD]', @period)
	from	tcu.ProcessFile			f
	join	tcu.ProcessParameter_v	p
			on	f.ProcessId = p.ProcessId
	where	f.ProcessId	= @ProcessId
	and		f.FileName	= 'TexansRewards_[PERIOD].txt';

	--	export the  file
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;

	--	build the command to produce the address file
	select	@actionCmd	= 'select DDA, PrimaryName, PrimarySSN, JointName, Address1, Address2, CityName, StateCd, ZipCd '
						+ 'from openquery(OSI,''select distinct DDA, PrimaryName, PrimarySSN, JointName, Address1, '
						+ 'Address2, CityName, StateCd, ZipCd from texans.RewardsNOW_CustomerAddress_vw'')'
		,	@actionFile	= p.FTPFolder + replace(f.FileName, '[PERIOD]', @period)
	from	tcu.ProcessFile			f
	join	tcu.ProcessParameter_v	p
			on	f.ProcessId = p.ProcessId
	where	f.ProcessId	=	@ProcessId
	and		f.FileName	like '%Address%';

	--	export the  file
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;

end;

PROC_EXIT:
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