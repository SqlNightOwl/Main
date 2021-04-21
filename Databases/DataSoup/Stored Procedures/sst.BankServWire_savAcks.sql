use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire_savAcks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[BankServWire_savAcks]
GO
setuser N'sst'
GO
CREATE procedure sst.BankServWire_savAcks
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/23/2008
Purpose  :	Handles loading BankServ Acknowledgements of the Corillian transfer
			requests.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@fileId		int
,	@fileName	varchar(50)
,	@template	varchar(255)
,	@ftpFolder	varchar(255)
,	@loadedOn	datetime
,	@result		int

--	load the Acknowledgements...
select	@actionCmd	= db_name() + '.sst.BankServWire_vLoad'
	,	@ftpFolder	= p.FTPFolder + 'ACKS\'
	,	@fileName	= f.FileName
	,	@template	= replace(replace(f.FileName, '*', '%'), '?', '_')
	,	@detail		= ''
	,	@loadedOn	= convert(char(16), getdate(), 121)
	,	@fileId		= 0
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId	= @ProcessId
and		f.ApplName	= 'Acknowledgement';

--	find the Acknowledgements...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @ftpFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	load the wire request files...
while exists (	select	top 1 *	from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId
				and		FileName	like @template	)
begin

	select	top 1
			@actionFile	= Path + '\' + FileName
		,	@archFile	= Path + '\archive\' + FileName
		,	@fileName	= FileName
		,	@fileId		= FileId
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	and		FileName	like @template
	order by FileId;

	--	we're only interested in the ACK2 Files
	if charindex('ack2', @fileName) > 0
	begin
		--	load the file
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= '-c -T'
								,	@output		= @detail output;

		--	no error occured loading the file
		if @result = 0 and len(@detail) = 0
		begin
			--	update the wire request...
			update	sst.BankServWire_load
			set		RecordType	= 'ACK'
			where	RecordType	is null;

			update	w
			set		Status		=	case len(isnull(rtrim(a.IMAD), ''))
									when 0 then 'Not '
									else '' end + 'Processed'
				,	IMAD		= nullif(rtrim(a.IMAD), '')
				,	AcknowledgmentFile	= @fileName
				,	AcknowledgedOn		= @loadedOn
			from	sst.BankServWire		w
			join	sst.BankServWire_vACK	a
					on	a.WireId = w.WireId
			where	AcknowledgedOn is null;

			--	this should never happen!!!
			--	... but, add acknowledgements for wires which aren't loaded
			insert	sst.BankServWire
				(	WireId
				,	Status
				,	IMAD
				,	AcknowledgmentFile
				,	AcknowledgedOn
				,	WireLoadedOn
				)
			select	WireId
				,	'Wire Not Found'
				,	nullif(IMAD, '')
				,	@fileName
				,	@loadedOn
				,	@loadedOn
			from	sst.BankServWire_vACK
			where	WireId not in (select WireId from sst.BankServWire);

		end;
		else	--	report any errors...
		begin
			set	@result = 1;	--	failure
			exec tcu.ProcessLog_sav	@RunId		= @RunId
								,	@ProcessId	= @ProcessId
								,	@ScheduleId	= @ScheduleId
								,	@StartedOn	= null
								,	@Result		= @result
								,	@Command	= @actionCmd
								,	@Message	= @detail;
			return @result;
		end;	--	error
	end;		--	ack2 file

	--	archive the file...
	exec @result = tcu.File_action	@action		= 'move'
								,	@sourceFile	= @actionFile
								,	@targetFile	= @archFile
								,	@overWrite	= 1
								,	@output		= @detail output;
	--	report any errors...
	if @result != 0 and len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= null
							,	@Result		= @result
							,	@Command	= @actionCmd
							,	@Message	= @detail;
		return @result;
	end;	--	report errors
end;		--	loop until done...

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO