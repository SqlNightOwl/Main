use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ihb_BankServWires_getFileDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ihb_BankServWires_getFileDate]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ihb_BankServWires_getFileDate
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	05/02/2007
Purpose  :	Retrieves available file dates for the Corillian BankServ Wire report.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	FileDate
from	sst.BankServWire
where	FileDate is not null
group by FileDate
order by FileDate;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO