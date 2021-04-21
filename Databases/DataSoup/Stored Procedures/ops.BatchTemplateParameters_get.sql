use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchTemplateParameters_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[BatchTemplateParameters_get]
GO
setuser N'ops'
GO
CREATE procedure ops.BatchTemplateParameters_get
	@QueNbr	int
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	02/11/2010
Purpose  :	Returns Parameters for a Que
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int

select	p.BatchTemplateId
	,	p.ApplNbr
	,	p.QueSubNbr
	,	p.ParameterCd
	,	p.ParameterValue
	,	p.DateLastMaint
from	ops.BatchProcessLog			l
join	ops.BatchTemplateParameters	p
		on	l.BatchTemplateId	= p.BatchTemplateId
		and l.ApplNbr			= p.ApplNbr
		and	l.QueSubNbr			= p.QueSubNbr
where	l.QueNbr = @QueNbr;

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO