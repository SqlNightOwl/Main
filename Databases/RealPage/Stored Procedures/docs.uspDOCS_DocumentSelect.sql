SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_DocumentSelect

Purpose    :  Gets Data from Document table based on primary key.
             
Parameters : 


Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_DocumentSelect

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_DocumentSelect]
(
  @IP_DocumentIDSeq varchar (22)
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
    OrderIDSeq,
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
    Document
  Where
    DocumentIDSeq = @IP_DocumentIDSeq

GO
