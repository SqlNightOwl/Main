SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetOwnerDetails
-- Description     : This procedure gets Owner Details for the specified Owner ID.

-- Input Parameters: @IPVC_OwnerIDSeq varchar(11)
-- 
-- OUTPUT          : RecordSet of the Owner with address.
--
-- Code Example    : Exec DOCUMENTS.dbo.[uspCUSTOMERS_GetOwnerDetails]
--                    @IPVC_OwnerIDSeq = 'A000000001'
--
-- Revision History:
-- Author          : STA, SRA Systems Limited.
-- 03/12/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetOwnerDetails](
                                                      @IPVC_OwnerIDSeq varchar(11)
                                                      )
	
AS
BEGIN
  ------------------------------------------------------
	SELECT      
              C.Name          AS OwnerName, 
              A.AddressLine1, 
              A.AddressLine2, 
              A.City, 
              A.State, 
              A.Zip,
              A.Country,
              A.CountryCode,
              CASE When CO.CustomerIDSeq=CO.OwnerIDSeq 
                Then '1'
                Else '0'
              END             AS PMCFlag
  
  FROM
              Customers.dbo.CustomerOwner CO with (nolock)
  INNER JOIN  
              Customers.dbo.Company       C with (nolock)
  ON        
              C.IDSeq = CO.OwnerIDSeq
  AND         C.OwnerFlag = 1
  AND         CO.OwnerIDSeq = @IPVC_OwnerIDSeq
  AND         C.IDSeq       = @IPVC_OwnerIDSeq
  LEFT OUTER JOIN  Customers.dbo.Address A with (nolock)
  ON          A.CompanyIDSeq = CO.OwnerIDSeq
  AND         A.CompanyIDSeq = C.IDSEQ
  AND         A.AddressTypeCode = 'COM'
  WHERE       CO.OwnerIDSeq = @IPVC_OwnerIDSeq
  AND         C.IDSeq       = @IPVC_OwnerIDSeq
  ------------------------------------------------------
END



GO
