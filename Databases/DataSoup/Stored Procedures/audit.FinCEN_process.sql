use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[FinCEN_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [audit].[FinCEN_process]
GO
setuser N'audit'
GO
CREATE procedure audit.FinCEN_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/04/2008
Purpose  :	Process to import new FinCEN File and then compare/export the matching
			data from OSI for Audits & Compliance.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/23/2008	Paul Hunter		Removed Process update code to disable the process
							as this is a feature of the Process_run based on a
							ProcessCategory of "On Demand".
07/07/2008	Paul Hunter		Truncate data after comparison for SOX compliance.
03/26/2009	Paul Hunter		Changed process to work with static file names.
							Added delete of source files after checking w/ Compliance
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@files		tinyint
,	@lastColumn	int
,	@message	varchar(255)
,	@result		int
,	@sqlCmd		nvarchar(255)
,	@sqlFolder	varchar(255)
,	@targetCmd	varchar(255)
,	@targetFile	varchar(255);

--	initialize the variables...
select	@sqlFolder	= p.SQLFolder
	,	@message	= replace(p.MessageBody, '#SQL_FOLDER#', p.SQLFolder)
	,	@targetCmd	= db_name() + '.' + f.FileName
	,	@targetFile	= p.SQLFolder + f.TargetFile
	,	@detail		= ''
	,	@fileName	= ''
	,	@files		= 0
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId	= @ProcessId
and		f.ApplName	= 'Target';

while exists (	select	top 1 FileName from tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		FileName	> @FileName
				and		ApplName	= 'Source'	)
begin
	--	retrieve the bcp command information...
	select top 1
			@actionCmd	= db_name() + '.' + FileName
		,	@actionFile	= @sqlFolder + TargetFile
		,	@sqlCmd		= 'truncate table ' + replace(FileName, '_vLoad', '')
		,	@fileName	= FileName
	from	tcu.ProcessFile
	where	ProcessId	= @ProcessId
	and		FileName	> @FileName
	and		ApplName	= 'Source'
	order by FileName;

	--	check to see if the file is there
	if tcu.fn_FileExists(@actionFile) = 1
	begin
		--	clear the old data
		exec sp_executesql @sqlCmd;

		--	import the new file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= '-c -F1 -T'
								,	@output		= @detail output;

		--	report any errors...
		if @result != 0 or len(@detail) > 0
		begin
			set	@files	= 0;	--	reset
			set	@result = 3;	--	warning
			break;				--	break out of the while loop
		end;
		else
		begin
			--	delete the file after loading....
			exec @result = tcu.File_action	@action		= 'eras'
										,	@sourceFile	= @actionFile
										,	@targetFile	= null
										,	@overWrite	= 0
										,	@output		= @detail output;
			if @result != 0 or len(@detail) > 0
			begin
				set	@files	= 0;	--	reset
				set	@result = 3;	--	warning
				break;				--	break out of the while loop
			end;
		end;	--	delete file

		set	@files = @files + 1

	end;		--	file exists
end;			--	process files exists

--	if 1 or more files were loaded then process them
if	@files		> 0
and @result		= 0
and len(@detail)= 0
begin
	--	update the double metaphone matching values
	update	audit.fincenBusinessMaster
	set		BusinessNameCode	= nullif(rtrim(tcu.fn_DoubleMetaPhone(BusinessName)), '')
		,	DbaNameCode			= nullif(rtrim(tcu.fn_DoubleMetaPhone(DbaName)), '');

	update	audit.fincenPeopleMaster
	set		NameCode	= nullif(rtrim(tcu.fn_DoubleMetaPhone(isnull(FirstName, '') + isnull(LastName, ''))), '')
		,	AliasCode	= nullif(rtrim(tcu.fn_DoubleMetaPhone(isnull(AliasFirstName, '') + isnull(AliasLastName, ''))), '');
	--	load up new osi data with which to match...
	exec @result = audit.fincenMatches_ins;

	if @result = 0
	begin
		--	determine what the last column of the queried columns is...
		select	@lastColumn = column_id from sys.columns
		where	[object_id] = object_id(ltrim(@targetCmd))
		and		name != 'RowType';

		--	build a sql string for the target command...
		select	@targetCmd	=	case column_id
								when 1 then 'select ' + name + ', '
								when @lastColumn then name + ' from '
								else name + ', '
								end + @targetCmd
		from	sys.columns
		where	[object_id] = object_id(ltrim(@targetCmd))
		and		name != 'RowType'
		order by column_id desc;

		set @targetCmd = @targetCmd + ' order by RowType'
	
		--	export the matching data...
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @targetCmd
								,	@actionFile	= @targetFile
								,	@switches	= '-c -t, -T'
								,	@output		= @detail	output;

		--	report any BCP errors...
		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 3;	--	warning
		end;
		else
		begin
			--	set @detail to @message if no errors occur and change the result to information...
			set	@result	= 2;	--	information
			set	@detail	= @message;
		end;
	end;
	else
	begin
		set	@result	= 1;	--	failure
		set	@detail = 'An unexpected failure occurred while extracting the OSI data '
					+ 'for FinCEN comparisons using the procedure audit.fincenMatches_ins.';
	end;

end;

--	remove data for SOX compliance...
truncate table audit.fincenBusinessMaster;
truncate table audit.fincenBusinessOSI;
truncate table audit.fincenPeopleMaster;
truncate table audit.fincenPeopleOSI;

--	save the results.
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId = @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @actionCmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO