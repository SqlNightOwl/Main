use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_process]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/28/2008
Purpose  :	Loads the HR Employee data file, updates the related systems and 
			generates/sends the associated reports.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/12/2009	Paul Hunter		Converted to work with the ONYX 6.0 schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@recipient	varchar(255)
,	@result		int
,	@sqlFolder	varchar(255)
,	@subject	varchar(255);

--	initialize the process variables
select	@actionCmd	= db_name() + '.tcu.Employee_load'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@fileName	= f.FileName
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId	= @ProcessId
and		f.ApplName	= 'Source';

--	search for the file
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	load the file if it exists...
if exists (	select	top 1 FileName from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId	)
begin
	--	drop/recreate the current load table if it exists
	if exists (	select name from sys.objects where object_id = object_id(N'tcu.Employee_load') and type in (N'U'))
	begin
		drop table tcu.Employee_load;
	end;

	--	create the load table...
	select	top 0 *
	into	tcu.Employee_load
	from	tcu.Employee_vTemplate;

	--	add a primary key...
	alter table tcu.Employee_load add constraint PK_Employee_load primary key ( PersonId );

	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-F2 -c -T'
							,	@output		= @detail	output;

	--	update the tables if no errors were encountered
	if @result = 0 and len(@detail) = 0
	begin
		--	update the Employee table
		exec @result = tcu.Employee_upd;

		--	update the LocationDepartment table
		exec @result = tcu.Employee_updLocationDepartment @ProcessId;

		--	no errors... so keep going
		if @result = 0
		begin
			--	archive the file...
			set	@actionCmd	= @sqlFolder + 'archive\'
							+ replace(@fileName, '.', ' ' + convert(char(10), getdate(), 121) + '.' );

			exec @result = tcu.File_action	@action		= 'move'
										,	@sourceFile	= @actionFile
										,	@targetFile	= @actionCmd
										,	@overWrite	= 1
										,	@output		= @detail output;

			--	report any errors...
			if @result != 0 or len(@detail) != 0
			begin
				set	@result = 1;	--	failure;
				goto PROC_EXIT;
			end;

			--	produce/send the related reports....
			set	@fileName = '';
			while exists (	select	top 1 *	from tcu.ProcessFile
							where	ProcessId	= @ProcessId
							and		ApplName	= N'Target'
							and		TargetFile	> @FileName	)
			begin
				--	fill in the processing logic
				select	top 1
						@actionCmd	= 'select * from ' + db_name() + '.' + FileName
					,	@actionFile	= @sqlFolder + TargetFile
					,	@fileName	= TargetFile
					,	@subject	= substring(FileName, 15, 40) + ' Report'
					,	@recipient	= tcu.fn_ProcessParameter(ProcessId, substring(FileName, 15, 40) + ' Notice')
				from	tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		ApplName	= N'Target'
				and		TargetFile	> @FileName
				order by TargetFile;

				--	export the results...
				exec @result = tcu.File_bcp	@action		= 'queryout'
										,	@actionCmd	= @actionCmd
										,	@actionFile	= @actionFile
										,	@switches	= '-t, -c -T'
										,	@output		= @detail output;

				--	send the email if no errors occured...
				if @result = 0 and len(@detail) = 0
				begin
					set	@detail	= '<font face=tahoma size=2>'
								+ '<p>The attached file contains the ' + @subject
								+ ' for the HR file received and loaded '
								+ convert(char(10), getdate(), 101) + '.</p>';
					exec tcu.Email_send	@subject		= @subject
									,	@message		= @detail
									,	@sendTo			= @recipient
									,	@sendCC			= null
									,	@asHtml			= 1
									,	@attachedFiles	= @actionFile;
					set	@detail	= '';
				end;
				else	--	report any errors...
				begin
					set	@result = 1;
					goto PROC_EXIT;
				end;
			end;
		end;
		else	--	report the error with the update process
		begin
			set	@result		= 1;	--	failure
			set	@actionCmd	= 'tcu.Employee_upd';
			set	@detail		= 'An unexpected error was encountered when updatating the Employee table from the HR file.';
			goto PROC_EXIT;
		end;

		--	update the Onyx user & employee records...
		if exists (	select name from sys.databases where name = N'Onyx6_0' )
		begin
			exec @result = Onyx6_0.sync.employee_data_process;
			if @result != 0
			begin
				set	@result		= 1;
				set	@actionCmd	= 'Onyx6_0.sync.employee_data_process';
				set	@detail		= 'An unexpected error was encountered when updatating Onyx from the Employee table.';
				goto PROC_EXIT;
			end;
		end;
	end;
	else	--	report any load errors...
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;

end;

PROC_EXIT:
if @result = 0
begin
	--	drop the table if no errors were encountered
	if exists (	select name from sys.objects where object_id = object_id(N'tcu.Employee_load') and type = (N'U'))
	begin
		drop table tcu.Employee_load;
	end;
end;
else
begin
	--	log the error
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO