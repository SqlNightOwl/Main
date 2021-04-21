use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_getForAD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_getForAD]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_getForAD
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	02/17/2006
Purpose  :	Returns a dataset of records present in both the HR Database and
			Active Directory.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/13/2006	Paul Hunter		Changed datasource to the view tcuEmployee_v.
07/08/2008	Paul Hunter		Moved to SQL 2005 schema.
03/03/2009	Paul Hunter		Added Company attribute.
							Changed to ANSI SQL92 format query.
————————————————————————————————————————————————————————————————————————————————
*/
as

set	nocount on;

select	EmployeeNumber
	,	EmployeeName
	,	PrincipalName
	,	LastName
	,	PreferredName
	,	HiredOn
	,	Company
	,	case left(DepartmentCode, 3)
		when 'SBU' then 'Branch - '
		when 'RBU' then 'Branch - '
		when 'RBS' then 'Branch - '
		else '' end + Department					as Department
	,	DepartmentCode
	,	JobTitle
	,	isnull(EmailAddress		, '')				as EmailAddress
	,	isnull(Telephone		, '972.348.2000')	as Telephone
	,	case rtrim(isnull(Ext, ''))
		when '' then right(Telephone, 4)
		else left(rtrim(Ext), 4) end				as Ext
	,	isnull(Fax				, '')				as Fax
	,	isnull(Category			, '')				as Category
	,	isnull(Type				, '')				as Type
	,	isnull(Gender			, '')				as Gender
	,	isnull(Location			, '')				as Location
	,	isnull(LocationCode		, '')				as LocationCode
	,	isnull(Pager			, '')				as Pager
	,	isnull(Mobile			, '')				as Mobile
	,	isnull(Address1			, '')				as Address1
	,	isnull(Address2			, '')				as Address2
	,	isnull(City				, '')				as City
	,	isnull(cast(ZipCode as varchar(5)), '') 	as ZipCode
	,	isnull(State			, '')				as State
	,	PersonId
	,	isnull(Classification	, '')				as Classification
	,	isnull(ManagerName		, '')				as ManagerName
	,	isnull(EmployeePhoto	, '')				as EmployeePhoto
	,	RecordSource
from	tcu.Employee_v
where	RecordSource		= 'Both'
and		isnull(IsActive, 1)	= 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Employee_getForAD]  TO [texanscu\saWinService]
GO
GRANT  EXECUTE  ON [tcu].[Employee_getForAD]  TO [wa_Services]
GO