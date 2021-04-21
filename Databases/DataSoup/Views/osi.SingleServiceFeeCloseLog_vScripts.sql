use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[SingleServiceFeeCloseLog_vScripts]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[SingleServiceFeeCloseLog_vScripts]
GO
setuser N'osi'
GO
CREATE view osi.SingleServiceFeeCloseLog_vScripts
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/23/2008
Purpose  :	Used to build the final account closing scripts for the Single Service
			Fee process.  These scripts were created by S. Guyer.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/16/2009	Paul Hunter		Changed to work with DNA schema modificaitons.
06/23/2009	Paul Hunter		Added update script to change the Acct.AddrFormatCd
							to the Tax Owner Id.
————————————————————————————————————————————————————————————————————————————————
*/

select	AccountNumber
	,	CloseOn
	,	1						as ScriptType	--	change the Accounts Address Format Code
	,	cast(	'UPDATE osiBank.Acct '
			+	'SET AddrFormatCd = ''TXID'', DateLastMaint = sysdate '
			+	'WHERE AcctNbr = ' + cast(AccountNumber as varchar) + ' '
			+	'AND MjAcctTypCd = ''SAV'' '
			+	'AND CurrAcctStatCd != ''CLS'';'
			as varchar(600))	as Script
from	osi.SingleServiceFeeCloseLog

union all

select	AccountNumber
	,	CloseOn
	,	2						as ScriptType	--	deactivate the current minor
	,	cast(	'UPDATE osiBank.AcctMiAcctHist '
			+	'SET InactiveDate = trunc(sysdate + 1), DateLastMaint = sysdate '
			+	'WHERE InactiveDate is null '
			+	'AND AcctNbr in ('
					+	'SELECT AcctNbr FROM osiBank.Acct '
					+	'WHERE AcctNbr = ' + cast(AccountNumber as varchar) + ' '
					+	'AND MjAcctTypCd = ''SAV'' '
					+	'AND CurrAcctStatCd != ''CLS'');'
			as varchar(600))	as Script
from	osi.SingleServiceFeeCloseLog

union all

select	AccountNumber
	,	CloseOn
	,	3						as ScriptType	--	creates the new minor for Balance closeout allotment
	,	cast(	'INSERT INTO osiBank.AcctMiAcctHist '
			+	'( AcctNbr, EffDate, MjAcctTypCd, MiAcctTypCd, DateLastMaint, StartDate, RenewalYN ) '
			+	'SELECT AcctNbr, trunc(sysdate + 1), ''SAV'', ''SSFS'', sysdate, trunc(sysdate + 1), ''N'' '
			+	'FROM osiBank.Acct '
			+	'WHERE AcctNbr = ' + cast(AccountNumber as varchar) + ' '
			+	'AND MjAcctTypCd = ''SAV'' '
			+	'AND CurrAcctStatCd != ''CLS'';'
			as varchar(600))	as Script
from	osi.SingleServiceFeeCloseLog

union all

select	AccountNumber
	,	CloseOn
	,	4						as ScriptType	--	create the closed out allotment
	,	cast(	'INSERT INTO osiBank.AcctSubAcctAllot '
			+	'( AcctNbr, SubAcctNbr, AllotNbr, RtxnTypCd, AllotTypCd, FundTypCd, EffDate, NextDisbDate'
			+	', DateLastMaint, GraceDays, AchOrigYN, CombineChecksYN, CurrRev, RevDatetime, NextInstanceNbr'
			+	', ModifyPendingYN, CancelPendingYN, FutureRcvbYN, RegDYN, EarlyAllotYN ) '
			+	'SELECT AcctNbr, 1, 2555, ''CI'', ''BALC'', ''EL'', trunc(sysdate + 2) , trunc(sysdate + 2)'
			+	', sysdate, 0, ''N'', ''N'', 0, sysdate, 1'		--	these two lines match with the columns on
			+	', ''N'', ''N'', ''N'', ''N'', ''N'' '			--	the INSERT INTO part of the statement...
			+	'FROM osiBank.Acct '
			+	'WHERE AcctNbr = ' + cast(AccountNumber as varchar) + ' '
			+	'AND MjAcctTypCd = ''SAV'' '
			+	'AND CurrAcctStatCd != ''CLS'';'
			as varchar(600))	as Script
from	osi.SingleServiceFeeCloseLog;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO