use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[SurveyKey_getURL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[SurveyKey_getURL]
GO
setuser N'mkt'
GO
create procedure mkt.SurveyKey_getURL
	@SurveyKeyId	int
,	@SurveyURL		varchar(255)	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/10/2008
Purpose  :	Returns the Survey URL that matches the Survey Key Id provided.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int;

set	@SurveyURL = '';

select	@SurveyURL = s.URL + k.SurveyKey
from	mkt.SurveyKey	k
join	mkt.Survey		s
		on	k.SurveyId	= s.SurveyId
where	k.SurveyKeyId	= @SurveyKeyId;

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[SurveyKey_getURL]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [mkt].[SurveyKey_getURL]  TO [wa_Services]
GO