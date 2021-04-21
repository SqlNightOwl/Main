SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- 11/03/2011  Naval Kishore Modified for Acceptence date TFS # 1185

CREATE PROCEDURE [quotes].[uspQUOTES_ApprovalDatesSelect] (@IPVC_QuoteID varchar(11))
AS
BEGIN
  select convert(varchar(10), isnull(CreateDate, getdate()), 101)				 CreateDate, 
	CASE WHEN convert(varchar(10),SubmittedDate,101)= convert(varchar(10),GETDATE(),101) 
	THEN convert(varchar(10), isnull(AcceptanceDate, getdate()), 101)
	ELSE convert(varchar(10), isnull(AcceptanceDate, getdate()-1), 101)  end as  AcceptanceDate,
    convert(varchar(10), isnull(SubmittedDate, getdate()), 101)					 SubmittedDate,
	TransferredFlag	
  from [Quote]
  where QuoteIDSeq = @IPVC_QuoteID
END


GO
