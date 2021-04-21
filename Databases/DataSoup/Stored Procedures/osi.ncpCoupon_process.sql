use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncpCoupon_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ncpCoupon_process]
GO
setuser N'osi'
GO
CREATE procedure osi.ncpCoupon_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/09/2008
Purpose  :	Loads the NCP Coupon file, removes unwanted records and re-exports
			the file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
11/25/2009	Paul Hunter		Changed to us format file for loading.
							Added deletion of Process Log and OSI Log records.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@detail		varchar(4000)
,	@result		int
,	@sourceFile	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(255)

--	build the load command and the target file name...
select	top 1
		@actionCmd	= db_name() + '.osi.ncpCoupon'
	,	@sourceFile	= l.FileSpec
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + '\' + p.FormatFile) + '" -T'
	,	@targetFile	= p.FTPFolder + l.FileName
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessOSILog_v		l
join	tcu.ProcessParameter_v	p
		on	l.ProcessId = p.ProcessId
where	l.RunId		= @RunId
and		l.ProcessId	= @ProcessId;

--	clean out any old data...
truncate table osi.ncpCoupon;
alter index all on osi.ncpCoupon rebuild;

--	load the data...
exec @result = tcu.File_bcp	@action		= 'in'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @sourceFile
						,	@switches	= @switches
						,	@output		= @detail output;

--	did anything get loaded...
if exists (	select top 1 Record from osi.ncpCoupon )
begin
	--	remove records...
	delete	osi.ncpCoupon
	where	Record like '%** DO NOT MAIL **%';

	--	extract/update the account numbers...
	update	osi.ncpCoupon
	set		AccountNumber = cast(substring(Record, 7, 15) as bigint);

	--	delete accounts having zero/negative balances...
	delete	osi.ncpCoupon
	where	AccountNumber in (	select	n.AccountNumber
								from	osi.ncpCoupon n
								join	openquery(OSI,'
										select AcctNbr from osiBank.Acct where MjAcctTypCd = ''CNS''
										and to_number(pack_Acct.func_Acct_Bal(AcctNbr,''NOTE'',''BAL'',trunc(sysdate))) <= 0') o
										on	n.AccountNumber = o.AcctNbr	);

	--	if anything is left then re-export the file...
	if exists (	select	top 1 Record from osi.ncpCoupon )
	begin
		--	build and execute the re-constituted NCP Coupon file...
		select	@actionCmd	= 'select Record from '
							+ @actionCmd + ' order by RecordId'
			,	@switches	= '-c -T';

		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @targetFile
								,	@switches	= @switches
								,	@output		= @detail output;

		if @result != 0 or len(@detail) > 0
			select	@detail	= 'An unexpected error occured producing the subject file.<br/>'
							+ @detail
				,	@result = 1;	--	failure
	end;
end;
else
begin
	select	@detail	= 'No records were loaded from the file ' + @sourceFile
		,	@result	= 1;	--	failure
end;

--	report any errors...
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

--	dump the data...
truncate table osi.ncpCoupon;
alter index all on osi.ncpCoupon rebuild;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO