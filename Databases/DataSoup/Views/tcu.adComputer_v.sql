use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[adComputer_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[adComputer_v]
GO
setuser N'tcu'
GO
CREATE view tcu.adComputer_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/09/2008
Purpose  :	View of TexansCU LDAP Computers.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	computer
	,	primaryOU	= substring(distinguishedName, 4, charindex(',', distinguishedName) - 4)
	,	OS
	,	managedBy
	,	isProduction
	,	isDevelopment
	,	isQA
	,	isDR
	,	isVirtual
	,	company
	,	department
	,	notes
	,	distinguishedName
from(	select	computer			=	name
			,	OS					=	operatingSystem + isnull('/' + operatingSystemServicePack, '')
			,	managedBy			=	substring(managedBy, charindex('CN=', managedBy) + 3, charindex(',', managedBy) - (charindex('CN=', managedBy) + 3))
			,	distinguishedName	=	cast(replace(distinguishedName, 'CN=' + name + ',', '') as varchar(255))
			,	isProduction		=	case charindex('OU=Prod', distinguishedName) when 0 then 0 else 1 end
			,	isDevelopment		=	case charindex('OU=Dev,', distinguishedName) when 0 then 0 else 1 end
			,	isQA				=	case charindex('OU=QA,' , distinguishedName) when 0 then 0 else 1 end
			,	isDR				=	case charindex('OU=Disa', distinguishedName) when 0 then 0 else 1 end
			,	isVirtual			=	case charindex('OU=VM,' , distinguishedName) when 0 then 0 else 1 end
			,	company
			,	department
			,	notes
		from	openquery (ADSI, '
				select	name
					,	location
					,	operatingSystem
					,	operatingSystemServicePack
					,	company
					,	department
					,	notes
					,	managedBy	
					,	distinguishedName
				from	''LDAP://texanscu''
				where	objectCategory = ''computer''')) c;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO