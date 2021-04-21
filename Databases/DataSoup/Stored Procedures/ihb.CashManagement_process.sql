use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[CashManagement_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[CashManagement_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.CashManagement_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/18/2008
Purpose  :	Sequences the BAI2 Cash Management file produced in OSI and copies 
			it to the FTP folder for loading into Voyager
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
10/03/2008	Paul Hunter		Modified update of "16" records to also include a
							replacement of all asterisks in the check number field
							with a like number of zeros.  This will fix bad scans
							of the check MICR line.
11/30/2009	Paul Hunter		Changed import to use a format file and removed using
							a table variable for sequencing transaction records.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@effDate	char(8)
,	@fileName	varchar(50)
,	@ftpFolder	varchar(255)
,	@result		int
,	@rtNbr		char(9)
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(255)

--	initialize the variables...
select	@actionCmd	= db_name() + '.ihb.CashManagement'
	,	@actionFile	= l.FileSpec
	,	@fileName	= f.TargetFile
	,	@ftpFolder	= p.FTPFolder
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-T -f"' + tcu.fn_UNCFileSpec(p.SQLFolder + p.FormatFile ) + '"'
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessOSILog_v		l
join	tcu.ProcessFile			f
		on	l.ProcessId = f.ProcessId
join	tcu.ProcessParameter_v	p
		on	l.ProcessId = p.ProcessId
where	l.RunId		= @RunId
and		l.ProcessId	= @ProcessId;

--	clear the old data...
truncate table ihb.CashManagement;
alter index all on ihb.CashManagement rebuild;

--	load the file...
exec @result = tcu.File_bcp	@action		= 'in'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= @switches
						,	@output		= @detail	output;

--	begin processing if there are no errors...
if @result = 0 and len(@detail) = 0
begin
	--	extract/update the line type...
	update	ihb.CashManagement
	set		LineType = left(Record, 2);

	--	Fix the header rows ("01" and "02"):
	--	Texans RTN is in the second positin on the "01" record and must be in the
	--	second and thrid position on both the "01" and "02" records.
	--	Collect the Effective Date is on the "01" record which is used for archiving.
	select	@rtNbr		= substring(Record, 4, 9)
		,	@effDate	= '20' + substring(Record, 24, 6)
		,	@fileName	= replace(@fileName, '[RTN]', substring(Record, 4, 9))
	from	ihb.CashManagement
	where	LineType	= 1;

	--	update the header records...
	update	ihb.CashManagement
	set		Record	= tcu.fn_ZeroPad(RowId, 2)
					+ replace(',|,|,', '|', @rtNbr)
					+ substring(Record, 24, 255)
	where	LineType in (1, 2);

	--	update the sequence numbers for the transaction lines...
	update	d
	set		Sequence = s.Sequence
	from	ihb.CashManagement	d
	join(	select	RowId, Sequence = row_number() over (order by RowId)
			from	ihb.CashManagement
			where	LineType = 16
		)	s	on	d.RowId = s.RowId;

	--	1) update the "16" records with a sequence number
	--	2) replace any invalid check numbers with all zeros
	update	ihb.CashManagement
	set		Record	= replace(	left(Record, charindex('Z,,', Record) + 1)
							+	cast(Sequence as varchar)
							+	substring(Record, charindex('Z,,', Record) + 2, 255)
						, '*********', '000000000')
	where	LineType = 16;

	--	setup the extract information...
	select	@actionCmd	= 'select Record from ' + @actionCmd + ' order by RowId'
		,	@actionFile	= @ftpFolder + @fileName
		,	@switches	= '-c -T'
		,	@targetFile	= @sqlFolder + 'archive\' + @effDate + '_' + @fileName;

	--	export the file...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail	output;

	--	report any errors...
	if @result != 0 and len(@detail) > 0
	begin
		set	@result = 1;
		goto PROC_EXIT
	end;

	--	archive the file
	exec @result = tcu.File_action	@action		= 'copy'
								,	@sourceFile	= @actionFile
								,	@targetFile	= @targetFile
								,	@overWrite	= 1
								,	@output		= @detail output;

	--	report any errors
	if @result != 0 and len(@detail) > 0
	begin
		set	@result = 1;
		goto PROC_EXIT
	end;
end;

PROC_EXIT:
if @result != 0 and len(@detail) > 0
begin
	set	@result = 1;
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId = @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
	return @result;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO