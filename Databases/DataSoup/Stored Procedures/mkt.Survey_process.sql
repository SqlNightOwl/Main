use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Survey_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Survey_process]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Survey_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/10/2008
Purpose  :	Loads Alegiance Surveys creating seperate Survey and Survey Key
			records.
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
,	@fileMask	varchar(50)
,	@loadedOn	datetime
,	@retention	int
,	@result		int
,	@uncFolder	varchar(255);

--	initialize the parameters...
select	@actionCmd	= db_name() + '.mkt.Survey_load'
	,	@fileMask	= f.FileName
	,	@uncFolder	= p.SQLFolder
	,	@retention	= p.RetentionPeriod
	,	@detail		= ''
	,	@fileId		= 0
	,	@loadedOn	= convert(char(10), getdate(), 121)
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	search for the 
exec @result = tcu.FileLog_findFiles	@ProcessId			= @ProcessId
									,	@RunId				= @RunId
									,	@uncFolder			= @uncFolder
									,	@fileMask			= @fileMask
									,	@includeSubFolders	= 0;

--	loop thru the loaded fils and load the survey.
while exists (	select	top 1 * from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin
	--	clear the table before loading...
	truncate table mkt.Survey_load;

	--	retrieve the next file...
	select	top 1
			@fileId		= FileId
		,	@actionFile	= Path + '\' + FileName
		,	@archFile	= Path + '\archive\' + FileName + '.' + convert(char(7), @loadedOn, 121)
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	order by FileId;

	--	load the file and skip the header row (-F2)
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T -F2'
							,	@output		= @detail output;

	--	continue if successful...
	if @result = 0 and len(@detail) = 0
	begin
		--	archive the file...
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @actionFile
									,	@targetFile	= @archFile
									,	@overWrite	= 1
									,	@output		= @detail output;

		--	add the distinct URL's to the survey...
		insert	mkt.Survey
			(	URL
			,	LoadedOn
			)
		select	distinct
				URL
			,	@loadedOn
		from	mkt.Survey_load;

		--	add the surveys associated with the file just loaded...
		insert	mkt.SurveyKey
			(	SurveyKeyId
			,	SurveyKey
			,	SurveyId	)
		select	l.SurveyKeyId
			,	l.SurveyKey
			,	s.SurveyId
		from	mkt.Survey		s
		join	mkt.Survey_load	l
				on	s.URL = l.URL
		left join	
				mkt.SurveyKey	k
				on	l.SurveyKeyId = k.SurveyKeyId
		where	s.LoadedOn		= @loadedOn
		and		k.SurveyKeyId	is null;

		set @result = @@error;

	end;
	else	-- report errors
	begin
		set	@result = 1;	--	failure
		break;
	end;
end;

PROC_EXIT:
if @result = 0 and len(@detail) = 0 and @fileId > 0
begin
	select	@result = 2	--	informaiton
		,	@detail	= replace('There was | new Survey file(s) loaded.', '|', @fileId);
end;

--	remove old data...
delete	mkt.Survey
where	LoadedOn <= dateadd(day, @retention, @loadedOn);

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