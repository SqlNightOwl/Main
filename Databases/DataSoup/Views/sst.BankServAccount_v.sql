use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServAccount_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[BankServAccount_v]
GO
setuser N'sst'
GO
CREATE view sst.BankServAccount_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/03/2007
Purpose  :	Produces the BankServ_GFX record for exporting the BankServ data.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record	= cast(AccountNumber as char(15))
				+ Institution
				+ CostCenter
				+ Branch
				+ AccountName1
				+ AccountName2
				+ AddressLine1
				+ AddressLine2
				+ CityName
				+ StateCode
				+ ZipCode
				+ Phone
				+ Fax
				+ Email
				+ CustomerId
				+ AccountType
				+ AnalyzedFlag
				+ Department
				+ HoldFlag
				+ FrozenFlag
				+ LockedFlag
				+ WaiveFeeFlag
				+ AccountBalance
	,	AccountNumber
from	sst.BankServAccount;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO