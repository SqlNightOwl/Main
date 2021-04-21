SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_GetInvoiceAsXML
-- Description     : This procedure is the main wrapper call to get and Insert Invoice XML into InvoiceXML table.
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(50)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_GetInvoiceAsXML 
--                                  @IPVC_InvoiceIDSequence ='I0804000326',
--                                  @IPVC_BatchGenerationID ='cae41376-5e43-46e5-bd48-17c8af2e62dd'    
-- 
-- Revision History:
-- Author          : Terry Sides
-- 02/19/2010      : Stored Procedure Created. 
-- 03/12/2010      : Defect #7550 (Changed for Lead Days Enhancement - SRS)
-- 05/15/2011      : TFS 592
-- 07/05/2011      : TFS 821 for GSTTaxAmt and PSTTaxAmt enhancement 
-- 2011-08-24      : SRS: PCR 627 CompanyName and Property Name is already available on the Invoice Header Record 
--                   This feature applies only to site invoices which have Billing Address PBT that have
--                   Same as PMC Flag  checked and ShowSiteNameOnInvoiceFlag for corresponding Invoice Delivery Rule                   
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetInvoiceAsXML]  (@IPVC_InvoiceIDSequence    varchar(50),  	                                               
                                                       @IPVC_BatchGenerationID    varchar(100) = NULL,
                                                       @IPBI_UserIDSeq            bigint       = -1
                                                      )
AS
BEGIN---> Main Begin:
  set nocount on;  
  ---------------------------------------------
  --Local Variable Declaration
  ---------------------------------------------
  DECLARE @LDT_BillingCycleDate      datetime;
  DECLARE @DetailRows                XML;
  DECLARE @InvoiceInfoRows           XML;
  DECLARE @InvoiceNotes              XML;
  DECLARE @XMLResults                XML;
  DECLARE @ErrorText                 varchar(max);
  DECLARE @LI_OutboundProcessStatus  int;
  declare @ErrorMessage              varchar(1000)
  declare @ErrorSeverity             Int
  declare @ErrorState                Int
  DECLARE @BusinessUnit              varchar(20);
  DECLARE @PrintFlag                 bit;
  DECLARE @EmailFlag                 bit;
  DECLARE @DeliveryOptionCode        varchar(20);
  DECLARE @CustomerIDSeq             varchar(15);
  DECLARE @AccountIDSeq              varchar(15);
  DECLARE @PropertyIDSeq             varchar(15);
  DECLARE @BillToEmailAddress        varchar(max);
  DECLARE @InvoiceTotal              money;
  DECLARE @MarkAsPrintedFlag         Int;
  DECLARE @SendInvoiceToClientFlag   Int;
  DECLARE @VersionNumber             bigint;

  DECLARE @LI_ProductRecordCount     int;
  DECLARE @LI_LineItemCount          int;   
  -- Declare the following additional variables
  DECLARE @RemitToAddressLine1       varchar(50);
  DECLARE @RemitToAddressLine2       varchar(50);
  DECLARE @RemitToCity               varchar(50);
  DECLARE @RemitToState              varchar(50);
  DECLARE @RemitToZip                varchar(50);

  declare @LVC_PrintNoticeFamilies   varchar(8000)
  --Initialize local variables.
  ---------------------------------------------  
  Select @PrintFlag        = 0,@EmailFlag = 0,
         @MarkAsPrintedFlag= 0,@SendInvoiceToClientFlag=0
  ---------------------------------------------
  BEGIN TRY---> Main TRY block begin:
    --Step 1 : Update for XMLProcessingStatus to Inprocess 5 in InvoiceHeader
    Update Invoices.dbo.Invoice 
    set    XMLProcessingStatus = 5
    where  InvoiceIDSeq        = @IPVC_InvoiceIDSequence    
    -----------------------------
    --Step 2 : Initialize variables and get different xmls for consolidations below.
    SET @LI_OutboundProcessStatus = 1;
    SET @ErrorText                = '';
    Execute INVOICES.[dbo].[uspINVOICES_GetInvoiceDetailAsXML]          @DetailRows      output,@IPVC_InvoiceID    = @IPVC_InvoiceIDSequence;
    Execute INVOICES.[dbo].[uspInvoices_GetInvoiceInfoAsXML]            @InvoiceInfoRows output,@IPVC_InvoiceID    = @IPVC_InvoiceIDSequence;
    Execute [Documents].[dbo].[uspDOCUMENTS_GetFootNotesAsXML] @InvoiceNotes    output,@IPVC_InvoiceIDSeq = @IPVC_InvoiceIDSequence;
    select  @BusinessUnit = Invoices.dbo.fnGetInvoiceLogoDefinition(@IPVC_InvoiceIDSequence);
    -----------------------------
    --Step 2.1 : Get attributes for @LI_ProductRecordCount and @LI_LineItemCount
    select TOP 1 @LI_ProductRecordCount = NULLIF(ltrim(rtrim(convert(varchar(100),EXD.NewDataSet.query('data(ProductRecordCount/.)')))),'0'),
                 @LI_LineItemCount      = NULLIF(ltrim(rtrim(convert(varchar(100),EXD.NewDataSet.query('data(LineItemCount/.)')))),'0')
    from   @DetailRows.nodes('/LineItem') as EXD(NewDataSet)
    -----------------------------
    --Step 3 : Get Main attributes of Invoice Header
    Select 
	  @DeliveryOptionCode      = Invoice.BillToDeliveryOptionCode,
	  @CustomerIDSeq           = Invoice.CompanyIDSeq,
	  @AccountIDSeq            = Invoice.AccountIdSeq,
	  @PropertyIDSeq           = Invoice.PropertyIDSeq,
	  @BillToEmailAddress      = Invoice.BillToEmailAddress,
	  @MarkAsPrintedFlag       = Invoice.MarkAsPrintedFlag,
	  @SendInvoiceToClientFlag = Invoice.SendInvoiceToClientFlag,
          @LDT_BillingCycleDate    = Invoice.BillingCycleDate,
          @InvoiceTotal            = Invoice.InvoiceTotal
    from  
         (Select Max(I.BillToDeliveryOptionCode)              as BillToDeliveryOptionCode,
                 Max(I.CompanyIDSeq)                          as CompanyIDSeq,
                 Max(I.AccountIdSeq)                          as AccountIdSeq,
                 Max(I.PropertyIDSeq)                         as PropertyIDSeq,
                 Max(I.BillToEmailAddress)                    as BillToEmailAddress,
                 Max(convert(int,I.MarkAsPrintedFlag))        as MarkAsPrintedFlag,
                 Max(convert(int,I.SendInvoiceToClientFlag))  as SendInvoiceToClientFlag,
                 Max(I.BillingCycleDate)                      as BillingCycleDate,
                 SUM(I.TaxAmount                 +
                     I.ShippingandHandlingAmount +
                     I.ILFChargeAmount           +
                     I.AccessChargeAmount        +
                     I.TransactionChargeAmount)               as InvoiceTotal
          from  Invoices.dbo.Invoice I with(nolock) 
          where I.InvoiceIDSeq = @IPVC_InvoiceIDSequence
          group by I.InvoiceIDSeq
         ) Invoice
    -----------------------------
    IF ((@MarkAsPrintedFlag = 1)  or (@SendInvoiceToClientFlag = 0))
    BEGIN
      Set @PrintFlag = 0;
      Set @EmailFlag = 0;
    END
    ELSE
    BEGIN
      ---NOTES : 07/30/2010 : 
      --- ONLY BillToDeliveryOptionCode on Invoice at the time of outbound Generate Invoice Process determines what should be PrintFlag and EmailFlag.
      --- BillToDeliveryOptionCode is snapshot of DeliveryOptionCode from Customer Setting at the time of Invoicing.
      Set @PrintFlag = Case @DeliveryOptionCode when 'SMAIL' then 1 Else 0 END;
      Set @EmailFlag = Case @DeliveryOptionCode when 'EMAIL' then 1 else 0 END;
    END;   
    -----------------------------
    -- Add this if Construct
    -----------------------------
    ---NOTES : 07/30/2010 :
    ---@BusinessUnit only determines what Logo and What Address to put on Invoice.
    ---@BusinessUnit will not determine the mode of delivery. 
    ---Mode of Delivery will Only be determined by BillToDeliveryOptionCode on Invoice at the time of outbound Generate Invoice Process
	---Everything begins with a realpage address. 
    set @RemitToAddressLine1 = 'RealPage, Inc.';
    set @RemitToAddressLine2 = 'PO Box 671777';
    Set @RemitToCity         = 'Dallas';
    Set @RemitToState        = 'TX';
    Set @RemitToZip          = '75267-1777';
    -------------------------------------------------------
    IF @BusinessUnit = 'OpsTech'
    BEGIN
      set @RemitToAddressLine1 = 'OpsTechnology Inc';
      set @RemitToAddressLine2 = 'PO Box 671569';
      Set @RemitToCity         = 'Dallas';
      Set @RemitToState        = 'TX';
      Set @RemitToZip          = '75267-1569';      
    END
    IF @BusinessUnit ='Domin-8CANADA'
    BEGIN
      set @RemitToAddressLine1 = '43642 Yukon Inc.';
      set @RemitToAddressLine2 = 'PO Box 6595, Main Post Office';
      Set @RemitToCity         = 'Winnipeg';
      Set @RemitToState        = 'MB';
      Set @RemitToZip          = 'R3C 4N6, CANADA';      
    END   
    /*IF @BusinessUnit = 'Domin-8'
    BEGIN
      set @RemitToAddressLine1 = 'Domin-8';
      set @RemitToAddressLine2 = 'PO Box 671733';
      Set @RemitToCity         = 'Dallas';
      Set @RemitToState        = 'TX';
      Set @RemitToZip          = '75267-1733';      
    END
    */
    IF @BusinessUnit = 'eREI'
    BEGIN
      set @RemitToAddressLine1 = 'eREI';
      set @RemitToAddressLine2 = 'PO BOX 671041';
      Set @RemitToCity         = 'Dallas';
      Set @RemitToState        = 'TX';
      Set @RemitToZip          = '75267-1041';      
    END
    IF @BusinessUnit = 'ALWizard'
    BEGIN
      set @RemitToAddressLine1 = 'A.L. Wizard';
      set @RemitToAddressLine2 = 'PO Box 671728';
      Set @RemitToCity         = 'Dallas';
      Set @RemitToState        = 'TX';
      Set @RemitToZip          = '75267-1728';      
    END
    IF @BusinessUnit = 'EverGreenSolutions'
    BEGIN
      set @RemitToAddressLine1 = 'RealPage, Inc.';
      set @RemitToAddressLine2 = 'PO Box 671777';
      Set @RemitToCity         = 'Dallas';
      Set @RemitToState        = 'TX';
      Set @RemitToZip          = '75267-1777';
    END
    -----------------------------------------------------------------------------------------
    --->TFS 1171 : Add PrintFamilyNoticeFlag  indicator : PrintNoticeFamilies pipe separated 
    -----------------------------------------------------------------------------------------
    select @LVC_PrintNoticeFamilies = '~#';
    ;with FN_CTE (familycode)
    as (select F.Code
        from   Invoices.dbo.InvoiceItem II with (nolock)
        inner join
               Products.dbo.Product     P  with (nolock)
        on     II.ProductCode = P.Code
        and    II.Priceversion= P.Priceversion
        and    II.InvoiceIDSeq= @IPVC_InvoiceIDSequence
        inner join
               Products.dbo.Family F with (nolock)
        on     P.FamilyCode = F.Code
        and    F.PrintFamilyNoticeFlag = 1
        where  II.InvoiceIDSeq         = @IPVC_InvoiceIDSequence
        and    F.PrintFamilyNoticeFlag = 1
        group by F.Code        
       )
    select @LVC_PrintNoticeFamilies = COALESCE(@LVC_PrintNoticeFamilies + '|', '') + S.familycode 
    from   FN_CTE S;
    select @LVC_PrintNoticeFamilies = replace(replace(@LVC_PrintNoticeFamilies,'~#','|'),'||','|')+ '|';
    ---------------------------------------------------------------------------------
    --Local Variable Declaration and Initialization
    declare @LI_ShowSiteNameOnInvoiceFlag  int;
    set @LI_ShowSiteNameOnInvoiceFlag = 0;
    ---------------------------------------------------------------------------------
    ---> TFS#627 : If a Property Invoice that goes to PBT address (default)
    --      and does have IDE Rule setting for ShowSiteNameOnInvoiceFlag, then show Propertyname on the Invoice.
    --      Else show the default BillToAccountName (which will be Property name for property Invoice and Company Name for Company Invoice) which are recorded on the invoice.
    if (@PropertyIDSeq is not null)
    BEGIN
      ------------------------------------------
      ;with 
      CBWithOMSID      (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as 
       (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
               (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
               ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                              ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 1
        and    X.ApplyToOMSIDSeq is not null
        and    X.ApplyToOMSIDSeq = @PropertyIDSeq
       ),
      ------------------------------------------
      CBWithNoOMSID    (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
       (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
               Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
               (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
                   ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                                      ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 1
        and    X.ApplyToOMSIDSeq is null
       ),
      ------------------------------------------
      AllNullWithOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0
        and    X.ApplyToOMSIDSeq is not null
        and    X.ApplyToOMSIDSeq = @PropertyIDSeq
        and    coalesce(X.ApplyToProductCode,X.ApplyToProductTypeCode,X.ApplyToCategoryCode,X.ApplyToFamilyCode,'ABCDEF') = 'ABCDEF'
       ),
      ------------------------------------------
      AllNullWithNoOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0
        and    X.ApplyToOMSIDSeq is null
        and    coalesce(X.ApplyToProductCode,X.ApplyToProductTypeCode,X.ApplyToCategoryCode,X.ApplyToFamilyCode,'ABCDEF') = 'ABCDEF'
       ),
      ------------------------------------------
      CTEProductWithOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductCode is not null
        and    X.ApplyToOMSIDSeq    is not null
        and    X.ApplyToOMSIDSeq = @PropertyIDSeq
       ),  
      ------------------------------------------
      CTEProductWithNoOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductCode is not null
        and    X.ApplyToOMSIDSeq    is null
       ),  
      ------------------------------------------
      CTEProductTypeWithOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductTypeCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductTypeCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductTypeCode is not null
        and    X.ApplyToOMSIDSeq        is not null
        and    X.ApplyToOMSIDSeq = @PropertyIDSeq
       ),
      ------------------------------------------
      CTEProductTypeWithNoOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductTypeCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductTypeCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductTypeCode is not null
        and    X.ApplyToOMSIDSeq        is null
       ),
      ------------------------------------------
      CTECategoryWithOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToCategoryCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCategoryCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToCategoryCode is not null
        and    X.ApplyToOMSIDSeq     is not null
        and    X.ApplyToOMSIDSeq = @PropertyIDSeq
       ),
      ------------------------------------------
      CTECategoryWithNoOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToCategoryCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCategoryCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToCategoryCode is not null
        and    X.ApplyToOMSIDSeq     is null
       ),
      ------------------------------------------
      CTEFamilyWithOMSID        (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToFamilyCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToFamilyCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToFamilyCode is not null
        and    X.ApplyToOMSIDSeq   is not null
        and    X.ApplyToOMSIDSeq = @PropertyIDSeq
       ),
      ------------------------------------------
      CTEFamilyWithNoOMSID        (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToFamilyCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToFamilyCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @CustomerIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToFamilyCode is not null
        and    X.ApplyToOMSIDSeq   is null
       ),
      ------------------------------------------
      CTE_II (InvoiceIDSeq,CompanyIDSeq,PropertyIDSeq,BillToAddressTypeCode,BillToDeliveryOptionCode,
              Productcode,ProductTypeCode,CategoryCode,Familycode,CustomBundlenameEnabledFlag
             ) as 
       (select  I.InvoiceIDSeq,I.CompanyIDSeq,I.PropertyIDSeq,I.BillToAddressTypeCode,I.BillToDeliveryOptionCode,
                PROD.Code as Productcode,PROD.ProductTypeCode,PROD.CategoryCode,PROD.Familycode,IG.CustomBundlenameEnabledFlag as CustomBundlenameEnabledFlag
        from    Invoices.dbo.Invoice     I  with (nolock)
        inner join
                Invoices.dbo.InvoiceItem II with (nolock)
        on     II.InvoiceIDSeq              = I.InvoiceIDSeq
        and    I.InvoiceIDSeq               = @IPVC_InvoiceIDSequence
        and    II.InvoiceIDSeq              = @IPVC_InvoiceIDSequence
        and    I.PropertyIDSeq is not null
        and    I.BillToAccountName <> coalesce(I.PropertyName,'')
        inner join
               Invoices.dbo.InvoiceGroup IG with (nolock)
        on     IG.Invoiceidseq = I.Invoiceidseq
        and    IG.Invoiceidseq = II.Invoiceidseq
        and    IG.InvoiceIDSeq = @IPVC_InvoiceIDSequence
        and    IG.IDSeq        = II.InvoiceGroupIDSeq
        and    IG.OrderIDSeq   = II.OrderIDSeq
        and    IG.OrderGroupIDSeq = II.OrderGroupIDSeq
        inner join
               Products.dbo.Product PROD with (nolock)
        on     II.ProductCode  = PROD.Code
        and    II.PriceVersion = PROD.PriceVersion
        group by I.InvoiceIDSeq,I.CompanyIDSeq,I.PropertyIDSeq,I.BillToAddressTypeCode,I.BillToDeliveryOptionCode,
                 PROD.Code,PROD.ProductTypeCode,PROD.CategoryCode,PROD.Familycode,IG.CustomBundlenameEnabledFlag
       )
  select Top 1 @LI_ShowSiteNameOnInvoiceFlag=(Case when CTE_II.CustomBundlenameEnabledFlag = 1
                                                     then coalesce(
                                                                   (case when CBWithOMSID.RuleIDSeq is not null then CBWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,(case when CBWithNoOMSID.RuleIDSeq is not null then CBWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,(case when AllNullWithOMSID.RuleIDSeq is not null then AllNullWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then AllNullWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,0
                                                                 )
                                                   else coalesce(
                                                                 (case when CTEProductWithOMSID.RuleIDSeq is not null then CTEProductWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEProductTypeWithOMSID.RuleIDSeq is not null then CTEProductTypeWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTECategoryWithOMSID.RuleIDSeq is not null then CTECategoryWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEFamilyWithOMSID.RuleIDSeq is not null then CTEFamilyWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when AllNullWithOMSID.RuleIDSeq is not null then AllNullWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEProductWithNoOMSID.RuleIDSeq is not null then CTEProductWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEProductTypeWithNoOMSID.RuleIDSeq is not null then CTEProductTypeWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTECategoryWithNoOMSID.RuleIDSeq is not null then CTECategoryWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEFamilyWithNoOMSID.RuleIDSeq is not null then CTEFamilyWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then AllNullWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,0
                                                               )
                                              end)

  from   CTE_II
  -----------------------------------------------------
  left outer join
                   CBWithOMSID
  on   CTE_II.CustomBundlenameEnabledFlag = CBWithOMSID.ApplyToCustomBundleFlag
  and  CTE_II.CustomBundlenameEnabledFlag       = 1
  and  CBWithOMSID.ApplyToCustomBundleFlag      = 1
  and  CBWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq               = coalesce(CBWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CBWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CBWithOMSID.DeliveryOptionCode
  ----------------
  left outer join
                   CBWithNoOMSID
  on   CTE_II.CustomBundlenameEnabledFlag = CBWithNoOMSID.ApplyToCustomBundleFlag
  and  CTE_II.CustomBundlenameEnabledFlag = 1
  and  CBWithNoOMSID.ApplyToCustomBundleFlag     = 1
  and  CBWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq               = coalesce(CBWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CBWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CBWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   AllNullWithOMSID
  on   AllNullWithOMSID.ApplyToCustomBundleFlag = 0
  and  AllNullWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(AllNullWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = AllNullWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = AllNullWithOMSID.DeliveryOptionCode
  ----------------
  left outer join
                   AllNullWithNoOMSID
  on   AllNullWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  AllNullWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(AllNullWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = AllNullWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = AllNullWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductWithOMSID
  on   CTE_II.ProductCode                 = CTEProductWithOMSID.ApplyToProductCode  
  and  CTEProductWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductWithNoOMSID
  on   CTE_II.ProductCode                 = CTEProductWithNoOMSID.ApplyToProductCode  
  and  CTEProductWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductTypeWithOMSID
  on   CTE_II.ProductTypeCode             = CTEProductTypeWithOMSID.ApplyToProductTypeCode    
  and  CTEProductTypeWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductTypeWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductTypeWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductTypeWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductTypeWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductTypeWithNoOMSID
  on   CTE_II.ProductTypeCode             = CTEProductTypeWithNoOMSID.ApplyToProductTypeCode    
  and  CTEProductTypeWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductTypeWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductTypeWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductTypeWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductTypeWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTECategoryWithOMSID
  on   CTE_II.CategoryCode                = CTECategoryWithOMSID.ApplyToCategoryCode    
  and  CTECategoryWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTECategoryWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTECategoryWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTECategoryWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTECategoryWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTECategoryWithNoOMSID
  on   CTE_II.CategoryCode                = CTECategoryWithNoOMSID.ApplyToCategoryCode  
  and  CTECategoryWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTECategoryWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTECategoryWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTECategoryWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTECategoryWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEFamilyWithOMSID
  on   CTE_II.FamilyCode                  = CTEFamilyWithOMSID.ApplyToFamilyCode  
  and  CTEFamilyWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTEFamilyWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEFamilyWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEFamilyWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEFamilyWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEFamilyWithNoOMSID
  on   CTE_II.FamilyCode                  = CTEFamilyWithNoOMSID.ApplyToFamilyCode  
  and  CTEFamilyWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTEFamilyWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEFamilyWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEFamilyWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEFamilyWithNoOMSID.DeliveryOptionCode
  ----------------------------------------------------- 
  where CTE_II.InvoiceIDSeq               = @IPVC_InvoiceIDSequence
  and   CTE_II.CompanyIDSeq               = @CustomerIDSeq
  and   CTE_II.PropertyIDSeq              = @PropertyIDSeq;
  END;
  ---------------------------------------------------------------------------------
    ;WITH XMLNAMESPACES (DEFAULT 'xmlns:xsd=http://www.w3.org/2001/XMLSchema xmlns:xsi=http://www.w3.org/2001/XMLSchema-Instance')
    Select @XMLResults = (
                          Select
                                Invoice.InvoiceIDSeq          as '@InvoiceOID',
                                @PrintFlag                    as '@Print',
                                @EmailFlag                    as '@Email',
                                Invoice.BillToEmailAddress    as '@EmailAddress',
                                ''                            as '@hasSupportingDetails',
                                @BusinessUnit                 as '@BusinessUnit',
                                @LVC_PrintNoticeFamilies      as '@PrintNoticeFamilies',
                                Invoice.PrePaidFlag           as '@PrePaidFlag',
                                ''                            as '@OffLineFlag',
                                Invoice.AccountIDSeq          as '@AccountID',
                                --------------------
                                Invoice.InvoiceIDSeq          as 'InvoiceHeader/@SupplierInvoiceNumber',
                                ''                            as 'InvoiceHeader/@IRN',
                                Invoice.EpicorCustomerCode    as 'InvoiceHeader/@ReferenceInvoiceNumber',
                                Invoice.InvoiceIDSeq          as 'InvoiceHeader/@OriginalInvoiceNumber',
                                ''                            as 'InvoiceHeader/@CustomerVoucherNumber',
                                ''                            as 'InvoiceHeader/@OffLineFlag',
		
                                ''                            as 'InvoiceHeader/InvoiceRoutingFlags',
                                ---------------------
                                convert(varchar(20),Invoice.InvoiceDate,101)     as 'InvoiceHeader/InvoiceDate',
                                convert(varchar(20),Invoice.InvoiceDueDate,101)  as 'InvoiceHeader/InvoiceDueDate',
                                ''                            as 'InvoiceHeader/ServiceDate',
                                ''                            as 'InvoiceHeader/OrderDate',		                 
                                ''                            as 'InvoiceHeader/CSR/FullName',
                                ''                            as 'InvoiceHeader/CSR/FirstName',
                                ''                            as 'InvoiceHeader/CSR/LastName',
                                'USPS'                        as 'InvoiceHeader/Shipment/ShipmentType',
                                '30 Days'                     as 'InvoiceHeader/Terms/PaymentTerm',
                                Convert(Numeric(13,2),Invoice.TaxAmount)                 as 'InvoiceHeader/Totals/TaxTotal',
                                Convert(Numeric(13,2),Invoice.ShippingandHandlingAmount) as 'InvoiceHeader/Totals/FreightTotal',
                                '0.00'                                                   as 'InvoiceHeader/Totals/DiscountTotal',
                                Convert(Numeric(13,2),(Invoice.ILFChargeAmount        +
                                                       Invoice.AccessChargeAmount     +
                                                       Invoice.TransactionChargeAmount
                                                      )
                                       )                     as 'InvoiceHeader/Totals/SubTotal',
                                Convert(Numeric(13,2),(Invoice.TaxAmount                 +
                                                       Invoice.ShippingandHandlingAmount +
                                                       Invoice.ILFChargeAmount           +
                                                       Invoice.AccessChargeAmount        +
                                                       Invoice.TransactionChargeAmount
                                                      )
                                       )                     as 'InvoiceHeader/Totals/GrandTotal',
		
                                Invoice.CompanyIDSeq         as	'InvoiceHeader/Customer/Company/@CompanyCode',
                                Invoice.[Units]              as	'InvoiceHeader/Customer/Company/@NoOfUnits',
                                Invoice.EpicorCustomerCode   as	'InvoiceHeader/Customer/Company/@EpicorCode',
                                Invoice.BillToPMCFlag        as	'InvoiceHeader/Customer/Company/@BillToPMCFlag',
                                (case when @LI_ShowSiteNameOnInvoiceFlag = 1
                                       then coalesce(Invoice.PropertyName,Invoice.BillToAccountName)
                                      else Invoice.BillToAccountName
                                end)                         as	'InvoiceHeader/Customer/Company/CompanyName',
                                Invoice.BillToAttentionName  as 'InvoiceHeader/Customer/Company/Address/Attention1',
                                ''                           as 'InvoiceHeader/Customer/Company/Address/Attention2',
                                Invoice.BillToAddressLine1   as 'InvoiceHeader/Customer/Company/Address/Address1',
                                Invoice.BillToAddressLine2   as 'InvoiceHeader/Customer/Company/Address/Address2',
                                Invoice.BillToCity           as 'InvoiceHeader/Customer/Company/Address/City',
                                Invoice.BillToState          as 'InvoiceHeader/Customer/Company/Address/State',
                                Invoice.BillToZip            as	'InvoiceHeader/Customer/Company/Address/PostalCode',
                                Upper(Invoice.BillToCountry) as 'InvoiceHeader/Customer/Company/Address/Country',
                                Invoice.BillToPhoneVoice     as	'InvoiceHeader/Customer/Company/Address/PhoneNumber',
                                Invoice.BillToPhoneFax       as	'InvoiceHeader/Customer/Company/Address/FaxNumber',

                                Invoice.PropertyIDSeq        as 'InvoiceHeader/Property/@PropertyCode',
                                Invoice.PropertyName         as 'InvoiceHeader/Property/PropertyName',

                                ''                           as 'InvoiceHeader/Buyer/@BuyerCode',
                                ''                           as 'InvoiceHeader/Buyer/FirstName',
                                ''                           as 'InvoiceHeader/Buyer/LastName',
                                ''                           as 'InvoiceHeader/Buyer/PhoneNumber',
                                ''                           as 'InvoiceHeader/Buyer/EmailAddress',
                                ''                           as 'InvoiceHeader/Buyer/BuyerLogin',
                                ''                           as 'InvoiceHeader/ROGApprover',
                                ''                           as 'InvoiceHeader/ROGApprover/UserName',
                                ''                           as 'InvoiceHeader/ROGApprover/LoginName',
                                '0'                          as 'InvoiceHeader/Supplier/@OfflineFlag',
                                '0'                          as 'InvoiceHeader/Supplier/@RequirePOFlag',
                                '0'	                     as 'InvoiceHeader/Supplier/@ActiveFlag',
                                '0'                          as 'InvoiceHeader/Supplier/@IsNationalSupplierFlag',
                                '0'                          as 'InvoiceHeader/Supplier/@OneTimeSupplierFlag',
                                'RealPage Inc.'              as 'InvoiceHeader/Supplier/SupplierName',
                                ''                           as 'InvoiceHeader/Supplier/SupplierDescription',
                                ''                           as 'InvoiceHeader/Supplier/CustomerSupplierCode',
                                ''                           as 'InvoiceHeader/Supplier/Address/Attention1',
                                ''                           as 'InvoiceHeader/Supplier/Address/Attention2',
                                '4000 International Parkway' as 'InvoiceHeader/Supplier/Address/Address1',
                                ''                           as 'InvoiceHeader/Supplier/Address/Address2',
                                'Carrollton'                 as 'InvoiceHeader/Supplier/Address/City',
                                'Texas'                      as 'InvoiceHeader/Supplier/Address/State',
                                '75007-1913'                 as 'InvoiceHeader/Supplier/Address/PostalCode',
                                'USA'                        as 'InvoiceHeader/Supplier/Address/Country',
                                '1-87-REALPAGE'              as 'InvoiceHeader/Supplier/Address/PhoneNumber',
                                '(972) 820-3036'             as 'InvoiceHeader/Supplier/Address/FaxNumber',
                                ''                           as 'InvoiceHeader/Supplier/Address/EmailAddress',
                                ''                           as 'InvoiceHeader/Supplier/RemitToAddress/Attention1',
                                ''                           as 'InvoiceHeader/Supplier/RemitToAddress/Attention2',
                                ---------------------------------------------------------------------------------
                                -- Change the Harded Coded values that appear here to the Variables 
                                @RemitToAddressLine1         as 'InvoiceHeader/Supplier/RemitToAddress/Address1',
                                @RemitToAddressLine2         as 'InvoiceHeader/Supplier/RemitToAddress/Address2',
                                @RemitToCity                 as 'InvoiceHeader/Supplier/RemitToAddress/City',
                                @RemitToState                as 'InvoiceHeader/Supplier/RemitToAddress/State',
                                @RemitToZip                  as 'InvoiceHeader/Supplier/RemitToAddress/PostalCode',
                                ---------------------------------------------------------------------------------
                                'USA'                        as 'InvoiceHeader/Supplier/RemitToAddress/Country',
                                ''                           as 'InvoiceHeader/Supplier/RemitToAddress/PhoneNumber',
                                ''                           as 'InvoiceHeader/Supplier/RemitToAddress/FaxNumber',
                                ''                           as 'InvoiceHeader/Supplier/RemitToAddress/EmailAddress',
                                coalesce(Invoice.PropertyName,Invoice.CompanyName) as 'InvoiceHeader/ShipTo/ContactName',
                                Invoice.BillToAttentionName  as 'InvoiceHeader/ShipTo/Address/Attention1',
                                ''                           as 'InvoiceHeader/ShipTo/Address/Attention2',
                                Invoice.BillToAddressLine1   as 'InvoiceHeader/ShipTo/Address/Address1',
                                Invoice.BillToAddressLine2   as 'InvoiceHeader/ShipTo/Address/Address2',
                                Invoice.BillToCity           as 'InvoiceHeader/ShipTo/Address/City',
                                Invoice.BillToState          as 'InvoiceHeader/ShipTo/Address/State',
                                Invoice.BillToZip            as 'InvoiceHeader/ShipTo/Address/PostalCode',
                                Invoice.BillToCountry        as 'InvoiceHeader/ShipTo/Address/Country',
                                Invoice.BillToPhoneVoice     as 'InvoiceHeader/ShipTo/Address/PhoneNumber',
                                Invoice.BillToPhoneFax       as 'InvoiceHeader/ShipTo/Address/FaxNumber',
                                ''                           as 'InvoiceHeader/ShipTo/Address/EmailAddress',
                                coalesce(Invoice.PropertyName,Invoice.CompanyName) as 'InvoiceHeader/RemitTo/Account/AccountName',
                                Invoice.AccountIDSeq         as 'InvoiceHeader/RemitTo/Account/AccountNumber',
                                ''                           as 'InvoiceHeader/RemitTo/Address/Attention1',
                                ''                           as 'InvoiceHeader/RemitTo/Address/Attention2',
                                ---------------------------------------------------------------------------------
                                -- Change the Harded Coded values that appear here to the Variables 
                                @RemitToAddressLine1         as 'InvoiceHeader/RemitTo/Address/Address1',
                                @RemitToAddressLine2         as 'InvoiceHeader/RemitTo/Address/Address2',
                                @RemitToCity                 as 'InvoiceHeader/RemitTo/Address/City',
                                @RemitToState                as 'InvoiceHeader/RemitTo/Address/State',
                                @RemitToZip                  as 'InvoiceHeader/RemitTo/Address/PostalCode',
                                ---------------------------------------------------------------------------------
                                'USA'                        as 'InvoiceHeader/RemitTo/Address/Country',
                                ''                           as 'InvoiceHeader/RemitTo/Address/PhoneNumber',
                                ''                           as 'InvoiceHeader/RemitTo/Address/FaxNumber',
                                ''                           as 'InvoiceHeader/RemitTo/Address/EmailAddress',
                                ''                           as 'InvoiceHeader/OrderIdentifier/PurchaseOrderNumber',
                                ''                           as 'InvoiceHeader/OrderIdentifier/SupplierOrderNumber',
                                ''                           as 'InvoiceHeader/BuyerNotes',
                                ''                           as 'InvoiceHeader/SupplierNotes',
                                ''                           as 'InvoiceHeader/InvoiceType/TypeName',
                                ''                           as 'InvoiceHeader/LedgerType/LedgerTypeName',
                                ''                           as 'InvoiceHeader/LedgerType/LedgerTypeDescription',
                                ''                           as 'InvoiceHeader/ImageURL',
                                ''                           as 'InvoiceHeader/Payment/PaymentDate',
                                ''                           as 'InvoiceHeader/Payment/CheckNumber',
                                ''                           as 'InvoiceHeader/Payment/PaymentAmount',
                                ''                           as 'InvoiceHeader/Payment/PropertyCode',
                                @DetailRows                  as 'LineItemList',
                                @InvoiceInfoRows             as 'InvoiceInfoRows',
                                @InvoiceNotes                as	'InvoiceNotes'
                          From  Invoices.dbo.Invoice as Invoice with (NoLock) 
                          Where Invoice.InvoiceIDSeq = @IPVC_InvoiceIDSequence
                          For XML Path('Invoice'))
    -----------------------------
    Select @VersionNumber = Max(VersionNumber) from InvoiceXML with (nolock) where InvoiceXML.InvoiceIDSeq = @IPVC_InvoiceIDSequence;
    IF (@VersionNumber is null) 
    BEGIN
      set @VersionNumber = 1;
    END
    ELSE
    BEGIN
      set @VersionNumber = @VersionNumber + 1;
    END
    -----------------------------
    --Final Insert into Invoices.dbo.InvoiceXML
    Insert into Invoices.dbo.InvoiceXML 
               (
                VersionNumber,
		InvoiceIDSeq, 
		CustomerIDSeq, 
		AccountIDSeq, 
		PropertyIDSeq, 
		InvoiceXML,		
		BillingCycleDate,
		OutboundProcessStatus,
		ErrorText,
		PrintFlag,
		EmailFlag,
		BusinessUnit,
		SendToEmailAddress,
		InvoiceTotal,
                ProductCount,
		LineItemCount,
		BatchGenerationID,
                CreatedByIDSeq,
                CreatedDate
	       ) 
    select	
		@VersionNumber,
		@IPVC_InvoiceIDSequence, 
		@CustomerIDSeq, 
		@AccountIDSeq, 
		@PropertyIDSeq, 
		@XMLResults,		
		@LDT_BillingCycleDate,
		@LI_OutboundProcessStatus,
		@ErrorText,
		@PrintFlag,
		@EmailFlag,
		@BusinessUnit,
		@BillToEmailAddress,
		@InvoiceTotal,
                @LI_ProductRecordCount,
                @LI_LineItemCount,		
		@IPVC_BatchGenerationID,                
                @IPBI_UserIDSeq as CreatedByIDSeq,
                Getdate()       as CreatedDate
                ;
    -----------------------------    
    --Update for XMLProcessingStatus to Success 1 in InvoiceHeader
    Update Invoices.dbo.Invoice 
    set    XMLProcessingStatus = 1
    where  InvoiceIDSeq        = @IPVC_InvoiceIDSequence;
    -----------------------------
    ---Update for Print Flag (Upon Success)
    EXEC INVOICES.dbo.uspINVOICES_UpdatePrintFlag @IPVC_InvoiceID = @IPVC_InvoiceIDSequence;
    -----------------------------
  END TRY---> Main TRY block End:
  BEGIN CATCH---> Main CATCH block begin:
    Set @ErrorMessage     = 'GetInvoiceAsXML '+ ERROR_MESSAGE();
    Set @ErrorSeverity    = ERROR_SEVERITY();
    Set @ErrorState       = ERROR_STATE();
    set @LI_OutboundProcessStatus = 2;
    Set @ErrorText        = @ErrorMessage + @ErrorSeverity + @ErrorState;

    --Update for XMLProcessingStatus to Failure 2 in InvoiceHeader
    Update Invoices.dbo.Invoice 
    set    XMLProcessingStatus = 2,
           PrintFlag           = 0
    where  InvoiceIDSeq        = @IPVC_InvoiceIDSequence;

    Insert into InvoiceXML (VersionNumber,InvoiceIDSeq,CustomerIDSeq,AccountIDSeq,PropertyIDSeq,
                            InvoiceXML,BillingCycleDate,PrintFlag,EmailFlag,
                            OutboundProcessStatus,ErrorText,CreatedByIDSeq,CreatedDate
                           ) 
    select                 @VersionNumber,@IPVC_InvoiceIDSequence,@CustomerIDSeq,@AccountIDSeq,@PropertyIDSeq,
                           @XMLResults,@LDT_BillingCycleDate,@PrintFlag,@EmailFlag,                              
                           @LI_OutboundProcessStatus as OutboundProcessStatus,@ErrorText,
                           @IPBI_UserIDSeq as CreatedByIDSeq,Getdate() as CreatedDate
    return;
  end CATCH;---> Main CATCH block end: 
END---> Main End:
GO
