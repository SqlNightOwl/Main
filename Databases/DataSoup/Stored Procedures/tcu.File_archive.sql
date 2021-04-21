use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[File_archive]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[File_archive]
GO
setuser N'tcu'
GO
create procedure tcu.File_archive
	@Action			char(4)
,	@SourceFile		varchar(255)
,	@ArchiveDate	varchar(10)		= null
,	@Detail			varchar(4000)			output
,	@AddDate		bit				= 1
,	@OverWrite		bit				= 1
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/21/2009
Purpose  :	Standard process for archiving files used in the processes.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@archFile	varchar(255)
,	@extension	varchar(25)
,	@fileName	varchar(255)
,	@result		int
,	@targetFile	varchar(255)

begin try

	--	split the soure file into folders and the last item is the actual file name...
	select	top 1 @fileName = value
	from	tcu.fn_split(@SourceFile, '\')
	order by row desc;

	--	standard process for adding a date...
	if isnull(@addDate, 1) = 1
	begin
		--	use current date if an archive date isn't provided...
		set @ArchiveDate	= isnull(nullif(@ArchiveDate, ''),  convert(char(10), getdate(), 121));
		set @extension		= reverse(left(reverse(@fileName), charindex('.', reverse(@fileName))));
		set	@archFile		= replace(@fileName, @extension, '_' + @ArchiveDate + @extension);
	end;
	else
	begin
		set	@archFile = @fileName;
	end;

	--	build the destination file name...
	set @targetFile = replace(@SourceFile, @fileName, 'archive\') + @archFile;

	--	archive the file...
	exec @result = tcu.File_action	@action		= @Action
								,	@sourceFile	= @SourceFile
								,	@targetFile	= @targetFile
								,	@overWrite	= @OverWrite
								,	@output		= @detail output;

	--	standardize the error return value...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
	end;

end try
begin catch
	select	@detail = 'Error Number: '	+ cast(error_number() as varchar)
					+ ' Severity: '		+ cast(error_severity() as varchar)
					+ ' State: '		+ cast(error_state() as varchar)
					+ ' Procedure: '	+ isnull(error_procedure(), 'MISSING')
					+ ' Line Number: '	+ cast(error_line() as varchar)
					+ ' Message: '		+ isnull(error_message(), 'MISSING')
		,	@result = 1;	--	failure
end catch

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO