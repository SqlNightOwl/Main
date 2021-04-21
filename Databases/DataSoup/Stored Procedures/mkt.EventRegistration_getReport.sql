use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventRegistration_getReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[EventRegistration_getReport]
GO
setuser N'mkt'
GO
create procedure mkt.EventRegistration_getReport
	@EventId	int
,	@FromDate	datetime	= null
,	@ToDate		datetime	= null
with recompile
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/09/2006
Purpose  :	Retrieves the fields used for the specified Event and creates a
			dynamic select statement to report on the event registgrations.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@cmd	nvarchar(4000)

if exists (	select	1 from mkt.Event
			where	EventId = @EventId)
begin

	set	@cmd = 'select Record = EventRegistrationId, '

	select	@cmd	=	@cmd
					+	case
						when Field in ('Is_A_Member', 'Has_Opted_In') then quotename(replace(Field, '_', ' '))
						else quotename(FieldCaption) end 
					+	' = ' + Field + ', ' 
	from	mkt.EventField
	where	EventId = @EventId
	order by
			FieldNumber

	set	@cmd	= @cmd
				+ ' [Registered On] = cast(coalesce(UpdatedOn, CreatedOn) as varchar) 
from	mkt.EventRegistration
where	EventId = ' + cast(@EventId as varchar)

	if (@FromDate is not null) and (@ToDate is not null)
	begin
		set	@cmd	= @cmd
					+ ' and coalesce(UpdatedOn, CreatedOn) between ''' 
					+ convert(varchar, @FromDate, 101) + ''' and ''' 
					+ convert(varchar, dateadd(day, 1, @ToDate), 101) + ''''
	end

	exec sp_executesql @cmd

end

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[EventRegistration_getReport]  TO [wa_Marketing]
GO