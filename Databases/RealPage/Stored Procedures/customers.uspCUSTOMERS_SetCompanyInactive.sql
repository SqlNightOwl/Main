SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_SetCompanyInactive
-- Description     : This procedure will do the following in an all or Nothing fashion
--                        a) Rollback all Open Invoiceitems pertaining Orders that relate to Company and its properties.
--                        b) Cancel Non Cancelled and Non Expired Orders (that relate to Company and its properties) 
--                                 and set it to a state where it does not Invoice again.
--                        C) Cancel all Non approved Quote that relate to Company
--                        d) Inactive Related Properties and its Accounts.
--                        e) Finally Inactivate the Company and its Accounts.
--                        f) Rollsback entire operation if there is any error and return a critical error which UI should trap.
--                        e) If no errors, Return Metrics back --- This will be used for future enhancement to show in UI
--                              as  to what the user cancelled.
-- Input Parameters: 1.  @IPVC_CompanyID    as String,
--                   2.  @IPVI_ModifiedByID as Integer
-- 
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_SetCompanyInactive @IPVC_CompanyID = 'C0901000003', 
--								        @IPVC_ModifiedByID = 123
-- Revision History:
-- Author          : Satya B
-- 05/24/2010      : Stored Procedure Created.
-- 06/18/2010      : Corrected proc for BL Logic to Rollback open Invoices as well
--                   And the entire operation should be a all or nothing operation--
-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 06/18/2010   Satya B		Defect #7750 -- Ability to Inactivate a company.
-- 06/18/2010   SRS             Enhancement and BL fix.
-- 08/09/2011   Mahaboob	Defect #909  Deactivate "Executive-Child" Relationships
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
--============================================================================================================================
CREATE PROCEDURE [customers].[uspCUSTOMERS_SetCompanyInactive] (@IPVC_CompanyIDSeq     varchar(50),
                                                          @IPBI_UserID           bigint
                                                         )
AS
BEGIN --> Main Begin
  set nocount on;
  --------------------------------------------------------------------
  declare @LVC_CodeSection         varchar(1000);  
  --------------------------------------------------------------------
  ---Validation 1: If input CompanyID is already in Inactive State, Validate and throw a critical error.
  --               UI will have to trap the error and show appropriately and also log to customers.dbo.ErrorLog table 
  --               using existing common logging mechanism
  --               This is sanity check.
  --------------------------------------------------------------------
  If exists (select top 1 1 
             from   Customers.dbo.Company C with (nolock)
             where  C.IDSeq          = @IPVC_CompanyIDSeq
             and    C.StatusTypecode = 'INACT'
            )
  begin
    select  @LVC_CodeSection ='Company :' + @IPVC_CompanyIDSeq + ' is already Inactive. Aborting Operation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  --------------------------------------------------------------------    
  ---Validation 2: If input CompanyID is does not exist in the system, Validate and throw a critical error.
  --               UI will have to trap the error and show appropriately and also log to customers.dbo.ErrorLog table 
  --               using existing common logging mechanism
  --               This is sanity check.
  --------------------------------------------------------------------
  If not exists (select top 1 1 
                 from   Customers.dbo.Company C with (nolock)
                 where  C.IDSeq          = @IPVC_CompanyIDSeq             
                 )
  begin
    select  @LVC_CodeSection ='Company :' + @IPVC_CompanyIDSeq + ' does not existing in OMS. Aborting Operation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  --------------------------------------------------------------------
  --Declare Local table Variable to capture metrics to show at the end.
  declare @LT_OrderitemsCanceled  table
                                  (IDSeq            bigint identity(1,1) not null primary key,
                                   CompanyIDSeq     varchar(50),
                                   PropertyIDSeq    varchar(50),
                                   AccountIDSeq     varchar(50),
                                   OrderIDSeq       varchar(50),
                                   OrderitemIDSeq   bigint
                                  );

  declare @LT_QuotesCanceled  table
                                  (IDSeq            bigint identity(1,1) not null primary key,
                                   CompanyIDSeq     varchar(50),
                                   QuoteIDSeq       varchar(50)
                                  );

  declare @LT_OpenInvoicesRolledback table
                                  (IDSeq            bigint identity(1,1) not null primary key,
                                   CompanyIDSeq     varchar(50),
                                   PropertyIDSeq    varchar(50),
                                   AccountIDSeq     varchar(50),
                                   InvoiceIDSeq     varchar(50),
                                   InvoiceItemIDSeq bigint
                                  );
  declare @LT_AccountsInactivated table
                                  (IDSeq            bigint identity(1,1) not null primary key,
                                   CompanyIDSeq     varchar(50),
                                   PropertyIDSeq    varchar(50),
                                   AccountIDSeq     varchar(50)                                   
                                  );
  declare @LT_PropertiesInactivated table
                                  (IDSeq            bigint identity(1,1) not null primary key,
                                   CompanyIDSeq     varchar(50),
                                   PropertyIDSeq    varchar(50)                                  
                                  );

  declare @LI_CancelorderItemCount        int,
          @LI_CancelQuoteCount            int,
          @LI_RolledbackInvoiceItemCount  int,
          @LI_InactivatedAccountsCount    int,
          @LI_InactivatedPropertiesCount  int;
          
  declare @LI_Min                         int, 
          @LI_Max                         int,
          @LVC_InvoiceIDSeq               varchar(50),
          @LVC_PropertyIDSeq              varchar(50);

  declare @LVC_UserName                   varchar(100);
  declare @LDT_CurrentSystemDate          datetime; --To keep datatime for entire operation the same

  select @LI_CancelorderItemCount=0,@LI_CancelQuoteCount=0,
         @LI_RolledbackInvoiceItemCount=0,@LI_InactivatedAccountsCount=0,
         @LI_InactivatedPropertiesCount=0,
         @LI_Min=1,@LI_Max=0,
         @LDT_CurrentSystemDate=GETDATE(); 

  select Top 1 @LVC_UserName = U.FirstName + ' ' + U.LastName
  from   Security.dbo.[User] U with (nolock)
  where  U.IDSeq = @IPBI_UserID
  --------------------------------------------------------------------
  --Start entire all or nothing opertations inside a Transaction.
  --    In the event of error, throw critical error and rollback.
  BEGIN TRY
    BEGIN TRANSACTION A;
      ---Step 1: Rollback open Invoices for Company and related Properties in Question.
      Delete IIN
      from   Invoices.dbo.Invoice I  with (nolock) 
      inner join
             Invoices.dbo.Invoiceitem II with (nolock)      
      on     II.InvoiceIDSeq = I.InvoiceIDSeq
      and    I.PrintFlag     = 0
      and    I.CompanyIDSeq  = @IPVC_CompanyIDSeq
      inner join
             Invoices.dbo.InvoiceitemNote IIN with (nolock)
      on     IIN.InvoiceIDSeq   = I.InvoiceIDSeq
      and    IIN.InvoiceIDSeq   = II.InvoiceIDSeq
      and    IIN.OrderIDSeq     = II.OrderIDSeq
      and    IIN.OrderItemIDSeq = IIN.OrderItemIDSeq
             
      Delete II
      Output I.CompanyIDSeq,I.PropertyIDSeq,I.AccountIDSeq,deleted.Invoiceidseq,deleted.IDSeq as InvoiceItemIDSeq
      into   @LT_OpenInvoicesRolledback (CompanyIDSeq,PropertyIDSeq,AccountIDSeq,InvoiceIDSeq,InvoiceItemIDSeq)
      from   Invoices.dbo.Invoice I  with (nolock) 
      inner join
             Invoices.dbo.Invoiceitem II with (nolock)      
      on     II.InvoiceIDSeq = I.InvoiceIDSeq
      and    I.PrintFlag     = 0
      and    I.CompanyIDSeq  = @IPVC_CompanyIDSeq
      ---Step2 : Cancel OrderItems (Non Cancelled, Non Expired only)  for Company and related Properties in Question.
      Update OI
      set    OI.StatusCode           = 'CNCL',                          
             OI.CancelDate           = @LDT_CurrentSystemDate,             
             OI.CancelReasonCode     = 'COIN',
             OI.CancelNotes          = 'Order Canceled due to Inactivation of Company and its properties, initiated by User :' + convert(varchar(50),@IPBI_UserID) + ':' + @LVC_UserName,
             OI.CancelByIDSeq        = @IPBI_UserID,
             OI.ModifiedByUserIDSeq  = @IPBI_UserID,
             OI.ModifiedDate         = @LDT_CurrentSystemDate,
             OI.DoNotInvoiceFlag     = 1,
             -------------------------
             OI.RenewalTypeCode      = 'DRNW',
             OI.HistoryFlag          = 1, 
             OI.HistoryDate          = @LDT_CurrentSystemDate
             -------------------------   
      output O.CompanyIDSeq,O.PropertyIDSeq,O.AccountIDSeq,Deleted.OrderIDSeq,Deleted.IDSeq as OrderitemIDSeq
      into   @LT_OrderitemsCanceled(CompanyIDSeq,PropertyIDSeq,AccountIDSeq,OrderIDSeq,OrderitemIDSeq)
      from   Orders.dbo.[Order]     O with (nolock)
      inner Join
             Orders.dbo.[OrderItem] OI with (nolock)
      on     O.OrderIdSeq  = OI.OrderIDSeq
      and    O.CompanyIDSeq= @IPVC_CompanyIDSeq
      and    OI.StatusCode Not in ('CNCL','EXPD')
      ---Step3 : Cancel Quotes (Non Approved only)  for Company
      Update Q
      set    Q.QuoteStatusCode = 'CNL',
             Q.ModifiedDate    = @LDT_CurrentSystemDate,
             Q.ModifiedByIDSeq = @IPBI_UserID
      output Deleted.QuoteIDSeq,Deleted.CustomerIDSeq 
      into   @LT_QuotesCanceled(QuoteIDSeq,CompanyIDSeq)
      from   Quotes.dbo.Quote Q with (nolock)
      where  Q.CustomerIDSeq = @IPVC_CompanyIDSeq
      and    Q.QuoteStatusCode <> 'APR'      
      ---Step4 : InActivate Property for Company that are currently Active only.
      Update PRP
      set    PRP.StatusTypeCode  = 'INACT',
             PRP.ModifiedDate    = @LDT_CurrentSystemDate,
             PRP.ModifiedByIDSeq = @IPBI_UserID        
      Output Deleted.IDSeq as PropertyIDSeq,Deleted.PMCIDSeq as CompanyIDSeq
      into   @LT_PropertiesInactivated(PropertyIDSeq,CompanyIDSeq)
      from   Customers.dbo.Property PRP with (nolock)
      where  PRP.PMCIDSeq       = @IPVC_CompanyIDSeq
      and    PRP.StatusTypeCode = 'ACTIV'
      ---Step5 : Finally InActivate Company that is currently Active only.
      Update COMP
      set    COMP.StatusTypeCode  = 'INACT',
             COMP.ModifiedDate    = @LDT_CurrentSystemDate,
             COMP.ModifiedByIDSeq = @IPBI_UserID             
      from   Customers.dbo.Company COMP with (nolock)
      where  COMP.IDSeq       = @IPVC_CompanyIDSeq
      and    COMP.StatusTypeCode = 'ACTIV'
     ---Step7 : InActivate Accounts for Company and related Properties in Question that are currently Active only.
     Insert into @LT_AccountsInactivated(AccountIDSeq,CompanyIDSeq,PropertyIDSeq)
     select ACT.IDSeq as AccountIDSeq,ACT.CompanyIDSeq,ACT.PropertyIDSeq
     from   Customers.dbo.Account ACT with (nolock)
     where  ACT.CompanyIDSeq = @IPVC_CompanyIDSeq
     and    ACT.ActiveFlag   = 1
     --->7.1 : Property Account
     select @LI_Min=1,@LI_Max=Count(1) from @LT_PropertiesInactivated
     while @LI_Min <= @LI_Max
     begin
       select @LVC_PropertyIDSeq = PropertyIDSeq from @LT_AccountsInactivated where IDSeq = @LI_Min
       begin try
          Exec CUSTOMERS.DBO.useCUSTOMERS_UpdateAccountStatus
                                  @IPVC_CompanyIDSeq   = @IPVC_CompanyIDSeq,
                                  @IPVC_PropertyIDSeq  = @LVC_PropertyIDSeq,
                                  @IPVC_StatusTypecode = 'INACT',
                                  @IPVC_AccountTypeCode= 'APROP',
                                  @IPBI_UserIDSeq      = @IPBI_UserID
      end try
      begin catch
      end catch
      select @LI_Min = @LI_Min + 1
     end
     --->7.2 : Company Account
     begin try
       Exec CUSTOMERS.DBO.useCUSTOMERS_UpdateAccountStatus
                                  @IPVC_CompanyIDSeq   = @IPVC_CompanyIDSeq,
                                  @IPVC_PropertyIDSeq  = @LVC_PropertyIDSeq,
                                  @IPVC_StatusTypecode = 'INACT',
                                  @IPVC_AccountTypeCode= 'AHOFF',
                                  @IPBI_UserIDSeq      = @IPBI_UserID  
    end try
    begin catch
    end catch
    ---Step8 : Remove Child Relationships if Company is an ExecutiveCompany
    ---		   (OR) Remove Executive Relation  if Company is a ChildCompany
  
		Declare @ExecutiveIDSeq varchar(11)
        select @ExecutiveIDSeq = ExecutiveCompanyIDSeq 
		from CUSTOMERS.dbo.ExecutiveCompany with (nolock) 
		where CompanyIDSeq = @IPVC_CompanyIDSeq and ActiveFlag = 1
        if( len(@ExecutiveIDSeq) = 11 )
        begin
			 Update CUSTOMERS.dbo.ExecutiveCompany 
			 set ActiveFlag = 0, ModifiedByIDSeq = @IPBI_UserID, ModifiedDate = @LDT_CurrentSystemDate, SystemLogDate = @LDT_CurrentSystemDate 
			 where ExecutiveCompanyIDSeq = @ExecutiveIDSeq	
			 Update CUSTOMERS.dbo.Company 
			 set ExecutiveCompanyIDSeq = null, ModifiedByIDSeq = @IPBI_UserID, ModifiedDate = @LDT_CurrentSystemDate, SystemLogDate = @LDT_CurrentSystemDate 
			 where ExecutiveCompanyIDSeq = @ExecutiveIDSeq
		end
        else
        begin
			 Update CUSTOMERS.dbo.Company 
			 set ExecutiveCompanyIDSeq = null, ModifiedByIDSeq = @IPBI_UserID, ModifiedDate = @LDT_CurrentSystemDate, SystemLogDate = @LDT_CurrentSystemDate  
			 where IDSeq = @IPVC_CompanyIDSeq and ExecutiveCompanyIDSeq is not null
        end
 
      ---------------------------------------------------------------
      --When Success, Commit Transaction and Proceed to report metrics for future use.
      --Else in event of any failute Go to Catch block Rollback entire operation
      -- and throw critical error for UI to catch and show to UI and Log to customers.dbo.ErrorLog table 
      --  and Quit operation.
      ---------------------------------------------------------------
    COMMIT TRANSACTION A;
  end TRY
  begin CATCH    
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION A;
    end
    else 
    if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION A;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION A;
    select @LVC_CodeSection='Company :' + @IPVC_CompanyIDSeq + ' Inactivation failed. Operation aborted and rolledback. Please try again.'
    return;                 
  end CATCH
  ---------------------------------------------------------------
  --Step 6 : Upon success of above, if open invoiceitems are deleted,run Sync proc to Sync invoices.
  select @LI_Min=1,@LI_Max=Count(1) from @LT_OpenInvoicesRolledback
  while @LI_Min <= @LI_Max
  begin
    select @LVC_InvoiceIDSeq = InvoiceIDSeq
    from   @LT_OpenInvoicesRolledback
    where  IDSeq =@LI_Min
    begin try
      exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID=@LVC_InvoiceIDSeq;
    end try
    begin catch
    end catch
    select @LI_Min = @LI_Min + 1
  end
  -----------------------------------------------------------------------------------
  ---Finally Return Metrics to UI. This will be used in future release to show in UI.
  -----------------------------------------------------------------------------------
  select @LI_RolledbackInvoiceItemCount = count(1) from @LT_OpenInvoicesRolledback;
  select @LI_CancelorderItemCount       = count(1) from @LT_OrderitemsCanceled;
  select @LI_CancelQuoteCount           = count(1) from @LT_QuotesCanceled;
  select @LI_InactivatedAccountsCount   = count(1) from @LT_AccountsInactivated;
  select @LI_InactivatedPropertiesCount = count(1) from @LT_PropertiesInactivated;
  ---Final select to UI
  select @LI_RolledbackInvoiceItemCount as InvoiceItemsRolledBack,
         @LI_CancelorderItemCount       as OrderitemsCanceled,
         @LI_CancelQuoteCount           as QuotesCanceled,
         @LI_InactivatedAccountsCount   as AccountsInactivated,
         @LI_InactivatedPropertiesCount as PropertiesInactivated,
         1                              as CompanyInactivated
  -----------------------------------------------------------------------------------
END
GO
