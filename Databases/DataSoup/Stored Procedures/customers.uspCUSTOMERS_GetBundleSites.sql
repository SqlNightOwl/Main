SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetBundleSites]
-- Description     : This procedure Selects CustomBundlesProductBreakDownTypeCode in Customer and Property Table
--Input Parameter  : @IPVC_CustomerIDSEQ           bigint, 
--                  
--
-- Code Example    : Products..[uspCUSTOMERS_GetBundleSites] 
--                   @IPVC_CustomerIDSEQ = 'C0802000010',
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 07/24/2007      : Stored Procedure Created.
-- Revised         : Anand Chakravarthy
-- 03/28/2008      : Stored Procedure Revised.
-- 12/01/2009      : Naval Kishore Modifed to add new parameters @IPVC_SelectedOption
-- 23/03/2010      : Naval Kishore Modifed to add get SameAsPMCAddressFlag.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetBundleSites] (
                                                      @IPVC_CustomerIDSEQ             varchar(50),
                                                      @IPVC_SelectedOption            varchar(30) 
                                                             
                                                      )     
AS
BEGIN 
  set nocount on;
  -------------------------------------------------
    CREATE TABLE #tempTblGetBundleSites
    (
      RowNumber                  int identity(1,1) not null primary key,
      PropertyIDSeq              varchar(22),
      PropertyName               varchar(100),
      BundleTypeCode             varchar(10),      
      BillingEmail               varchar(2000),
      SameAsPMCAddressFlag       bit
     )
  -------------------------------------------------
    INSERT INTO #tempTblGetBundleSites(PropertyIDSeq,PropertyName,BundleTypeCode,BillingEmail,SameAsPMCAddressFlag)
    SELECT C.IDSEQ                                                          AS PropertyIDSeq,
           C.[Name]                                                         AS PropertyName,
           CASE WHEN @IPVC_SelectedOption = 'ExpandBundle' THEN CustomBundlesProductBreakDownTypeCode
                WHEN @IPVC_SelectedOption = 'PrintSeparateInvoice'
                     and C.SeparateInvoiceByFamilyFlag = 1 THEN 'YEBR'
                WHEN @IPVC_SelectedOption = 'PrintSeparateInvoice'
                     and C.SeparateInvoiceByFamilyFlag = 0 THEN 'NOBR'
                WHEN @IPVC_SelectedOption = 'DoNotPrint'
                     and C.SendInvoiceToClientFlag = 1 THEN 'YEBR'
                WHEN @IPVC_SelectedOption = 'DoNotPrint'
                     and C.SendInvoiceToClientFlag = 0 THEN 'NOBR'		
                ELSE ''
          END                                                               AS BundleTypeCode,
          Addr.Email                                                        AS BillingEmail,
          Addr.SameAsPMCAddressFlag                                         AS SameAsPMCAddressFlag
    FROM    CUSTOMERS.dbo.COMPANY C with (nolock)
    INNER JOIN
            CUSTOMERS.dbo.[ADDRESS] Addr with (nolock)
    ON    C.IDSEq = Addr.CompanyIDSeq
    and   C.IDSeq = @IPVC_CustomerIDSEQ
    and   Addr.CompanyIDSeq = @IPVC_CustomerIDSEQ
    AND   Addr.PropertyIDSeq is null
    AND   Addr.AddressTypeCode = 'CBT'     
    WHERE C.IDSeq = @IPVC_CustomerIDSEQ
    -------------------------------------------------
    INSERT INTO #tempTblGetBundleSites(PropertyIDSeq,PropertyName,BundleTypeCode,BillingEmail,SameAsPMCAddressFlag)
    SELECT P.IDSEQ                                                          AS PropertyIDSeq,
           P.[Name]                                                         AS PropertyName,
           CASE WHEN @IPVC_SelectedOption = 'ExpandBundle' THEN CustomBundlesProductBreakDownTypeCode
                WHEN @IPVC_SelectedOption = 'PrintSeparateInvoice'
                     and P.SeparateInvoiceByFamilyFlag = 1 THEN 'YEBR'
                WHEN @IPVC_SelectedOption = 'PrintSeparateInvoice'
                     and P.SeparateInvoiceByFamilyFlag = 0 THEN 'NOBR'
                WHEN @IPVC_SelectedOption = 'DoNotPrint'
                     and P.SendInvoiceToClientFlag = 1 THEN 'YEBR'
                WHEN @IPVC_SelectedOption = 'DoNotPrint'
                     and P.SendInvoiceToClientFlag = 0 THEN 'NOBR'		
                ELSE ''
          END                                                               AS BundleTypeCode,
          Addr.Email                                                        AS BillingEmail,
          Addr.SameAsPMCAddressFlag                                         AS SameAsPMCAddressFlag
    FROM    CUSTOMERS.dbo.Property P with (nolock)
    INNER JOIN
            CUSTOMERS.dbo.[ADDRESS] Addr with (nolock)
    ON    P.PMCIDSEQ = Addr.CompanyIDSeq
    and   P.PMCIDSEQ = @IPVC_CustomerIDSEQ
    and   Addr.CompanyIDSeq = @IPVC_CustomerIDSEQ
    AND   Addr.AddressTypeCode = 'PBT'  
    AND   P.IDSeq   = Addr.PropertyIDSeq
    AND   Addr.PropertyIDSeq is not null
    WHERE P.PMCIDSeq = @IPVC_CustomerIDSEQ
    ORDER BY PropertyName
  -------------------------------------------------
    SELECT PropertyIDSeq,PropertyName,BundleTypeCode,BillingEmail,SameAsPMCAddressFlag
    From   #tempTblGetBundleSites with (nolock) 
    Order by RowNumber ASC
  -------------------------------------------------
   if (object_id('tempdb.dbo.#tempTblGetBundleSites') is not null) 
   begin
     drop table #tempTblGetBundleSites
   end 
  -------------------------------------------------
END
GO
