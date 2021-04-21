use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_updFromHR_Employee]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_updFromHR_Employee]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_updFromHR_Employee
	@Detail		varchar(4000)	output
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
12/15/2009	Paul Hunter		Changed to us the new HR Employee load data.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	varchar(4000)
,	@name	varchar(25)
,	@now	datetime
,	@result	int

select	@cmd	= ''
	,	@result = 0;

begin try
	--	only update if the load table is available.
	if exists (	select * from sys.objects where object_id = object_id(N'tcu.Employee_load') and type in (N'U') )
	begin
		select	@name	= 'HR Import'
			,	@now	= getdate();

		--	standardize the phone numbers and titles...
		set	@cmd = 'Clean up and standardize the imported data.'
		update	tcu.Employee_load		-- trim the number & replace / dash for dot	no slash / no () / no spaces
		set		LAST_NAME			=	ltrim(rtrim(LAST_NAME))
			,	PREFERRED_NAME		=	ltrim(rtrim(PREFERRED_NAME))
			,	DEPARTMENT			=	ltrim(rtrim(DEPARTMENT))
			,	DEPARTMENT_NAME		=	ltrim(rtrim(DEPARTMENT_NAME))
			,	COST_CENTER			=	ltrim(rtrim(COST_CENTER))
			,	JOB_TITLE			=	case ascii(right(rtrim(JOB_TITLE), 1))
										when ascii('I') then reverse(substring(reverse(ltrim(rtrim(JOB_TITLE))), charindex(' ', reverse(ltrim(rtrim(JOB_TITLE)))) + 1, 255))
										when ascii('V') then reverse(substring(reverse(ltrim(rtrim(JOB_TITLE))), charindex(' ', reverse(ltrim(rtrim(JOB_TITLE)))) + 1, 255))
										when ascii('X') then reverse(substring(reverse(ltrim(rtrim(JOB_TITLE))), charindex(' ', reverse(ltrim(rtrim(JOB_TITLE)))) + 1, 255))
										else ltrim(rtrim(JOB_TITLE)) end
			,	APPT_TEL_NO			=	left(replace(replace(replace(replace(replace(ltrim(rtrim(APPT_TEL_NO))	, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
			,	EXT					=	ltrim(rtrim(EXT))
			,	FAX					=	left(replace(replace(replace(replace(replace(ltrim(rtrim(FAX))			, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
			,	CATEGORY			=	ltrim(rtrim(CATEGORY))
			,	Classification		=	ltrim(rtrim(Classification))
			,	TYPE				=	ltrim(rtrim(TYPE))
			,	PAGER_NO			=	left(replace(replace(replace(replace(replace(ltrim(rtrim(PAGER_NO))		, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
			,	GENDER				=	ltrim(rtrim(GENDER))
			,	MOBILE_TEL_NO		=	left(replace(replace(replace(replace(replace(ltrim(rtrim(MOBILE_TEL_NO))	, '-', '.'), '/', ''), '(', ''), ')', ''), ' ', ''), 12)
			,	LOC_NAME			=	ltrim(rtrim(LOC_NAME))
			,	LOC_CODE			=	ltrim(rtrim(LOC_CODE))
			,	LOC_ADDRESS1		=	ltrim(rtrim(LOC_ADDRESS1))
			,	LOC_ADDRESS2		=	ltrim(rtrim(LOC_ADDRESS2))
			,	LOC_CITY			=	ltrim(rtrim(LOC_CITY))
			,	LOC_ZIP_POST_CODE	=	ltrim(rtrim(LOC_ZIP_POST_CODE))
			,	Bargain_unit_code	=	ltrim(rtrim(Bargain_unit_code))

		if @@error != 0 goto PROC_EXIT;

		--	make sure that the Employee Number matches their Person Id before proceeding
		--	this will accomodate when a person moves from one state to another
		set	@cmd = 'Update missing employee numbers.'
		update	e
		set		EmployeeNumber	= isnull(l.EMPLOYEE_NO, l.PERSON_ID)
			,	UpdatedOn		= @now
			,	UpdatedBy		= @name
		from	tcu.Employee		e
		join	tcu.Employee_load	l
				on	e.PersonId = l.PERSON_ID
		where	e.EmployeeNumber != isnull(l.EMPLOYEE_NO, l.PERSON_ID);

		if @@error != 0 goto PROC_EXIT;

		--	reactivate re-hired employees...
		set	@cmd = 'Reactivate re-hired employees.'
		update	e
		set		IsActive	= 1
			,	UpdatedOn	= @now
			,	UpdatedBy	= @name
		from	tcu.Employee		e
		join	tcu.Employee_load	l
				on	e.EmployeeNumber = isnull(l.EMPLOYEE_NO, l.PERSON_ID)
		where	e.IsActive	= 0;

		if @@error != 0 goto PROC_EXIT;

		--	update the existing Employee records...
		set	@cmd = 'Update the existing Employee records.'
		update	e
		set		FirstName		= l.PREFERRED_NAME
			,	LastName		= l.LAST_NAME
			,	HiredOn			= l.EMPL_HIRE_DATE
			,	Email			= n.Email
			,	CostCenter		= l.DEPARTMENT_CODE
			,	FacilityCd		= l.LOC_CODE
			,	LocationId		= o.LocationId	
			,	JobTitle		= l.JOB_TITLE
	 		,	Phone			= isnull(l.APPT_TEL_NO	, n.Phone)
	 		,	Ext				= left(isnull(l.EXT		, n.Extension), 4)
 	 		,	Fax				= isnull(l.FAX			, n.Fax)
			,	Pager			= isnull(l.PAGER_NO		, n.Pager)
			,	Mobile			= isnull(l.MOBILE_TEL_NO, n.Mobile)
			,	Category		= l.CATEGORY
			,	Type			= l.TYPE
			,	Gender			= l.GENDER
			,	PersonId		= l.PERSON_ID
			,	Classification	= l.CLASSIFICATION
			,	ManagerNumber	= m.MANAGER_CODE
			,	EPMSCd			= l.BARGAIN_UNIT_CODE
			,	IsActive		= 1
			,	UpdatedOn		= @now
			,	UpdatedBy		= @name
		from	tcu.Employee		e
		join	tcu.Employee_load	l
				on	e.EmployeeNumber = isnull(l.EMPLOYEE_NO, l.PERSON_ID)
		left join	tcu.Location	o
				on	l.DEPARTMENT_CODE = o.CostCenter
		left join
				tcu.adUser_v		n
				on	e.EmployeeNumber = n.EmployeeNumber
		left join
			(	select	PERSON_ID, min(MANAGER_CODE) as MANAGER_CODE
				from	tcu.Employee_load
				where	MANAGER_CODE is not null
				group by PERSON_ID
			)	m	on	l.PERSON_ID = m.PERSON_ID;

		if @@error != 0 goto PROC_EXIT;

		--	add new Employee records
		set	@cmd = 'Add new Employee records.'
		insert	tcu.Employee
			(	EmployeeNumber
			,	FirstName
			,	LastName
			,	HiredOn
			,	Email
			,	CostCenter
			,	FacilityCd
			,	LocationId
			,	JobTitle
			,	Phone
			,	Ext
			,	Fax
			,	Pager
			,	Mobile
			,	Category
			,	Type
			,	Gender
			,	Classification
			,	ManagerNumber
			,	EPMSCd
			,	PersonId
			,	PersNbr
			,	OnyxUserId
			,	IsActive
			,	CreatedOn
			,	CreatedBy
			)
		select	distinct
				isnull(l.EMPLOYEE_NO, l.PERSON_ID)
			,	l.PREFERRED_NAME
			,	l.LAST_NAME
			,	l.EMPL_HIRE_DATE
			,	n.Email
			,	l.DEPARTMENT_CODE			--	CostCenterId
			,	o.LocationId
			,	l.LOC_CODE
			,	l.JOB_TITLE
	 		,	isnull(l.APPT_TEL_NO	, n.Phone)
	 		,	left(isnull(l.EXT		, n.Extension), 4)
	 		,	isnull(l.FAX			, n.Fax)
			,	isnull(l.PAGER_NO		, n.Pager)
			,	isnull(l.MOBILE_TEL_NO	, n.Mobile)
			,	l.CATEGORY
			,	l.TYPE
			,	l.GENDER
			,	l.CLASSIFICATION
			,	m.MANAGER_CODE
			,	l.BARGAIN_UNIT_CODE
			,	l.PERSON_ID
			,	0							--	OSI PersNbr
			,	left(l.PREFERRED_NAME, 6) +
				left(l.LAST_NAME	 , 4)	--	Onyx User Id
			,	1							--	IsActive
			,	@now						--	CreatedOn
			,	@name						--	CreatedBy
		from	tcu.Employee		e
		right join
				tcu.Employee_load	l
				on	e.EmployeeNumber = isnull(l.EMPLOYEE_NO, l.PERSON_ID)
		left join	tcu.Location	o
				on	l.DEPARTMENT_CODE = o.CostCenter
		left join
				tcu.adUser_v		n
				on	l.EMPLOYEE_NO = n.EmployeeNumber
		left join
			(	select	PERSON_ID, min(MANAGER_CODE) as MANAGER_CODE
				from	tcu.Employee_load
				where	MANAGER_CODE is not null
				group by PERSON_ID
			)	m	on	l.PERSON_ID = m.PERSON_ID
		where	e.EmployeeNumber is null;

		if @@error != 0 goto PROC_EXIT;

		--	mark missing employees as no longer active...
		set	@cmd = 'Mark missing employees as no longer active.'
		update	e
		set		IsActive	= 0
			,	UpdatedOn	= @now
			,	UpdatedBy	= @name
		from	tcu.Employee		e
		left join
				tcu.Employee_load	l
				on	e.EmployeeNumber = isnull(l.EMPLOYEE_NO, l.PERSON_ID)
		where	l.EMPLOYEE_NO		is null
		and		e.IsActive			= 1;

		if @@error != 0 goto PROC_EXIT;

		--	update the email address...
		set	@cmd = 'Update the email address from Active Directory.'
		update	e
		set		Email		= ad.EmailAddress
			,	UpdatedOn	= @now
			,	UpdatedBy	= @name
		from	tcu.Employee	e
		join	tcu.Employee_v	ad
				on	e.EmployeeNumber	=	ad.EmployeeNumber
				and	isnull(e.Email,'x')	!=	ad.EmailAddress
		where	e.IsActive	= 1;

		if @@error != 0 goto PROC_EXIT;

		select	@cmd	= ''
			,	@result = @@error;
	end;
end try
begin catch
	--	collect the error details...
	exec tcu.ErrorDetail_get @Detail out;
	set	@result = 1;
end catch;

PROC_EXIT:
if @cmd != ''
	set	@result = 1;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO