use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[pcsATMFeeRefund_load]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[pcsATMFeeRefund_load]
GO
setuser N'osi'
GO
CREATE procedure osi.pcsATMFeeRefund_load
	@ProcessId	smallint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/24/2009
Purpose  :	Loads PCS foreign AMT fees from OSI and calculates the refund amount.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@acct		bigint
,	@accum		smallmoney
,	@amount		smallmoney
,	@beginOn	datetime
,	@charged	smallmoney
,	@maxFee		smallmoney
,	@postOn		datetime
,	@result		int
,	@retention	int
,	@row		int
,	@txn		int	

declare	@transactions	table
	(	row				int			identity primary key
	,	AccountNbr		bigint		not null
	,	TransactionNbr	int			not null
	,	FeeCharged		smallmoney	not null
	,	TotalRefunded	smallmoney	not null
	);

--	initialize the variables...
select	@acct		= 0
	,	@maxFee		= cast(tcu.fn_ProcessParameter(@ProcessId, 'Max Fee Refund') as smallmoney)
	,	@postOn		= convert(char(10), getdate() - 1, 121)
	,	@result		= 0
	,	@retention	= cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int) * -1
	,	@row		= 0

--	set the beginning date to the first day of the month...
set	@beginOn = (@postOn - day(@postOn)) + 1

--	load ATM transactions posted yesterday in OSI that haven't already been posted...
insert	osi.pcsATMFeeRefund
	(	AccountNumber
	,	TransactionNumber
	,	PostOn
	,	FeeCharged
	,	FeeRefunded
	)
select	o.AcctNbr
	,	o.RtxnNbr
	,	o.OrigPostDate
	,	o.TxnFeeAmt
	,	0
from	openquery(OSI, '
		select	AcctNbr
			,	RtxnNbr
			,	OrigPostDate
			,	TxnFeeAmt
		from	texans.pcs_ATMFeeRefund_vw') o
left join
		osi.pcsATMFeeRefund	l
		on	o.AcctNbr = l.AccountNumber
		and	o.RtxnNbr = l.TransactionNumber
where	l.PostOn is null	--	not already loaded...
order by
		o.OrigPostDate
	,	o.AcctNbr
	,	o.RtxnNbr;

--	if any ATM Fees were loaded then 
if @@rowcount > 0
begin
	--	collect the accounts to be potentially be credited...
	insert	@transactions
		(	AccountNbr
		,	TransactionNbr
		,	FeeCharged
		,	TotalRefunded
		)
	select	d.AccountNumber
		,	d.TransactionNumber
		,	d.FeeCharged
		,	isnull(s.TotalRefunded, 0)
	from	osi.pcsATMFeeRefund	d
	left join
		(	--	summarize by accounts the total amount refunded for the current month...
			select	AccountNumber
				,	sum(FeeRefunded) as TotalRefunded
			from	osi.pcs_ATMFeeRefund
			where	PostOn	between @beginOn
								and	@postOn
			group by AccountNumber )	s
			on	d.AccountNumber = s.AccountNumber
	where	d.PostOn		= @postOn	--	transactions posted yesterday
	and	(	s.TotalRefunded	< @maxFee	--	and haven't exceeded the maximum refund amount
		or	s.TotalRefunded is null	)	--	 or haven't had any refund yet
	order by
			d.AccountNumber
		,	d.TransactionNumber;

	--	loop thru the accounts to be potentially be credited...
	while exists (	select	top 1 row from @transactions
					where	row	> @row	)
	begin
		--	load the next available record...
		select	top 1
				@accum		=	case AccountNbr
								when @acct then @accum	--	keep the accumulator if on the same account, otherwise...
								else TotalRefunded		--	...reset the accumulator to the amount refunded this month
								end + FeeCharged
			,	@acct		=	AccountNbr
			,	@txn		=	TransactionNbr
			,	@charged	=	FeeCharged
			,	@amount		=	0
			,	@row		=	row
		from	@transactions
		where	row			> @row
		order by row;

		--	calculate the amount to be refunded..
		set	@amount	=	case
						when @accum <=	@maxFee then @charged
						else @maxFee - (@accum - @charged)
						end;

		--	update if the amount to refund is > 0...
		if @amount > 0
		begin
			update	osi.pcsATMFeeRefund
			set		FeeRefunded			= @amount
			where	AccountNumber		= @acct
			and		TransactionNumber	= @txn;
		end;
	end;
end;
else
begin
	set	@result	= 2;	--	informational
end;

--	remove legacy data...
delete	osi.pcsATMFeeRefund
where	PostOn	< dateadd(day, @retention, @postOn)

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO