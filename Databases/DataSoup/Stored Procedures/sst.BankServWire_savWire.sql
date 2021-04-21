use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire_savWire]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[BankServWire_savWire]
GO
setuser N'sst'
GO
CREATE procedure sst.BankServWire_savWire
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
Purpose  :	Handles loading Corillian wires transfer requests which are destined
			for BankServ.
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
,	@ftpFolder	varchar(255)
,	@loadedOn	datetime
,	@result		int
,	@template	varchar(50);

select	@actionCmd	= db_name() + '.sst.BankServWire_vLoad'
	,	@ftpFolder	= p.FTPFolder
	,	@fileName	= f.FileName
	,	@template	= replace(replace(f.FileName, '*', '%'), '?', '_')
	,	@detail		= ''
	,	@fileId		= 0
	,	@loadedOn	= convert(char(16), getdate(), 121)
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId	= @ProcessId
and		f.ApplName	= 'Wire Request';

--	find the wire requests...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @ftpFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	load the files...
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
		set		RecordType	= 'WTX'
		where	RecordType	is null;

		--	load the data into the table...
		insert	sst.BankServWire
			(	WireId
			,	Status
			,	FileDate
			,	Amount
			,	SenderAccount
			,	ReceiverName
			,	ReceiverBank
			,	ReceiverAccount
			,	WireFile
			,	WireLoadedOn
			)
		select	l.WireId
			,	'unknown'
			,	l.FileDate
			,	isnull(l.Amount, 0)
			,	isnull(l.SenderAccount, 0)
			,	isnull(l.ReceiverName, '')
			,	isnull(l.ReceiverBank, '')
			,	isnull(l.ReceiverAccount, '')
			,	@fileName
			,	@loadedOn
		from	sst.BankServWire_vWire	l
		left join	sst.BankServWire	w
				on	l.WireId = w.WireId
		where	w.WireId is null;

		--	update the FileId to prevent duplicates when the Acknowledgement part runs
		update	tcu.FileLog
		set		FileId		= FileId * -1
		where	ProcessId	= @ProcessId
		and		RunId		= @RunId
		and		FileId		= @FileId;

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
		end;
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
	end;	--	errors
end;		--	loop until done...

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO