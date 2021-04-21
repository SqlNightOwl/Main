use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[adGroupUser_vMatrix]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[adGroupUser_vMatrix]
GO
setuser N'tcu'
GO
CREATE view tcu.adGroupUser_vMatrix
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/28/2007
Purpose  :	Expanded matrix view of LDAP Groups and the associated Users.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/
select	ug.samGroupName
	,	groupDisplayName		= g.DisplayName
	,	groupEmail				= g.eMail
	,	groupDescription		= g.Description
	,	IsDistributionGroup		= g.IsDistribution
	,	IsSecurityGroup			= g.IsSecurity
	,	groupDistinguishedName	= g.distinguishedName
	,	ug.samUserName
	,	ug.EmployeeNumber
	,	u.FullName
	,	u.userPrincipalName
	,	userEmail				= u.Email
	,	u.IsUser
	,	u.IsAdmin
	,	u.IsServiceAccount
	,	u.IsTerminated
	,	u.IsMobile
	,	u.IsResource
	,	userDistinguishedName	= u.distinguishedName
	,	userIsActiveInGroup		= ug.IsActive
	,	ug.CreatedOn
	,	ug.CreatedBy
	,	ug.UpdatedOn
	,	ug.UpdatedBy
from	tcu.adGroupUser	ug
join	tcu.adUser_v	u
	on	ug.samUserName = u.samUserName
join	tcu.adGroup_v	g
	on	ug.samGroupName = g.samGroupName
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO