use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[File_action]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[File_action]
GO
setuser N'tcu'
GO
CREATE procedure tcu.File_action
	@action		varchar(4)		--	supported actions are: copy, move, eras[e]
,	@sourceFile	varchar(255)
,	@targetFile	varchar(255)
,	@overWrite	bit				= 0
,	@output		varchar(4000)	= null	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/14/2008
Purpose  :	Performs the designated the action (copy, move or delete) on the source
			and target file and overwrites if requested.  The procedure will not
			overwrite a file that exists.
Returns  :	-1	= an invalid aciton was provided
			-2	= source file doesn't exist
			-3	= target file cannot be copied (cannot overwrite)
			-4	= erase specified with a target file isn't permitted
			 0	= file not copied
			 #	= file copied or an error occured
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
10/08/2008	Paul Hunter		Added the "erase" command to the File Action
04/23/2009	Paul Hunter		Removed calls to sp_configure to toggle xp_cmdshell.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(1000)
,	@retval	int;

--	initialize to failure
set @retval = 1;

--	check for a valid command...
if charindex(@action, 'copy,move,eras') = 0
begin
	set	@output	= 'An invaild command action was supplied.';
	return -1;	--	not a vaild command action...
end;

--	make sure the source file exists...
if tcu.fn_FileExists(@sourceFile) = 0
begin
	set	@output	= 'An invaild source file was supplied.';
	return -2;	--	not a valid source file...
end;

--	if the target file exists and they didn't specifiy overwriting...
if(	@overWrite = 0 and
	tcu.fn_FileExists(@targetFile) = 1 )
begin
	set	@output	= 'The target file exists and the overwrite option wasn''t supplied.';
	return -3;	--	does the target file exist and/or is it okay to overwrite it
end

if(	@action = 'eras' and
	len(isnull(@targetFile, '')) > 0 )
begin
	set	@output	= 'A target file isn''t allowed for the option selected.';
	return -4;	--	delete and target file don't go together
end;

--	change "eras[e]" to delete
if @action = 'eras' set @action = 'del'

declare @results	table
	(	record	varchar(255)
	,	row		int identity
	);

--	build and execute the DOS command, collect the results for error reporting/checking
set	@cmd =	lower(@action)
		 +	case @action
			when 'del' then ' /F /Q "' + @sourceFile + '"'
			else	case @overWrite when 1 then ' /Y ' else ' ' end
				+	'"' + @sourceFile + '" '
				+	'"' + @targetFile + '"'
			end;

--	turn xp_cmdshell on...
--exec sp_configure	N'show advanced options', 1;	--	allow advanced options to be changed.
--exec sp_executesql	N'reconfigure;'					--	update the configured values.
--exec sp_configure	N'xp_cmdshell', 1;				--	enable the feature.
--exec sp_executesql	N'reconfigure;'					--	update the configured values.

--	run the OS command...
insert @results exec @retval = master.sys.xp_cmdshell @cmd;

--	turn xp_cmdshell back off...
--exec sp_configure	N'xp_cmdshell', 0;				--	disable the feature.
--exec sp_configure	N'show advanced options', 0;	--	disable advanced options to be changed.
--exec sp_executesql	N'reconfigure;'					--	apply the configured values.

--	return the results if the file isn't copied or the return from the command isn't zero
if exists (	select	top 1 * from @results
			where (	ltrim(rtrim(record)) = '0 file(s) copied.'
					and	@action = 'copy' )
				or(	charindex(' cannot ', record) > 0
					and	@action = 'move' )
				or(	charindex(' could not ', record) > 0
					and	@action = 'del' )
			)
or	@retval != 0
begin
	set	@output	= 'File Error: ' + @cmd + char(13) + char(10)
	set	@retval	= isnull(nullif(@retval, 0), 1)
	select	@output	= @output
					+ isnull(record, '') + char(13) + char(10)
	from	@results
	order by row;
end;

return @retval;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO