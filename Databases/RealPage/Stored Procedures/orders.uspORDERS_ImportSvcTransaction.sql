SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportSvcTransaction]
-- Description     : Imports a single transaction into an order
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_ImportSvcTransaction] (
                                              @IPVC_CompanyIDSeq     varchar(50), -- SiteMaster ID for the Company
                                              @IPVC_PropertyIDSeq    varchar(50), -- SiteMaster ID for the Property
                                              @IPVC_ProductCode      varchar(30), 
                                              @IPN_Quantity          numeric(5,2), 
                                              @IPN_Amount            decimal(18,3),
                                              @IPD_BillDate          datetime, 
                                              @IPVC_Description      varchar(70),
                                              @IPB_InvoiceFlag            bit,
                                              @IPI_TransactionImportIDSeq bigint = NULL,
                                              @IPI_SourceTransactionID    varchar(30) = NULL,
                                              @IPB_OverridePriceFlag      bit = 0,
                                              @IPB_ForceImportFlag        bit = 0 -- Do not check for duplicate
					    )					
AS
BEGIN 
  set nocount on;
  declare @LVC_AccountIDSeq varchar(50)
  declare @LVC_CodeSection  varchar(200)

  -- Using a left outer join may cause the wrong account to be returned. 
  if isnull(@IPVC_PropertyIDSeq,'') = ''
  begin
    --1 Try with SitemasterID first for @IPVC_CompanyIDSeq
    select Top 1
           @LVC_AccountIDSeq = a.IDSeq
    from   Customers.dbo.Account a with (nolock)
    inner join 
          Customers.dbo.Company c  with (nolock)
    on    c.IDSeq           = a.CompanyIDSeq
    and   c.SiteMasterID    = @IPVC_CompanyIDSeq 
    and   a.ActiveFlag      = 1
    and   a.AccountTypeCode = 'AHOFF'
    where a.ActiveFlag      = 1
    and   a.AccountTypeCode = 'AHOFF'
    ------------------------------------ 
    --2 If @LVC_AccountIDSeq is null then try with CompanyID for @IPVC_CompanyIDSeq
    If (@LVC_AccountIDSeq is null or @LVC_AccountIDSeq = '')
    begin
      select Top 1
           @LVC_AccountIDSeq = a.IDSeq
      from   Customers.dbo.Account a with (nolock)
      inner join 
             Customers.dbo.Company c  with (nolock)
      on    c.IDSeq           = a.CompanyIDSeq
      and   c.IDSeq           = @IPVC_CompanyIDSeq 
      and   a.ActiveFlag      = 1
      where a.ActiveFlag      = 1
      and   a.AccountTypeCode = 'AHOFF'
    end
  end
  ------------------------------------------------------------------------------------
  else
  ------------------------------------------------------------------------------------
  begin
    --1 Try with SitemasterID first for @IPVC_PropertyIDSeq
    select Top 1
          @LVC_AccountIDSeq = a.IDSeq
    from  Customers.dbo.Account a  with (nolock)
    inner join 
          Customers.dbo.Company c  with (nolock)
    on    c.IDSeq        = a.CompanyIDSeq
    and   c.SiteMasterID = @IPVC_CompanyIDSeq 
    inner join 
          Customers.dbo.[Property] p with (nolock)
    on    p.IDSeq            = a.PropertyIDSeq
    and   p.SiteMasterID     = @IPVC_PropertyIDSeq
    and   a.AccountTypeCode  = 'APROP'
    and   a.ActiveFlag = 1
    where a.ActiveFlag = 1
    and   a.AccountTypeCode  = 'APROP'
    ------------------------------------ 
    --2 If @LVC_AccountIDSeq is null then try with PropertyID for @IPVC_PropertyIDSeq
    If (@LVC_AccountIDSeq is null or @LVC_AccountIDSeq = '')
    begin
      select Top 1
             @LVC_AccountIDSeq = a.IDSeq
      from  Customers.dbo.Account a  with (nolock)
      inner join 
            Customers.dbo.Company c  with (nolock)
      on    c.IDSeq        = a.CompanyIDSeq
      and   c.IDSeq        = @IPVC_CompanyIDSeq 
      inner join 
            Customers.dbo.[Property] p with (nolock)
      on    p.IDSeq            = a.PropertyIDSeq
      and   p.IDSeq            = @IPVC_PropertyIDSeq
      and   a.AccountTypeCode  = 'APROP'
      and   a.ActiveFlag = 1
      where a.ActiveFlag = 1
      and   a.AccountTypeCode  = 'APROP'
    end
  end
  ------------------------------------------------------------------------------------  
  if (@LVC_AccountIDSeq is null or @LVC_AccountIDSeq = '')
  begin
    set @LVC_CodeSection = 'No account exists (PMC ID:' + @IPVC_CompanyIDSeq + 
        case when @IPVC_PropertyIDSeq is not null and @IPVC_PropertyIDSeq != ''
        then ' Site ID: ' + @IPVC_PropertyIDSeq
        else ''
        end + ')'

    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ------------------------------------------------------------------------------------
  ---If there are no errors and valid OMS Accountid is found then proceed
  exec [dbo].[uspORDERS_ImportTransaction] @IPVC_AccountIDSeq               = @LVC_AccountIDSeq, 
                                                @IPVC_ProductCode           = @IPVC_ProductCode, 
                                                @IPN_Quantity               = @IPN_Quantity, 
                                                @IPN_Amount                 = @IPN_Amount,
                                                @IPD_BillDate               = @IPD_BillDate, 
                                                @IPVC_Description           = @IPVC_Description,
                                                @IPB_InvoiceFlag            = @IPB_InvoiceFlag,
                                                @IPI_TransactionImportIDSeq = @IPI_TransactionImportIDSeq,
                                                @IPI_SourceTransactionID    = @IPI_SourceTransactionID,
                                                @IPB_OverridePriceFlag      = @IPB_OverridePriceFlag,
                                                @IPB_ForceImportFlag        = @IPB_ForceImportFlag

  ------------------------------------------------------------------------------------
END

GO
