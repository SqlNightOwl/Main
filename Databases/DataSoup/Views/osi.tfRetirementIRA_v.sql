use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfRetirementIRA_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[tfRetirementIRA_v]
GO
setuser N'osi'
GO
CREATE view osi.tfRetirementIRA_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/12/2010
Purpose  :	Provides Texans Financial with summary tranaciton information relating
			to Time Deposits for the preceeding month.  This view is built so that
			a simple CSV file can be generated that included column headers.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

-- bulid the column header row...
select	'Account Group'		as AccountGroup
	,	'"Minor Type'		as MinorType
	,	'"Branch"'			as Branch
	,	'"Fund Source"'		as FundSource
	,	'"Employee"'		as Employee
	,	'Balance'			as Balance

union all

select	AcctGrpNbr
	,	'"' + MinorDesc		+ '"'
	,	'"' + Branch		+ '"'
	,	'"' + FundSource	+ '"'
	,	'"' + OrigEmpl		+ '"'
	,	cast(Amount as varchar(25))
from	osi.tfTimeDeposit
where	Account			> 0
and		IsRetirement	= 'Y';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO