use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[VINtek_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [lnd].[VINtek_v]
GO
setuser N'lnd'
GO
CREATE view lnd.VINtek_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/06/2010
Purpose  :	View used for extracting the VINtek Title Lien file.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/19/2010	Paul Hunter		Added new Collateral Type column.
————————————————————————————————————————————————————————————————————————————————
*/

select	'Record Type'		as RecordType
	,	'ETL Action'		as ETLAction
	,	'Lien Holder Id'	as LienHolderId
	,	'Account Id'		as AcctNbr
	,	'VIN'				as VIN
	,	'Year'				as [Year]
	,	'Make'				as Make
	,	'Model'				as Model
	,	'Dealer Id'			as DealerId
	,	'Borrower'			as Borrower
	,	'Co-Borrower'		as CoBorrower
	,	'Address 1'			as Address1
	,	'Address 2'			as Address2
	,	'City'				as City
	,	'State'				as [State]
	,	'Zip'				as Zip
	,	'Lien Start'		as LienStart
	,	'Lien End'			as LienEnd
	,	'Lien Amount'		as LienAmount
	,	'Lien Balance'		as LienBalance
	,	'Lien Type'			as LienType
	,	'Title State'		as TitleState
	,	'Title Number'		as TitleNumber
	,	'Status'			as [Status]
	,	'Title Flag'		as TitleFlag
	,	'Mileage'			as Mileage
	,	'Image Id'			as ImageId
	,	'Courier'			as Courier
	,	'Shipping Method'	as ShippingMethod
	,	'Saturday Delivery'	as SaturdayDelivery
	,	'Courier Account'	as CourierAccount
	,	'Sign-off'			as SignOff
	,	'Signature Flag'	as SignatureFlag
	,	'New Account Id'	as NewAccountId
	,	'Member Number'		as MemberNumber
	,	'New VIN'			as NewVIN
	,	'Collateral Type'	as CollateralType

union all

select	v.RecordType
	,	v.ETLAction
	,	'3215'									as LienHolderId
	,	cast(v.AcctNbr as varchar(22))
	,	v.PropId								as VIN
	,	v.PropYear
	,	v.PropMake
	,	v.PropModel
	,	cast(v.DealerNbr as varchar(22))
	,	v.Borrower
	,	v.CoBorrower
	,	v.Address1
	,	v.Address2
	,	v.City
	,	v.StateCd
	,	v.ZipCd
	,	convert(char(10), v.ContractDate, 101)	as LienStart
	,	convert(char(10), v.MaturesOn, 101)		as LienEnd
	,	null									as LienAmount
	,	null									as LienBalance
	,	'Retail'								as LienType
	,	v.TitleStateCd
	,	null									as TitleNumber
	,	v.StatusCd
	,	null									as TitleFlag
	,	cast(v.PropVehicleOdometer as varchar(10))
	,	null									as ImageId
	,	'001'									as Courier
	,	'001'									as ShippingMethod
	,	'0'										as SaturdayDelivery
	,	null									as CourierAccount
	,	'1'										as SignOff
	,	'0'										as SignatureFlag
	,	cast(v.NewAcctNbr	as varchar(22))
	,	cast(v.MemberNbr	as varchar(22))
	,	null									as NewVIN
	,	v.CollateralType
from	lnd.VINtek	v
cross apply
	(	select	cast(convert(char(10), getdate(), 121) as datetime) as Today	)	d
where(	v.LoadedOn	= d.Today
	or	v.UpdatedOn	= d.Today );
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO