SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function oms.fnSplit
(	@list		varchar(max)
,	@delimiter	varchar(10)	)
returns	table
/*
————————————————————————————————————————————————————————————————————————————————————————————————————
							© 2000-11 RealPage, Inc. • All rights reserved.
			This module is the confidential & proprietary property of RealPage Inc.
————————————————————————————————————————————————————————————————————————————————————————————————————
Purpose		:	Divides the @list parameter at the @delimiter into an enumerated table.
Parameters	:	@list		- the delimited list of values up to 8000 characters long
				@delimeter	- the delimter value 
Calling		:	select Value, RowId from dbo.fnSplit(@list, @delimeter);
Returns		:	Table
History		: 
   Date		Developer			TFS #	Description
——————————	——————————————————	——————	————————————————————————————————————————————————————————————
2011-12-08	Paul Hunter			0		Initial function creation
————————————————————————————————————————————————————————————————————————————————————————————————————
*/
return(	select	cast(v2.l.value('.', 'varchar(8000)') as varchar(8000))	as Value
			,	row_number() over ( order by r.row )					as RowId
		from(	select(	select	convert(xml, '<l><v>'
							+	replace(@list, @delimiter, '</v><v>')
							+	'</v></l>') ) ) as v1(x) 
		cross apply x.nodes('/l/v') v2(l)
		cross apply ( select 1 as row ) r );
GO
