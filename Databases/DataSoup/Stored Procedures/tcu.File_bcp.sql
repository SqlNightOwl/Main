use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[File_bcp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[File_bcp]
GO
setuser N'tcu'
GO
CREATE procedure tcu.File_bcp
	@action		varchar(8)
,	@actionCmd	varchar(3500)
,	@actionFile	varchar(255)
,	@switches	varchar(255)
,	@output		varchar(4000)	= null	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/03/2008
Purpose  :	Performs the designated the BCP action for the source command and 
			target file.
Returns  :	-1	= an invalid aciton was provided
			-2	= not enough of a source command was provided
			-3	= not enough of a target file was provided
			-4	= resulting command was too long
			 0	= success
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/23/2009	Paul Hunter		Removed calls to sp_configure to toggle xp_cmdshell.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(4000)
,	@error	varchar(max)
,	@return		int;

declare	@results	table
	(	record	varchar(255)
	,	row		int identity
	);

set	@action		= lower(ltrim(rtrim(@action)));
set	@actionCmd	= ltrim(rtrim(isnull(@actionCmd, '')));
set	@actionFile	= ltrim(rtrim(isnull(@actionFile, '')));
set	@switches	= ltrim(rtrim(isnull(@switches, '')));

if @action = 'in'
or @action = 'out'
or @action = 'queryout'
	set	@return = 0;	--	valid command was provided
else
begin
	return -1;	--	invalid bcp command provided
end;
if	len(@actionCmd) < 10
begin
	return -2;	--	not enough of a source command?	
end;
if	len(@actionFile) < 10
begin
	return -3;	--	not enough of a target file
end;

--	add the server\instance if it's not provided
if charindex('-S' + @@servername, @switches) = 0
	set	@switches = @switches + ' -S' + @@servername;

--	build and execute the bcp command, collect the results for error reporting/checking
set	@cmd	= 'bcp "' + @actionCmd + '" '
			+ @action
			+ ' "' + @actionFile + '" '
			+ @switches;

if len(@cmd) < 4000
	insert @results exec @return = master.sys.xp_cmdshell @cmd;
else
begin
	set @return = -4;
	insert	@results(record)
	values	('The command resulting from this request is to long.');
end;

--	return the results if the file isn't copied or the return from the command isn't zero
if not exists (	select	top 1 * from @results
				where	record like '%rows copied%'	)
or	@return	!= 0
begin
	set @error = '';
	select	@output	= 'BCP Error: ' + @cmd + '...' + char(13) + char(10)
		,	@return	= isnull(nullif(@return, 0), 1);
	select	@error	= @error + char(13) + char(10) + isnull(record, '')
	from	@results
	order by row;
	set @output = @output + right(@error, 4000 - len(@output));
end;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO