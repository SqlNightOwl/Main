use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ncr_RemoteCaptureFundsAvailability]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ncr_RemoteCaptureFundsAvailability]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ncr_RemoteCaptureFundsAvailability
	@CaptureOn	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/03/2008
Purpose  :	Provides the release schedule for Remote Capture deposits for the
			date provided.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set	@CaptureOn = convert(char(10), isnull(@CaptureOn, getdate()), 121);

select	CaptureOn	= @CaptureOn
	,	dtl.Merchant
	,	dtl.DepositAccount
	,	dtl.ClearCatCd
	,	dtl.Availability
	,	fa.ReleaseOn
	,	dtl.Amount
from(	--	collect the deposits by Merchant
		select	m.Merchant
			,	rc.DepositAccount
			,	cc.ClearCatCd
			,	cc.Availability
			,	Amount		= sum(rc.Amount)
		from	osi.ncrRemoteCapture	rc
		join	osi.ncrMerchant			m
				on	rc.DepositBy = m.MerchantId
		join	osi.FundsAvailability_v	cc
				on	rc.ClearingCategoryCode = cc.ClearCatCd
		where	@CaptureOn			= convert(char(10), rc.CaptureOn, 101)
		and		rc.TransactionType	= 'D'
		group by
				m.Merchant
			,	rc.DepositAccount
			,	cc.ClearCatCd
			,	cc.Availability
	)	dtl
join(	--	collect the release dates for the various Clearing Categories
		select	ClearCatCd	
			,	ReleaseOn	= tcu.fn_NextBusinessDay(@CaptureOn, Availability)
		from	osi.FundsAvailability_v
	)	fa	on	dtl.ClearCatCd = fa.ClearCatCd
order by 
		dtl.Merchant
	,	dtl.DepositAccount
	,	dtl.Availability;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO