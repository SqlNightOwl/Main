use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncrRemoteCapture_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ncrRemoteCapture_process]
GO
setuser N'osi'
GO
CREATE procedure osi.ncrRemoteCapture_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/02/2008
Purpose  :	Load the NCR Remote Capture file and produces the a SWIM file based
			on the data loaded.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/31/2008	Paul Hunter		Added a check to discontinue running the process if
							no transactions are received in the file for the
							current date.
07/02/2008	Paul Hunter		Added the Clearing Category Code and funds availability
							logic so management holds can be tracked.  Update the
							Merchant Id & Account to the individual deposit records.
05/23/2009	Paul Hunter		Added logic to only load the newest file for the current
							date and delete all others.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd		varchar(500)
,	@actionFile		varchar(255)
,	@chkFile		money
,	@countCR		int
,	@countDR		int
,	@deposit		money
,	@detail			varchar(4000)
,	@fileDate		datetime
,	@fileId			int
,	@newestFile		varchar(255)
,	@result			int
,	@sourceFile		varchar(255)
,	@sqlFolder		varchar(255)
,	@STAT_FAILURE	int
,	@STAT_SUCCESS	int
,	@STAT_INFO		int
,	@STAT_WARNING	int
,	@targetFile		varchar(255);

declare	@osiMerchant	table
(	AccountNumber	bigint primary key
,	AccountAge		int	
);

--	initialize the tracking variables
select	@sourceFile		= f.FileName
	,	@sqlFolder		= p.SQLFolder
	,	@detail			= ''
	,	@fileId			= 0
	,	@result			= 0
	,	@STAT_FAILURE	= 1
	,	@STAT_INFO		= 2
	,	@STAT_SUCCESS	= 0
	,	@STAT_WARNING	= 3
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	search for any Remote Capture files
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @sourceFile
						,	@includeSubFolders	= 0;

--	get the newest file for today...
select	@newestFile	= @sqlFolder + max(FileName)
from	tcu.FileLog
where	ProcessId	= @ProcessId
and		RunId		= @RunId
and		FileDate	> convert(char(10), getdate(), 121);

--	load all Remote Capture files...
while exists (	select	top 1 * from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin

	--	create the commands for loading/archiving the file...
	select	top 1
			@actionCmd	= db_name() + '.osi.ncrRemoteCaptureRaw_vLoad'
		,	@sourceFile	= Path + '\' + fileName
		,	@targetFile	= Path + '\archive\' + fileName
		,	@fileDate	= FileDate
		,	@fileId		= FileId
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId;

	--	if the source file is the newest file
	if @sourceFile = @newestFile
	begin
		--	...clear out any old raw data...
		truncate table osi.ncrRemoteCaptureRaw;

		--	...load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @sourceFile
								,	@switches	= '-c -T'
								,	@output		= @detail output;
		--	report any errors...
		if @result != @STAT_SUCCESS or len(@detail) > 0
		begin
			set	@result = @STAT_FAILURE;
			goto PROC_EXIT;
		end;

		--	...archive the file...
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @sourceFile
									,	@targetFile	= @targetFile
									,	@overwrite	= 1
									,	@output		= @detail output;

		--	report any errors...
		if @result != 0 or len(@detail) > 0
		begin
			set	@result = @STAT_FAILURE;
			goto PROC_EXIT;
		end;
		else
		begin	--	validate the file before loading....
			--	collect details about the file just loaded from the footer record
			select	@deposit	=	case cast(Col1 as money)
									when cast(Col3 as money) then cast(Col1 as money)
									else 0 end
				,	@countDR	=	cast(Col2 as int)
				,	@countCR	=	cast(Col4 as int)
			from	osi.ncrRemoteCaptureRaw
			where	RowType	= 9;

			--	report an error if the total deposit, number debits or credits is zero
			if @deposit = 0 or @countDR = 0 or @countCR = 0
			begin
				--	this handles cases where the the file header doesn't balance or doesn't have transaceions
				set	@result	=	case (@deposit + @countDR + @countCR)	--	nothing in the file
								when @STAT_SUCCESS then case datediff(day, @fileDate, getdate())
														when 0 then @STAT_SUCCESS	--	produced today
														else @STAT_INFO end			--	produced previously
								else @STAT_WARNING
								end;

				set	@detail	=	case	--	get the time of day this is running
								when datepart(hour, getdate()) < 12 then 'morning '
								when datepart(hour, getdate()) < 17 then 'afternoon '
								else 'evening '
								end;

				set	@detail	=	'The file "' + @targetFile + '" loaded this ' + @detail
							+	'and produced ' + cast(@fileDate as varchar) + ' '
							+	case @result
								when @STAT_SUCCESS then		--	success, no transacitons...
										'doesn''t contain any transactions. &nbsp;Please contact Operations and verify this is correct.'
									+	'<p>This Process is now considered complete and no additional runs of this schedule will be made.</p>'
								when @STAT_INFO then		--	information, no transacitons...
										'doesn''t contain any transactions.'
									+	'<p>This Process will continue to run under this schedule.</p>'
								when @STAT_WARNING then	--	warning, file doesn't balance...
										'doesn''t balance and either the total amount to be deposited is zero (' + cast(@deposit as varchar) + ') '
									+	'and/or the number of debits/credits don''t match (dr: ' + cast(@countDR as varchar) 
									+	', cr: ' + cast(@countCR as varchar) + ') in the Remote Capture file.'
									+	'<p>The file cannot be processed until the file balances.</p>'
								end;
			end;
			else	--	the file contains transactions so, begin processing the file
			begin
				--	subtract deposits, debits and credits from the footer numbers should result in a zero
				select	@chkFile = sum(Amount) + sum(Items)
				from(	select	TranType	=	left(Col5, 1)
							,	Amount		=	sum(cast(isnull(Col4, 0) as money)) - @deposit	--	back out the deposits from the footer
							,	Items		=	case left(Col5, 1)
												when 'C' then count(1) - @countCR				--	back out the number credits from the footer
												when 'D' then count(1) - @countDR				--	back out the number debits from the footer
												else -999 end
						from	osi.ncrRemoteCaptureRaw
						where	RowType	= 5
						group by left(Col5, 1)
					)	d;

				--	the file doesn't balance...
				if @chkFile != 0
				begin
					set	@result	= @STAT_WARNING;	--	warning
					set	@detail	= '';
					--	collect the detail items...
					select	@detail = @detail
									+ '<tr><td align="center">'
										+ isnull(left(Col5, 1), '') + 'R</td>'
									+ '<td align="right">'
										+	cast(case left(Col5, 1)
											when 'D' then count(1)
											when 'C' then count(1)
											else -999 end as varchar) + '&nbsp;</td>'
									+ '<td align="right">' 
										+ cast(sum(cast(isnull(Col4, 0) as money)) as varchar) + '</td></tr>'
					from	osi.ncrRemoteCaptureRaw
					where	RowType	= 5
					group by left(Col5, 1);
					--	add the rest of the data
					set	@detail	= 'The footer data balanced for the <a href="' + @targetFile + '">Remote Capture file</a> '
								+ '(amt: ' + cast(@deposit as varchar) 
								+ ' dr: ' + cast(@countDR as varchar) 
								+ ' cr: ' + cast(@countCR as varchar) 
								+ ') but doesn''t match one or more values in the detail data below:'
								+ '<table><tr><td align="center" colspan="3">Detail Data</td></tr>'
								+ '<tr align="center"><td>Type</td><td>Items</td><td>Amount</td></tr>' 
								+ @detail + '</table>';
				end;
				else
				begin	--	the file "balances".
					--	add "new" Merchants from this run
					insert	osi.ncrMerchant
						(	MerchantId
						,	Merchant
						,	FedDistrict
						,	Tier
						,	CreatedBy
						,	CreatedOn
						)
					select	rc.MerchantId
						,	rc.Merchant
						,	rc.FedDistrict
						,	rc.Tier
						,	CreatedBy	= tcu.fn_UserAudit()
						,	CreatedOn	= getdate()
					from(	--	collect merchant information from the raw data
							select	MerchantId	= cast(Col3 as bigint)
								,	Merchant	= 'Merchant #' + Col3
								,	FedDistrict	= cast(left(tcu.fn_ZeroPad(ltrim(rtrim(Col2)), 9), 2) as tinyint)
								,	Tier		= 'Tier 1'
							from	osi.ncrRemoteCaptureRaw
							where	RowType = 5
							and		Col5	= 'C'
						)	rc	left join osi.ncrMerchant	m
							on	rc.MerchantId	= m.MerchantId
					where	m.MerchantId is null;

					--	add the records to the detail table...
					insert	osi.ncrRemoteCapture
						(	CaptureOn
						,	RecordType
						,	AccountNumber
						,	RTN
						,	FedDistrict
						,	MerchantId
						,	ClearingCategoryCode
						,	Amount
						,	TransactionType
						,	Sequence
						,	LoadedOn
						,	RunId
						,	ProcessStatus
						)
					select	h.captureOn
						,	RecordType				= d.RowType
						,	AccountNumber			= isnull(cast(d.Col1 as bigint), 0)
						,	RTN						= left(tcu.fn_ZeroPad(d.Col2, 9), 9)
						,	FedDistrict				= left(tcu.fn_ZeroPad(d.Col2, 9), 2)
						,	MerchantId				= isnull(cast(d.Col3 as bigint), 0)
						,	ClearingCategoryCode	= ''
						,	Amount					= cast(isnull(d.Col4, 0) as money)
						,	TransacitonType			= left(d.Col5, 1)
						,	Sequence				= cast(isnull(d.Col6, 0) as int)
						,	LoadedOn				= getdate()
						,	@RunId
						,	Status					= 'Loaded'
					from	osi.ncrRemoteCaptureRaw	d
					cross join
						(	select	captureOn = cast(Col1 + ' ' +  Col2 as datetime)
							from	osi.ncrRemoteCaptureRaw
							where	RowType	= 1
						)	h
					where	d.RowType = 5;

					--	collect the merchant account values from OSI
					--	* this is done because the query sometimes fail when performed inline
					insert	@osiMerchant
					select	distinct
							m.AccountNumber
						,	AccountAge		=	datediff(day, o.ContractDate, getdate())
					from	osi.ncrRemoteCapture	m
					join	openquery(OSI, '
							select	AcctNbr, ContractDate from osiBank.Acct
							where	CurrAcctStatCd	=	''ACT''
							and		MjAcctTypCd		in	(''BKCK'', ''CK'', ''SAV'')'
						)	o	on	m.AccountNumber = o.AcctNbr
					where	m.RunId				= @RunId
					and		m.TransactionType	= 'C';

					--	update the clearing category of the payor for reporting purposes
					update	d
					set		ClearingCategoryCode =	case
													when len(mi.ClearingCode) > 0 then mi.ClearingCode
														/*	If a merchant specific Clearing Category isn't provided then
															funds availability is base on:
															 1) tier and/or amount of the deposit
															 2)	the age of the merchants account
				 											 3)	the merchant/deposit fed district
														*/
													else case
														 when mi.Tier	= 'Premium'	then 'IMED'
														 when mi.Tier	= 'Standard'
														  and d.Amount	<= 5000		then 'IMED'
														 when mi.Tier	= 'Tier 1'
														  and d.Amount	<= 800		then 'IMED'
														 else	case	--	"seasoned" accounts
																when	mi.AccountAge > 29 then
																		case	--	availablity based on Fed Districts
																		when d.FedDistrict	in (10, 11, 30, 31)	then '20MM'	--	Local 2-Days
																		when d.FedDistrict	=	mi.FedDistrict	then '20MM'	--	Local 2-Days
																		else '30MM' end										--	Non-Local 5-Days
																else	case	-- "newer" accounts
																		when d.FedDistrict	in (10, 11, 30, 31)	then '40MM'	--	Extended Local 7-Days
																		when d.FedDistrict	=	mi.FedDistrict	then '40MM'	--	Extended Local 7-Days
																		else '50MM' end										--	Extended Non-Local 11-Days
																end
														 end
													end
						,	DepositBy			= mi.MerchantId
						,	DepositAccount		= mi.DepositAccount
					from	osi.ncrRemoteCapture	d
					join(	--	collect the merchant information
							select	rc.RunId
								,	m.MerchantId
								,	DepositAccount	=	rc.AccountNumber
								,	m.FedDistrict
								,	m.Tier
								,	ClearingCode	=	isnull(m.ClearingCategoryCode, '')
								,	StartRowId		=	rc.RemoteCaptureId
								,	EndRowId		= (	select	top 1 RemoteCaptureId
														from	osi.ncrRemoteCapture
														where	RunId			= rc.RunId
														and		RemoteCaptureId	> rc.RemoteCaptureId
														and		TransactionType	= 'C'
														group by RemoteCaptureId
														order by RemoteCaptureId
														)
								,	o.AccountAge
							from	osi.ncrRemoteCapture	rc
							join	osi.ncrMerchant			m
									on	rc.MerchantId	= m.MerchantId
							join	@osiMerchant			o
									on	rc.AccountNumber	= o.AccountNumber
									and	rc.TransactionType	= 'C'
							--	end merchant information
						)	mi	on	d.RunId				= mi.RunId
								and	d.RemoteCaptureId	between	mi.StartRowId
														and		isnull(mi.EndRowId, d.RemoteCaptureId)
					where	@RunId	= d.RunId
					and		'D'		= d.TransactionType;
				end;	--	the file balanced and could be processes
			end;		--	process the file with transactions
		end;			--	validate the file
	end;				--	newest file
	else
	begin
		--	delete the non-newest file...
		exec @result = tcu.File_action	@action		= 'erase'
									,	@sourceFile	= @sourceFile
									,	@targetFile	= null
									,	@overwrite	= 0
									,	@output		= @detail output;
		
	end;
end;					--	while loop (files exists)

if @fileId = 0
begin
	set	@result	= @STAT_INFO;	--	information
	set	@detail	= 'A Remote Capture file wasn''t available for loading.';
end;
--	if files were loaded during this run then build a SWIM file to transfer the money.
else if exists(	select	top 1 * from osi.ncrRemoteCapture
				where	RunId	= @RunId	)
begin
	exec @result = osi.ncrRemoteCapture_savSWIM	@RunId		= @RunId
											,	@ProcessId	= @ProcessId
											,	@ScheduleId	= @ScheduleId;
end;

PROC_EXIT:
--	clear the load data
truncate table osi.ncrRemoteCaptureRaw;

if @result != @STAT_SUCCESS or len(@detail) > 0
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