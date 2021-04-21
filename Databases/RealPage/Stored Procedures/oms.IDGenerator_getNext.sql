SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure oms.IDGenerator_getNext
	@IdGeneratorCd	char(1)
,	@IdGeneratorSeq	varchar(25)	output
as

set nocount on;
set transaction isolation level serializable;

begin transaction
	update	oms.IDGenerator
	set		IdNumber		= IdNumber + 1
		,	GeneratedOn		= current_timestamp
	where	IDGeneratorCd	= @IdGeneratorCd;

	if @@error = 0
	begin
		commit transaction;
		select	@IdGeneratorSeq = IdGeneratorSeq
		from	oms.IDGenerator with (nolock)
		where	IdGeneratorCd	= @IdGeneratorCd;
	end;
	else
	begin
		rollback transaction;
		set	@IdGeneratorSeq = 'nope';
	end;
return;
GO
