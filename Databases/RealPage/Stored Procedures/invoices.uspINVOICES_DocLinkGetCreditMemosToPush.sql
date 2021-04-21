SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_DocLinkGetCreditMemosToPush
-- Description     : This procedure gets the invoices that have been printed
-- Revision History:
-- Author          : SRS
-- 01/19/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_DocLinkGetCreditMemosToPush] 
AS
BEGIN
  set nocount on;
  -----------------------------
  select   Min(doc.DocumentIDSeq)                              as DocumentIDSeq
          ,Min(ISNULL(cdp.CompanyIDDocumentPath, '')) 
           + '\' + 
           Min(doc.DocumentPath)                               as DocumentPath
          ,CM.CreditMemoIDSeq                                  as CreditMemoIDSeq
          ,Max(cdp.CompanyIDSeq)                               as CompanyIDSeq
		  ,MAX(AD.CountryCode)								  as CountryCode
    from INVOICES.dbo.CreditMemo     CM   with (nolock)
    inner join 
         DOCUMENTS.dbo.[document]    doc with (nolock) 
    on   doc.CreditMemoIDSeq =CM.CreditMemoIDSeq              
    and  doc.CreditMemoIDSeq is not null
    and  doc.DocumentPath    is not null
    and  doc.ActiveFlag      = 1        
    and  CM.SentToEpicorFlag = 1
    and  CM.SentToDocLinkFlag= 0         
    Left outer Join
        DOCUMENTS.dbo.CompanyDocumentPath cdp with (nolock)
    on   doc.CompanyIDSeq = cdp.CompanyIDSeq   
	inner join customers.dbo.[Address] AD with (nolock) 
    on AD.CompanyIDSeq=doc.CompanyIDSeq 
    and AD.AddressTypeCode='COM'  
    group by CM.CreditMemoIDSeq
END
GO
