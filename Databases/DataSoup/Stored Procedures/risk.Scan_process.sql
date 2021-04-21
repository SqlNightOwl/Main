use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Scan_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[Scan_process]
GO
setuser N'risk'
GO
CREATE procedure risk.Scan_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/01/2008
Purpose  :	Loads Microsolved Scan results file
History  :
   Date		Developer		Description  
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@dbCmd		nvarchar(255)
,	@dbCmdRun	nvarchar(255)
,	@detail		varchar(4000)
,	@fileDate	datetime
,	@fileId		int
,	@fileName	varchar(50)
,	@fileSize	int
,	@message	varchar(4000)
,	@parentId	int
,	@result		int
,	@scanId		smallint
,	@scanOn		char(10)
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(255);

select	@actionCmd	= db_name() + '.risk.ScanDetail'
	,	@fileName	= f.FileName
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-T -f"' + p.SQLFolder + p.FormatFile + '"'
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

while exists (	select	top 1 * from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin
	--	retrieve the next available file...
	select	top 1
			@fileId		= FileId
		,	@actionFile	= Path + '\' + left(FileName, 50)
		,	@fileName	= left(FileName, 50)
		,	@scanOn		= replace(replace(replace(FileName, '.nbe', ''), 'internal', ''), 'external', '')
		,	@fileDate	= FileDate
		,	@fileSize	= FileSize
		,	@scanId		= 0
		,	@parentId	= 0
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	order by FileId;

	set	@dbCmd	= 'alter table risk.ScanDetail drop	constraint DF_ScanDetail_ScanId; '
				+ 'alter table risk.ScanDetail add	constraint DF_ScanDetail_ScanId	default (|) for ScanId; '
				+ 'dbcc checkident (''risk.ScanDetail'', reseed, 0) with no_infomsgs;'

	if exists (	select	top 1 * from risk.Scan
					where	FileName = @fileName )
	begin
		select	@scanId		= ScanId
			,	@parentId	= isnull(ParentId, 0)
		from	risk.Scan
		where	FileName	= @fileName;

		if exists (	select	top 1 ScanId from risk.ScanDetail
					where	ScanId = @ScanId	)
		begin
			set	@scanId = 0;
			--	file with that name already loaded
			print 'file with that name already loaded';
		end;
	end;
	else
	begin
		--	add the file to the Scan table
		insert	risk.Scan
			(	Scan
			,	ScanOn
			,	ScanType
			,	FileName
			,	FileDate
			,	FileSize
			,	LoadedOn
			)
		values
			(	@fileName
			,	case isdate(@scanOn)
				when 1 then cast(@scanOn as datetime)
				else convert(char(10), @fileDate, 101) end
			,	case
				when charindex('external', @fileName) > 0 then 'E'
				when charindex('internal', @fileName) > 0 then 'I'
				else 'U' end	--	unknown
			,	@fileName
			,	@fileDate
			,	@fileSize
			,	getdate()
			);

		set	@scanId = scope_identity();

	end;

	if @scanId != 0
	begin

		--	rebuild the constraints for with the scanId as the default value
		set	@dbCmdRun = replace(@dbCmd, '|', @scanId);
		exec sp_executesql @dbCmdRun;

		--	load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail	output;

		--	the detail loaded so begin processing...
		if @result = 0 and len(@detail) = 0
		begin
			--	standardize the severity...
			update	d
			set		Severity	=	case d.Severity
									when 'INFO'				then 'Info'
									when 'Informational'	then 'Info'
									when 'Security Hole'	then 'High'
									when 'Security Note'	then 'Low'
									when 'Security Warning'	then 'Medium'
									else 'UNK' end
				,	PortName	=	rtrim(replace(left(d.RawProtocol, p.prnOpen) , '(', ''))
				,	Port		=	substring(d.RawProtocol, p.prnOpen + 1, p.slash - p.prnOpen - 1 )
				,	Protocol	=	replace(substring(d.RawProtocol, p.slash + 1, 15), ')', '')
				,	UpdatedBy	=	null
				,	UpdatedOn	=	null
			from	risk.ScanDetail	d
			join(	select	ScanId
						,	ScanDetailId
						,	prnOpen = charindex('(', RawProtocol)
						,	slash	= charindex('/', RawProtocol)
					from risk.ScanDetail
				)	p	on	d.ScanId		= p.ScanId
						and	d.ScanDetailId	= p.ScanDetailId
			where	d.ScanId = @scanId;

			--	update to port name when the port name is blank and the port isn't numeric...
			update	risk.ScanDetail
			set		PortName		= Port
				,	Port			= ''
				,	UpdatedBy		= null
				,	UpdatedOn		= null
			where	ScanId			= @scanId
			and		PortName		= ''
			and		isnumeric(Port) = 0;

			--	add new devices and assign those with non-static IP's
			exec risk.ScanDetail_assignDevice @ScanId;

			--	now that you have device Id's, update the new scan with "accepted" risks...
			update	n
			set		Status		= p.Status
				,	Resolution	= p.Resolution
				,	ApprovedBy	= p.ApprovedBy
				,	UpdatedBy	= p.UpdatedBy
				,	UpdatedOn	= p.UpdatedOn
			from	risk.ScanDetail	n	--	new scan
			join	risk.ScanDetail	p	--	prior scan(s)
					on	n.DeviceId		= p.DeviceId
					and	n.ScriptId		= p.ScriptId
					and	n.RawProtocol	= p.RawProtocol
			join(	--	collect the most recent acceptance of a risk...
					select	max(ScanId)			as ScanId
						,	max(ScanDetailId)	as ScanDetailId
					from	risk.ScanDetail
					where	ScanId	 < @scanId
					and		DeviceId > 0
					and		Status	 = 'Accept'
				)	mr	on	p.ScanId		= mr.ScanId
						and	p.ScanDetailId	= mr.ScanDetailId
			where	n.ScanId	= @scanId
			and		n.DeviceId	> 0;

			if @parentId > 0
			begin
				--	handle the rescan by setting accepted/fixed items...
				update	n
				set		AssignedTo	= p.AssignedTo
					,	Status		= case p.Status when 'Fixed' then 'Open' else p.Status end
					,	Resolution	= p.Resolution
					,	ApprovedBy	= p.ApprovedBy
					,	UpdatedBy	= p.UpdatedBy
					,	UpdatedOn	= p.UpdatedOn
				from	risk.ScanDetail	n	--	new scan
				join	risk.ScanDetail	p	--	parent scan
						on	n.DeviceId		= p.DeviceId
						and	n.ScriptId		= p.ScriptId
						and	n.RawProtocol	= p.RawProtocol
				where	n.ScanId	= @scanId
				and		p.ScanId	= @parentId
				and		p.Status	in ('Accept', 'Fixed');
			end;

			exec @result = tcu.File_action	@action		= 'erase'
										,	@sourceFile	= @actionFile
										,	@targetFile	= null
										,	@overWrite	= 0
										,	@output		= @detail output;
		end;
		else	--	report errors and "rename" the file
		begin
			set	@message	= @detail;
			set	@detail		= '';
			set	@targetFile	= @actionFile + '.load_error';

			exec @result	= tcu.File_action	@action		= 'copy'
											,	@sourceFile	= @actionFile
											,	@targetFile	= @targetFile
											,	@overWrite	= 0
											,	@output		= @detail output;
		end;	--	error

	end;	--	scan id > 0

end;	--	while file exists

--	report/record errors...
if len(isnull(@message, '')) > 0
begin
	set	@result	= 3;	--	warning
	exec tcu.ProcessLog_sav	@RunId			= @RunId
						,	@ProcessId		= @ProcessId
						,	@ScheduleId		= @ScheduleId
						,	@StartedOn		= null
						,	@Result			= @result
						,	@Command		= @actionCmd
						,	@Message		= @message;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO