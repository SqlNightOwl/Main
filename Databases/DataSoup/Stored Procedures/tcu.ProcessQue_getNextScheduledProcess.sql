use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessQue_getNextScheduledProcess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessQue_getNextScheduledProcess]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessQue_getNextScheduledProcess
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/13/2010
Purpose  :	Returns the next available ProcessQueId from the table..
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@result	int

set	@result = 0;

if exists ( select	top 1 ProcessQueId from tcu.ProcessQue
			where	StartedOn is null	)
begin
	begin transaction
		select	top 1 @result = ProcessQueId
		from	tcu.ProcessQue
		where	StartedOn is null;

		--	update the table to "claim" the record for this process...
		update	tcu.ProcessQue	with (serializable)
		set		StartedOn		= getdate() 
		where	ProcessQueId	= @result
		and		StartedOn		is null;

		--	if no record was updated then reset the result...
		if @@rowcount = 0 set @result = -1;
	commit transaction;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO