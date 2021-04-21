use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_upd]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_upd]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_upd
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/28/2008
Purpose  :	Loads the new HR Employee data into the permanent table.
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/13/2008	Paul Hunter		Added logic to remove roman numbers from the end of
							the job titles.
06/24/2008	Paul Hunter		Added the EPMSCode to the insert/update logic.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@name	varchar(25)
,	@now	datetime;

--	only update if the load table is available.
if exists (	select * from sys.objects where object_id = object_id(N'tcu.Employee_load') and type in (N'U') )
begin

	select	@name	= 'HR Import'
		,	@now	= getdate();

	--	standardize the phone numbers
	update	tcu.Employee_load									-- trim the number & replace	dash for dot	no slash	no ()			no spaces
	set		Telephone	= left(replace(replace(replace(replace(replace(ltrim(rtrim(Telephone))	, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
		,	Fax			= left(replace(replace(replace(replace(replace(ltrim(rtrim(Fax))		, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
		,	Pager		= left(replace(replace(replace(replace(replace(ltrim(rtrim(Pager))		, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
		,	Mobile		= left(replace(replace(replace(replace(replace(ltrim(rtrim(Mobile))		, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)

	--	make sure that the Employee Number matches their Person Id before proceeding
	--	this will accomodate when a person moves from one state to another
	update	e
	set		EmployeeNumber	= isnull(l.EmployeeNumber, l.PersonId)
		,	UpdatedOn		= @now
		,	UpdatedBy		= @name
	from	tcu.Employee		e
	join	tcu.Employee_load	l
			on	e.PersonId = l.PersonId
	where	e.EmployeeNumber != isnull(l.EmployeeNumber, l.PersonId);

	--	reactivate re-hired employees
	update	e
	set		IsDeleted	= 0
		,	UpdatedOn	= @now
		,	UpdatedBy	= @name
	from	tcu.Employee		e
	join	tcu.Employee_load	l
			on	e.EmployeeNumber = isnull(l.EmployeeNumber, l.PersonId)
	where	e.IsDeleted	= 1;

	--	update the existing Employee records
	update	e
	set		LastName		=	rtrim(l.LastName)
		,	FirstName		=	rtrim(l.FirstName)
		,	PreferredName	=	rtrim(l.PreferredName)
		,	HiredOn			=	l.HiredOn
		,	Email			=	e.Email
		,	Department		=	rtrim(l.Department)
		,	DepartmentCode	=	rtrim(l.DepartmentCode)
		,	JobTitle		=	rtrim(	case ascii(right(l.JobTitle, 1))
										when ascii('I') then reverse(substring(reverse(l.JobTitle), charindex(' ', reverse(l.JobTitle)) + 1, 255))
										when ascii('V') then reverse(substring(reverse(l.JobTitle), charindex(' ', reverse(l.JobTitle)) + 1, 255))
										when ascii('X') then reverse(substring(reverse(l.JobTitle), charindex(' ', reverse(l.JobTitle)) + 1, 255))
										else l.JobTitle end)
	 	,	Telephone		=	l.Telephone
	 	,	Ext				=	rtrim(l.Ext)
 	 	,	Fax				=	l.Fax
		,	Category		=	rtrim(l.Category)
		,	Type			=	rtrim(l.Type)
		,	Gender			=	rtrim(l.Gender)
		,	Location		=	rtrim(l.Location)
		,	LocationCode	=	rtrim(l.LocationCode)
		,	Pager			=	l.Pager
		,	Mobile			=	l.Mobile
		,	Address1		=	rtrim(l.Address1)
		,	Address2		=	rtrim(l.Address2)
		,	City			=	rtrim(l.City)
		,	ZipCode			=	rtrim(l.ZipCode)
		,	PersonId		=	l.PersonId
		,	Classification	=	rtrim(l.Classification)
		,	ManagerNumber	= (	select	min(ManagerNumber)
								from	tcu.Employee_load
								where	PersonId = l.PersonId	)
		,	CostCenterCode	=	l.CostCenterCode
		,	CostCenter		=	rtrim(l.CostCenter)
		,	EPMSCode		=	rtrim(l.EPMSCode)
		,	IsDeleted		=	0
		,	UpdatedOn		=	@now
		,	UpdatedBy		=	@name
	from	tcu.Employee		e
	join	tcu.Employee_load	l
			on	e.EmployeeNumber = isnull(l.EmployeeNumber, l.PersonId);

	--	add new Employee records
	insert	tcu.Employee
		(	EmployeeNumber
		,	LastName
		,	FirstName
		,	PreferredName
		,	HiredOn
		,	Email
		,	Department
		,	DepartmentCode
		,	JobTitle
		,	Telephone
		,	Ext
		,	Fax
		,	Category
		,	Type
		,	Gender
		,	Location
		,	LocationCode
		,	Pager
		,	Mobile
		,	Address1
		,	Address2
		,	City
		,	ZipCode
		,	State
		,	PersonId
		,	Classification
		,	ManagerNumber
		,	CostCenterCode
		,	CostCenter
		,	EPMSCode
		,	IsDeleted
		,	CreatedOn
		,	CreatedBy
		)
	select	distinct
			EmployeeNumber	=	coalesce(l.EmployeeNumber, l.PersonId)
		,	LastName		=	rtrim(l.LastName)
		,	FirstName		=	rtrim(l.FirstName)
		,	PreferredName	=	rtrim(l.PreferredName)
		,	HiredOn			=	l.HiredOn
		,	Email			=	null
		,	Department		=	rtrim(l.Department)
		,	DepartmentCode	=	rtrim(l.DepartmentCode)
		,	JobTitle		=	rtrim(	case ascii(right(l.JobTitle, 1))
										when ascii('I') then reverse(substring(reverse(l.JobTitle), charindex(' ', reverse(l.JobTitle)) + 1, 255))
										when ascii('V') then reverse(substring(reverse(l.JobTitle), charindex(' ', reverse(l.JobTitle)) + 1, 255))
										when ascii('X') then reverse(substring(reverse(l.JobTitle), charindex(' ', reverse(l.JobTitle)) + 1, 255))
										else l.JobTitle end)
		,	Telephone		=	l.Telephone
		,	Ext				=	rtrim(l.Ext)
		,	Fax				=	l.Fax
		,	Category		=	rtrim(l.Category)
		,	Type			=	rtrim(l.Type)
		,	Gender			=	rtrim(l.Gender)
		,	Location		=	rtrim(l.Location)
		,	LocationCode	=	rtrim(l.LocationCode)
		,	Pager			=	l.Pager
		,	Mobile			=	l.Mobile
		,	Address1		=	rtrim(l.Address1)
		,	Address2		=	rtrim(l.Address2)
		,	City			=	rtrim(l.City)
		,	ZipCode			=	rtrim(l.ZipCode)
		,	State			=	'TX'
		,	PersonId		=	l.PersonId
		,	Classification	=	rtrim(l.Classification)
		,	ManagerNumber	= (	select	min(ManagerNumber)
								from	tcu.Employee_load
								where	PersonId = l.PersonId	)
		,	CostCenterCode	=	l.CostCenterCode
		,	CostCenter		=	rtrim(l.CostCenter)
		,	EPMSCode		=	rtrim(l.EPMSCode)
		,	IsDeleted		=	0
		,	CreatedOn		=	@now
		,	CreatedBy		=	@name
	from	tcu.Employee		e
	right join
			tcu.Employee_load	l
			on	e.EmployeeNumber = coalesce(l.EmployeeNumber, l.PersonId)
	where	e.EmployeeNumber is null;

	--	mark missing employees as deleted
	update	e
	set		IsDeleted	= 1
		,	UpdatedOn	= @now
		,	UpdatedBy	= @name
	from	tcu.Employee		e
	left join
			tcu.Employee_load	l
			on	e.EmployeeNumber = isnull(l.EmployeeNumber, l.PersonId)
	where	l.EmployeeNumber	is null
	and		e.IsDeleted			= 0;

	--	update the email address
	update	e
	set		Email		= ad.EmailAddress
		,	UpdatedOn	= @now
		,	UpdatedBy	= @name
	from	tcu.Employee	e
	join	tcu.Employee_v	ad
			on	e.EmployeeNumber	=	ad.EmployeeNumber
			and	isnull(e.Email,'x')	!=	ad.EmailAddress
	where	e.IsDeleted	= 0;

end;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO