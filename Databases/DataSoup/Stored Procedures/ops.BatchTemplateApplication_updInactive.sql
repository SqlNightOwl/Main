use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchTemplateApplication_updInactive]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[BatchTemplateApplication_updInactive]
GO
setuser N'ops'
GO
CREATE procedure ops.BatchTemplateApplication_updInactive
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	02/22/2010
Purpose  :	Find applications that are no longer active and mark them as Inactive
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

update	bt
set		InactiveOn	= getdate()
from	ops.BatchTemplateApplication	bt
left join
		openquery(OSI,'
		select  qa.QueNbr
			,	qa.ApplNbr
			,   qa.QueSubNbr
		from	Que		q
		join	QueAppl	qa
				on	q.QueNbr = qa.QueNbr
		join	Appl	a
				on	qa.ApplNbr = a.ApplNbr 
		where	q.CreatedByQueNbr	is null 
		and		q.TemplateYN		= ''Y''')	o
		on	bt.BatchTemplateId	= o.QueNbr
		and	bt.ApplNbr			= o.ApplNbr
		and	bt.QueSubNbr		= o.QueSubNbr
where	bt.InactiveOn	is null
and		o.QueNbr		is null;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO