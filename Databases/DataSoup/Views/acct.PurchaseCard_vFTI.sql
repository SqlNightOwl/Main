use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[acct].[PurchaseCard_vFTI]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [acct].[PurchaseCard_vFTI]
GO
setuser N'acct'
GO
CREATE view acct.PurchaseCard_vFTI
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/07/2009
Purpose  :	Returns the Pruchase Card data in a format ready for import into FTI.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	'001'								-- Institution
	+	'00' +	case 
				when IsPersonal = 1
				then '727100'
				when len(AccountCd) = 15
				then isnull(cast(GLAccountOverride as char(6)),
							substring(AccountCd, 6, 6))
				else AccountCd
				end							-- GLNumber
	+	case len(AccountCd)
		when 15 then right(AccountCd, 4)
		else '9000' 
		end									-- CostCenter
	+	case TransactionCd
		when 'DR' then '03'
		else '01'
		end									-- TxnCode
	+	tcu.fn_ZeroPad(Amount * 100, 13)	-- Amount 
	+	case TransactionCd
		when 'DR' then cast(Vendor as char(6))
		else '000000'
		end									-- SourceId
	+	space(6)							-- ReconCode
	+	'AMX'								-- FundsType
	+	space(8)							-- UserId
	+	case isnumeric(ReportOn)
		when 1 then left(ReportOn, 4)
				+	right(ReportOn, 2)
		else replace(convert(varchar(8), LoadedOn, 1), '/', '')
		end									-- EffectiveDate
	+	'099'								-- DescriptionCode
	+	cast(isnull(TransactionDesc + ' ', '') +
			 isnull(Vendor, '')
			as char(31))					-- PurchaseDesc
	+	'.'									as Record
	,	case TransactionCd
		when 'DR'
		then	case IsPersonal
				when 1 then '801125'
				else '801120'
				end
		else '801120'
		end									as GLOffset
	,	isnull(FirstName + ' ', '') + 
		isnull(LastName, '')				as CardHolder
	,	cast(
			case IsPersonal
			when 1 then 'EXPENSE REIM: '
			else 'PURCHASE CARD: '
			end	+	isnull(FirstName + ' ', '') +
					isnull(LastName, '')
			as char(31))			as GLOffsetName
	,	cast(Amount * 100 as int)	as OffsetAmt
	,	RecordId
	,	LoadedOn
from	acct.PurchaseCard;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO