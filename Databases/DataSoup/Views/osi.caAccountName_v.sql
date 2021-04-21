use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[caAccountName_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[caAccountName_v]
GO
setuser N'osi'
GO
CREATE view osi.caAccountName_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/05/20008
Purpose  :	View used to create the Akcelerant Collect Anywhere person name file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	AcctNbr
	,	AcctNbr		as AcctNbr2
	,	PersonId
	,	FirstName
	,	LastName
from	openquery(OSI, '
		select	a.AcctNbr
			,	''P'' || cast(p.PersNbr as varchar(22)) as PersonId
			,	p.FirstName
			,	p.LastName
		from	osiBank.Pers	p
			,	osiBank.Acct	a
		where	p.PersNbr = a.TaxRptForPersNbr
		and		p.PurgeYN = ''N''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO