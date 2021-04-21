SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_LogTransactionImport
-- Description     : Log information about the import that occurred for a transaction
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Bhavesh Shah - 07/11/2008
--                 : Added CompanyIDSeq, PropertyIDSeq, AccountIDSeq to improve performance.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_LogTransactionImport] (
                                              @IPVC_PMCDBID                   varchar(20), 
                                              @IPVC_SiteDBID                  varchar(20), 
                                              @IPI_TransactionImportIDSeq     bigint,
                                              @IPI_OrderItemTransactionIDSeq  bigint,
                                              @IPC_StatusCode                 char(5), 
                                              @IPVC_ProductCode               varchar(20), 
                                              @IPVC_ServiceCode               varchar(20), 
                                              @IPVC_TransactionName           varchar(70),
                                              @IPN_Amount                     numeric(10, 2),
                                              @IPB_TransactionalFlag          bit,
                                              @IPB_InvoicedFlag               bit,
                                              @IPD_ServiceDate                datetime, 
                                              @IPI_SourceTransactionID        varchar(30),
                                              @IPN_Quantity                   decimal(18,3), 
                                              @IPVC_Description               varchar(255),
                                              @IPVC_CompanyIDSeq              varchar(22) = null,
                                              @IPVC_PropertyIDSeq             varchar(22) = null,
                                              @IPVC_AccountIDSeq              varchar(22) = null
					    )					
AS
BEGIN 
  declare @LVC_AccountIDSeq varchar(22)

  SET @IPVC_CompanyIDSeq = nullif(@IPVC_CompanyIDSeq, '');
  SET @IPVC_PropertyIDSeq = nullif(@IPVC_PropertyIDSeq, '');
  SET @IPVC_AccountIDSeq = nullif(@IPVC_AccountIDSeq, '');

  if ( @IPVC_AccountIDSeq is null )
  BEGIN
    if isnull(@IPVC_SiteDBID, '') = ''
      select @LVC_AccountIDSeq = a.IDSeq
      from Customers.dbo.Account a with (nolock)
      inner join Customers.dbo.Company c with (nolock)
      on    c.IDSeq = a.CompanyIDSeq
      and   c.SiteMasterID = @IPVC_PMCDBID 
      where a.ActiveFlag = 1
      and   a.AccountTypeCode = 'AHOFF'
    else
      select @LVC_AccountIDSeq = a.IDSeq
      from Customers.dbo.Account a with (nolock)
      inner join Customers.dbo.Company c with (nolock)
      on    c.IDSeq = a.CompanyIDSeq
      and   c.SiteMasterID = @IPVC_PMCDBID 
      inner join Customers.dbo.[Property] p with (nolock)
      on    p.IDSeq = a.PropertyIDSeq
      and   p.SiteMasterID = @IPVC_SiteDBID
      where a.ActiveFlag = 1
      and   a.AccountTypeCode = 'APROP'
  END
  ELSE
  BEGIN
    SET @LVC_AccountIDSeq = @IPVC_AccountIDSeq;
  END
/*
  select @LVC_AccountIDSeq = IDSeq
  from Customers.dbo.Account a
  where SiteMasterID = case when @IPVC_SITEDBID = '' then 
                        @IPVC_PMCDBID 
                       else @IPVC_SITEDBID end
*/

  insert into TransactionImportItem (AccountIDSeq, TransactionImportIDSeq, OrderItemTransactionIDSeq,
    TransactionStatusCode, ProductCode, ServiceCode, TransactionItemName, NetChargeAmount, TransactionalFlag,
    InvoicedFlag, SourceTransactionID, ServiceDate, Quantity, [Description], 
    CompanyIDSeq, PropertyIDSeq)
  values (@LVC_AccountIDSeq, @IPI_TransactionImportIDSeq, @IPI_OrderItemTransactionIDSeq,
    @IPC_StatusCode, @IPVC_ProductCode, @IPVC_ServiceCode, @IPVC_TransactionName, @IPN_Amount, 
    @IPB_TransactionalFlag, @IPB_InvoicedFlag, @IPI_SourceTransactionID, @IPD_ServiceDate, @IPN_Quantity, 
    @IPVC_Description,@IPVC_CompanyIDSeq,@IPVC_PropertyIDSeq)

  select SCOPE_IDENTITY() as TransactionImportItemIDSeq
END

GO
