SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-----------------------------------------------------------------------
Procedure  : uspINVOICES_DocLinkGetCreditListForCreditMemos

Purpose    : Gets data from Invoices PrintBatch table and also
             Checking to see if PrintBatchIDSeq has atleast 1
             qualifying Invoice already printed,senttoepicor
             and ready to be pushed to DOCLink
             
Parameters : @IPI_PageNumber,@IPI_RowsPerPage

Returns    : All Qualifying Batches
Date         Author                  Comments
-------------------------------------------------------
01/19/2008   SRS              Initial Creation

Example: EXEC uspINVOICES_DocLinkGetCreditListForCreditMemos

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
-----------------------------------------------------------------------
*/     
CREATE Procedure [invoices].[uspINVOICES_DocLinkGetCreditListForCreditMemos]
AS
BEGIN
  set nocount on;
  SELECT  Count(distinct CM.CreditMemoIDSeq) AS CreditMemoCount
  from INVOICES.dbo.CreditMemo     CM   with (nolock)
  inner join 
       DOCUMENTS.dbo.[document]    doc with (nolock) 
  on    doc.CreditMemoIDSeq =CM.CreditMemoIDSeq              
  and   doc.CreditMemoIDSeq is not null
  and   doc.DocumentPath    is not null
  and   doc.ActiveFlag      = 1        
  and   CM.SentToEpicorFlag = 1
  and   CM.SentToDocLinkFlag= 0
  where doc.CreditMemoIDSeq is not null
  and   doc.DocumentPath    is not null
  and   doc.ActiveFlag      = 1        
  and   CM.SentToEpicorFlag = 1
  and   CM.SentToDocLinkFlag= 0
END
GO
