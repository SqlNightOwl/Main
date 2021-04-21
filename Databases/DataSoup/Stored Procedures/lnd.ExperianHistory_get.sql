use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[ExperianHistory_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[ExperianHistory_get]
GO
setuser N'lnd'
GO
CREATE procedure lnd.ExperianHistory_get
	@SSN	char(9)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	07/28/2006
Purpose  :	Returns the FICO score history for a given Social Security Number
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/30/2008	Paul Hunter		Changed to use the Experian History table and support
	`						retirement of the legacy Premier link.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	SSN		= TaxId
	,	ScoreOn
	, 	FICOScore
	, 	MDSScore 
from	lnd.ExperianHistory
where	TaxId	= @SSN
order by 
		ScoreOn	desc
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [lnd].[ExperianHistory_get]  TO [wa_FicoHistory]
GO
GRANT  EXECUTE  ON [lnd].[ExperianHistory_get]  TO [wa_Lending]
GO