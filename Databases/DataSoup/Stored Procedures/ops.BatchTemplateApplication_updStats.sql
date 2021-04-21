use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchTemplateApplication_updStats]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[BatchTemplateApplication_updStats]
GO
setuser N'ops'
GO
CREATE procedure ops.BatchTemplateApplication_updStats
	@errmsg	varchar(255)	= ''	output	-- in case of error
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	01/21/2010
Purpose  :	Update the BatchTemplateApplication with the standard deviation and
			median execution time for each Template/Application.
History  :
  Date		Developer		Description 
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	varchar(500)
,	@return	int

--	initialize the variables...
select	@cmd	= ''
	,	@return	= 0;

begin try
	set	@cmd = 'Update StandardDeviation values in ops.BatchTemplateApplication'
	update	ta
	set		StdDev = l.StdDeviation
	from	ops.BatchTemplateApplication	ta
	join(	select	BatchTemplateId
				,	ApplNbr
				,	QueSubNbr
				,	coalesce(stdev(cast(ApplExecTime as int)), 60) as StdDeviation
			from	ops.BatchProcessLog
			group by 
					BatchTemplateId
				,	ApplNbr
				,	QueSubNbr	)		l
			on	ta.BatchTemplateId	= l.BatchTemplateId
			and	ta.ApplNbr			= l.ApplNbr
			and	ta.QueSubNbr		= l.QueSubNbr;

	set	@cmd = 'Get all Templates-Appls-QueSubNbr in order of ApplExecTime'
	select	RowId	= identity(int,1,1)
		,	BatchTemplateId
		,	ApplNbr
		,	QueSubNbr
		,	ApplExecTime
	into	#temp
	from	ops.BatchProcessLog
	where	ApplStopTime is not null
	order by
			BatchTemplateId
		,	ApplNbr
		,	QueSubNbr
		,	ApplExecTime;

	set	@cmd = 'Calculate Median and Update in ops.BatchTemplateApplication'
	update	ba
	set	Median	=	 t.ApplExecTime
	from	ops.BatchTemplateApplication	ba
	join	#temp							t
			on	t.BatchTemplateId	= ba.BatchTemplateId 
			and t.ApplNbr			= ba.ApplNbr 
			and t.QueSubNbr			= ba.QueSubNbr
	join(	select	BatchTemplateId
				,	ApplNbr
				,	QueSubNbr
				,	min(RowId) + ((max(RowId) - min(RowId)) / 2) as MedianRowId
			from	#temp
			group by
					BatchTemplateId
				,	ApplNbr
				,	QueSubNbr	)	m
			on	t.RowId	= m.MedianRowId;

	drop table #temp;

end try
begin catch
	--	collect the standard error message...
	select	@return	=	@@error
		,	@errmsg =	case @@error
						when 0 then ''
						else 'Error executing command "' + @cmd + '" inside procedure '
							+ error_procedure() + '.' + char(13) + 'ErrorMessage:' + error_message() + '.'
						end;
end catch;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO