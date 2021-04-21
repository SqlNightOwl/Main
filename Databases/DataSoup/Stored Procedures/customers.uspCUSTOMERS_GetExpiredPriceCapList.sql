SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  [uspCUSTOMERS_GetExpiredPriceCapList]
-- Description     :  This procedure gets the list of Price Cap 
--                    for the specified Company ID.
-- Input Parameters: 	1. @PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetExpiredPriceCapList
--                        @IPI_PageNumber       1, 
--                        @IPI_RowsPerPage      10,
--                        @IPVC_CompanyIDSeq    'C000000001'
-- 
-- Revision History:
-- Author          : Naval Kishore
-- 07/13/2007      : Stored Procedure Created.
-- 07/28/2009      : Naval Kishore Modified to get count of Properties & Products
-- 11/05/2009      : Naval Kishore Modified to get total page count. Defect #6962 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [customers].[uspCUSTOMERS_GetExpiredPriceCapList]   
                  @IPI_PageNumber       int, 
                  @IPI_RowsPerPage      int,
                  @IPVC_CompanyIDSeq    char(11),
                  @IPVC_PriceCapIDSeq   varchar(11),
                  @IPVC_PropertyIDSeq   varchar(11)

AS
BEGIN
  
  -----------------------------------------------------------------------------
  SELECT  * FROM 
    -----------------------------------------------------------------------
	  (SELECT TOP (@IPI_RowsPerPage * @IPI_PageNumber)
                    PH.PriceCapIDSeq                                               as PriceCapIDSeq,
                    PH.PriceCapName                                                as ProductName,
                    Customers.dbo.fnGetPropertiesCountForExpiredPriceCap(PH.PriceCapIDSeq)           as Properties,
                    Customers.dbo.fnGetProductCountForExpiredPriceCap(PH.PriceCapIDSeq)              as Products,
                    convert(numeric(30,2),PH.PriceCapPercent)                      as PriceCapPercent,
                    pcapbasis.Name                                                 as PriceCapBasis, 
                    convert(varchar(10),PH.PriceCapStartDate,101)                  as PriceCapStartDate,
                    convert(varchar(10),PH.PriceCapEndDate,101)                    as PriceCapEndDate,
                    'Expired'                                                      as Status,
                    (select dbo.fnGetUserNamefromID(PH.CreatedByID))               as CreatedBy,
                    row_number() over(order by PH.PriceCapIDSeq) as RowNumber 
                    from  Customers.dbo.PriceCapHistory PH        with (nolock)
                    inner join 
                          Products.dbo.PriceCapBasis    pcapbasis with (nolock)
                    on    PH.PriceCapBasisCode = pcapbasis.Code
                    and   PH.CompanyIDSeq = @IPVC_CompanyIDSeq
                    and  (@IPVC_PriceCapIDSeq    is not null and  PH.PriceCapIDSeq  like '%'+@IPVC_PriceCapIDSeq+'%')           
                    and   PH.PriceCapIDSeq NOT IN (select IDSeq FROM Customers.dbo.PriceCap with (nolock))
           WHERE          PH.CompanyIDSeq = @IPVC_CompanyIDSeq
           and            (@IPVC_PriceCapIDSeq    is not null and  PH.PriceCapIDSeq  like '%'+@IPVC_PriceCapIDSeq+'%')           
           and            PH.PriceCapIDSeq NOT IN (select IDSeq FROM Customers.dbo.PriceCap with (nolock))
           group by PH.PriceCapIDSeq,PH.PriceCapName,convert(numeric(30,2),PH.PriceCapPercent),pcapbasis.Name,
                 convert(varchar(10),PH.PriceCapStartDate,101),convert(varchar(10),PH.PriceCapEndDate,101),
                 PH.CreatedByID
          
   ) LV_PriceCapTable
    -----------------------------------------------------------------------
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
  -----------------------------------------------------------------------------
   SELECT COUNT(*) FROM  Customers.dbo.PriceCapHistory PH        with (nolock)
                    inner join 
                          Products.dbo.PriceCapBasis    pcapbasis with (nolock)
                    on    PH.PriceCapBasisCode = pcapbasis.Code
                    and   PH.CompanyIDSeq = @IPVC_CompanyIDSeq
                    and   PH.PriceCapIDSeq NOT IN (select IDSeq FROM Customers.dbo.PriceCap with (nolock))
           WHERE          PH.CompanyIDSeq = @IPVC_CompanyIDSeq


END
GO
