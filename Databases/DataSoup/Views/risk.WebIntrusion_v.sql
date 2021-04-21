use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[WebIntrusion_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[WebIntrusion_v]
GO
setuser N'risk'
GO
CREATE view risk.WebIntrusion_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/21/2006
Purpose  :	Used by the web intrusion detection application.  Information
				from this view should not go out in clear text.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	MemberNumber
	,	FirstName
	,	LastName
	,	SSN			= nullif(nullif(ssn, '000000000'), '999999999')
	,	JointSSN	= nullif(nullif(SecondarySSN, '000000000'), '999999999')
	,	Type		= 'Primary'
from	rpt.Member

union all

select	MemberNumber
	,	FirstName1
	,	LastName1
	,	SSN1
	,	null
	,	Type		= 'POD 1'
from	rpt.Member
where	isnumeric(SSN1) = 1

union all

select	MemberNumber
	,	FirstName2
	,	LastName2
	,	SSN2
	,	null
	,	Type		= 'POD 2'
from	rpt.Member
where	isnumeric(SSN2) = 1

union all

select	MemberNumber
	,	FirstName3
	,	LastName3
	,	SSN3
	,	null
	,	Type		= 'POD 3'
from	rpt.Member
where	isnumeric(SSN3) = 1
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO