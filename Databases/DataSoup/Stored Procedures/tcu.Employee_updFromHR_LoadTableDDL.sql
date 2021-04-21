use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_updFromHR_LoadTableDDL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_updFromHR_LoadTableDDL]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_updFromHR_LoadTableDDL
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/15/2009
Purpose  :	Drops & recreates the Employee_load table for the HR Sync Process.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

--	drop the table if it exists...
if exists (	select top 1 name from sys.tables where object_id = object_id(N'tcu.Employee_load'))
	drop table tcu.Employee_load;


create table tcu.Employee_load
(	LAST_NAME			varchar(25)		null
,	FIRST_NAME			varchar(25)		null
,	PREFERRED_NAME		varchar(25)		null
,	EMPLOYEE_NO			int				null
,	EMPL_HIRE_DATE		datetime		null
,	DEPARTMENT			varchar(50)		null
,	DEPARTMENT_NAME		varchar(10)		null
,	COST_CENTER			varchar(30)		null
,	DEPARTMENT_CODE		int				null
,	JOB_TITLE			varchar(50)		null
,	APPT_TEL_NO			varchar(12)		null
,	EXT					varchar(4)		null
,	FAX					varchar(12)		null
,	CATEGORY			varchar(9)		null
,	Classification		varchar(25)		null
,	TYPE				varchar(15)		null
,	PAGER_NO			varchar(12)		null
,	GENDER				char(1)			null
,	MOBILE_TEL_NO		varchar(12)		null
,	LOC_NAME			varchar(50)		null
,	LOC_CODE			varchar(10)		null
,	LOC_ADDRESS1		varchar(30)		null
,	LOC_ADDRESS2		varchar(30)		null
,	LOC_CITY			varchar(25)		null
,	LOC_ZIP_POST_CODE	varchar(10)		null
,	PERSON_ID			int				null
,	MANAGER_CODE		int				null
,	Bargain_unit_code	varchar(5)		null
);

create clustered index CX_Employee_load on tcu.Employee_load(EMPLOYEE_NO);
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO