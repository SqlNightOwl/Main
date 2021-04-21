use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[Alert_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[Alert_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.Alert_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/17/2008
Purpose  :	Load's the Corillian balance and transaction request files, matches 
			them to OSI and exports the alert files.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/17/2009	Paul Hunter		Changed the transaction extract to use rw_AcctRtxn_vw
							for completed transactions where the amount is not
							equal to zero.
							Added Oracle optomizer hint.
							Constrained the types of transactions retrieved to
							only those listed in the table ihb.AlertTransactionType.
11/25/2009	Paul Hunter		Changed to use format file and streamlined table usage.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@arcFolder	varchar(255)
,	@detail		varchar(4000)
,	@fileId		int
,	@fileName	varchar(50)
,	@outFolder	varchar(255)
,	@respBase	varchar(50)
,	@result		int
,	@switches	varchar(255)
,	@targetFile	varchar(255)
,	@type		char(3)

--	initialize the variables...
select	@actionCmd	= db_name() + '.ihb.Alert'
	,	@actionFile	= p.SQLFolder + 'inbox\'
	,	@arcFolder	= p.SQLFolder + 'archive\' + convert(char(11), dateadd(day, -1, getdate()), 121)
	,	@fileName	= f.FileName
	,	@outFolder	= p.SQLFolder + 'outbox\'
	,	@respBase	= f.TargetFile
	,	@switches	= '-T -f"' + tcu.fn_UNCFileSpec(p.SQLFolder + '\' + p.FormatFile) + '"'
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
	,	@type		= ''
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	search for the files...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @actionFile
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	if files are found then loaded them...
if exists (	select	top 1 FileId from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId )
begin

	--	clear the old data and rebuild the indexes...
	truncate table ihb.Alert;
	alter index all on ihb.Alert rebuild;

	truncate table ihb.AlertTransaction;
	alter index all on ihb.AlertTransaction	rebuild;

	--	loop thru each files and load...
	while exists (	select	top 1 * from tcu.FileLog
					where	ProcessId	= @ProcessId
					and		RunId		= @RunId
					and		FileId		> @fileId )
	begin
		--	setup the command parameters...
		select	top  1
				@actionFile	= Path + '\' + FileName
			,	@fileName	= FileName
			,	@targetFile	= @arcFolder + FileName
			,	@type		= isnull(nullif(upper(left(FileName, 3)), 'TRA'), 'TRN')
			,	@fileId		= FileId
		from	tcu.FileLog
		where	ProcessId	= @ProcessId
		and		RunId		= @RunId
		and		FileId		> @fileId
		order by FileId;

		--	load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail output;

		--	report any errors and exit...
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
			return @result;
		end;

		--	extract the details from the record...
		update	ihb.Alert
		set		AlertType		=	@type
			,	RecordType		=	cast(left(Record, 2) as tinyint)
			,	AccountNumber	=	case
									when cast(left(Record, 2) as tinyint) = 10
									and	 isnumeric(substring(Record, 13, 22)) = 1
									then cast(substring(Record, 13, 22) as bigint)
									else 0 end
		where	AlertType		=	'';

		if @type = 'BAL'
		begin
			--	update balances for balance requests...
			update	a
			set		Balance	= b.BalAmt
			from	ihb.Alert	a
			join	openquery(OSI, '
					select	/*+CHOOSE*/ AcctNbr ,BalAmt
					from	ihb_AcctBalance_vw') b
					on	a.AccountNumber = b.AcctNbr
			where	a.RecordType	= 10
			and		a.AlertType		= @type
			and		a.AccountNumber	> 0;
		end;
		else if @type = 'TRN'
		begin
			--	extract transacitons for transaction requests...
			insert	ihb.AlertTransaction
				(	AcctNbr
				,	RtxnTypCd
				,	RtxnTypCatCd
				,	TranAmt
				,	ActDateTime
				,	Description
				)
			select	a.AccountNumber
				,	t.RtxnTypCd
				,	t.RtxnTypCd
				,	o.TranAmt
				,	o.ActDateTime
				,	case
					when cast(o.TranAmt as money) < 0 then t.DebitDesc
					else t.CreditDesc end
			from	ihb.Alert						a
			join	openquery(OSI, '
					select	/*+CHOOSE*/
							AcctNbr
						,	RtxnTypCd
						,	RtxnTypCatCd
						,	TranAmt
						,	ActDateTime
					from	texans.rw_AcctRtxn_vw
					where	PostDate		= trunc(sysdate - 1)
					and		CurrRtxnStatCd	= ''C''
					and		TranAmt			!=	0')	o
					on	a.AccountNumber = o.AcctNbr
			join	ihb.AlertTransactionType		t
					on	o.RtxnTypCd		= t.RtxnTypCd
					and	o.RtxnTypCatCd	= t.RtxnCatCd
			where	a.AlertType		= @type
			and		a.RecordType	= 10
			and		a.AccountNumber	> 0;
		end;

		--	archive the loaded file...
		set	@targetFile = @arcFolder + @fileName
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @actionFile
									,	@targetFile	= @targetFile
									,	@overWrite	= 1
									,	@output		= @detail output;

		--	report any errors and exit...
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
			return @result;
		end;
	end;

	--	produce the response files...
	if exists (	select top 1 Record from ihb.Alert )
	begin
		--	re-initialize the variables...
		select	@switches	= '-T -c'
			,	@type		= '';

		--	loop thru each alert type and create the files...
		while exists (	select	top 1 AlertType from ihb.Alert
						where	AlertType > @type
						order by AlertType	)
		begin
			--	setup the command and command parameters...
			select	top 1
					@actionCmd	=	'select Record from ' + db_name() + '.ihb.Alert'
								+	case AlertType
									when 'BAL'	then 'Balance_v'
									when 'TRN'	then 'Transaction_v'
									else null end
								+	' order by RecordId'
				,	@fileName	=	lower(replace(AlertType, 'N', 'ans') + @respBase)
				,	@type		=	AlertType
			from	ihb.Alert
			where	AlertType	> @type;

			--	setup the fully qualified file paths...
			select	@actionFile	= @outFolder + @fileName
				,	@targetFile	= @arcFolder + @fileName;

			--	export the data
			exec @result = tcu.File_bcp	@action		= 'queryout'
									,	@actionCmd	= @actionCmd
									,	@actionFile	= @actionFile
									,	@switches	= @switches
									,	@output		= @detail output;

			--	report any errors and exit...
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
				return @result;
			end;

			--	archive the file...
			exec @result = tcu.File_action	@action		= 'copy'
										,	@sourceFile	= @actionFile
										,	@targetFile	= @targetFile
										,	@overWrite	= 1
										,	@output		= @detail output;
			--	report any errors and exit...
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
				return @result;
			end;
		end;
	end;
end;
else	--	no files were found so fail
begin
	set	@result		= 1
	set	@actionCmd	= 'tcu.File_findFiles "' + @actionFile + @fileName + '"'
	set	@detail		= 'No IHB Alert files were received from the Voyager system.'
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