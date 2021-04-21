use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenMatches_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [audit].[fincenMatches_v]
GO
setuser N'audit'
GO
CREATE view audit.fincenMatches_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	05/18/2007
Purpose  :	Attempts to match FinCEN data to extracted OSI data in the tables
			fincen_People and fincen_Business based on similarities in the name
			and exact matches on TaxId.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
10/10/2007	Paul Hunter		Moved to tcuDataSoup
10/12/2007	Paul Hunter		Changed to 90% confidence matching per Anita Mugg.
05/08/2007	Vivian Liu		Retrieve OSITaxId.
————————————————————————————————————————————————————————————————————————————————
*/

select	TrackingNumber	= 'Tracking Number'
	,	MatchType		= '"Match Type"'
	,	MatchReason		= '"Match Reason"'
	,	MemberNumber	= 'Member Number'
	,	FinCenName		= '"FinCEN Name"'
	,	MemberName		= '"Member Name"'
	,	Address			= '"Address"'
	,	City			= '"City"'
	,	State			= '"State"'
	,	Zip				= '"Zip Code"'
	,	FinCenTaxId		= '"FinCEN Tax Id"'
	,	OSITaxId		= '"OSI Tax Id"'
	,	Ceratinty		= 'Ceratinty'
	,	RowType			= 0

union

select	cast(f.TrackingNumber as varchar)
	,	'"INDIVIDUAL"'	--	Type
	,	'"Match SSN"'	--	Reason
	,	cast(o.MemberNumber as varchar)
	,	tcu.fn_QuoteString(isnull(f.FirstName + ' ', '') + isnull(f.LastName, ''))
	,	tcu.fn_QuoteString(isnull(o.FirstName + ' ', '') + isnull(o.LastName, ''))
	,	tcu.fn_QuoteString(o.Address)
	,	tcu.fn_QuoteString(o.CityName)
	,	tcu.fn_QuoteString(o.StateCd)
	,	tcu.fn_QuoteString(o.ZipCd)
	,	tcu.fn_QuoteString(f.Number)
	,	tcu.fn_QuoteString(o.TaxId)
	,	'100'	--	certainty
	,	1		--	row type
from	audit.fincenPeopleOSI		o
Join	audit.fincenPeopleMaster	f
		on	o.TaxId = f.Number
where	f.NumberType = 'SOCIAL SECURITY NUMBER'

union

select	cast(f.TrackingNumber as varchar)
	,	'"BUSINESS"'		--	Type
	,	'"Match Tax ID"'	--	Reason
	,	cast(o.MemberNumber as varchar)
	,	tcu.fn_QuoteString(f.BusinessName)
	,	tcu.fn_QuoteString(o.OrgName)
	,	tcu.fn_QuoteString(o.Address)
	,	tcu.fn_QuoteString(o.City)
	,	tcu.fn_QuoteString(o.State)
	,	tcu.fn_QuoteString(o.Zip)
	,	tcu.fn_QuoteString(f.Number)
	,	tcu.fn_QuoteString(o.TaxId)
	,	'100'	--	Ceratinty
	,	1		--	row type
from	audit.fincenBusinessOSI		o
join	audit.fincenBusinessMaster	f
		on	o.TaxId = f.Number
where	f.NumberType in ('EMPLOYER IDENTIFICATION NUMBER', 'TAX IDENTIFICATION NUMBER')

union

select	cast(f.TrackingNumber as varchar)
	,	'"BUSINESS"'			--	Type
	,	'"Match Business Name"'	--	Reason
	,	cast(o.MemberNumber as varchar)
	,	tcu.fn_QuoteString(f.BusinessName)
	,	tcu.fn_QuoteString(o.OrgName)
	,	tcu.fn_QuoteString(o.Address)
	,	tcu.fn_QuoteString(o.City)
	,	tcu.fn_QuoteString(o.State)
	,	tcu.fn_QuoteString(o.Zip)
	,	tcu.fn_QuoteString(f.Number)
	,	tcu.fn_QuoteString(o.TaxId)
	,	cast(tcu.fn_FuzzyMatchPercent(o.OrgName, f.BusinessName) as varchar)
	,	1		--	row type
from	audit.fincenBusinessOSI		o
join	audit.fincenBusinessMaster	f
		on	o.OrgNameCode = f.BusinessNameCode
where	tcu.fn_FuzzyMatchPercent(o.OrgName, f.BusinessName) > 89
and		f.BusinessName	is not null

union

select	cast(f.TrackingNumber as varchar)
	,	'"BUSINESS"'		--	Type
	,	'"Match DBA Name"'	--	Reason
	,	cast(o.MemberNumber as varchar)
	,	tcu.fn_QuoteString(f.DbaName)
	,	tcu.fn_QuoteString(o.OrgName)
	,	tcu.fn_QuoteString(o.Address)
	,	tcu.fn_QuoteString(o.City)
	,	tcu.fn_QuoteString(o.State)
	,	tcu.fn_QuoteString(o.Zip)
	,	tcu.fn_QuoteString(f.Number)		
	,	tcu.fn_QuoteString(o.TaxId)
	,	cast(tcu.fn_FuzzyMatchPercent(o.OrgName, f.DbaName) as varchar)
	,	1		--	row type
from	audit.fincenBusinessOSI			o
join	audit.fincenBusinessMaster	f
		on	o.OrgNameCode = f.DbaNameCode
where	tcu.fn_FuzzyMatchPercent(o.OrgName, f.DbaName) > 89
and		f.DbaNameCode	is not null

union

select	cast(f.TrackingNumber as varchar)
	,	'"INDIVIDUAL"'	--	Type
	,	'"Match Name"'	--	Reason
	,	cast(o.MemberNumber as varchar)
	,	tcu.fn_QuoteString(isnull(f.FirstName + ' ', '') + isnull(f.LastName, ''))
	,	tcu.fn_QuoteString(isnull(o.FirstName + ' ', '') + isnull(o.LastName, ''))
	,	tcu.fn_QuoteString(o.Address)
	,	tcu.fn_QuoteString(o.CityName)
	,	tcu.fn_QuoteString(o.StateCd)
	,	tcu.fn_QuoteString(o.ZipCd)
	,	tcu.fn_QuoteString(f.Number)
	,	tcu.fn_QuoteString(o.TaxId)
	,	cast(tcu.fn_FuzzyMatchPercent(	isnull(f.FirstName, '') + isnull(f.LastName, '')
									 ,	isnull(o.FirstName, '') + isnull(o.LastName, '')) as varchar)
	,	1		--	row type
from	audit.fincenPeopleOSI		o
join	audit.fincenPeopleMaster	f
		on	o.NameCode = f.NameCode
where	tcu.fn_FuzzyMatchPercent(isnull(f.FirstName, '') + isnull(f.LastName, '')
							,	 isnull(o.FirstName, '') + isnull(o.LastName, '')) > 89

union

select	cast(f.TrackingNumber as varchar)
	,	'"INDIVIDUAL"'	--	Type
	,	'"Match Alias"'	--	Reason
	,	cast(o.MemberNumber as varchar)
	,	tcu.fn_QuoteString(isnull(f.AliasFirstName	+ ' ', '') + isnull(f.AliasLastName, ''))
	,	tcu.fn_QuoteString(isnull(o.FirstName		+ ' ', '') + isnull(o.LastName, ''))
	,	tcu.fn_QuoteString(o.Address)
	,	tcu.fn_QuoteString(o.CityName)
	,	tcu.fn_QuoteString(o.StateCd)
	,	tcu.fn_QuoteString(o.ZipCd)
	,	tcu.fn_QuoteString(f.Number)
	,	tcu.fn_QuoteString(o.TaxId)
	,	cast(tcu.fn_FuzzyMatchPercent(	isnull(f.AliasLastName, '') + isnull(f.AliasLastName, '')
								  	,	isnull(o.FirstName, '') + isnull(o.LastName, '')) as varchar)
	,	1		--	row type
from	audit.fincenPeopleOSI		o
join	audit.fincenPeopleMaster	f
		on	o.NameCode = f.AliasCode
where	tcu.fn_FuzzyMatchPercent(isnull(o.FirstName, '') + isnull(o.LastName, '')
							,	 isnull(f.AliasFirstName, '') + isnull(f.AliasLastName, '')) > 89
and		isnull(f.AliasFirstName, f.AliasLastName) is not null;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO