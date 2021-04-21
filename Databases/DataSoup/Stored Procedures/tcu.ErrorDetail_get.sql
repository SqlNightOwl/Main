use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ErrorDetail_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ErrorDetail_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ErrorDetail_get
	@Detail		varchar(4000)	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/08/2009
Purpose  :	Creates a standard error message for use in TRY..CATCH blocks.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

set	@Detail	= 'An unexpected error occured in the ' + isnull('procedure ' + error_procedure(), 'T-SQL Code')
			+ ' on line number ' + isnull(cast(error_line() as varchar(10)), 'missing')
			+ ' with the error number ' + isnull(cast(isnull(error_number(), 0) as varchar(10)), 'missing')
			+ ' and the error message<br/>"' + isnull(error_message(), 'missing') + '".'

return 0;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO