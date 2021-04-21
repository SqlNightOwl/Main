use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vPhoneList]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vPhoneList]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_vPhoneList
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/24/2008
Purpose  :	Returns the Employee/Department information for use by SharePoint as
			XML based nodes to be exported as the PhoneList.xml file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	top 100 percent Node
from	tcu.Employee_vPhoneListXml
order by
		LocationId
	,	dow
	,	Sequence
	,	Department
	,	FirstName
	,	LastName;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO