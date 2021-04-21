use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[SingleServiceFee_vMail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[SingleServiceFee_vMail]
GO
setuser N'osi'
GO
CREATE view osi.SingleServiceFee_vMail
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/10/2008
Purpose  :	Provides BCP exportable results for Single Service Fee mailings.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	'Account'		as AcctNbr
	,	'Posted'		as Posted
	,	'Balance'		as Balance
	,	'Member Number'	as MemberNbr
	,	'Member Name'	as Member
	,	'Address 1'		as Address1
	,	'Address 2'		as Address2
	,	'City'			as City
	,	'State'			as State
	,	'Zip Code'		as Zip
	,	'Country'		as Ctry
	,	0				as RowType

union all

select	cast(AcctNbr as varchar(25))
	,	convert(char(10), PostedOn, 101)
	,	cast(cast(EndingBalance as money) as varchar(30))
	,	cast(MemberAgreeNbr as varchar(25))
	,	MemberName
	,	Address1
	,	Address2
	,	CityName
	,	StateCd
	,	ZipCd
	,	CtryCd
	,	1
from	openquery(OSI, '
		select	AcctNbr
			,	PostedOn
			,	EndingBalance
			,	MemberAgreeNbr
			,	MemberName
			,	Address1
			,	Address2
			,	CityName
			,	StateCd
			,	ZipCd
			,	CtryCd
		from	texans.SnglSrvcFee_MailingList_vw');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO