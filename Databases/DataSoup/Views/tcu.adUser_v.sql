use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[adUser_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[adUser_v]
GO
setuser N'tcu'
GO
CREATE view tcu.adUser_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/07/2007
Purpose  :	View of TexansCU LDAP Users.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/03/2009	Paul Hunter		Added explicit values from AD that are being updated
							by the HR Sync Service.
							Changed to use SQL-92 style
————————————————————————————————————————————————————————————————————————————————
*/

select	lower(cast(samAccountName as varchar(50)))			as samUserName
	,	name												as FullName
	,	lower(userPrincipalName)							as userPrincipalName
	,	lower(mail)											as Email
	,	case
		when patindex('E[0-9][0-9][0-9][0-9][0-9]%', samAccountName) > 0
		and len(samAccountName) < 8 then cast(substring(samAccountName, 2, 6) as int)
		else 0 end											as EmployeeNumber
	,	EmployeeNumber										as EmployeeNumberAD
	,	isnull(EmployeeId, 0)								as EmployeeId
	,	givenName											as FirstName
	,	sn													as LastName
	,	Title
	,	Company
	,	StreetAddress										as Address1
	,	l													as City
	,	st													as State
	,	PostalCode
	,	Department
	,	replace(physicalDeliveryOfficeName, '-', '.')		as Phone
	,	telephoneNumber										as Extension
	,	replace(facsimileTelephoneNumber, '-', '.')			as Fax
	,	HomePhone
	,	Pager
	,	Mobile
	,	substring(Manager, 4, charindex(',', Manager) - 4)	as Manager
	,	Notes
	,	case
		when patindex('E[0-9][0-9][0-9][0-9][0-9][0-9]'	, samAccountName)
		   + patindex('E[0-9][0-9][0-9][0-9][0-9]'		, samAccountName) > 0 then 1
		else 0 end											as IsEmployee
	,	cast(charindex('OU=Users,'		, distinguishedName) as bit)	as IsUser
	,	cast(charindex('OU=Admins,'		, distinguishedName) as bit)	as IsAdmin
	,	cast(charindex('OU=SrvAccts,'	, distinguishedName) as bit)	as IsServiceAccount
	,	cast(charindex('OU=Terminated,'	, distinguishedName) as bit)	as IsTerminated
	,	cast(charindex('OU=Mobile,'		, distinguishedName) as bit)	as IsMobile
	,	cast(charindex('OU=Resources,'	, distinguishedName) as bit)	as IsResource
	,	DistinguishedName
from	openquery (ADSI, '
select	company
	,	department
	,	distinguishedName
	,	employeeId
	,	EmployeeNumber
	,	facsimileTelephoneNumber
	,	givenName
	,	homePhone
	,	l
	,	mail
	,	manager
	,	mobile
	,	name
	,	notes
	,	pager
	,	physicalDeliveryOfficeName
	,	postalCode
	,	samAccountName
	,	sn
	,	st
	,	streetAddress
	,	telephoneNumber
	,	title
	,	userPrincipalName
from	''LDAP://texanscu''
where	objectCategory = ''user''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO