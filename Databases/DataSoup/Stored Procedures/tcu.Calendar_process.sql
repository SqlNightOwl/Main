use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Calendar_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Calendar_process]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Calendar_process
	@year	smallint	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/07/2010
Purpose  :	Persists the holiday dates to the calendar table for the year provided.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@result	int

set @year	= isnull(@year, year(getdate()) + 1);
set	@result	= 0;

if	@year	between year(getdate()) - 2
				and	year(getdate()) + 2
begin
	insert	tcu.Calendar
		(	HolidayOn
		,	Holiday
		,	IsCompany
		,	IsFederal
		)
	select	HolidayOn
		,	Holiday
		,	isCompany = case holiday when 'Veterans Day' then 0 else 1 end 
		,	isFederal = 1
	from	tcu.fn_HolidayCalendar(@year)
	where	not exists (select HolidayOn from tcu.Calendar where year(HolidayOn) = @year );
end;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO