use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenMatches_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [audit].[fincenMatches_ins]
GO
setuser N'audit'
GO
CREATE procedure audit.fincenMatches_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/04/2008
Purpose  :	Extracts new data from OSI for FinCEN comparisons using the OFAC views.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

--	first load the Organizations
truncate table audit.fincenBusinessOSI;

insert	audit.fincenBusinessOSI
	(	OrgName
	,	Address
	,	City
	,	State
	,	Zip
	,	MemberNumber
	,	TaxId
	,	OrgNumber
	,	OrgNameCode	)
select	OrgName
	,	Address
	,	City
	,	State
	,	Zip
	,	MemberNumber
	,	TaxId
	,	OrgNumber
	,	rtrim(tcu.fn_DoubleMetaPhone(OrgName))	as OrgNameCode
from	openQuery(OSI, '
		select	OrgName
			,	Address
			,	City
			,	State
			,	Zip
			,	MemberNumber
			,	TaxId
			,	OrgNumber
		from	texans.ofac_Company_vw');

--	next load the Persons
truncate table audit.fincenPeopleOSI;

insert	audit.fincenPeopleOSI
	(	FirstName
	,	LastName
	,	Address
	,	CityName
	,	StateCd
	,	ZipCd
	,	MemberNumber
	,	TaxId
	,	DateBirth
	,	PersonNumber
	,	NameCode	)
select	FirstName
	,	LastName
	,	Address
	,	CityName
	,	StateCd
	,	ZipCd
	,	MemberNumber
	,	TaxId
	,	DateBirth
	,	PersonNumber
	,	rtrim(tcu.fn_DoubleMetaPhone(isnull(FirstName, '') + isnull(LastName, '')))	as NameCode
from	openquery(OSI, '
		select	FirstName
			,	LastName
			,	Address
			,	CityName
			,	StateCd
			,	ZipCd
			,	MemberNumber
			,	TaxId
			,	DateBirth
			,	PersonNumber
		from	texans.ofac_Person_vw')

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO