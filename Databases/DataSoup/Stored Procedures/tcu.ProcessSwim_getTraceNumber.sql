use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwim_getTraceNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSwim_getTraceNumber]
GO
setuser N'tcu'
GO
create procedure tcu.ProcessSwim_getTraceNumber
	@CountOfRecords		int
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/26/2007
Purpose  :	Method to collect and increment Trace Numbers for SWIM files which
			require them.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@lastNumber	varchar(255)
,	@return		int

set	@return = 0

if isnull(@CountOfRecords, 0) > 1
begin
	begin transaction
		set	@return		= cast(tcu.fn_Dictionary('OSI', 'Last SWIM Trace Number') as int)
		set	@lastNumber	= cast(@return + @CountOfRecords as varchar(255))
		exec tcu.Dictionary_sav 'OSI', 'Last SWIM Trace Number', @lastNumber
	commit transaction
end

return @return
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO