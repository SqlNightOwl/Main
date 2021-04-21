use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[UnPostedCardTransaction_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[UnPostedCardTransaction_process]
GO
setuser N'sst'
GO
CREATE procedure [sst].[UnPostedCardTransaction_process]
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/12/2010
Purpose  :	Retrieves details about Card Transactions from the prior day that
			haven't posted to the Members Account.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		varchar(75)
,	@detail		varchar(4000)
,	@result		int
,	@rows		int

declare	@txns	table
	(	CardNbr	char(16)	not null
	,	RefNbr	varchar(10)	not null
	,	TxnAmt	varchar(10)	not null
	,	FeeAmt	varchar(10)	not null
	,	Settle	char(19)	not null
	,	RowId	int identity primary key
	);

--	initialize the variables...
select	@cmd		= 'insert @txns select * from openquery(OSI, ''select * from texans.sst_UnPostedCardTxn_vw'')'
	,	@detail		= '<style type="text/css">TD{text-align:right} .hdr{text-align:center;}</style>'
					+ '<p>There were # unposted card transactions for ' + convert(char(10), getdate() -1, 101) + '.</p>'
					+ '<table><tr><td class="hdr">Card Number</td>'
					+ '<td class="hdr">Reference</td>'
					+ '<td class="hdr">Amount</td>'
					+ '<td class="hdr">Fee</td>'
					+ '<td class="hdr">Settles</td></tr>'
	,	@result		= 0;

begin try
	--	retrieve unposted transactions from yesterday...
	insert	@txns
		(	CardNbr
		,	RefNbr
		,	TxnAmt
		,	FeeAmt
		,	Settle
		)
	select	cast(ExtCardNbr		as char(16))
		,	cast(RetRefNbr		as varchar(10))
		,	cast(cast(TxnAmt	as money) as varchar(10))
		,	cast(cast(TxnFeeAmt as money) as varchar(10))
		,	cast(SettleOn		as char(19))
	from	openquery(OSI, '
			select	ExtCardNbr
				,	RetRefNbr
				,	TxnAmt
				,	TxnFeeAmt
				,	SettleOn
			from	texans.sst_UnPostedCardTxn_vw');

	--	determine the number of transactions affected
	set	@rows = @@rowcount;

	set	@detail = replace(@detail, '#', isnull(cast(nullif(@rows, 0) as varchar(10)), 'no'))

	--	display the transaction details...
	if @rows > 0
	begin
		select	@detail	= @detail 
						+ '<tr><td>'	+ CardNbr
						+ '</td><td>'	+ RefNbr
						+ '</td><td>'	+ TxnAmt
						+ '</td><td>'	+ FeeAmt
						+ '</td><td>'	+ Settle
						+ '</td></tr>'
		from	@txns;
		--	complete the table and set the return value...
		select	@detail = @detail + '</table>'
			,	@result	= 2;	--	information
	end;
end try
begin catch
	exec tcu.ErrorDetail_get @detail out;
	set	@result	= 1;	--	failure
end catch;

exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @cmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO