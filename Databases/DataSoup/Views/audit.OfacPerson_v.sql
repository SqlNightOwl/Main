use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[OfacPerson_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [audit].[OfacPerson_v]
GO
setuser N'audit'
GO
CREATE view audit.ofacPerson_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/04/2008
Purpose  :	Used for exporting OFAC Person data for loading by the Audits department
			into the Bridger system
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

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
		from	texans.ofac_Person_vw');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO