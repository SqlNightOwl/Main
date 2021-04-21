use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[RewardsNow_vClosedDebitCard]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[RewardsNow_vClosedDebitCard]
GO
setuser N'osi'
GO
CREATE view osi.RewardsNow_vClosedDebitCard
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/07/2008
Purpose  :	View to create Closed debit card file for RewardsNow 
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	AcctNbr
	,	ClosedPeriod
from	openquery(OSI, '
		select	AcctNbr
			,	to_char(DateLastMaint,''MM/YYYY'') as ClosedPeriod
		from	osiBank.Acct
		where	MjAcctTypCD		= ''CK''
		and		CurrAcctStatCd	= ''CLS''
		and		DateLastMaint	between texans.pkg_Date.FirstDay_Months(-1)
									and	texans.pkg_Date.LastDay_Months(-1)');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO