use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancingLog_vReport]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[ATMBalancingLog_vReport]
GO
setuser N'sst'
GO
create view sst.ATMBalancingLog_vReport
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/26/2009
Purpose  :	Used to produce an extract of the results for use by end users.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	'Report On'				as ReportOn
	,	'Terminal'				as Terminal
	,	'Withdrawal'			as Withdrawal
	,	'Fee'					as Fee
	,	'Net Withdrawal'		as NetWithdrawal
	,	'Deposit/Save'			as DepositSave
	,	'Deposit/Check'			as DepositCheck
	,	'Deposit/Credit Card'	as DepositCrCard
	,	'Deposit/Credit Line'	as DepositCrLine
	,	'Deposit'				as Deposit

union all

select	convert(char(10), ReportOn, 121)
	,	Terminal
	,	cast(Withdrawal as varchar(25))
	,	cast(Fee as varchar(25))
	,	cast(NetWithdrawal as varchar(25))
	,	cast(DepositSave as varchar(25))
	,	cast(DepositCheck as varchar(25))
	,	cast(DepositCrCard as varchar(25))
	,	cast(DepositCrLine as varchar(25))
	,	cast(Deposit as varchar(25))
from	sst.ATMBalancingLog;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO