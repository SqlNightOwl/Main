use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementRegZ_vStatement]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[StatementRegZ_vStatement]
GO
setuser N'osi'
GO
CREATE view osi.StatementRegZ_vStatement
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/09/2009
Purpose  :	Used for exporting the supplemental Statement file for compliance with
			the Credit Card Act.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	MemberNumber
	,	AccountNumber
	,	DailyRate
	,	cast(isnull(AccruedInterest, 0.0) as varchar(25)) as AccruedInterest
	,	CourtesyPeriod
from	osi.StatementRegZ;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO