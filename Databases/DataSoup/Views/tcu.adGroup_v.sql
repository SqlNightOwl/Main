use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[adGroup_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[adGroup_v]
GO
setuser N'tcu'
GO
CREATE view tcu.adGroup_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/07/2007
Purpose  :	View of TexansCU LDAP Groups.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	samGroupName	= cast(samAccountName as varchar(50))
	,	displayName		= replace(name, '_', ' ')
	,	eMail			= lower(mail)
	,	description		= info
	,	isDistribution	= case charindex('OU=Distribution,'	, distinguishedName) when 0 then 0 else 1 end
	,	isSecurity		= case charindex('OU=Security,'		, distinguishedName) when 0 then 0 else 1 end
	,	distinguishedName
	,	managedBy
from	openquery
(	ADSI
, 'select	name
	,	samAccountName
	,	mail
	,	distinguishedName
	,	info
	,	managedBy
from	''LDAP://texanscu'' 
where	ObjectCategory	= ''Group''
and		ObjectClass		= ''Group''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO