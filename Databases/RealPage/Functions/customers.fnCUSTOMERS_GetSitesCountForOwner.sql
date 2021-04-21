SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : fnCUSTOMERS_GetSitesCountForOwner
-- Description     : This procedure gets the no. of sites for the specified owner
-- Input Parameters: 1. @IPVC_OwnerIDSeq varchar(11)
--
-- OUTPUT          : A RecordSet that contains the no. of sites for the specified owner
--
-- Code Example    : Exec CUSTOMERS.dbo.[fnCUSTOMERS_GetSitesCountForOwner]  
--                   @IPVC_CompanyIDSeq = 'A0000000001'
--	
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 03/12/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE FUNCTION [customers].[fnCUSTOMERS_GetSitesCountForOwner]
(	
	@IPVC_OwnerIDSeq varchar(11)
)
RETURNS INT 
AS
BEGIN 
  ----------------------------------------------

  DECLARE @LI_PropertyCount INT

	SELECT 
          @LI_PropertyCount = COUNT(IDSeq) 
  FROM
          Customers.dbo.[Property] P 
  WHERE
          P.OwnerIDSeq = @IPVC_OwnerIDSeq
  AND     P.StatusTypeCode = 'ACTIV'

  RETURN @LI_PropertyCount
  ----------------------------------------------
END


GO
