SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [orders].[uspORDERS_ValidateOrderItemFulfillment] (@IPVC_OrderIDSeq       varchar(50),
                                                                 @IPVC_OrderItemIDSeq   varchar(50),
                                                                 @IPVC_OrderGroupIDSeq  varchar(50),
                                                                 @IPVC_FulFillStartDate varchar(20),
                                                                 @IPVC_FulFillEndDate   varchar(20),
                                                                 @IPVC_ValidationType   varchar(100)='FulFillOrder'
                                                                )
AS
BEGIN
  set nocount on;
  --------------------------------------------------------------------------------------------
  ---Declare Local Variables.
  declare @LVC_CompanyID                  varchar(50),
          @LVC_PropertyID                 varchar(50),
          @LVC_CompanyEpicorCustomerCode  varchar(50),
          @LVC_PropertyEpicorCustomerCode varchar(50),
          @LVC_CompanyName                varchar(255),
          @LVC_PropertyName               varchar(255),
          @LVC_CompanyStatus              varchar(20),
          @LVC_PropertyStatus             varchar(20),
          @LVC_OrderGroupType             varchar(20),
          @LI_IsCustomPackage             int,
          @LDT_QuoteApprovedDate          datetime
  --------------------------------------------------------------------------------------------
  ---Declare Local Tables
  create table #LTBL_OrderFulFillmentErrors  (Seq              int identity(1,1)  not null primary key,
                                              ErrorMsg         varchar(2000)      null, 
                                              Name             varchar(2000)      null,
                                              CanOverrideFlag  Bit                not null default(0)
                                             );

  create table #LT_ProductCode                (Seq              int identity(1,1)  not null primary key,
                                               ProductCode      varchar(50),
                                               ProductName      varchar(255)
                                              );

  select @IPVC_OrderItemIDSeq = nullif(@IPVC_OrderItemIDSeq,''),
         @IPVC_FulFillStartDate = convert(varchar(50),convert(datetime,@IPVC_FulFillStartDate),101)
  --------------------------------------------------------------------------------------------
  select Top 1
         @LVC_CompanyID    = CompanyIDSeq,
         @LVC_PropertyID   = PropertyIDSeq,
         @LDT_QuoteApprovedDate = ApprovedDate
  from   ORDERS.dbo.[Order] with (nolock)
  where  OrderIDSeq = @IPVC_OrderIDSeq

  select Top 1
         @LVC_OrderGroupType = OrderGroupType,
         @LI_IsCustomPackage = convert(int,CustomBundleNameEnabledFlag)
  from   ORDERS.dbo.[OrderGroup] with (nolock)
  where  IDSeq               = @IPVC_OrderGroupIDSeq

  select Top 1
         @LVC_CompanyName    = C.Name,
         @LVC_CompanyStatus  = C.StatusTypeCode
  from Customers.dbo.Company  C with (nolock) where C.IdSeq = @LVC_CompanyID;

  select Top 1
         @LVC_PropertyName   = P.Name, 
         @LVC_PropertyStatus = P.StatusTypeCode
  from Customers.dbo.Property P with (nolock) where P.IdSeq = @LVC_PropertyID;

  select Top 1
         @LVC_CompanyEpicorCustomerCode = Nullif(ltrim(rtrim(A.EpicorCustomerCode)),'')
  from   Customers.dbo.Account A with (nolock)
  where  A.CompanyIDSeq    = @LVC_CompanyID
  and    A.AccountTypeCode = 'AHOFF'
  and    A.PropertyIDSeq   is null
  and    A.ActiveFlag      = 1

  select Top 1
         @LVC_PropertyEpicorCustomerCode = Nullif(ltrim(rtrim(A.EpicorCustomerCode)),'')
  from   Customers.dbo.Account A with (nolock)
  where  A.CompanyIDSeq    = @LVC_CompanyID
  and    A.PropertyIDSeq   = @LVC_PropertyID
  and    A.AccountTypeCode = 'APROP'
  and    A.PropertyIDSeq   is not null
  and    A.ActiveFlag      = 1
  ---------------------------------------------------------------------------------------------
  if  (@LVC_CompanyEpicorCustomerCode is null and @LVC_CompanyID is not null)
  begin
    insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    select 'Company: ' + @LVC_CompanyID + '-' + @LVC_CompanyName + ' does not have an valid and ACTIVE EpicorCustomerCode.'+char(13) as ErrorMsg,
           'Activate Company before Fulfilling this Order.'+char(13) as Name,
           0  as CanOverrideFlag
  end

  if  (@LVC_PropertyEpicorCustomerCode is null and @LVC_PropertyID is not null)
  begin
    insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    select 'Property: ' + @LVC_PropertyID + '-' + @LVC_PropertyName + ' does not have an valid and ACTIVE EpicorCustomerCode.'+char(13) as ErrorMsg,
           'Activate Property before Fulfilling this Order.'+char(13) as Name,
           0  as CanOverrideFlag
  end
  ---------------------------------------------------------------------------------------------
  ---Step 1 : Mandatory Validation for Company , Property Status.
  if (@LVC_OrderGroupType = 'PMC' and @IPVC_ValidationType ='FulFillOrder' and @LVC_CompanyStatus <> 'ACTIV')
  begin
    insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    select 'Current Status for Account and Company: ' + @LVC_CompanyID + '-' + @LVC_CompanyName + ' is NOT ACTIVE.'+char(13) as ErrorMsg,
           'Activate Company before Fulfilling this Order.'+char(13) as Name,
           0  as CanOverrideFlag
  end
  else if (@LVC_OrderGroupType <> 'PMC' and @IPVC_ValidationType ='FulFillOrder')
  begin
    insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    select 'Current Status for Account and Company: ' + @LVC_CompanyID + '-' + @LVC_CompanyName + ' is NOT ACTIVE.'+char(13) as ErrorMsg,
           'Activate Company before Fulfilling this Order.'+char(13) as Name,
           0  as CanOverrideFlag
    where  @LVC_CompanyStatus <> 'ACTIV'

    insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    select 'Current Status for Account and Property: ' + @LVC_PropertyID + '-' + @LVC_PropertyName + ' is NOT ACTIVE.' +char(13) as ErrorMsg,
           'Activate Property before Fulfilling this Order.'+char(13) as Name,
           0  as CanOverrideFlag
    where  @LVC_PropertyStatus <> 'ACTIV'
  end
  --------------------------------------------------------------------------------------------- 
  ---Step 2 : Mandatory Validation for GL,TaxwareCodes
  insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
  select distinct 
        'Some Product(s) of Order ' + @IPVC_OrderIDSeq + ' is missing critical associated Revenue and/or Taxware Code : '+  char(13)+ 
         Pr.DisplayName + ': ' + ltrim(rtrim(OI.Chargetypecode)) + '/' + ltrim(rtrim(OI.MeasureCode)) + '/' + 
              REPLACE(REPLACE(OI.FREQUENCYCODE,'SG','INITIAL FEE'),'OT','ONE-TIME') + char(13) as ErrorMsg, 
        'Submit Product request forms to get OMS Product Master Updated.'+char(13) as Name, 
         0         as CanOverrideFlag
  from    Orders.dbo.OrderItem OI   with (nolock)
  inner join
          Products.dbo.Charge C     with (nolock)
  on      OI.ProductCode  = C.ProductCode
  and     OI.PriceVersion = C.PriceVersion
  and     OI.Measurecode  = C.measurecode
  and     OI.Frequencycode= C.Frequencycode 
  and     OI.Chargetypecode=C.Chargetypecode
  and     OI.StatusCode    = 'PEND' 
  and     OI.OrderIDseq      = @IPVC_OrderIDSeq
  and     OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
  and    ((@LI_IsCustomPackage = 1)
            OR
          (OI.IDSeq = @IPVC_OrderItemIDSeq and @LI_IsCustomPackage = 0)
         )       
  and (
        (ltrim(rtrim(C.RevenueAccountCode)) is NULL or ltrim(rtrim(C.RevenueAccountCode)) = '') --> Mandatory   
          OR
        (ltrim(rtrim(C.RevenueTierCode)) is NULL or ltrim(rtrim(C.RevenueTierCode)) = '') --> Mandatory          
          OR
        (ltrim(rtrim(C.TaxwareCode)) is NULL or ltrim(rtrim(C.TaxwareCode)) = '') --> Mandatory                                    
          OR  
        (C.RevenueRecognitionCode in ('SRR','MRR') and (ltrim(rtrim(C.DeferredRevenueAccountCode)) is null or ltrim(rtrim(C.DeferredRevenueAccountCode)) = '')
        ) --> DeferredRevenueAccountCode is Mandatory for RevenueRecognitionCode SRR, MRR
  )
  inner join
         Products.dbo.Product Pr with (nolock)
  on     OI.ProductCode  = Pr.Code
  and    OI.PriceVersion = Pr.PriceVersion
  and    C.ProductCode   = Pr.Code
  and    C.PriceVersion  = Pr.PriceVersion
  where  OI.OrderIDseq      = @IPVC_OrderIDSeq
  and     OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
  and     OI.StatusCode    = 'PEND'
  and    ((@LI_IsCustomPackage = 1)
            OR
          (OI.IDSeq = @IPVC_OrderItemIDSeq and @LI_IsCustomPackage = 0)
         ) 
   ---------------------------------------------------------------------------------------------
   Insert into #LT_ProductCode(ProductCode,ProductName) 
   select OI.ProductCode,Max(PROD.DisplayName) as ProductName
   from   ORDERS.dbo.OrderItem OI   with (nolock)
   Inner Join
          PRODUCTS.dbo.Product PROD with (nolock)
   on     OI.OrderIDSeq      = @IPVC_OrderIDSeq
   and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
   and    ((@LI_IsCustomPackage = 1)
            OR
           (OI.IDSeq = @IPVC_OrderItemIDSeq and @LI_IsCustomPackage = 0)
          ) 
   and    OI.Productcode     = PROD.Code
   and    OI.Priceversion    = PROD.Priceversion
   group by OI.ProductCode  
  -----------------------------------------------------------------------------------------------------------
  --Step 3 : check if the products of current Order has active Agreement(s) in past Orders
  -----------------------------------------------------------------------------------------------------------
  insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
  select (case when @LVC_OrderGroupType = 'PMC' then 'Company: ' + @LVC_CompanyName
               else @LVC_PropertyName
          end)  + ' has Active Overlapping Agreement(s) for same Product(s): ' + char(13) +
          Max(PROD.ProductName) + '.(Order #' + convert(varchar(50),O.OrderIDSeq) + ').' + char(13) as ErrorMsg, 
         char(13) + '(Order #' + convert(varchar(50),O.OrderIDSeq) + ') is ' +
         (Case when Max(OI.StatusCode) = 'EXPD'
                then 'Currently Expired but was Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+
                     '[Suggestion(s):--->] (1) If Back bill Consider Fulfilling ' + @IPVC_OrderIDSeq + ' with Startdate and Enddate that does not overlap with existing active product order(s). ' + char(13)+
                     '                     (2) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
               when OI.Canceldate is not null 
                 then 'Cancelled and Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.Canceldate,101)+ '.' +char(13)+
                       '[Suggestion(s):--->] (1) Backdate ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate :' + convert(varchar(50),coalesce(OI.StartDate,@IPVC_FulFillStartDate),101) + char(13)+
                       '                     (2) Consider Fulfilling ' + @IPVC_OrderIDSeq  + ' with Startdate   :' + convert(varchar(50),OI.Canceldate,101)+ char(13)+
                       '                     (3) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
                when OI.Canceldate is null 
                 then 'Fulfilled and Active from ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+
                      '[Suggestion(s):--->] (1) Cancel ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate :  ' + convert(varchar(50),@IPVC_FulFillStartDate,101) + char(13)+
                      '                     (2) Else Consider Fulfilling ' + @IPVC_OrderIDSeq + ' with Startdate :  ' + convert(varchar(50),OI.Enddate+1,101)+ char(13)+
                      '                     (3) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)                  
          end)                                                                           as [Name],
          0                                                                              as CanOverrideFlag
  from   ORDERS.dbo.[ORDER] O With (nolock) 
  inner join
         ORDERS.dbo.[OrderItem] OI with (nolock)
  on     O.OrderIDSeq      = OI.OrderIDSeq  
  and    O.CompanyIDSeq    = @LVC_CompanyID
  and   ( (@LVC_OrderGroupType = 'PMC' and O.PropertyIDSeq   is NULL)
             OR
          (@LVC_OrderGroupType <> 'PMC' and O.PropertyIDSeq   is NOT NULL and O.PropertyIDSeq   = @LVC_PropertyID)
        )
  and    OI.Chargetypecode        = 'ACS' 
  and    isdate(OI.Startdate)     = 1
  --------------------------------------------
  and  (
         (@IPVC_FulFillStartDate >= OI.Startdate
            and
          @IPVC_FulFillStartDate <= coalesce(OI.Canceldate-1,OI.Enddate)
            and
          (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)
         ) 
          OR
         (@IPVC_FulFillEndDate >= OI.Startdate
            and
          @IPVC_FulFillEndDate <= coalesce(OI.Canceldate-1,OI.Enddate)
            and
          (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)
         ) 
       )
  --------------------------------------------
  and   OI.IDSeq <> @IPVC_OrderItemIDSeq
  and   Not exists (select top 1 1
                    from   [ORDERS].[dbo].[OrderItem] oiILF WITH (NOLOCK)
                    where  oiILF.OrderIDSeq     = oi.OrderIDSeq
                    and    oiILF.ProductCode    = oi.ProductCode
                    and    oi.statuscode        = 'FULF'
                    and    oiILF.chargetypecode = 'ILF'
                    and    oiILF.statuscode     = 'PEND'
                   )
  inner join
         #LT_ProductCode  PROD with (nolock)
  on     OI.Productcode = PROD.ProductCode
  inner join
         Products.dbo.Charge CHGO with (nolock)
  on     OI.productCode    = CHGO.productCode
  and    OI.PriceVersion   = CHGO.PriceVersion
  and    OI.Chargetypecode = CHGO.Chargetypecode
  and    OI.MeasureCode    = CHGO.MeasureCode
  and    OI.FrequencyCode  = CHGO.FrequencyCode     
  and    CHGO.QuantityEnabledFlag = 0
  and    ((CHGO.MeasureCode  = 'TRAN' and CHGO.ReportingTypeCode   = 'ACSF')
             Or
          (CHGO.MeasureCode <> 'TRAN' and CHGO.Chargetypecode      = 'ACS')
         )
  and    Not exists (select Top 1 1
                     from   Products.dbo.Charge CX with (nolock)
                     inner Join
                            Products.dbo.Product PX with (nolock)
                     on     CX.Productcode = PX.Code
                     and    CX.Priceversion= PX.Priceversion
                     and    PX.DisabledFlag        = 0
                     and    PX.PendingApprovalFlag = 0
                     and    CX.DisabledFlag        = 0
                     and    CX.QuantityEnabledFlag = 1
                     and    CX.ProductCode = OI.ProductCode 
                     where  CX.DisabledFlag        = 0
                     and    CX.QuantityEnabledFlag = 1
                     and    CX.MeasureCode in ('UNIT','BED','SITE','PMC')
                     and    CX.ProductCode = OI.ProductCode
                     and    (CX.DisplayType = (case when O.PropertyIDSeq is null then 'PMC' else 'SITE' end)
                                   or
                             CX.DisplayType = 'BOTH'
                            )
                       )   
  group by O.OrderIDSeq,OI.StartDate,OI.Canceldate,OI.EndDate
  -----------------------------------------------------------------------------------------------------------
  --Step 4 : check if the products of current Order has active Agreement(s) in past Orders for Invalid combos
  -----------------------------------------------------------------------------------------------------------
  insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
  select (case when @LVC_OrderGroupType = 'PMC' then 'Company: ' + @LVC_CompanyName
               else 'Property: ' + @LVC_PropertyName
          end)   + 'has Active Overlapping Agreement(s) for Invalid Combo Product(s): ' + char(13) +
         'ie.' + Max(PROD.DisplayName) + '.(Order #' + convert(varchar(50),O.OrderIDSeq) + ').' + ' Invalid to ' + Max(S.CurrentOrderProductName) + char(13) as ErrorMsg, 
         char(13)+ '(Order #' + convert(varchar(50),O.OrderIDSeq) + ') is ' +
         (Case when Max(OI.StatusCode) = 'EXPD'
                then 'Currently Expired but was Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+
                     '[Suggestion(s):--->] (1) If Back bill Consider Fulfilling ' + @IPVC_OrderIDSeq + ' with Startdate and Enddate that does not overlap with existing active product order(s). ' + char(13)+
                     '                     (2) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
               when OI.Canceldate is not null 
                 then 'Cancelled and Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.Canceldate,101)+ '.' +char(13)+
                      '[Suggestion(s):--->] (1) Backdate ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate :' + convert(varchar(50),coalesce(OI.StartDate,@IPVC_FulFillStartDate),101) + char(13)+
                      '                     (2) Else Consider Fulfilling ' + @IPVC_OrderIDSeq  + ' with Startdate :'  + convert(varchar(50),OI.Canceldate,101)+ char(13)+
                      '                     (3) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)    
                when OI.Canceldate is null 
                 then 'Fulfilled and Active from ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+
                      '[Suggestion(s):--->] (1) Cancel ' + convert(varchar(50),O.OrderIDSeq)  + ' with Canceldate :  ' + convert(varchar(50),@IPVC_FulFillStartDate,101) + char(13)+
                      '                     (2) Else Consider Fulfilling ' + @IPVC_OrderIDSeq + ' with Startdate  :  ' + convert(varchar(50),OI.Enddate+1,101)+ char(13)+
                      '                     (3) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
          end)                                                                           as [Name],
          0                                                                              as CanOverrideFlag
  from   ORDERS.dbo.[ORDER] O With (nolock) 
  inner join
         ORDERS.dbo.[OrderItem] OI with (nolock)
  on     O.OrderIDSeq      = OI.OrderIDSeq  
  and    O.CompanyIDSeq    = @LVC_CompanyID
  and   ( (@LVC_OrderGroupType = 'PMC' and O.PropertyIDSeq   is NULL)
             OR
          (@LVC_OrderGroupType <> 'PMC' and O.PropertyIDSeq   is NOT NULL and O.PropertyIDSeq   = @LVC_PropertyID)
        ) 
  and    OI.Chargetypecode        = 'ACS' 
  and    isdate(OI.Startdate)     = 1
  --------------------------------------------
  and  (
         (@IPVC_FulFillStartDate >= OI.Startdate
            and
          @IPVC_FulFillStartDate <= coalesce(OI.Canceldate-1,OI.Enddate)
            and
          (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)
         ) 
          OR
         (@IPVC_FulFillEndDate >= OI.Startdate
            and
          @IPVC_FulFillEndDate <= coalesce(OI.Canceldate-1,OI.Enddate)
            and
          (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)
         ) 
       )
  --------------------------------------------
  and   OI.IDSeq <> @IPVC_OrderItemIDSeq
  inner join
         Products.dbo.Product PROD with (nolock)
  on     OI.ProductCode = PROD.Code
  and    OI.PriceVersion= PROD.PriceVersion 
  inner join
         Products.dbo.Charge CHGO with (nolock)
  on     OI.productCode    = CHGO.productCode
  and    OI.PriceVersion   = CHGO.PriceVersion
  and    OI.Chargetypecode = CHGO.Chargetypecode
  and    OI.MeasureCode    = CHGO.MeasureCode
  and    OI.FrequencyCode  = CHGO.FrequencyCode     
  and    CHGO.QuantityEnabledFlag = 0
  and    ((CHGO.MeasureCode  = 'TRAN' and CHGO.ReportingTypeCode   = 'ACSF')
             Or
          (CHGO.MeasureCode <> 'TRAN' and CHGO.Chargetypecode      = 'ACS')
         )
  and    Not exists (select Top 1 1
                     from   Products.dbo.Charge CX with (nolock)
                     inner Join
                            Products.dbo.Product PX with (nolock)
                     on     CX.Productcode = PX.Code
                     and    CX.Priceversion= PX.Priceversion
                     and    PX.DisabledFlag        = 0
                     and    PX.PendingApprovalFlag = 0
                     and    CX.DisabledFlag        = 0
                     and    CX.QuantityEnabledFlag = 1
                     and    CX.ProductCode = OI.ProductCode 
                     where  CX.DisabledFlag        = 0
                     and    CX.QuantityEnabledFlag = 1
                     and    CX.MeasureCode in ('UNIT','BED','SITE','PMC')
                     and    CX.ProductCode = OI.ProductCode
                     and    (CX.DisplayType = (case when O.PropertyIDSeq is null then 'PMC' else 'SITE' end)
                                   or
                             CX.DisplayType = 'BOTH'
                            )
                    ) 
  inner join (Select coalesce(PIC2.FirstProductCode,PIC1.SecondProductCode) as InvalidProduct,
                     Max(PRDIn.ProductName)                                 as CurrentOrderProductName
              from   #LT_ProductCode                  PRDIn with (nolock)
              inner join
                     Products.dbo.ProductInvalidCombo PIC1 with (nolock)
              on     (PRDIn.ProductCode = PIC1.FirstProductCode)
              left outer join
                     Products.dbo.ProductInvalidCombo PIC2 with (nolock)
              on    (PRDIn.ProductCode = PIC2.SecondProductCode)                
              group by coalesce(PIC2.FirstProductCode,PIC1.SecondProductCode)
             ) S
  on  OI.ProductCode = S.InvalidProduct
  group by O.OrderIDSeq,OI.StartDate,OI.Canceldate,OI.EndDate  
  -------------------------------------------------------------------------------------------------------
  If (@LVC_OrderGroupType <> 'PMC') ----> Only if it is a SITE Bundle.
  begin
    ---Step 5: Get Properties that have exact city,state,zip,phase belonging any other PMC
    create table #TempOrginalPMCProperty(seq           int identity(1,1) not null primary Key,
                                         companyidseq  varchar(50),
                                         propertyidseq varchar(50),
                                         propertyname  varchar(255),
                                         city          varchar(50),
                                         state         varchar(50),
                                         zip           varchar(50)
                                        );
    insert into #TempOrginalPMCProperty(companyidseq,propertyidseq,propertyname,city,state,zip)
    select A.companyidseq,A.propertyidseq,Max(Prp.Name) as PropertyName,A.city,A.state,A.zip
    from   Customers.dbo.address A with (nolock)
    inner Join
           Customers.dbo.Property Prp with (nolock)
    on     Prp.IDseq         =  A.propertyidseq
    and    Prp.IDSeq        <>  @LVC_PropertyID
    and    A.addresstypecode =  'PRO'
    and    A.companyidseq    <> @LVC_CompanyID
    and    A.propertyidseq   <> @LVC_PropertyID
    and    A.propertyidseq   is not null
    inner join
           (Select Y.IDseq as propertyidseq,ltrim(rtrim(X.AddressLine1)) as AddressLine1,ltrim(rtrim(X.city)) as city,ltrim(rtrim(X.state)) as state,ltrim(rtrim(X.zip)) as Zip,
                   coalesce(Y.Phase,'-1') as Phase
            from   Customers.dbo.address  X with (nolock)
            inner join
                   Customers.dbo.Property Y with (nolock)
            on     Y.IDseq             =  X.propertyidseq
            and    X.addresstypecode = 'PRO'                   
            and    X.propertyidseq is not null
            and    X.companyidseq    = @LVC_CompanyID
            and    X.propertyidseq   = @LVC_PropertyID
            group by Y.IDseq ,ltrim(rtrim(X.AddressLine1)),ltrim(rtrim(X.city)),ltrim(rtrim(X.state)),ltrim(rtrim(X.zip)),coalesce(Y.Phase,'-1')
           ) S
    on   ltrim(rtrim(A.AddressLine1)) = S.AddressLine1
    and  ltrim(rtrim(A.city))         = S.City
    and  ltrim(rtrim(A.state))        = S.State
    and  coalesce(Prp.Phase,'-1')     = S.Phase 
    and  A.propertyidseq   <> S.propertyidseq
    and  Prp.IDSeq         <> S.propertyidseq
    group by A.companyidseq,A.propertyidseq,A.city,A.state,A.zip


    insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    select 'Property: ' + Max(P.propertyname)+ ' with a different Account but same address as current property has Active Overlapping Agreement(s) for same Product(s):' +
           Max(PROD.ProductName) + '.(Order #' + convert(varchar(50),O.OrderIDSeq) + ').' + char(13) as ErrorMsg, 
           char(13)+ '(Order #' + convert(varchar(50),O.OrderIDSeq) + ') is ' + 
           (Case
               when Max(OI.StatusCode) = 'EXPD'
                then 'Currently Expired but was Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+
                     '[Suggestion(s):--->] (1) If Back bill Consider Fulfilling ' + @IPVC_OrderIDSeq + ' with Startdate and Enddate that does not overlap with existing active product order(s). ' + char(13)+
                     '                     (2) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
               when OI.Canceldate is not null 
                 then 'Cancelled and Active from : ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.Canceldate,101)+ '.' +char(13)+
                      '[Suggestion(s):--->] (1) Backdate ' + convert(varchar(50),O.OrderIDSeq) + ' with Canceldate :' + convert(varchar(50),coalesce(OI.StartDate,@IPVC_FulFillStartDate),101) + char(13)+
                      '                     (2) Else Consider Fulfilling ' + @IPVC_OrderIDSeq  + ' with Startdate  :' + convert(varchar(50),OI.Canceldate,101)+ char(13)+
                      '                     (3) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
                when OI.Canceldate is null 
                 then 'Fulfilled and Active from ' + convert(varchar(50),OI.StartDate,101) + '-' + convert(varchar(50),OI.EndDate,101)+ '.' +char(13)+
                      '[Suggestion(s):--->] (1) Cancel ' + convert(varchar(50),O.OrderIDSeq)  + ' with Canceldate : ' + convert(varchar(50),@IPVC_FulFillStartDate,101) + char(13)+
                      '                     (2) Else Consider Fulfilling ' + @IPVC_OrderIDSeq + ' with Startdate :  ' + convert(varchar(50),OI.Enddate+1,101)+ char(13)+
                      '                     (3) Abort Fulfilling ' + @IPVC_OrderIDSeq + '. Explore other options with Client Services Manager.' + char(13)
          end)                                                                           as [Name],
           0                                                                             as CanOverrideFlag
    from   ORDERS.dbo.[Order]        O  with (nolock)
    inner join
           #TempOrginalPMCProperty   P with (nolock)
    on     O.CompanyIDSeq    = P.companyidseq
    and    O.PropertyIDSeq   = P.PropertyIDSeq
    and    O.PropertyIDSeq   is not null  
    and    O.OrderIDSeq      <> @IPVC_OrderIDSeq
    inner join
           ORDERS.dbo.[OrderItem] OI with (nolock)
    on     O.OrderIDSeq       =  OI.OrderIDSeq
    and    O.OrderIDSeq       <> @IPVC_OrderIDSeq  
    and    OI.OrderIDSeq      <> @IPVC_OrderIDSeq
    and    OI.Chargetypecode      = 'ACS' 
    and    isdate(OI.Startdate)   = 1
    --------------------------------------------
    and  (
           ( @IPVC_FulFillStartDate >= OI.Startdate
             and
             @IPVC_FulFillStartDate <= coalesce(OI.Canceldate-1,OI.Enddate)
             and
            (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)
           ) 
            OR
           ( @IPVC_FulFillEndDate >= OI.Startdate
             and
             @IPVC_FulFillEndDate <= coalesce(OI.Canceldate-1,OI.Enddate)
             and
            (OI.Startdate<>OI.Canceldate OR OI.Canceldate is null)
           ) 
       )
    --------------------------------------------
    inner join
          #LT_ProductCode  PROD with (nolock)
    on     OI.Productcode = PROD.ProductCode
    inner join
          Products.dbo.Charge CHGO with (nolock)
    on     OI.productCode    = CHGO.productCode
    and    OI.PriceVersion   = CHGO.PriceVersion
    and    OI.Chargetypecode = CHGO.Chargetypecode
    and    OI.MeasureCode    = CHGO.MeasureCode
    and    OI.FrequencyCode  = CHGO.FrequencyCode     
    and    CHGO.QuantityEnabledFlag = 0
    and    ((CHGO.MeasureCode  = 'TRAN' and CHGO.ReportingTypeCode   = 'ACSF')
             Or
            (CHGO.MeasureCode <> 'TRAN' and CHGO.Chargetypecode      = 'ACS')
           )
    and    Not exists (select Top 1 1
                       from   Products.dbo.Charge CX with (nolock)
                       inner Join
                              Products.dbo.Product PX with (nolock)
                       on     CX.Productcode = PX.Code
                       and    CX.Priceversion= PX.Priceversion
                       and    PX.DisabledFlag        = 0
                       and    PX.PendingApprovalFlag = 0
                       and    CX.DisabledFlag        = 0
                       and    CX.QuantityEnabledFlag = 1
                       and    CX.ProductCode = OI.ProductCode 
                       where  CX.DisabledFlag        = 0
                       and    CX.QuantityEnabledFlag = 1
                       and    CX.MeasureCode in ('UNIT','BED','SITE','PMC')
                       and    CX.ProductCode = OI.ProductCode
                       and    (CX.DisplayType = (case when O.PropertyIDSeq is null then 'PMC' else 'SITE' end)
                                    or
                               CX.DisplayType = 'BOTH'
                              )
                       )     
    group by P.PropertyIDSeq,O.OrderIDSeq,OI.StartDate,OI.Canceldate,OI.EndDate
  end
  ----------------------------------------------------------------------------------------------------------------------------     
  ---Final Select for all Validation Errors
  select Distinct ErrorMsg,[Name],CanOverrideFlag from #LTBL_OrderFulFillmentErrors with (nolock)
  ----------------------------------------------------------
  if (object_id('tempdb.dbo.#LTBL_OrderFulFillmentErrors') is not null) 
  begin
    drop table #LTBL_OrderFulFillmentErrors
  end
  if (object_id('tempdb.dbo.#TempOrginalPMCProperty') is not null) 
  begin
    drop table #TempOrginalPMCProperty
  end 
  if (object_id('tempdb.dbo.#LT_ProductCode') is not null) 
  begin
    drop table #LT_ProductCode
  end
  ---------------------------------------------------------
END
GO
