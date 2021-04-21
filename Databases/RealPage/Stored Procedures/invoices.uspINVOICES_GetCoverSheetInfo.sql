SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_GetCoverSheetInfo]
-- Description     : This procedure returns CoverSheet Info for PrintFlag = 1 and SentToEpicorFlag =0
--                   This is intended to be used only for Adhoc process where regular coversheet printing
--                   from UI has missed printing CoverSheet
-- OUTPUT          : RecordSet 
-- Revision History:
-- Author          : SRS
-- 02/06/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
-- exec uspINVOICES_GetCoverSheetInfo @IPVC_PrintBatchID = 67
CREATE PROCEDURE [invoices].[uspINVOICES_GetCoverSheetInfo] (@IPVC_PrintBatchID  varchar(50)='')
AS
BEGIN
  set nocount on;
  set @IPVC_PrintBatchID = nullif(@IPVC_PrintBatchID,'');
  ------------------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_TEMPCoverSheetInfo') is not null) 
  begin
    drop table #LT_TEMPCoverSheetInfo;
  end;
  ------------------------------------------------------------------------------------
  select distinct   I.InvoiceIDSeq                                    as InvoiceIDSeq,
                    Max(I.CompanyIDSeq)                               as CompanyIDSeq,
                    isnull(Max(I.PropertyName),Max(I.CompanyName))    as AccountName,
                    Max(I.CompanyName)                                as CompanyName,
                    I.AccountIDSeq                                    as AccountIDSeq,                     
                    Max(I.BillToAccountName)                          as BillToAccountName,
                    coalesce(Max(I.BillToAddressLine1),'')            as BillToAddressLine1,
                    coalesce(Max(I.BillToAddressLine2),'')            as BillToAddressLine2,
                    Max(I.BillToCity)                                 as BillToCity,
                    Max(I.BillToState)                                as BillToState,
                    Max(I.BillToZip)                                  as BillToZip,
                    Max(I.BillToCountry)                              as BillToCountry,                                       
                    SUM(TotalPageCount)                               as TotalPages,
                    MAX(I.PrintBatchId)                               as PrintBatchId,
                    RANK() OVER (ORDER BY Max(I.BillToState)        ASC,
                                          Max(I.BillToZip)          ASC,
                                          Max(I.BillToCity)         ASC,
                                          Max(I.BillToCountry)      ASC,
                                          Max(I.BillToAddressLine1) ASC,
                                          Max(I.BillToAddressLine2) ASC,
                                          Max(I.BillToAccountName)  ASC
                                 )                                    as InternalRank
  ---------------------------------------------------  
  Into #LT_TEMPCoverSheetInfo                       
  ---------------------------------------------------
  from INVOICES.dbo.Invoice     I   with (nolock)       
  where I.printflag = 1  and I.SentToEpicorFlag = 0 
  and   coalesce(I.PrintBatchID,'') = coalesce(@IPVC_PrintBatchID,I.PrintBatchID,'')
  group by I.Invoiceidseq,I.AccountIDSeq
  order by BillToState ASC,BillToZip ASC,BillToCity ASC,BillToCountry ASC,BillToAddressLine1 ASC,BillToAccountName ASC,I.Invoiceidseq ASC
  ------------------------------------------------------------------------------------
  --Final Select  
  select S.BillToAccountName ,S.BillToAddressLine1,S.BillToAddressLine2,S.BillToCity,S.BillToState,S.BillToZip,S.BillToCountry,       
       Sum(S.TotalPages) as TotalPages,Count(Distinct S.InvoiceIDSeq) as TotalInvoiceCount,
       Max(S.PrintBatchId) as PrintBatchId
  from #LT_TEMPCoverSheetInfo S with (nolock)   
  Group by S.BillToAccountName,S.BillToAddressLine1,S.BillToAddressLine2,S.BillToCity,S.BillToState,S.BillToZip,S.BillToCountry,
           S.InternalRank--,S.PrintBatchId
  having (Sum(S.TotalPages) > 5 or Count(Distinct S.InvoiceIDSeq) > 1)
  order by PrintBatchId asc,BillToState ASC,BillToZip ASC,BillToCity ASC,BillToCountry ASC,
           BillToAddressLine1 ASC,BillToAccountName ASC;
  ------------------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_TEMPCoverSheetInfo') is not null) 
  begin
    drop table #LT_TEMPCoverSheetInfo;
  end;
  ------------------------------------------------------------------------------------
End

GO
