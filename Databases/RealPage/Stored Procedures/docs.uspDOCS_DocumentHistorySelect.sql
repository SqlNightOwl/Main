SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_DocumentHistorySelect

Purpose    :  Gets Data from Document table based on primary key.
             
Parameters : 


Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_DocumentHistorySelect

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_DocumentHistorySelect]
(
  @IP_DocumentHistoryIDSeq varchar (22)
)
AS
  Select
    DocumentIDSeq,
    IterationCount,
    StatusCode,
    DocumentClassIDSeq,
    ScopeCode,
    Name,
    Description,
    CompanyIDSeq,
    PropertyIDSeq,
    AccountIDSeq,
    ContractIDSeq,
    QuoteIDSeq,
    InvoiceIDSeq,
    CreditMemoIDSeq,
    ActiveFlag,
    DocumentPath,
    AttachmentFlag,
    CreatedBy,
    ModifiedBy,
    CreatedDate,
    ModifiedDate
  From
    DocumentHistory
  Where
   IDSeq = @IP_DocumentHistoryIDSeq

GO
