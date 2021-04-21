SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Exec Quotes.dbo.uspQUOTES_ValidateQuote 'Q1010000790','ApproveQuote', '11/02/2010', '0', '0'  
  
CREATE PROCEDURE [invoices].[uspQUOTES_ValidateQuote] (@IPVC_QuoteID             varchar(50),                                                                                     
                                                  @IPVC_ValidationType      varchar(100)= 'SubmitQuote',  
                                                  @IPVC_ValidationDate      varchar(50) = NULL,  
                                                  @IPB_DelayILFBilling      bit, -- 1 means DelayILFBilling Checkbox checked. 0 is uncheked. For SubmitQuote pass this as 1. For Approval, Pass in checkbox value.  
                                                  @IPB_DelayACSANCBilling   bit  -- 1 means DelayACSANCBilling Checkbox checked. 0 is uncheked.For SubmitQuote pass this as 1. For Approval, Pass in checkbox value.  
                                                  )  
AS  
BEGIN  
  set nocount on;  
  --------------------------------------------------------------------------------------------  
  ---Declaring Local Variables  
  declare @LDT_ApprovalDate        datetime,  
          @LVC_QuoteStatus         varchar(3),  
          @LVC_quotetypecode       varchar(5),  
          @LVC_CompanyID           varchar(50),  
          @LI_DealDeskCurrentLevel int,  
          @LVC_DealDeskStatusCode  varchar(5)  
  
  select @IPVC_ValidationDate = nullif(@IPVC_ValidationDate,'')  
  
  create table #LTBL_Errors          (Seq             int identity(1,1)  not null primary key,  
                                      ErrorMsg        varchar(2000),  
                                      Name            varchar(2000),  
                                      CanOverrideFlag bit  
                                     );  
  
  create table #LT_QuoteProductCode  (Seq              int identity(1,1)  not null primary key,  
                                      ProductCode      varchar(50),  
                                      ProductName      varchar(255),  
                                      GroupType        varchar(20)  
                                      );    
     
  --------------------------------------------------------------------------------------------  
  select Top 1  
         @LDT_ApprovalDate = (case when isdate(@IPVC_ValidationDate)=1 then @IPVC_ValidationDate  
                                   else coalesce(Q.AcceptanceDate,Q.SubmittedDate,Q.CreateDate)  
                              end),  
         @LVC_CompanyID           = Q.CustomerIDSeq,  
         @LVC_QuoteStatus         = Q.QuoteStatusCode,  
         @LVC_quotetypecode       = Q.quotetypecode,  
         @LI_DealDeskCurrentLevel = Q.DealDeskCurrentLevel,  
         @LVC_DealDeskStatusCode  = Q.DealDeskStatusCode  
  from  QUOTES.DBO.[Quote] Q with (nolock)  
  where QuoteIDSeq = @IPVC_QuoteID  
  --------------------------------------------------------------------------------------------  
  ---Get all Products in the Current Quote  
  Insert into #LT_QuoteProductCode(ProductCode,ProductName,GroupType)   
  select QI.ProductCode,Max(PROD.DisplayName) as ProductName,G.GroupType   
  from   QUOTES.dbo.QuoteItem QI   with (nolock)    
  inner join  
         QUOTES.dbo.[Group] G with (nolock)  
  on     QI.GroupIDSeq = G.IDSeq  
  and    QI.Quoteidseq = @IPVC_QuoteID  
  and    G.Quoteidseq  = @IPVC_QuoteID  
  Inner Join  
         PRODUCTS.dbo.Product PROD with (nolock)  
  on     QI.Quoteidseq      = @IPVC_QuoteID    
  and    QI.Productcode     = PROD.Code  
  and    QI.Priceversion    = PROD.Priceversion  
  group by QI.ProductCode,G.GroupType   
  --------------------------------------------------------------------------------------------  
  --Non Overridable Critical Errors  
  --------------------------------------------------------------------------------------------  
  --1 : Check if current Quote is already approved to prevent any further operation  
  --------------------------------------------------------------------------------------------  
  if @LVC_QuoteStatus = 'APR'  
  begin  
    insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
    select 'The quote has already been Approved.', 'Abort Approval.', 0  
      
    if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
    begin  
      GOTO FinalSelectToUI  
      GOTO CleanUp  
      return;  
    end  
  end  
  --------------------------------------------------------------------------------------------  
  --2 : Check if current Quote requires Deal Desk Approval and proper approval is gotten first.  
  ---TFS : 267 : Deal Desk Project  
  --------------------------------------------------------------------------------------------  
  if (@LVC_DealDeskStatusCode <> 'APR' and @LI_DealDeskCurrentLevel > 0 and @IPVC_ValidationType = 'ApproveQuote')  
  begin  
    insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
    select 'The quote requires Deal Desk Approval.' as ErrorMsg, 'Please Submit Quote for Deal Desk Approval.' as Name, 0 as CanOverrideFlag  
  
    if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
    begin  
      GOTO FinalSelectToUI  
      GOTO CleanUp  
      return;  
    end  
  end  
  --------------------------------------------------------------------------------------------  
  --2 : Check if current Quote is in Submitted State for approval.  
  --------------------------------------------------------------------------------------------  
  if (@LVC_QuoteStatus <> 'SUB' and @IPVC_ValidationType = 'ApproveQuote')  
  begin  
    insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
    select 'The quote is not yet Submitted.' as ErrorMsg, 'Please Submit Quote and then Approve.' as Name, 0 as CanOverrideFlag  
  
    if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
    begin  
      GOTO FinalSelectToUI  
      GOTO CleanUp  
      return;  
    end  
  end  
  --------------------------------------------------------------------------------------------  
  --3 : Check if current Quote is already approved to prevent any further operation  
  ---TFS : 267 : Deal Desk Project  
  --------------------------------------------------------------------------------------------  
  if @LVC_QuoteStatus = 'DNY'  
  begin  
    insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
    select 'The quote is Deal Desk Denied' as ErrorMsg,'No Operations are allowed on Deal Desk Denied Quote.' as Name, 0 as CanOverrideFlag  
      
    if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
    begin  
      GOTO FinalSelectToUI  
      GOTO CleanUp  
      return;  
    end  
  end  
  
  if @LVC_QuoteStatus = 'CNL'  
  begin  
    insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
    select 'The quote is Cancelled' as ErrorMsg,'No Operations are allowed on Cancelled Quote.' as Name, 0 as CanOverrideFlag  
      
    if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
    begin  
      GOTO FinalSelectToUI  
      GOTO CleanUp  
      return;  
    end  
  end  
  --------------------------------------------------------------------------------------------  
  ---4 : check for Orphan Orders already present for this Quote  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Active (Order #' + convert(varchar(50),O.OrderIDSeq) + ') already exists for this Quote.' as ErrorMsg,   
         'Roll Back Quote, Verify and Approve again.'  
                                                                                                    as Name,  
          0                                                                                         as CanOverrideFlag  
  from   ORDERS.dbo.[Order]     O  with (nolock)  
  inner join  
         Orders.dbo.[OrderItem] OI with (nolock)  
  on     O.OrderIdSeq  = OI.OrderIDSeq  
  and    OI.StatusCode <> 'CNCL'  
  and    O.Quoteidseq  = @IPVC_QuoteID      
  where  O.Quoteidseq  = @IPVC_QuoteID       
  group by O.OrderIDSeq  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --5 : Check if atleast one  QuoteSalesAgent exist for the Current Quote  
  --------------------------------------------------------------------------------------------  
  if not exists (select 1 from QUOTES.DBO.QuoteSaleAgent  with (nolock) where QuoteIDSeq = @IPVC_QuoteID)  
  begin  
    insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
    select 'Missing Sales Representative.' as ErrorMsg, 'Please assign a sales representative to this quote.' as Name, 0 as CanOverrideFlag  
      
    if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
    begin  
      GOTO FinalSelectToUI  
      GOTO CleanUp  
      return;  
    end  
  
  end  
  --------------------------------------------------------------------------------------------  
  --6 : Check if atleast One Bundle is created for Current Quote  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Valid Bundle(s) are Not present.' as ErrorMsg,'Create and Associate Valid Bundle(s) to this Quote.' as Name, 0 as CanOverrideFlag  
  from  QUOTES.DBO.[Quote] Q  with (nolock)  
  where Q.QuoteIDSeq = @IPVC_QuoteID  
  and not exists (select 1 from QUOTES.DBO.[Group] with (nolock)    
                  where QuoteIDSeq = @IPVC_QuoteID   
                  and   QuoteIDSeq = Q.QuoteIDSeq)  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --7 : check if all bundles have atleast one item for Current Quote  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Bundle Group:'+Grp.[Name]+ 'has not product(s)'  as ErrorMsg,'Delete Bundle or Add Product(s) to this Bundle' as Name, 0 as CanOverrideFlag  
  from  QUOTES.DBO.[Group] Grp  with (nolock)  
  where QuoteIDSeq = @IPVC_QuoteID  
  and not exists (select Top 1 1 from QUOTES.DBO.QuoteItem  with (nolock)   
                  where QuoteIDSeq = @IPVC_QuoteID  
                  and   GroupIDSeq = grp.IDSeq)  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --8 :Check if all property level groups have properties assigned to them  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Properties are not attached to this Bundle Group:'+Grp.[Name] as ErrorMsg,'Attach atleast one valid property to this Bundle.' as Name, 0 as CanOverrideFlag  
  from  QUOTES.DBO.[Group] grp  with (nolock)  
  where QuoteIDSeq = @IPVC_QuoteID  
  and   GroupType = 'SITE'  
  and not exists (select 1 from QUOTES.DBO.[GroupProperties]  with (nolock)   
                  where  QuoteIDSeq = @IPVC_QuoteID  
                  and    GroupIDSeq = grp.IDSeq)  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --9 : Check if the company has a billing or shipping address  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Company:(' +@LVC_CompanyID+ ');Name:{'+C.Name+'} does not have valid Billing Address.' as ErrorMsg,  
         'Correct Billing Address through Customer Section.' as Name, 0 as CanOverrideFlag  
  from  Customers.dbo.Company C         with (nolock)  
  Left outer join  
        Customers.dbo.Address AddrBill  with (nolock)  
  on    C.IDSeq = AddrBill.CompanyIDSeq  
  and   C.IDSeq = @LVC_CompanyID  
  and   AddrBill.CompanyIDSeq = @LVC_CompanyID  
  and   AddrBill.PropertyIDSeq is null  
  and   AddrBill.AddressTypeCode = 'CBT'  
  where C.IDSeq = AddrBill.CompanyIDSeq  
  and   C.IDSeq = @LVC_CompanyID  
  and   AddrBill.CompanyIDSeq = @LVC_CompanyID  
  and   AddrBill.PropertyIDSeq is null  
  and   AddrBill.AddressTypeCode = 'CBT'  
  and  (  
        (coalesce(ltrim(rtrim(AddrBill.AddressLine1)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrBill.City)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrBill.Zip)),'')='')  
          OR  
        (AddrBill.CountryCode = 'USA' AND coalesce(ltrim(rtrim(AddrBill.State)),'')= '')  
       )  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --10: Check if the company has a billing or shipping address  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Company:(' +@LVC_CompanyID+ ');Name:{'+C.Name+'} does not have valid Shipping Address.' as ErrorMsg,  
         'Correct Shipping Address through Customer Section.' as Name, 0 as CanOverrideFlag  
  from  Customers.dbo.Company C         with (nolock)  
  Left outer join  
        Customers.dbo.Address AddrShip  with (nolock)  
  on    C.IDSeq = AddrShip.CompanyIDSeq  
  and   C.IDSeq = @LVC_CompanyID  
  and   AddrShip.CompanyIDSeq = @LVC_CompanyID  
  and   AddrShip.PropertyIDSeq is null  
  and   AddrShip.AddressTypeCode = 'CST'  
  where C.IDSeq = AddrShip.CompanyIDSeq  
  and   C.IDSeq = @LVC_CompanyID  
  and   AddrShip.CompanyIDSeq = @LVC_CompanyID  
  and   AddrShip.PropertyIDSeq is null  
  and   AddrShip.AddressTypeCode = 'CST'  
  and  (  
        (coalesce(ltrim(rtrim(AddrShip.AddressLine1)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrShip.City)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrShip.Zip)),'')='')  
          OR  
        (AddrShip.CountryCode = 'USA' AND coalesce(ltrim(rtrim(AddrShip.State)),'')= '')  
       )  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --11 : Check if all properties have a billing address  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Property:(' +P.IDSeq+ ');Name:{'+Max(P.Name)+'} does not have valid Billing Address.' as ErrorMsg,  
         'Correct Billing Address through Customer Property Section.' as Name, 0 as CanOverrideFlag  
  from QUOTES.DBO.GroupProperties GP  with (nolock)  
  inner join  
       Customers.dbo.Property     P       with (nolock)  
  on   GP.PropertyIDSeq = P.IDSeq  
  and  GP.CustomerIDSeq = P.PMCIDSeq  
  and  gp.QuoteIDSeq    = @IPVC_QuoteID  
  and  P.PMCIDSeq       = @LVC_CompanyID  
  and  GP.CustomerIDSeq = @LVC_CompanyID  
  Left outer join  
        Customers.dbo.Address AddrBill  with (nolock)  
  on    P.PMCIDSeq            = AddrBill.CompanyIDSeq    
  and   GP.CustomerIDSeq      = AddrBill.CompanyIDSeq  
  and   P.IDSeq               = AddrBill.PropertyIDSeq    
  and   GP.PropertyIDSeq      = AddrBill.PropertyIDSeq  
  and   P.PMCIDSeq            = @LVC_CompanyID  
  and   AddrBill.CompanyIDSeq = @LVC_CompanyID  
  and   AddrBill.PropertyIDSeq is not null  
  and   AddrBill.AddressTypeCode = 'PBT'  
  where P.PMCIDSeq            = AddrBill.CompanyIDSeq    
  and   GP.CustomerIDSeq      = AddrBill.CompanyIDSeq  
  and   P.IDSeq               = AddrBill.PropertyIDSeq    
  and   GP.PropertyIDSeq      = AddrBill.PropertyIDSeq  
  and   P.PMCIDSeq            = @LVC_CompanyID  
  and   AddrBill.CompanyIDSeq = @LVC_CompanyID  
  and   AddrBill.PropertyIDSeq is not null  
  and   AddrBill.AddressTypeCode = 'PBT'  
  and  (  
        (coalesce(ltrim(rtrim(AddrBill.AddressLine1)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrBill.City)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrBill.Zip)),'')='')  
          OR  
        (AddrBill.CountryCode = 'USA' AND coalesce(ltrim(rtrim(AddrBill.State)),'')= '')  
       )  
  group by P.IDSeq  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --12 : Check if all properties have a shipping address  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Property:(' +P.IDSeq+ ');Name:{'+Max(P.Name)+'} does not have valid Shipping Address.' as ErrorMsg,  
         'Correct Shipping Address through Customer Property Section.' as Name, 0 as CanOverrideFlag  
  from QUOTES.DBO.GroupProperties GP  with (nolock)  
  inner join  
       Customers.dbo.Property     P       with (nolock)  
  on   GP.PropertyIDSeq = P.IDSeq  
  and  GP.CustomerIDSeq = P.PMCIDSeq  
  and  gp.QuoteIDSeq    = @IPVC_QuoteID  
  and  P.PMCIDSeq       = @LVC_CompanyID  
  and  GP.CustomerIDSeq = @LVC_CompanyID  
  Left outer join  
        Customers.dbo.Address AddrShip  with (nolock)  
  on    P.PMCIDSeq            = AddrShip.CompanyIDSeq    
  and   GP.CustomerIDSeq      = AddrShip.CompanyIDSeq  
  and   P.IDSeq               = AddrShip.PropertyIDSeq    
  and   GP.PropertyIDSeq      = AddrShip.PropertyIDSeq  
  and   P.PMCIDSeq            = @LVC_CompanyID  
  and   AddrShip.CompanyIDSeq = @LVC_CompanyID  
  and   AddrShip.PropertyIDSeq is not null  
  and   AddrShip.AddressTypeCode = 'PST'  
  where P.PMCIDSeq            = AddrShip.CompanyIDSeq    
  and   GP.CustomerIDSeq      = AddrShip.CompanyIDSeq  
  and   P.IDSeq               = AddrShip.PropertyIDSeq    
  and   GP.PropertyIDSeq      = AddrShip.PropertyIDSeq  
  and   P.PMCIDSeq            = @LVC_CompanyID  
  and   AddrShip.CompanyIDSeq = @LVC_CompanyID  
  and   AddrShip.PropertyIDSeq is not null  
  and   AddrShip.AddressTypeCode = 'PST'  
  and  (  
        (coalesce(ltrim(rtrim(AddrShip.AddressLine1)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrShip.City)),'')='')  
          OR  
        (coalesce(ltrim(rtrim(AddrShip.Zip)),'')='')  
          OR  
        (AddrShip.CountryCode = 'USA' AND coalesce(ltrim(rtrim(AddrShip.State)),'')= '')  
       )  
  group by P.IDSeq  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --13 : Validate Company to be Active  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Company:(' +@LVC_CompanyID+ ');Name:{'+C.Name+'} Is NOT ACTIVE.' as ErrorMsg,  
         'Activate Company  through Customer Section.' as Name, 0 as CanOverrideFlag  
  from   Customers.dbo.Company C with (nolock)  
  where  C.IDSeq         = @LVC_CompanyID  
  and    C.StatusTypeCode<> 'ACTIV'  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --14 : Validate Property(s) to be Active  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Property:(' +P.IDSeq+ ');Name:{'+Max(P.Name)+'} Is NOT ACTIVE.' as ErrorMsg,  
         'Activate Property through Property Section.' as Name, 0 as CanOverrideFlag  
  from QUOTES.DBO.GroupProperties GP  with (nolock)  
  inner join  
       Customers.dbo.Property     P       with (nolock)  
  on   GP.PropertyIDSeq = P.IDSeq  
  and  GP.CustomerIDSeq = P.PMCIDSeq  
  and  gp.QuoteIDSeq    = @IPVC_QuoteID  
  and  P.PMCIDSeq       = @LVC_CompanyID  
  and  GP.CustomerIDSeq = @LVC_CompanyID  
  and  P.StatusTypeCode<> 'ACTIV'  
  group by P.IDSeq  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  --15 : Validate Company Bundle for GSA Products and GSAEntity Flag  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Company:(' +@LVC_CompanyID+ ');Name:{'+C.Name+'} is not GSA Enabled.' + char(13) +  
         'GSA Product(s) cannot be sold to Non GSA Company at Company Bundle Level.'                as ErrorMsg,  
         '[Suggestion(s):--->] (1) Check GSA Flag on Company through Customer Section.' + char(13)+  
         '                  (2) Remove GSA Product(s) from this Quote for Non GSA Company.'         as Name,  
         0 as CanOverrideFlag  
  from   Quotes.dbo.Quote Q with (nolock)  
  inner join   
         Quotes.dbo.[Group] G with (nolock)  
  on     Q.Quoteidseq    = G.QuoteIDSeq  
  and    Q.CustomerIDSeq = G.CustomerIDSeq  
  and    Q.Quoteidseq    = @IPVC_QuoteID  
  and    Q.CustomerIDSeq = @LVC_CompanyID  
  and    G.QuoteIDSeq    = @IPVC_QuoteID  
  and    G.CustomerIDSeq = @LVC_CompanyID  
  and    G.GroupType     = 'PMC'      
  inner Join  
         Quotes.dbo.QuoteItem QI With (nolock)  
  on     Q.Quoteidseq = QI.Quoteidseq  
  and    G.QuoteIDSeq = QI.Quoteidseq  
  and    G.IDSeq      = QI.GroupIDSeq  
  and    QI.Quoteidseq= @IPVC_QuoteID  
  and    QI.Familycode= 'GSA'  
  inner Join  
         Customers.dbo.Company C with (nolock)  
  on     Q.CustomerIDSeq = C.IDSeq  
  and    G.CustomerIDSeq = C.IDSeq  
  and    C.IDSeq         = @LVC_CompanyID  
  and    C.GSAEntityFlag <> 1  
  group by C.IDSeq,C.Name  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  ----------------------------------------------------------------------------------  
  --16 : Validate Property Bundle for GSA Products and GSAEntity Flag  
  --------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Property:(' +PRP.IDSeq+ ');Name:{'+Max(PRP.Name)+'} is not GSA Enabled;Bundle: ' + Max(G.[Name])+ char(13) +  
         'GSA Product(s) cannot be sold to Non GSA Properties at Property Bundle Level.'                as ErrorMsg,  
         '[Suggestion(s):--->] (1) Check GSA Flag on Property through Customer Property Section.' + char(13)+  
         '                  (2) Remove GSA Product(s) from this Quote Bundle for Non GSA Property.'     as Name,  
         0 as CanOverrideFlag  
  from   Quotes.dbo.Quote Q with (nolock)  
  inner join   
         Quotes.dbo.[Group] G with (nolock)  
  on     Q.Quoteidseq    = G.QuoteIDSeq  
  and    Q.CustomerIDSeq = G.CustomerIDSeq  
  and    Q.Quoteidseq    = @IPVC_QuoteID  
  and    Q.CustomerIDSeq = @LVC_CompanyID  
  and    G.QuoteIDSeq    = @IPVC_QuoteID  
  and    G.CustomerIDSeq = @LVC_CompanyID  
  and    G.GroupType     = 'SITE'  
  inner Join  
         Quotes.dbo.[GroupProperties] GP with (nolock)   
  on     Q.QuoteIDSeq    = GP.QuoteIDSeq  
  and    G.IDSeq         = GP.GroupIDSeq  
  and    G.CustomerIDSeq = GP.CustomerIDSeq  
  and    Q.CustomerIDSeq = GP.CustomerIDSeq  
  and    GP.Quoteidseq   = @IPVC_QuoteID  
  and    GP.CustomerIDSeq= @LVC_CompanyID   
  inner Join  
         Quotes.dbo.QuoteItem QI With (nolock)    on     Q.Quoteidseq = QI.Quoteidseq  
  and    G.QuoteIDSeq = QI.Quoteidseq  
  and    G.IDSeq      = QI.GroupIDSeq  
  and    GP.GroupIDSeq= QI.GroupIDSeq  
  and    QI.Quoteidseq= @IPVC_QuoteID  
  and    QI.Familycode= 'GSA'  
  inner Join  
         Customers.dbo.Property PRP with (nolock)  
  on     GP.PropertyIDSeq  = PRP.IDSeq  
  and    PRP.PMCIDSeq      = @LVC_CompanyID  
  and    PRP.GSAEntityFlag   <> 1  
  group by PRP.IDSeq,G.IDSeq  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
   ----------------------------------------------------------------------------------  
  --17 : Validation for FamilyInvalidCombo   
  ----------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select Max(F.Name) + ' family is incompatible with ' + Max(F1.Name) + ' family.' as ErrorMsg,  
         'Resolve incompatibility by deselecting incompatible family product(s)' as Name,0 as CanOverrideFlag  
  from   Products.dbo.FamilyInvalidCombo FIC with (nolock)  
  inner join  
         Products.dbo.Family             F   with (nolock)  
  on     FIC.FirstFamilyCode = F.Code  
  inner join  
         Products.dbo.Family             F1   with (nolock)  
  on     FIC.SecondFamilyCode = F1.Code  
  inner join  
         Quotes.dbo.Quoteitem QI with (nolock)  
  on     FIC.FirstFamilyCode = QI.FamilyCode  
  and    QI.Quoteidseq     = @IPVC_QuoteID  
  inner join  
         Quotes.dbo.Quoteitem LQI with (nolock)  
  on     FIC.SecondFamilyCode = LQI.FamilyCode  
  and    LQI.Quoteidseq      = @IPVC_QuoteID   
  group by F.Code,F1.Code  
  ------  
  UNION  
  ------  
  select Max(F.Name) + ' family is incompatible with ' + Max(F1.Name)+ ' family.' as ErrorMsg,  
         'Resolve incompatibility by deselecting incompatible family product(s)' as Name,0 as CanOverrideFlag  
  from   Products.dbo.FamilyInvalidCombo FIC with (nolock)  
  inner join  
         Products.dbo.Family             F   with (nolock)  
  on     FIC.FirstFamilyCode = F.Code  
  inner join  
         Products.dbo.Family             F1   with (nolock)  
  on     FIC.SecondFamilyCode = F1.Code  
  inner join  
         Quotes.dbo.Quoteitem  QI with (nolock)  
  on     FIC.SecondFamilyCode  = QI.FamilyCode  
  and    QI.Quoteidseq         = @IPVC_QuoteID  
  inner join  
         Quotes.dbo.Quoteitem  LQI with (nolock)  
  on     FIC.FirstFamilyCode = LQI.FamilyCode  
  and    LQI.Quoteidseq      = @IPVC_QuoteID  
  group by F.Code,F1.Code  
  order by ErrorMsg asc  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  ----------------------------------------------------------------------------------  
  --18 : Validate that all products have the same LeadDays in a given custom bundle.  
  ----------------------------------------------------------------------------------  
  declare @LT_TMP_LeadDays table (GroupIDSeq   bigint,ErrorMsg     varchar(2000),  
                                  Name         varchar(2000),CanOverrideFlag bit,  
                                  recordcount  int not null default (0),  
                                  LeadDays     int not null default (0)  
                                 )   
  
  insert into @LT_TMP_LeadDays(GroupIDSeq,ErrorMsg,Name,CanOverrideFlag,recordcount,LeadDays)  
  select distinct G.IDSeq as GroupIDSeq,  
        'Bundle :' + Max(G.Name) + '- Products with different Billing cycle configuration cannot be bundled together '  as ErrorMsg,   
         Max(Pr.DisplayName) + ': Billing ' + (case when C.Leaddays = 0 then 'Immediate'  
                                            when C.Leaddays < 0 then convert(varchar(50),C.Leaddays) + ' in arrears'   
                                            when C.Leaddays > 0 then convert(varchar(50),C.Leaddays) + ' in advance'  
                                       end) +  
         ' which is different from other products in the bundle. This product may be removed from the bundle.'  
                                                                                    as Name,  
         0                                                                          as CanOverrideFlag,  
         Count(1)                                                                   as RecordCount,  
         C.LeadDays                                                                 as LeadDays  
  from    Quotes.dbo.QuoteItem QI   with (nolock)  
  inner join  
          Quotes.dbo.[Group]   G    with (nolock)  
  on      G.QuoteIDSeq    = QI.QuoteIDSeq  
  and     QI.QuoteIDSeq   = @IPVC_QuoteID   
  and     G.QuoteIDSeq    = @IPVC_QuoteID  
  and     G.IDSeq         = QI.GroupIDSeq  
  and     G.CustomBundleNameEnabledFlag = 1  
  and     QI.ChargetypeCode =  'ACS'  
  and     QI.MeasureCode    <> 'TRAN'  
  and     QI.FrequencyCode  <> 'OT'  
  inner join  
          Products.dbo.Charge C     with (nolock)  
  on      QI.ProductCode   = C.ProductCode  
  and     QI.PriceVersion  = C.PriceVersion  
  and     QI.Measurecode   = C.measurecode  
  and     QI.Frequencycode = C.Frequencycode   
  and     QI.Chargetypecode= C.Chargetypecode   
  and     QI.QuoteIDSeq    = @IPVC_QuoteID   
  inner join  
         Products.dbo.Product Pr with (nolock)  
  on     QI.ProductCode  = Pr.Code  
  and    QI.PriceVersion = Pr.PriceVersion  
  and    C.ProductCode   = Pr.Code  
  and    C.PriceVersion  = Pr.PriceVersion  
  where  QI.QuoteIDseq   = @IPVC_QuoteID   
  group by G.IDSeq,C.LeadDays    
    
   
  insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
  select ErrorMsg,Name,CanOverrideFlag  
  from   @LT_TMP_LeadDays S   
  inner join   (select S1.GroupIDSeq,MIN(S1.LeadDays) as MinLeadDays  
                from  @LT_TMP_LeadDays S1  
                group by S1.GroupIDSeq  
                having count(*) > 1  
               ) X  
  on     S.GroupIDSeq = X.GroupIDSeq  
  and    S.LeadDays   = X.MinLeadDays  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  ----------------------------------------------------------------------------------  
  --19: Validate that all products have the same TaxwareCompanyCode in a given custom bundle.  
  ----------------------------------------------------------------------------------  
  declare @LT_TMP_BillingEntities table (GroupIDSeq   bigint,ErrorMsg     varchar(2000),  
                                         Name         varchar(2000),CanOverrideFlag bit,  
                                         recordcount  int not null default (0),  
                                         EpicorPostingCode  varchar(20),  
                                         TaxwareCompanyCode varchar(20)  
                                         )   
  
  insert into @LT_TMP_BillingEntities(GroupIDSeq,ErrorMsg,Name,CanOverrideFlag,recordcount,EpicorPostingCode,TaxwareCompanyCode)  
  select distinct G.IDSeq as GroupIDSeq,  
        'Bundle :' + Max(G.Name) + '- Products with different Billing entities cannot be bundled together. ' +   
                                   'ie. EpicorPostingCode and TaxwareCompanyCode of all products should be the same. '  as ErrorMsg,   
         Max(Pr.DisplayName) + ': has EpicorPostingCode = ' + F.EpicorPostingCode + ',TaxwareCompanyCode = ' + convert(varchar(50),TaxwareCompanyCode) +  
                               ' which is different from other products in the bundle. This product may be removed from the bundle.'  
                                                                                    as Name,  
         0                                                                          as CanOverrideFlag,  
         Count(1)                                                                   as RecordCount,  
         F.EpicorPostingCode                                                        as EpicorPostingCode,  
         F.TaxwareCompanyCode                                                       as TaxwareCompanyCode  
  from    Quotes.dbo.QuoteItem QI   with (nolock)  
  inner join  
          Quotes.dbo.[Group]   G    with (nolock)  
  on      G.QuoteIDSeq    = QI.QuoteIDSeq  
  and     QI.QuoteIDSeq   = @IPVC_QuoteID   
  and     G.QuoteIDSeq    = @IPVC_QuoteID  
  and     G.IDSeq         = QI.GroupIDSeq  
  and     G.CustomBundleNameEnabledFlag = 1    
  inner join  
         Products.dbo.Product Pr with (nolock)  
  on     QI.ProductCode  = Pr.Code  
  and    QI.PriceVersion = Pr.PriceVersion  
  inner join  
         Products.dbo.Family F with (nolock)  
  on     Pr.FamilyCode   = F.Code  
  where  QI.QuoteIDseq   = @IPVC_QuoteID   
  group by G.IDSeq,F.EpicorPostingCode,F.TaxwareCompanyCode  
    
   
  insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
  select ErrorMsg,Name,CanOverrideFlag  
  from   @LT_TMP_BillingEntities S   
  inner join   (select S1.GroupIDSeq,Max(S1.TaxwareCompanyCode+'-'+S1.EpicorPostingCode) as MaxCode  
                from  @LT_TMP_BillingEntities S1  
                group by S1.GroupIDSeq  
                having count(*) > 1  
               ) X  
  on     S.GroupIDSeq = X.GroupIDSeq  
  and    (S.TaxwareCompanyCode+'-'+S.EpicorPostingCode) = X.MaxCode  
    
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  ----------------------------------------------------------------------------------  
  --20: Check if the products of current quote has associated PublicationYear  
  --                and PublicationQuarter for MPFPublicationFlag = 1 products.  
  ----------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
  select distinct   
        'The following products needs PublicationYear and PublicationQuarter:'   as ErrorMsg,   
         Pr.DisplayName + ': ' + 'Please click on link to confirm PublicationYear,PublicationQuarter and Save'  
                                                                                    as Name,  
         (Case when @IPVC_ValidationType = 'SubmitQuote' then 0 else 0 end)         as CanOverrideFlag  
  from    Quotes.dbo.QuoteItem QI   with (nolock)  
  inner join  
          Products.dbo.Charge C     with (nolock)  
  on      QI.ProductCode  = C.ProductCode  
  and     QI.PriceVersion = C.PriceVersion  
  and     QI.Measurecode  = C.measurecode  
  and     QI.Frequencycode= C.Frequencycode   
  and     QI.Chargetypecode=C.Chargetypecode   
  and     QI.QuoteIDSeq    =@IPVC_QuoteID   
  --> Mandatory   
  and    ( isnumeric(QI.PublicationYear)=0   
              OR  
          (QI.PublicationQuarter is null or QI.PublicationQuarter='')   
         )  
  inner join  
         Products.dbo.Product Pr with (nolock)  
  on     QI.ProductCode  = Pr.Code  
  and    QI.PriceVersion = Pr.PriceVersion  
  and    C.ProductCode   = Pr.Code  
  and    C.PriceVersion  = Pr.PriceVersion  
  and    Pr.MPFPublicationFlag = 1  
  where  QI.QuoteIDseq   = @IPVC_QuoteID  
  
  if exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  -----------------------------------------------------------------------------------------------------------------  
  ---OVERRIABLE ERRORS  
  -----------------------------------------------------------------------------------------------------------------  
  ---1 : Validate Company Bundle for SiteMasterId  
  -----------------------------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Company:(' +@LVC_CompanyID+ ');Name:{'+Max(C.Name)+'} does not have valid SitemasterID.'+char(13)+  
         'Product(s)- Transactional And/Or Subscription (for which SitemasterID is mandatory) '   +char(13)+  
         ' and those qualify for Auto Fulfillment (unless Delayed ACS/ANC Billing)'               +char(13)+  
         ' sold at Company Bundle Level requires valid SiteMasterID at the Company before approval of this Quote.' as ErrorMsg,  
         'Key in Valid SiteMasterID through Customer Section.'                                                     as Name,  
         (Case when @IPVC_ValidationType = 'SubmitQuote' then 1 else 0 end)                                        as CanOverrideFlag  
  from   Quotes.dbo.Quote Q with (nolock)  
  inner join   
         Quotes.dbo.[Group] G with (nolock)  
  on     Q.Quoteidseq    = G.QuoteIDSeq  
  and    Q.CustomerIDSeq = G.CustomerIDSeq  
  and    Q.Quoteidseq    = @IPVC_QuoteID  
  and    Q.CustomerIDSeq = @LVC_CompanyID  
  and    G.QuoteIDSeq    = @IPVC_QuoteID  
  and    G.CustomerIDSeq = @LVC_CompanyID  
  and    G.GroupType     = 'PMC'      
  inner Join  
         Quotes.dbo.QuoteItem QI With (nolock)  
  on     Q.Quoteidseq  = QI.Quoteidseq  
  and    G.QuoteIDSeq  = QI.Quoteidseq  
  and    G.IDSeq       = QI.GroupIDSeq  
  and    QI.Quoteidseq = @IPVC_QuoteID    
  and    QI.Chargetypecode   = 'ACS'    
  inner join  
         Products.dbo.product   P  with (nolock)  
  on     QI.ProductCode = P.Code  
  and    QI.Priceversion= P.Priceversion  
  inner join  
         Products.dbo.Charge CHG with (nolock)  
  on     QI.ProductCode      = CHG.ProductCode  
  and    QI.PriceVersion     = CHG.Priceversion  
  and    QI.Chargetypecode   = CHG.ChargetypeCode  
  and    QI.Measurecode      = CHG.Measurecode  
  and    QI.FrequencyCode    = CHG.FrequencyCode  
  and    QI.Chargetypecode   = 'ACS'  
  and    (QI.MeasureCode = 'TRAN' or (P.Autofulfillflag = 1 and @IPB_DelayACSANCBilling = 0))   
  and    CHG.ValidateSiteMasterIDFlag = 1        
  inner Join  
         Customers.dbo.Company C with (nolock)  
  on     Q.CustomerIDSeq = C.IDSeq  
  and    G.CustomerIDSeq = C.IDSeq  
  and    C.IDSeq         = @LVC_CompanyID  
  and    (len(C.SiteMasterID) = 0 OR coalesce(C.SiteMasterID,'')='')  
  group by C.IDSeq  
  
  if (@IPVC_ValidationType = 'ApproveQuote') and exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  -----------------------------------------------------------------------------------------------------------------  
  ---2 : Validate Property Bundle for SiteMasterId  
  -----------------------------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,[Name],CanOverrideFlag)  
  select 'Property:(' +PRP.IDSeq+ ');Name:{'+Max(PRP.Name)+'} does not have valid SitemasterID.'+char(13)+  
         'Product(s)- Transactional And/Or Subscription (for which SitemasterID is mandatory) '   +char(13)+  
         ' and those qualify for Auto Fulfillment (unless Delayed ACS/ANC Billing)'               +char(13)+  
         ' sold at Property Bundle Level requires valid SiteMasterID at the Property before approval of this Quote.' as ErrorMsg,  
         'Key in Valid SiteMasterID through Customer Property Section.'                                              as Name,  
         (Case when @IPVC_ValidationType = 'SubmitQuote' then 1 else 0 end)                                          as CanOverrideFlag  
  from   Quotes.dbo.Quote Q with (nolock)  
  inner join   
         Quotes.dbo.[Group] G with (nolock)  
  on     Q.Quoteidseq    = G.QuoteIDSeq  
  and    Q.CustomerIDSeq = G.CustomerIDSeq  
  and    Q.Quoteidseq    = @IPVC_QuoteID  
  and    Q.CustomerIDSeq = @LVC_CompanyID  
  and    G.QuoteIDSeq    = @IPVC_QuoteID  
  and    G.CustomerIDSeq = @LVC_CompanyID  
  and    G.GroupType     = 'SITE'  
  inner Join  
         Quotes.dbo.[GroupProperties] GP with (nolock)   
  on     Q.QuoteIDSeq    = GP.QuoteIDSeq  
  and    G.IDSeq         = GP.GroupIDSeq  
  and    G.CustomerIDSeq = GP.CustomerIDSeq  
  and    Q.CustomerIDSeq = GP.CustomerIDSeq  
  and    GP.Quoteidseq   = @IPVC_QuoteID  
  and    GP.CustomerIDSeq= @LVC_CompanyID   
  inner Join  
         Quotes.dbo.QuoteItem QI With (nolock)  
  on     Q.Quoteidseq = QI.Quoteidseq  
  and    G.QuoteIDSeq = QI.Quoteidseq  
  and    G.IDSeq      = QI.GroupIDSeq  
  and    GP.GroupIDSeq= QI.GroupIDSeq  
  and    QI.Quoteidseq= @IPVC_QuoteID   
  and    QI.Chargetypecode   = 'ACS'     
  inner join  
         Products.dbo.product   P  with (nolock)  
  on     QI.ProductCode = P.Code  
  and    QI.Priceversion= P.Priceversion  
  inner join  
         Products.dbo.Charge CHG with (nolock)  
  on     QI.ProductCode      = CHG.ProductCode  
  and    QI.PriceVersion     = CHG.Priceversion  
  and    QI.Chargetypecode   = CHG.ChargetypeCode  
  and    QI.Measurecode      = CHG.Measurecode  
  and    QI.FrequencyCode    = CHG.FrequencyCode  
  and    QI.Chargetypecode   = 'ACS'    
  and    (QI.MeasureCode = 'TRAN' or (P.Autofulfillflag = 1 and @IPB_DelayACSANCBilling = 0))  
  and    CHG.ValidateSiteMasterIDFlag = 1  
  inner Join  
         Customers.dbo.Property PRP with (nolock)  
  on     GP.PropertyIDSeq  = PRP.IDSeq  
  and    PRP.PMCIDSeq      = @LVC_CompanyID  
  and    (len(PRP.SiteMasterID) = 0 or coalesce(PRP.SiteMasterID,'')='')  
  group by PRP.IDSeq  
   
  if (@IPVC_ValidationType = 'ApproveQuote') and exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end   
  ------------------------------------------------------------------------------------------------------  
  -- 3: Check if the products of current quote has associated Revenue Code and Taxware Code.  
  ------------------------------------------------------------------------------------------------------  
  insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
  select distinct   
        'Some Product(s) of Quote ' + @IPVC_QuoteID + ' is missing critical associated Revenue and/or Taxware Code :'+     
         Pr.DisplayName + ': ' + ltrim(rtrim(QI.Chargetypecode)) + '/' + ltrim(rtrim(QI.MeasureCode)) + '/' +   
              REPLACE(REPLACE(QI.FREQUENCYCODE,'SG','INITIAL FEE'),'OT','ONE-TIME') as ErrorMsg,   
        'Submit Product request forms to get OMS ProductMaster Updated.'            as Name,  
         (Case when @IPVC_ValidationType = 'SubmitQuote' then 1 else 0 end)         as CanOverrideFlag  
  from    Quotes.dbo.QuoteItem QI   with (nolock)  
  inner join  
          Products.dbo.Charge C     with (nolock)  
  on      QI.ProductCode  = C.ProductCode  
  and     QI.PriceVersion = C.PriceVersion  
  and     QI.Measurecode  = C.measurecode  
  and     QI.Frequencycode= C.Frequencycode   
  and     QI.Chargetypecode=C.Chargetypecode   
  and     QI.QuoteIDSeq    =@IPVC_QuoteID   
  and (  
        (ltrim(rtrim(C.RevenueAccountCode)) is NULL or ltrim(rtrim(C.RevenueAccountCode)) = '') --> Mandatory     
          OR  
        (ltrim(rtrim(C.RevenueTierCode)) is NULL or ltrim(rtrim(C.RevenueTierCode)) = '') --> Mandatory            
          OR  
        (ltrim(rtrim(C.TaxwareCode)) is NULL or ltrim(rtrim(C.TaxwareCode)) = '') --> Mandatory                                      
          OR    
        (C.RevenueRecognitionCode in ('SRR','MRR') and (ltrim(rtrim(C.DeferredRevenueAccountCode)) is null or ltrim(rtrim(C.DeferredRevenueAccountCode)) = '')  
        ) --> DeferredRevenueAccountCode is Mandatory for RevenueRecognitionCode SRR and MRR  
  )  
  inner join  
         Products.dbo.Product Pr with (nolock)  
  on     QI.ProductCode  = Pr.Code  
  and    QI.PriceVersion = Pr.PriceVersion  
  and    C.ProductCode   = Pr.Code  
  and    C.PriceVersion  = Pr.PriceVersion  
  where  QI.QuoteIDseq   = @IPVC_QuoteID      
    
  if (@IPVC_ValidationType = 'ApproveQuote') and exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end   
  ---------------------------------------------------------------------------------------------------------------------  
  if (@IPVC_ValidationType = 'ApproveQuote')  
  begin  
    ---------------------------------------------------------------------------------------------------------------------  
    -- 4: check if the products of current Quote has active Agreement(s) in past Orders for the same account  
    ---------------------------------------------------------------------------------------------------------------------  
    insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
    select (case when O.PropertyIDSeq is NULL then 'Company: ' + Max(Com.Name)  
               else Max(Prpty.Name)  
          end)  + ' has Active Agreement(s) for same Product(s): ' +                          
         Max(QPC.ProductName) + '.(Order #' + convert(varchar(50),O.OrderIDSeq) + ').' + char(13) as ErrorMsg,   
         (Case   
              when Max(OI.StatusCode) = 'EXPD'  
                then 'Currently Expired but was Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+  
                     '[Suggestion(s):--->] (1) If Back bill then Consider Approving ' + @IPVC_QuoteID + ' with Approval Date that does not overlap with existing active product order(s). ' + char(13)+  
                     '                     (2) Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)+  
                     '                     (3) Do not approve the Quote ' + @IPVC_QuoteID + '. Explore other options with Client Services Manager.' + char(13)  
               when OI.Canceldate is not null   
                 then 'Cancelled and Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.Canceldate,101)+ '.' +char(13)+  
                       '[Suggestion(s):--->] (1) Backdate ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate :' + convert(varchar(50),coalesce(OI.StartDate,@LDT_ApprovalDate),101) + char(13)+  
                       '                     (2) Consider Approving ' + @IPVC_QuoteID + ' with Approval Date   :' + convert(varchar(50),OI.Canceldate,101)+ char(13)+  
                       '                     (3) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)+  
                       '                     (4) Do not approve the Quote ' + @IPVC_QuoteID + '. Explore other options with Client Services Manager.' + char(13)  
                when OI.Canceldate is null   
                 then 'Fulfilled and Active from ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+  
                      '[Suggestion(s):--->] (1) Cancel ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate :  ' + convert(varchar(50),coalesce(OI.StartDate,@LDT_ApprovalDate),101) + char(13)+  
                      '                     (2) Consider Approving ' + @IPVC_QuoteID + ' with Approval Date : ' + convert(varchar(50),OI.Enddate+1,101)+ char(13)+  
                      '                     (3) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)+  
                      '                     (4) Do not approve the Quote ' + @IPVC_QuoteID + '. Explore other options with Client Services Manager.' + char(13)  
          end)                                                                           as [Name],  
          0                                                                              as CanOverrideFlag  
    from   ORDERS.dbo.[ORDER] O With (nolock)  
    inner join  
           CUSTOMERS.dbo.Company Com with (nolock)  
    on     O.CompanyIDSeq = Com.IDSeq  
    and    O.CompanyIDSeq = @LVC_CompanyID  
    and    Com.IDSeq      = @LVC_CompanyID  
    inner join  
           ORDERS.dbo.[OrderItem] OI with (nolock)  
    on     O.OrderIDSeq      = OI.OrderIDSeq    
    and    O.CompanyIDSeq    = @LVC_CompanyID      
    and    OI.Chargetypecode        = 'ACS'   
    and    isdate(OI.Startdate)     = 1  
    and   (@LDT_ApprovalDate >= OI.Startdate  
            and  
           @LDT_ApprovalDate <= coalesce(OI.Canceldate-1,OI.Enddate)  
            and  
           (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)  
          )  
    inner join  
           #LT_QuoteProductCode  QPC with (nolock)  
    on     OI.Productcode = QPC.ProductCode  
    inner join  
           Products.dbo.product   P  with (nolock)  
    on     OI.ProductCode   = P.Code  
    and    OI.Priceversion  = P.Priceversion  
    and    QPC.ProductCode = P.Code  
    inner join  
           Products.dbo.Charge CHGO with (nolock)  
    on     OI.productCode    = CHGO.productCode  
    and    OI.PriceVersion   = CHGO.PriceVersion  
    and    OI.Chargetypecode = CHGO.Chargetypecode  
    and    OI.MeasureCode    = CHGO.MeasureCode  
    and    OI.FrequencyCode  = CHGO.FrequencyCode       
    and    CHGO.QuantityEnabledFlag = 0  
    and  ( (OI.MeasureCode          = 'TRAN')   
               OR   
           (P.Autofulfillflag = 1 and @IPB_DelayACSANCBilling = 0)  
                OR  
           (@IPB_DelayILFBilling = 0)                 
         )  
    inner join  
            (select GP.CustomerIDSeq as CompanyIDSeq,GP.PropertyIDSeq,G.GroupType,QI.ProductCode,QI.Chargetypecode  
             from   QUOTES.dbo.QuoteItem QI with (nolock)  
             inner join  
                    QUOTES.dbo.[Group] G    with (nolock)  
             on     G.IDSeq            = QI.GroupIDSeq   
             and    G.QuoteIdSeq       = QI.QuoteIdSeq  
             and    G.Quoteidseq       = @IPVC_QuoteID  
             and    QI.Quoteidseq      = @IPVC_QuoteID  
             and    G.CustomerIDSeq    = @LVC_CompanyID  
             and    QI.chargetypecode  =  'ACS'  
             left outer join  
                    QUOTES.dbo.[GroupProperties] GP with (nolock)  
             on     QI.Quoteidseq   = GP.Quoteidseq  
             and    G.IDSeq         = GP.GroupIDSeq  
             and    QI.GroupIDSeq   = GP.GroupIDSeq  
             and    GP.Quoteidseq   = @IPVC_QuoteID  
             and    G.CustomerIDSeq = GP.CustomerIDSeq  
             and    GP.CustomerIDSeq= @LVC_CompanyID  
             group by GP.CustomerIDSeq,GP.PropertyIDSeq,G.GroupType,QI.ProductCode,QI.Chargetypecode  
            ) S  
    on   O.CompanyIDSeq    = S.CompanyIDSeq  
    and  O.PropertyIDSeq   = S.PropertyIDSeq  
    and  OI.ProductCode    = S.ProductCode  
    and  OI.Chargetypecode = S.Chargetypecode  
    and  QPC.GroupType     = S.GroupType  
    left outer join  
         CUSTOMERS.dbo.Property Prpty with (nolock)  
    on   O.CompanyIDSeq = Prpty.PMCIDSeq  
    and  S.CompanyIDSeq = Prpty.PMCIDSeq  
    and  O.PropertyIDSeq= Prpty.IDSeq  
    and  S.PropertyIDSeq= Prpty.IDSeq      
    and  Prpty.PMCIDSeq = @LVC_CompanyID  
    group by O.CompanyIDSeq,O.PropertyIDSeq,O.OrderIDSeq,OI.StartDate,OI.Canceldate,OI.EndDate  
    ---------------------------------------------------------------------------------------------------------------------  
    -- 5: check if the invalid combo products of current Quote has active Agreement(s) in past Orders for the same account  
    ---------------------------------------------------------------------------------------------------------------------  
    insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
    select (case when O.PropertyIDSeq is NULL then 'Company: ' + Max(Com.Name)  
               else Max(Prpty.Name)  
            end)   + 'has Active Agreement(s) for Invalid Combo Product(s): ' + char(13) +  
         'ie.' + Max(P.DisplayName) + '.(Order #' + convert(varchar(50),O.OrderIDSeq) + ').' + ' Invalid to ' + Max(S.CurrentOrderProductName) + char(13) as ErrorMsg,   
         (Case   
               when Max(OI.StatusCode) = 'EXPD'  
                 then 'Currently Expired but was Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+  
                      '[Suggestion(s):--->] (1) If Back bill then Consider Approving ' + @IPVC_QuoteID + ' with Approval Date that does not overlap with existing active product order(s). ' + char(13)+  
                      '                     (2) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)+  
                      '                     (3) Do not approve the Quote ' + @IPVC_QuoteID + '. Explore other options with Client Services Manager.' + char(13)  
               when OI.Canceldate is not null   
                 then  'Cancelled and Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.Canceldate,101)+ '.' +char(13)+  
                       '[Suggestion(s):--->] (1) Backdate ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate : ' + convert(varchar(50),coalesce(OI.StartDate,@LDT_ApprovalDate),101) + char(13)+  
                       '                     (2) Consider Approving ' + @IPVC_QuoteID      + ' with Approval Date : ' + convert(varchar(50),OI.Canceldate,101)+ char(13)+  
                       '                     (3) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)+  
                       '                     (4) Do not approve the Quote ' + @IPVC_QuoteID + '. Explore other options with Client Services Manager.' + char(13)  
               when OI.Canceldate is null   
                 then 'Fulfilled and Active from ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+  
                      '[Suggestion(s):--->] (1) Cancel ' + convert(varchar(50),O.OrderIDSeq)  + ' with Canceldate : ' + convert(varchar(50),coalesce(OI.StartDate,@LDT_ApprovalDate),101) + char(13)+  
                      '                     (2) Consider Approving ' + @IPVC_QuoteID     + ' with Approval Date : ' + convert(varchar(50),OI.Enddate+1,101)+ char(13)+  
                      '                     (3) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)+  
                      '                     (4) Do not approve the Quote ' + @IPVC_QuoteID + '. Explore other options with Client Services Manager.' + char(13)  
          end)                                                                           as [Name],  
          0                                                                              as CanOverrideFlag  
    from   ORDERS.dbo.[ORDER] O With (nolock)  
    inner join  
           CUSTOMERS.dbo.Company Com with (nolock)  
    on     O.CompanyIDSeq = Com.IDSeq  
    and    O.CompanyIDSeq = @LVC_CompanyID  
    and    Com.IDSeq      = @LVC_CompanyID  
    inner join  
           ORDERS.dbo.[OrderItem] OI with (nolock)  
    on     O.OrderIDSeq       = OI.OrderIDSeq    
    and    O.CompanyIDSeq     = @LVC_CompanyID      
    and    OI.Chargetypecode        = 'ACS'   
    and    isdate(OI.Startdate)     = 1  
    and   (@LDT_ApprovalDate >= OI.Startdate  
            and  
           @LDT_ApprovalDate <= coalesce(OI.Canceldate-1,OI.Enddate)  
            and  
           (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)  
          )   
    inner join  
           Products.dbo.product   P  with (nolock)  
    on     OI.ProductCode   = P.Code  
    and    OI.Priceversion  = P.Priceversion  
    inner join  
           Products.dbo.Charge CHGO with (nolock)  
    on     OI.productCode    = CHGO.productCode  
    and    OI.PriceVersion   = CHGO.PriceVersion  
    and    OI.Chargetypecode = CHGO.Chargetypecode  
    and    OI.MeasureCode    = CHGO.MeasureCode  
    and    OI.FrequencyCode  = CHGO.FrequencyCode       
    and    CHGO.QuantityEnabledFlag = 0  
    and  ( (OI.MeasureCode          = 'TRAN')   
               OR   
           (P.Autofulfillflag = 1 and @IPB_DelayACSANCBilling = 0)  
               OR  
           (@IPB_DelayILFBilling = 0)  
         )  
    inner join  
            (select GP.CustomerIDSeq as CompanyIDSeq,GP.PropertyIDSeq,G.GroupType,QI.ProductCode,QI.Chargetypecode,  
                    coalesce(PIC2.FirstProductCode,PIC1.SecondProductCode) as InvalidProduct,  
                    Max(ProductName)                                       as CurrentOrderProductName  
             from   QUOTES.dbo.QuoteItem QI with (nolock)  
             inner join  
                    QUOTES.dbo.[Group] G    with (nolock)  
             on     G.IDSeq            = QI.GroupIDSeq   
             and    G.QuoteIdSeq       = QI.QuoteIdSeq  
             and    G.Quoteidseq       = @IPVC_QuoteID  
             and    QI.Quoteidseq      = @IPVC_QuoteID  
             and    G.CustomerIDSeq    = @LVC_CompanyID  
             and    QI.chargetypecode  =  'ACS'  
             inner join  
                    #LT_QuoteProductCode  QPC with (nolock)  
             on     QI.Productcode = QPC.ProductCode  
             and    G.GroupType    = QPC.GroupType  
             inner join  
                     Products.dbo.ProductInvalidCombo PIC1 with (nolock)  
             on     QPC.ProductCode = PIC1.FirstProductCode  
             and    QI.ProductCode = PIC1.FirstProductCode  
             left outer join  
                     Products.dbo.ProductInvalidCombo PIC2 with (nolock)  
             on     QPC.ProductCode = PIC2.SecondProductCode  
             and    QI.ProductCode  = PIC2.SecondProductCode  
             left outer join  
                    QUOTES.dbo.[GroupProperties] GP with (nolock)  
             on     QI.Quoteidseq   = GP.Quoteidseq  
             and    G.IDSeq         = GP.GroupIDSeq  
             and    QI.GroupIDSeq   = GP.GroupIDSeq  
             and    GP.Quoteidseq   = @IPVC_QuoteID  
             and    G.CustomerIDSeq = GP.CustomerIDSeq  
             and    GP.CustomerIDSeq= @LVC_CompanyID  
             group by GP.CustomerIDSeq,GP.PropertyIDSeq,G.GroupType,QI.ProductCode,QI.Chargetypecode,coalesce(PIC2.FirstProductCode,PIC1.SecondProductCode)  
            ) S  
    on   O.CompanyIDSeq    = S.CompanyIDSeq  
    and  O.PropertyIDSeq   = S.PropertyIDSeq  
    and  OI.ProductCode    = S.InvalidProduct  
    and  OI.Chargetypecode = S.Chargetypecode  
    and ((S.GroupType = 'PMC' and O.PropertyIDSeq is null)  
           OR  
         (S.GroupType <> 'PMC' and O.PropertyIDSeq is not null)  
        )  
    left outer join  
         CUSTOMERS.dbo.Property Prpty with (nolock)  
    on   O.CompanyIDSeq = Prpty.PMCIDSeq  
    and  S.CompanyIDSeq = Prpty.PMCIDSeq  
    and  O.PropertyIDSeq= Prpty.IDSeq  
    and  S.PropertyIDSeq= Prpty.IDSeq      
    and  Prpty.PMCIDSeq = @LVC_CompanyID  
    group by O.CompanyIDSeq,O.PropertyIDSeq,O.OrderIDSeq,OI.StartDate,OI.Canceldate,OI.EndDate  
    ---------------------------------------------------------------------------------------------------------------------  
    -- 6: Validate to check Original property having the same city,state,zip belonging to Orginal PMC,   
    ---   as the transferred property has any outstanding active orders.  
    ---------------------------------------------------------------------------------------------------------------------  
    if exists(select top 1 1   
              from   QUOTES.dbo.[GroupProperties] GP with (nolock)  
              where  GP.Quoteidseq   = @IPVC_QuoteID  
              and    GP.CustomerIDSeq= @LVC_CompanyID  
             )  
    begin  
      create table #TempOrginalProperty(seq           int identity(1,1) not null primary key,  
                                        companyidseq  varchar(50),  
                                        propertyidseq varchar(50),  
                                        propertyname  varchar(255),  
                                        city          varchar(50),state varchar(50),zip varchar(50)  
                                        );  
  
      insert into #TempOrginalProperty(companyidseq,propertyidseq,propertyname,city,state,zip)  
      select A.companyidseq,A.propertyidseq,Max(Prp.Name) as propertyname,A.city,A.state,A.zip  
      from   Customers.dbo.address A with (nolock)  
      inner Join  
             Customers.dbo.Property Prp with (nolock)  
      on     Prp.IDseq = A.propertyidseq  
      and    A.addresstypecode = 'PRO'  
      and    A.companyidseq <> @LVC_CompanyID  
      and    A.propertyidseq is not null  
      inner join  
             (Select GP.propertyidseq,ltrim(rtrim(X.AddressLine1)) as AddressLine1,ltrim(rtrim(X.city)) as city,ltrim(rtrim(X.state)) as state,ltrim(rtrim(X.zip)) as zip,coalesce(Y.Phase,'-1') as Phase  
              from   QUOTES.dbo.[GroupProperties] GP with (nolock)  
              inner join  
                     Customers.dbo.address        X with (nolock)  
              on     X.companyidseq    = GP.CustomerIDSeq  
              and    X.propertyidseq   = GP.propertyidseq  
              and    X.addresstypecode = 'PRO'  
              and    X.companyidseq    = @LVC_CompanyID  
              and    X.propertyidseq is not null  
              and    GP.CustomerIDSeq  = @LVC_CompanyID  
              and    GP.Quoteidseq     = @IPVC_QuoteID  
              inner join  
                     Customers.dbo.Property Y with (nolock)  
              on      Y.IDSeq           = X.propertyidseq  
              and     Y.IDSeq           = GP.propertyidseq  
              group by GP.propertyidseq,ltrim(rtrim(X.AddressLine1)),ltrim(rtrim(X.city)),ltrim(rtrim(X.state)),ltrim(rtrim(X.zip)),coalesce(Y.Phase,'-1')  
            ) S  
      on   ltrim(rtrim(A.AddressLine1)) = S.AddressLine1  
      and  ltrim(rtrim(A.city))         = S.City  
      and  ltrim(rtrim(A.state))        = S.State  
      and  coalesce(Prp.Phase,'-1')     = S.Phase   
      and  A.propertyidseq   <> S.propertyidseq  
      and  Prp.IDSeq         <> S.propertyidseq  
      group by A.companyidseq,A.propertyidseq,A.city,A.state,A.zip  
  
      insert into #LTBL_Errors(ErrorMsg,Name,CanOverrideFlag)  
      select 'Property: ' + Max(Prpty.propertyname)   + ' with a different Account but same address as current property has Active Agreement(s) for:' +char(13)+  
             Max(QPC.ProductName) + '.(Order #' + convert(varchar(50),O.OrderIDSeq) + ').' + char(13) as ErrorMsg,   
            (Case   
                 when Max(OI.StatusCode) = 'EXPD'  
                   then 'Currently Expired but was Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+  
                     '[Suggestion(s):--->] (1) If Back bill then Consider Approving ' + @IPVC_QuoteID + ' with Approval Date that does not overlap with existing active product order(s). ' + char(13)+  
                      '                    (2) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)  
                 when OI.Canceldate is not null   
                   then 'Cancelled and Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.Canceldate,101)+ '.' +char(13)+  
                        '[Suggestion(s):--->] (1) Backdate ' + convert(varchar(50),O.OrderIDSeq)  + ' with Canceldate :' + convert(varchar(50),coalesce(OI.StartDate,@LDT_ApprovalDate),101) + char(13)+  
                        '                     (2) Consider Approving ' + @IPVC_QuoteID       + ' with Approval Date  :' + convert(varchar(50),OI.Canceldate,101)+ char(13)+  
                        '                     (3) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)  
                 when OI.Canceldate is null   
                   then 'Fulfilled and Active from ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+  
                        '[Suggestion(s):--->] (1) Cancel ' + convert(varchar(50),O.OrderIDSeq)  + ' with Canceldate : ' + convert(varchar(50),coalesce(OI.StartDate,@LDT_ApprovalDate),101) + char(13)+  
                        '                     (2) Else Consider Approving ' + @IPVC_QuoteID     + ' with Approval Date : ' + convert(varchar(50),OI.Enddate+1,101)+ char(13)+  
                        '                     (3) Else Approve Quote ' + @IPVC_QuoteID + ' with Delay ILF and Delay ACS/ANC to allow quote approval and then fulfil later with Non-overlapping Startdate. ' + char(13)  
            end)                                                                           as [Name],  
            0                                                                              as CanOverrideFlag  
      from   ORDERS.dbo.[ORDER] O With (nolock)  
      inner join  
            #TempOrginalProperty   Prpty with (nolock)  
      on     O.CompanyIDSeq    = Prpty.companyidseq  
      and    O.PropertyIDSeq   = Prpty.PropertyIDSeq  
      and    O.PropertyIDSeq   is not null    
      and    coalesce(O.Quoteidseq,'') <> @IPVC_QuoteID  
      inner join  
             ORDERS.dbo.[OrderItem] OI with (nolock)  
      on     O.OrderIDSeq      = OI.OrderIDSeq        
      and    OI.Chargetypecode        = 'ACS'   
      and    isdate(OI.Startdate)     = 1  
      and   (@LDT_ApprovalDate >= OI.Startdate  
              and  
             @LDT_ApprovalDate <= coalesce(OI.Canceldate-1,OI.Enddate)  
              and  
             (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)  
            )  
      inner join  
             #LT_QuoteProductCode  QPC with (nolock)  
      on     OI.Productcode = QPC.ProductCode  
      and    QPC.GroupType  = 'SITE'  
      inner join  
             Products.dbo.product   P  with (nolock)  
      on     OI.ProductCode   = P.Code  
      and    OI.Priceversion  = P.Priceversion  
      and    QPC.ProductCode = P.Code  
      inner join  
             Products.dbo.Charge CHGO with (nolock)  
      on     OI.productCode    = CHGO.productCode  
      and    OI.PriceVersion   = CHGO.PriceVersion  
      and    OI.Chargetypecode = CHGO.Chargetypecode  
      and    OI.MeasureCode    = CHGO.MeasureCode  
      and    OI.FrequencyCode  = CHGO.FrequencyCode       
      and    CHGO.QuantityEnabledFlag = 0  
      and  ( (OI.MeasureCode          = 'TRAN')   
               OR   
             (P.Autofulfillflag = 1 and @IPB_DelayACSANCBilling = 0)  
               OR  
             (@IPB_DelayILFBilling = 0)  
            )  
      group by O.CompanyIDSeq,O.PropertyIDSeq,O.OrderIDSeq,OI.StartDate,OI.Canceldate,OI.EndDate  
    end  
  end   
  --------------------------------------------------------------------------------------------  
  if (@IPVC_ValidationType = 'ApproveQuote') and exists (select Top 1 1 from #LTBL_Errors with (nolock))  
  begin  
    GOTO FinalSelectToUI  
    GOTO CleanUp  
    return;  
  end  
  --------------------------------------------------------------------------------------------  
  ---Label Final Select to UI of Errors from #LTBL_Errors  
  --------------------------------------------------------------------------------------------  
  FinalSelectToUI:  
  begin  
    select ErrorMsg,[Name],CanOverrideFlag from #LTBL_Errors with (nolock)  
    order  by Seq ASC;  
  end  
  --------------------------------------------------------------------------------------------  
  ---Label CleanUp to drop all temp tables  
  CleanUp:  
  --------------------------------------------------------------------------------------------  
  if (object_id('tempdb.dbo.#LTBL_Errors') is not null)   
  begin  
    drop table #LTBL_Errors  
  end  
  if (object_id('tempdb.dbo.#TempOrginalProperty') is not null)   
  begin  
    drop table #TempOrginalProperty  
  end   
  if (object_id('tempdb.dbo.#LT_QuoteProductCode') is not null)   
  begin  
    drop table #LT_QuoteProductCode  
  end   
  
END  
GO
