SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_DocumentHistoryInsert

Purpose    :  Saves Data into DocumentHistory table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/08/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_DocumentHistoryInsert

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_DocumentHistoryInsert]
(
  @IP_IDSeq numeric (30, 0),
  @IP_DocumentIDSeq varchar (22),
  @IP_IterationCount bigint,
  @IP_StatusCode varchar (3),
  @IP_DocumentClassIDSeq bigint,
  @IP_ScopeCode varchar (3),
  @IP_Name varchar (255),
  @IP_Description varchar (4000),
  @IP_CompanyIDSeq varchar (11),
  @IP_PropertyIDSeq varchar (11),
  @IP_AccountIDSeq varchar (11),
  @IP_ContractIDSeq [varchar](22),
  @IP_QuoteIDSeq varchar (22),
  @IP_OrderIDSeq varchar (22),
  @IP_InvoiceIDSeq varchar (22),
  @IP_CreditMemoIDSeq varchar (22),
  @IP_ActiveFlag bit,
  @IP_DocumentPath varchar (255),
  @IP_AttachmentFlag bit,
  @IP_CreatedBy varchar (70),
  @IP_ModifiedBy varchar (70),
  @IP_CreatedDate datetime,
  @IP_ModifiedDate datetime 
)
AS
    INSERT INTO DocumentHistory
      (DocumentIDSeq
       , IterationCount, StatusCode, DocumentClassIDSeq
       , ScopeCode, Name, Description
       , CompanyIDSeq, PropertyIDSeq, AccountIDSeq
       , ContractIDSeq, QuoteIDSeq,OrderIDSeq,InvoiceIDSeq
       , CreditMemoIDSeq, ActiveFlag, DocumentPath
       , AttachmentFlag, CreatedBy, ModifiedBy
       , CreatedDate, ModifiedDate)
    OUTPUT 
       INSERTED.IDSeq as IDSeq
    VALUES
      (@IP_DocumentIDSeq
       , @IP_IterationCount, @IP_StatusCode, @IP_DocumentClassIDSeq
       , @IP_ScopeCode, @IP_Name, @IP_Description
       , @IP_CompanyIDSeq, @IP_PropertyIDSeq, @IP_AccountIDSeq
       , @IP_ContractIDSeq, @IP_QuoteIDSeq, @IP_OrderIDSeq, @IP_InvoiceIDSeq
       , @IP_CreditMemoIDSeq, @IP_ActiveFlag, @IP_DocumentPath
       , @IP_AttachmentFlag, @IP_CreatedBy, @IP_ModifiedBy
       , @IP_CreatedDate, @IP_ModifiedDate)

GO
