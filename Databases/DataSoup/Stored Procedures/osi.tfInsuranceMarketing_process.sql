use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfInsuranceMarketing_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[tfInsuranceMarketing_process]
GO
setuser N'osi'
GO
CREATE procedure osi.tfInsuranceMarketing_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	12/11/2007
Purpose  :	For Texans Financial to market AD&D Insurance to members.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/21/2008	Paul Hunter		Replaced columns for Average Balance and Date of Birth
							and with Balance >= 100 and Age.  Removed the Tax Id
							completely.
05/01/2009	Paul Hunter		Added OptOut column to the output
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/05/2009	Paul Hunter		Changed to use the RPT2 instance.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int

--	initialize the variables...
select	@actionCmd	= db_name() + '.osi.tfInsuranceMarketing_v'
	,	@actionFile	= p.SQLFolder + replace(f.FileName, '[DATE]', convert(char(8), dateadd(day, -1, getdate()), 112))
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	clean up last data before reloading...
truncate table osi.tfIsiAccount;
alter index all on osi.tfIsiAccount rebuild;

truncate table osi.tfIsiTransaction;
alter index all on osi.tfIsiTransaction rebuild;

--	load the Demographic & Account information for the period
insert	osi.tfIsiAccount
select	FirstName
	,	LastName
	,	Address1
	,	Address2
	,	CityName
	,	StateCd
	,	ZipCd
	,	CtryCd
	,	EmailAddress
	,	Age
	,	PersNbr
	,	AcctNbr
	,	BalanceGTE100
	,	MajorType
	,	MinorType
	,	isnull(ContractDate, 0)
	,	OptOut
from	openquery(OSI, '
		select	FirstName
			,	LastName
			,	Address1
			,	Address2
			,	CityName
			,	StateCd
			,	ZipCd
			,	CtryCd
			,	EmailAddress
			,	Age
			,	PersNbr
			,	AcctNbr
			,	BalanceGTE100
			,	MajorType
			,	MinorType
			,	ContractDate
			,	OptOut
		from	texans.tf_ISIAccountDemographics_vw');

--	load the Transactions for the period...
insert	osi.tfIsiTransaction
select	AcctNbr
	,	RtxnNbr
	,	TaxRptForPersNbr
from	openquery(OSI, '
		select	AcctNbr
			,	RtxnNbr
			,	TaxRptForPersNbr
		from	texans.tf_IsiMTDTransactions_vw')
order by AcctNbr, RtxnNbr;

--	if there are records then export them and archive the file
if exists (	select top 1 AcctNbr from osi.tfInsuranceMarketing_v )
begin
	--	export the data...
	exec @result = tcu.File_bcp	@action		= 'out'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	archive the file...
	if @result = 0 and len(@detail) = 0
	begin
		exec @result = tcu.File_archive	@action			= 'copy'
									,	@sourceFile		= @actionFile
									,	@archiveDate	= null
									,	@detail			= @detail output
									,	@addDate		= 0
									,	@overwrite		= 1;
		if @result != 0 or len(@detail) > 0
		begin
			set	@result	= 3;	--	warning
		end;
	end;
	else
	begin
		set	@result	= 3;	--	warning
	end;
end;
else
begin
	select	@detail	= 'Unable to extract one or more values from OSI.  '
					+ 'Please check the extract routines in the stored procedure "'
					+ schema_name(schema_id) + '.' + object_name(object_id) + '".'
		,	@result	= 1	--	failure
	from	sys.procedures
	where	object_id = @@procid;
end;

--	log any errors from execution
if @result != 0 or len(@detail) > 0
begin
	exec tcu.ProcessLog_sav	@RunId			= @RunId
						,	@ProcessId		= @ProcessId
						,	@ScheduleId		= @ScheduleId
						,	@StartedOn		= null
						,	@Result			= @result
						,	@Command		= @actionCmd
						,	@Message		= @detail;
end;
else
begin
	truncate table osi.tfIsiAccount;
	alter index all on osi.tfIsiAccount rebuild;

	truncate table osi.tfIsiTransaction;
	alter index all on osi.tfIsiTransaction rebuild;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO