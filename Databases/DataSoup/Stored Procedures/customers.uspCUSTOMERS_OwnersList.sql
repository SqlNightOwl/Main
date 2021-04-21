SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_OwnersList
-- Description     : This procedure gets the list of owners for the specified Company.
-- Input Parameters: 1. @IPI_PageNumber int, 
--                   2. @IPI_RowsPerPage int,
--                   3. @IPVC_CompanyIDSeq varchar(11)
--
-- OUTPUT          : A RecordSet that contains the list of Owners and their Address.
--
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_OwnersList]  
--                   @IPI_PageNumber = 1, 
--                   @IPI_RowsPerPage = 10,
--                   @IPVC_CompanyIDSeq = 'A0000000001'
--	
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 03/12/2007      : Stored Procedure Created.
-- 23/08/2007      : Changed PMCFlag to show PMC AS Owner
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_OwnersList]  @IPI_PageNumber int, 
                                                  @IPI_RowsPerPage int,
                                                  @IPVC_CompanyIDSeq varchar(11)
AS
BEGIN
	-----------------------------------------------------------------------------------------
  SELECT * FROM (
    ---------------------------------------------------------------------------------
    Select   
                row_number() OVER (ORDER BY C.Name)					  AS Seq,   
                CO.OwnerIDSeq                                         AS OwnerIDSeq,  
                CO.CustomerIDSeq                                      AS CustomerIDSeq,  
                C.Name                                                AS OwnerName,  
                A.AddressLine1                                        AS AddressLine1,  
                A.AddressLine2                                        AS AddressLine2,  
                A.City                                                AS City,  
                A.State                                               AS State,  
                A.Zip                                                 AS Zip,  
                dbo.fnCUSTOMERS_GetSitesCountForOwner(CO.OwnerIDSeq)  AS Sites  
                 
    FROM   
                Customers.dbo.CustomerOwner CO with (nolock)  
    INNER JOIN  Customers.dbo.Company C with (nolock)  
      ON        C.IDSeq = CO.OwnerIDSeq  
      AND       C.OwnerFlag = 1  
      AND       CO.CustomerIDSeq LIKE '%' + @IPVC_CompanyIDSeq + '%'  
    LEFT OUTER JOIN  Customers.dbo.Address A with (nolock)  
      ON            A.CompanyIDSeq = CO.OwnerIDSeq  
      AND           A.CompanyIDSeq = C.IDSEQ  
      AND           A.AddressTypeCode = 'COM'  
    WHERE       CO.CustomerIDSeq LIKE '%' + @IPVC_CompanyIDSeq + '%') tbl  
    ---------------------------------------------------------------------------------  
  
   where  Seq >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
   and   Seq <= (@IPI_PageNumber)   * @IPI_RowsPerPage  
  order by Seq asc  
  -----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------
  SELECT      COUNT(*) 
  FROM        Customers.dbo.CustomerOwner CO with (nolock)
  INNER JOIN  Customers.dbo.Company C with (nolock)
  ON          C.IDSeq = CO.OwnerIDSeq
  AND         C.OwnerFlag = 1
  AND         CO.CustomerIDSeq LIKE '%' + @IPVC_CompanyIDSeq + '%'
  WHERE       CO.CustomerIDSeq LIKE '%' + @IPVC_CompanyIDSeq + '%'
  -----------------------------------------------------------------------------------------
END

-- EXEC CUSTOMERS.dbo.[uspCUSTOMERS_OwnersList]  1, 10, 'C0000001635'
GO
