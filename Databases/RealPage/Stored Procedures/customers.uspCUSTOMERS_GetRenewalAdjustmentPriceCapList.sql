SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspCUSTOMERS_GetPriceCapList
-- Description     :  This procedure gets the list of Price Cap 
--                    for the specified Company ID.
-- Input Parameters: 	1. @PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetRenewalAdjustmentPriceCapList  
--                        @IPI_PageNumber       1, 
--                        @IPI_RowsPerPage      10,
--                        @IPVC_CompanyIDSeq    'C000000001'
-- 
-- Revision History:
-- Author          : Naval Kishore SIngh
-- 04/12/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [customers].[uspCUSTOMERS_GetRenewalAdjustmentPriceCapList]   
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
	  (SELECT  TOP   (@IPI_RowsPerPage * @IPI_PageNumber)
                    pcap.IDSeq                                                     as PriceCapIDSeq,
                    pcap.PriceCapName                                              as ProductName,
                    Customers.dbo.fnGetPropertiesCount(pcap.IDSeq)                 as Properties,
                    Customers.dbo.fnGetProductCount(pcap.IDSeq)                    as Products,
                    convert(numeric(30,2),pcap.PriceCapPercent) as PriceCapPercent,
                    pcapbasis.Name as PriceCapBasis, 
                    convert(varchar(10),pcap.PriceCapStartDate,101) as PriceCapStartDate,
                    convert(varchar(10),pcap.PriceCapEndDate,101) as PriceCapEndDate,
                    (case when ActiveFlag = 1
                         then 'Active'
                          else 'Inactive' end)                    as Status,
                    (select dbo.fnGetUserNamefromID(pcap.CreatedByID))       as CreatedBy,
                    row_number() over(order by pcap.IDSeq) as RowNumber 
                    from Customers.dbo.PriceCap pcap
                    inner join Products.dbo.PriceCapBasis pcapbasis 
                    on pcap.PriceCapBasisCode = pcapbasis.Code
 
 where              pcap.CompanyIDSeq = @IPVC_CompanyIDSeq
				
                      and (@IPVC_PriceCapIDSeq    is not null and  pcap.IDSeq  like '%'+@IPVC_PriceCapIDSeq+'%')           
                     
					and SystemGeneratedPriceCapFlag = 1
          
   ) LV_PriceCapTable
    -----------------------------------------------------------------------
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
  -----------------------------------------------------------------------------
  

  -----------------------------------------------------------------------------
   
  SELECT  count(*) from Customers.dbo.PriceCap pcap
                    left join Products.dbo.PriceCapBasis pcapbasis 
                    on pcap.PriceCapBasisCode = pcapbasis.Code

                     where  pcap.CompanyIDSeq = @IPVC_CompanyIDSeq

                      and (@IPVC_PriceCapIDSeq    is not null and  pcap.IDSeq  like '%'+@IPVC_PriceCapIDSeq+'%')
						and SystemGeneratedPriceCapFlag = 1
           
  -----------------------------------------------------------------------------

END

--exec Customers.dbo.[uspCUSTOMERS_GetPriceCapList] 1, 14, 'C0000025553','',''

--Customers.dbo.[uspCUSTOMERS_GetPriceCapList] 1, 14, 'C0000001635'
--
GO
