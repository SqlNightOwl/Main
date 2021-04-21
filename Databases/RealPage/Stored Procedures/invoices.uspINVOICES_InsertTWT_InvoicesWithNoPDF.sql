SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_InsertTWT_InvoicesWithNoPDF
-- Description     : This procedure Inserts TWT_InvoicesWithNoPDF
-- Input Parameters: as below
--      
-- OUTPUT          : 
--
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_InsertTWT_InvoicesWithNoPDF;
    
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 10/12/2009      : Stored Procedure Created.         
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InsertTWT_InvoicesWithNoPDF] (@IPVC_DocumentIDSeq     varchar(50),
                                                                  @IPVC_DocumentPath      varchar(8000),
                                                                  @IPVC_InvoiceIDSeq      varchar(50),
                                                                  @IPVC_CompanyIDSeq      varchar(50),
                                                                  @IPVC_AccountName       varchar(255),
                                                                  @IPVC_CompanyName       varchar(255),
                                                                  @IPVC_AccountIDSeq      varchar(50),
                                                                  @IPVC_RunDate           varchar(50)
                                                                 )
AS
BEGIN 
  set nocount on;
  Insert into INVOICES.dbo.TWT_InvoicesWithNoPDF(DocumentIDSeq,DocumentPath,InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,RunDateTime)
  select @IPVC_DocumentIDSeq as DocumentIDSeq,@IPVC_DocumentPath as DocumentPath,
         @IPVC_InvoiceIDSeq  as InvoiceIDSeq,@IPVC_CompanyIDSeq  as CompanyIDSeq,
         @IPVC_AccountName   as AccountName,@IPVC_CompanyName    as CompanyName,
         @IPVC_AccountIDSeq  as AccountIDSeq,
         @IPVC_RunDate       as RunDateTime
END
GO
