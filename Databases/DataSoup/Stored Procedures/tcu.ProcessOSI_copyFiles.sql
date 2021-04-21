use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessOSI_copyFiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessOSI_copyFiles]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessOSI_copyFiles
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	10/02/2007
Purpose  :	Copies files from OSI folder to ftp folder.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/01/2008	Paul Hunter		Changed to use files the ProcessOSILog table as the
							source for the files to copy.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@addToExt	varchar(50)
,	@cmd		varchar(4000)
,	@CRLF		char(2)
,	@fileExt	varchar(50)
,	@fileSpec	varchar(255)
,	@ftpFolder	varchar(255)
,	@detail	varchar(4000)
,	@procName	varchar(255)
,	@return		int
,	@row		int
,	@started	datetime
,	@targetFile	varchar(255);

declare	@copyFiles	table
(	fileSpec	varchar(255)	not null
,	targetFile	varchar(50)		not null
,	addToExt	varchar(50)		not null
,	row			int	identity	primary key
);

--	retrieve some parameters and initialize some variables
select	@ftpFolder	= FTPFolder
	,	@CRLF		= char(13) + char(10)
	,	@detail		= ''
	,	@return		= 0
	,	@row		= 0
	,	@started	= getdate()
	,	@procName	= db_name() + '.' + object_name(@@procid)
from	tcu.ProcessParameter_v
where	ProcessId = @ProcessId;

--	collect all of the files to be copied
insert	@copyFiles
	(	fileSpec
	,	targetFile
	,	addToExt
	)
select	l.FileSpec
	,	TargetFile	=	isnull(f.TargetFile, l.FileName)
	,	AddToExt	=	case l.FileCount	when 1 then '' else '(' + cast(l.QueNbr as varchar) + ')' end +
						case f.AddDate		when 0 then '' else '_' + convert(char(8), l.EffectiveOn, 112) end
from	tcu.ProcessOSILog_v	l
join	tcu.ProcessFile		f
		on	l.ProcessId	= f.ProcessId
		and	l.ApplName	= f.ApplName
where	l.RunId		= @RunId
and		l.ProcessId	= @ProcessId
order by l.QueNbr;

--	loop until there are no more files to copy
while exists (	select	top 1 * from @copyFiles
				where	row > @row	)
begin
	--	get the next file details...
	select	top 1
			@fileSpec	= fileSpec
		,	@targetFile	= targetFile
		,	@addToExt	= isnull(addToExt, '')
						+ reverse(left(reverse(targetFile), charindex('.', reverse(targetFile))))
		,	@fileExt	= reverse(left(reverse(targetFile), charindex('.', reverse(targetFile))))
		,	@row		= row
	from	@copyFiles
	where	@row		< row
	order by row;

	--	the target is the ftp folder plus the modified extension
	set	@targetFile = @ftpFolder + replace(@targetFile, @fileExt, @addToExt);

	--	copy the OSI file to the ftp folder
	exec @return = tcu.File_action	@action		= 'copy'
								,	@sourceFile	= @fileSpec
								,	@targetFile	= @targetFile
								,	@overwrite	= 1
								,	@output		= @detail output;

	if @return != 0 or len(@detail) > 0
	begin
		set	@return	= 1;	--	failure
		set	@detail	= @detail + @CRLF + @fileSpec;
	end;
end;

--	log the results...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= @started
					,	@Result		= @return
					,	@Command	= @procName
					,	@Message	= @detail;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO