use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_getFromHR_Exceptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_getFromHR_Exceptions]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_getFromHR_Exceptions
	@ProcessId	smallint
,	@Detail		varchar(4000)	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/16/2009
Purpose  :	Exports the "target" queries after the file has been loaded.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@hasRow		bit
,	@result		int
,	@source		varchar(50)
,	@sqlFolder	varchar(255)
,	@switches	varchar(25)

--	initialize the variables...
select	@sqlFolder	= SQLFolder
	,	@source		= ''
	,	@Detail		= isnull(@Detail, '')
from	tcu.ProcessParameter_v
where	ProcessId = @ProcessId;

begin try
	--	loop thru the target files and export the results...
	while exists (	select	top 1 * from tcu.ProcessFile
					where	ProcessId	= @ProcessId
					and		ApplName	= 'Target'
					and		FileName	> @source	)
	begin
		--	retrieve the next export file...
		select	top 1
				@actionCmd	= 'select '
			,	@actionFile	= @sqlFolder + TargetFile
			,	@source		= FileName
			,	@switches	= '-c -t, -T'
			,	@hasRow		= case charindex('.XML', TargetFile) when 0 then 1 else 0 end
		from	tcu.ProcessFile
		where	ProcessId	= @ProcessId
		and		ApplName	= 'Target'
		and		FileName	> @source
		order by FileName;

		--	collect all column names from the table except for the "row"...
		select	@actionCmd = @actionCmd + name + ', ' 
		from	sys.columns
		where	object_id	= object_id(@source)
		and		name		!= 'row'
		order by column_id;

		--	trim up the command...
		set	@actionCmd = rtrim(@actionCmd);

		--	build the final query...
		set @actionCmd	= left(@actionCmd, len(@actionCmd) - 1)
						+ ' from ' + db_name() + '.' + @source
						+ case @hasRow when 1 then ' order by Row' else '' end

		--	export the file...
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail out;	

		--	collect any errors...
		set	@result = isnull(nullif(@result, 0), @result);
	end;
end try
begin catch
	exec tcu.ErrorDetail_get @detail out;
	set	@result = 1;	--	failure
end catch;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO