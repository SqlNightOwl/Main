use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[ExperianRequest_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[ExperianRequest_process]
GO
setuser N'lnd'
GO
CREATE procedure lnd.ExperianRequest_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/20/2006
Purpose  :	Exports a file of members for Experian so Texans can obtain FICO, MDS
			and other scores.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/29/2007	Vivian Liu		Changed to use the the OSI database and renamed to
							conform with new OSI name.
04/03/2008	Paul Hunter		Changed to use the new file system command wrappers.
07/07/2008	Paul Hunter		Truncated request table for data protection purposes.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int
,	@sqlFolder	varchar(255);

-- clear the table from the previous run
truncate table lnd.ExperianRequest;

--	retrieve the customer record from OSI database
insert	lnd.ExperianRequest
select	Customer
	,	Address1
	,	Address2
	,	CityName
	,	StateCd
	,	ZipCd
	,	TaxId
from	openquery(OSI, '
		select	distinct
				Customer
			,	Address1
			,	Address2
			,	CityName
			,	StateCd
			,	ZipCd
			,	TaxId
		from	texans.ExperianRequest_vw
		where	substr(TaxId, 1, 1) < ''7''');

--	build the base select statement
select	@actionCmd	= db_name() + '.lnd.ExperianRequest'
	,	@actionFile	= p.FTPFolder + replace(f.FileName, '.[DATE]', '')
	,	@archFile	= p.SQLFolder + 'archive\' 
					+ replace(f.FileName, '[DATE]', convert(char(7), getdate(), 121))
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	execute the bulk copy stored procedure
exec @result = tcu.File_bcp	@action		= 'out'
						,	@actionCmd	= @actionCmd
						,	@actionFile = @actionFile
						,	@switches	= '-c -T'
						,	@output		= @detail output;
--	report any errors...
if @result != 0 or len(@detail) > 0
begin
	set	@result = 1;
end;
else
begin
	--	Success, so copy the file to the archive folder
	exec @result = tcu.File_action	@action		= 'copy'
								,	@sourceFile	= @actionFile
								,	@targetFile = @archFile
								,	@overWrite	= 1
								,	@output		= @detail output;

	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;
	end;
	else
	begin
		--	success so, send notification... 
		set	@detail	= 'An Experian request file has been produced and is now available '
					+ 'in the <a href="' + @sqlFolder + '">Experian</a> folder.';
	end;
end;

--	clear the table for SOX compliance.
truncate table lnd.ExperianRequest;

--	record the process run
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
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