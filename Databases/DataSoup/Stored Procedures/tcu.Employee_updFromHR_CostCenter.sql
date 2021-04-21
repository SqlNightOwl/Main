use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_updFromHR_CostCenter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_updFromHR_CostCenter]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_updFromHR_CostCenter
	@Detail	varchar(4000)	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/16/2009
Purpose  :	Adds new Cost Centers from the HR File into the CostCenter table.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@count	int
,	@now	datetime
,	@result	int
,	@user	varchar(25)

select	@count	= 0
	,	@now	= getdate()
	,	@result	= 0
	,	@user	= 'HR Import'

begin try
	--	add any missing cost centers...
	insert	tcu.CostCenter
		(	CostCenter
		,	CostCenterName
		,	ManagerNumber
		,	ParentCostCenter
		,	IsActive
		,	CreatedBy
		,	CreatedOn
		)
	select	e.DEPARTMENT_CODE
		,	min(e.COST_CENTER)	as CostCenterName
		,	null				as ManagerNumber
		,	null				as ParentCostCenter
		,	1					as IsActive
		,	@user				as CreatedBy
		,	@now				as CreatedOn
	from	tcu.Employee_load	e
	left join
			tcu.CostCenter		c
			on	e.DEPARTMENT_CODE = c.CostCenter
	where	c.CostCenter is null
	and		e.DEPARTMENT_CODE is not null
	group by e.DEPARTMENT_CODE
	order by e.DEPARTMENT_CODE;

	select	@count	= @@rowcount
		,	@result	= @@error;

	if @count > 0
		set @detail = @detail + 'There were ' + cast(@count as varchar(10))
					+ ' new Cost Centers added from the most recent HR Sync file.<br/>';
end try
begin catch
	--	collect the error details...
	exec tcu.ErrorDetail_get @Detail out;
	set	@result = 1;
end catch;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO