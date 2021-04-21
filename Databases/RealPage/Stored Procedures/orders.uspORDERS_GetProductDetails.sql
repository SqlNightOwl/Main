SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_GetProductDetails
-- Description     : This procedure gets Product Details pertaining to passed Product Code
-- Input Parameters: 1. @IPVC_OrderIDSeq        as varchar(10)
--                   2. @IPVC_OrderGroupIDSeq   as varchar(10)
--                   
-- OUTPUT          : The recordset that contains the Product name, the product status,
--                   the Status, the start date and the end date.
--
-- Code Example    : Exec ORDERS.DBO.uspORDERS_GetProductDetails Input Parameters
-- 
-- 
-- Revision History:
-- Author          : STA
-- 12/01/2006      : Stored Procedure Created.
-- 07/02/2008      : Defect #5259
-- 06/08/2010      : Shashi Bhushan - Defect #7754 -Modified to get the QuoteType,LastBillingPeriodFromDate and  LastBillingPeriodToDate values
-- 08/03/2010      : Anand Chakravarthy - Defect #8169 - Modified to get the renewal status
------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetProductDetails](@IPVC_OrderID           varchar(50),       ---> This is the Orderidseq of the Current Orderitem. UI knows this already  
                                                     @IPVC_OrderItemIDSeq    varchar(50)=NULL,  ---> This is the OrderItemIDSeq of the Current Orderitem. UI knows this already 
                                                                                                ---     This will be NULL for CustomBundles ie PreconfiguredBundleFlag = 1
                                                     @IPVC_OrderGroupIDSeq   varchar(50),       ---> This is the OrderGroupIDSeq of the Current Orderitem. UI knows this already
                                                     @IPVC_ChargeTypeCode    varchar(5),        ---> This is the ChargeTypeCode of the Current Orderitem. UI knows this already
                                                     @IPB_IsCustomPackage    bit,               ---> This is the custombundleFlag ie IsCustomPackage of the Current Orderitem. UI knows this already
                                                                                                ---     0 means it is Alacarte and not part of Custom Bundle. 1 means it is part of Custom Bundle. This is PreconfiguredBundleFlag
                                                     @IPVC_RenewalCount      bigint     =0      ---> This is renewal count number of the current Orderitem. UI knows this already.  
                                                    )

as
BEGIN
  set nocount on;
  ------------------------------------------------------------------------------------------------------ 
  ---Declaring Local Variables
  ------------------------------------------------------------------------------------------------------ 
  declare @LVC_CompanyIDSeq              varchar(50),
          @LVC_AccountIDSeq              varchar(50),
          @LVC_PropertyIDSeq             varchar(50),
          @LVC_OrderApprovalDate         varchar(50),
          @LVC_CompanyName               varchar(255),
          @LVC_PropertyName              varchar(255)
  declare @LI_OrderSynchStartMonth       int
  declare @LVC_QuoteIDSeq                varchar(50),
          @LVC_SiteMasterID              varchar(30)
  declare @LVC_QuoteTypeCode             varchar(10),
          @LVC_QuoteTypeName             varchar(50),          
          @LVC_BundleName                varchar(255),
          @LVC_BundleDescription         varchar(255)
  declare @LVC_ProductCustomerSinceDate  varchar(20)  
  declare @LI_HigherRenewalExistsFlag    bit,
          @LI_PreviousRenewalStatusFlag  bit

  select @LI_HigherRenewalExistsFlag=0,@LI_PreviousRenewalStatusFlag=0
  ------------------------------------------------------------------------------------------------------
  select Top 1 @LVC_AccountIDSeq             = O.AccountIDSeq,
               @LVC_CompanyIDSeq             = O.CompanyIDSeq, 
               @LVC_PropertyIDSeq            = NullIf(O.PropertyIDSeq,''),
               @LVC_OrderApprovalDate        = convert(varchar(50),O.ApprovedDate,101),
               @LI_OrderSynchStartMonth      = C.OrderSynchStartMonth,
               @LVC_SiteMasterID             = coalesce(P.SiteMasterID,C.SiteMasterID,''),
               @LVC_QuoteIDSeq               = coalesce(O.QuoteIDSeq,''),
               @LVC_QuoteTypeCode            = coalesce(QT.Code,'NEWQ'),
               @LVC_QuoteTypeName            = coalesce(QT.Name,'New'),
               @LVC_BundleName               = OG.[Name],
               @LVC_BundleDescription        = OG.[Description],
               @LVC_CompanyName              = C.Name,
               @LVC_PropertyName             = P.Name
  from  ORDERS.dbo.[Order] O with (nolock)
  inner join
         ORDERS.dbo.[OrderGroup] OG with (nolock)
  on     O.OrderIDSeq       = OG.OrderIDSeq
  and    O.Orderidseq       = @IPVC_OrderID
  and    OG.Orderidseq      = @IPVC_OrderID
  and    OG.IDSeq           = @IPVC_OrderGroupIDSeq
  inner join
        CUSTOMERS.dbo.Company C with (nolock)
  on    O.CompanyIDSeq = C.IDSeq
  and   O.OrderIDSeq   = @IPVC_OrderID
  left outer Join
         CUSTOMERS.dbo.Property   P with (nolock)
  on     O.PropertyIDSeq = P.IDSeq
  and    O.CompanyIDSeq  = P.PMCIDSeq
  and    C.IDSeq         = P.PMCIDSeq
  left outer Join
         QUOTES.dbo.Quote        Q  with (nolock)
  on     O.QuoteIDSeq = Q.QuoteIDSeq
  left outer Join
         Quotes.dbo.QuoteType    QT with (nolock)
  on     Q.QuoteTypeCode = QT.Code  
  where  O.OrderIDSeq   = @IPVC_OrderID;
  ---------------------------------------------------------------------------------------
  --Get @LVC_ProductCustomerSinceDate
  ---------------------------------------------------------------------------------------
  ;With CTE
   as  (select Convert(varchar(50),Min(OI.StartDate),101) as ProductCustomerSinceDate
        from   Orders.dbo.[Order]   O  with (nolock)
        inner Join
               Orders.dbo.OrderItem OI with (nolock)
        on     O.Orderidseq   = OI.OrderIdSeq 
        and    O.AccountIDSeq = @LVC_AccountIDSeq 
        and    isdate(OI.StartDate) = 1
        and    @IPB_IsCustomPackage = 0
        inner join
              (select XII.ProductCode
               from   ORDERS.dbo.[Orderitem] XII with (nolock)
               where  XII.Orderidseq      = @IPVC_OrderID
               and    XII.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
               and    XII.IDSeq           = @IPVC_OrderItemIDSeq
               and    @IPB_IsCustomPackage = 0
               group by XII.ProductCode
              ) S
        on OI.ProductCode = S.ProductCode
       )
  select @LVC_ProductCustomerSinceDate = (case when (@IPB_IsCustomPackage=1) then '-'
                                               when (isdate(CTE.ProductCustomerSinceDate)=0) then '-'
                                               else CTE.ProductCustomerSinceDate
                                          end)
  from CTE;
  ---------------------------------------------------------------------------------------
  --Get @LI_HigherRenewalExistsFlag and @LI_PreviousRenewalStatusFlag
  ---------------------------------------------------------------------------------------
  if exists (select top 1 1 
             from   ORDERS.dbo.[Orderitem] OI with (nolock)
             where  OI.Orderidseq       = @IPVC_OrderID
             and    OI.OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
             and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
             and    OI.RenewalCount    > @IPVC_RenewalCount
             and    OI.ChargeTypeCode   = 'ACS'
             and    OI.ReportingTypeCode= 'ACSF'
             and    OI.statuscode       in ('FULF','PENR','PEND')
             and    ((@IPB_IsCustomPackage = 1)
                       OR
                     (OI.RenewedFromOrderitemIDSeq = @IPVC_OrderItemIDSeq and @IPB_IsCustomPackage = 0)            
                    )             
           )
  begin
    select @LI_HigherRenewalExistsFlag = 1;
  end
  --------------------
  if exists (select top 1 1 
             from   ORDERS.dbo.[Orderitem] OI with (nolock)
             where  OI.Orderidseq       = @IPVC_OrderID
             and    OI.OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
             and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
             and    OI.RenewalCount    < @IPVC_RenewalCount
             and    OI.ChargeTypeCode   = 'ACS'
             and    OI.ReportingTypeCode= 'ACSF'
             and    OI.statuscode       in ('FULF','PENR','PEND')
             and    ((@IPB_IsCustomPackage = 1)
                       OR
                     (OI.RenewedFromOrderitemIDSeq = @IPVC_OrderItemIDSeq and @IPB_IsCustomPackage = 0)            
                    )             
           )
  begin
    select @LI_PreviousRenewalStatusFlag = 1;
  end
  ---------------------------------------------------------------------------------------
  ;with CTE as
  (select top 1 OI.OrderIDSeq                                                    as OrderIDSeq,
                OI.OrderGroupIDSeq                                               as OrderGroupIDSeq,
                OI.BillToAddressTypeCode                                         as BillToAddressTypeCode,
                OI.BillToDeliveryOptionCode                                      as BillToDeliveryOptionCode,
                PROD.PlatformCode                                                as PlatformCode,
                OI.FamilyCode                                                    as FamilyCode,
                (case when @IPB_IsCustomPackage = 1 then 'Multiple Product(s)'
                       else OI.ProductCode
                 end)                                                            as ProductCode,
                (case when @IPB_IsCustomPackage = 1 then @LVC_BundleName
                       else PROD.DisplayName
                 end)                                                            as ProductName,
                (case when @IPB_IsCustomPackage = 1 then @LVC_BundleDescription
                       else PROD.DisplayName
                end)                                                             as [Description],
                OI.PriceVersion                                                  as PriceVersion,
                OI.StatusCode                                                    as Status,
                OI.FrequencyCode                                                 as FrequencyCode,
                OI.MeasureCode                                                   as MeasureCode, 
                CHG.ReportingTypeCode                                            as ReportingTypeCode,               
                convert(varchar(50),OI.StartDate,101)                            as StartDate,
                convert(varchar(50),coalesce(OI.CancelDate,OI.EndDate),101)      as EndDate,
                convert(varchar(50),OI.ActivationStartDate,101)                  as ActivationStartDate,
                convert(varchar(50),OI.ActivationEndDate,101)                    as ActivationEndDate,
                convert(varchar(50),OI.CancelDate,101)                           as CancelDate, 
                convert(varchar(20),OI.ILFStartDate,101)                         as ILFStartDate, -- ILFStartDate will be filled in as part of the ACS record.
                convert(varchar(50),OI.ILFEndDate,101)                           as ILFEndDate,
                convert(varchar(50),OI.LastBillingPeriodFromDate,101)            as LastBillingPeriodFromDate,
                convert(varchar(50),OI.LastBillingPeriodToDate,101)              as LastBillingPeriodToDate,
                OI.Quantity                                                      as Quantity,
                Convert(numeric(10,2),OI.ShippingAndHandlingAmount)              as SHAmount,         
                OI.RenewalTypeCode                                               as RenewalTypeCode,
                OI.MasterOrderItemIDSeq                                          as MasterOrderItemIDSeq,
                OI.PrintedOnInvoiceFlag                                          as PrintFlag,
                OI.DoNotInvoiceFlag                                              as CheckInvoice,
                OI.MinUnits                                                      as MinUnits,
                OI.MaxUnits                                                      as MaxUnits,
                OI.DollarMinimum                                                 as DollarMinimum,
                OI.DollarMaximum                                                 as DollarMaximum,
                OI.RenewalCount                                                  as RenewalCount,
                OI.PublicationQuarter                                            as PublicationQuarter,
                OI.PublicationYear                                               as PublicationYear,
                PROD.MPFPublicationFlag                                          as MPFPublicationFlag,
                CHG.MPFPublicationName                                           as MPFPublicationName,
                coalesce(OI.CancelReasonCode,'')                                 as CancelReasonCode,
                OI.CancelNotes                                                   as CancelNotes,
                CHG.AllowLongerContractFlag                                      as AllowLongerContractFlag,
                (UM.FirstName + ' ' + UM.LastName)                               as LastModifiedbyUser,
                OI.ModifiedDate                                                  as LastModifiedDate,
                -------------------------
               (UF.FirstName + ' ' + UF.LastName)                                as FulfillbyUser,
                OI.FulfilledDate                                                 as FulfillActivityDate,
                -------------------------
               (UC.FirstName + ' ' + UC.LastName)                                as CancelbyUser,
                OI.CancelActivityDate                                            as CancelActivityDate,
                -------------------------
               coalesce(R.ReasonName,'')                                         as RollBackReason, 
               (URB.FirstName + ' ' + URB.LastName)                              as RollbackbyUser,
                OI.RollbackDate                                                  as RollbackActivityDate
   from  ORDERS.dbo.[Orderitem] OI   with (nolock)
   inner join
         PRODUCTS.dbo.Product   PROD with (nolock) 
   on    OI.ProductCode     = PROD.code 
   and   OI.PriceVersion    = PROD.PriceVersion
   and    OI.Orderidseq      = @IPVC_OrderID
   and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
   and    ((@IPB_IsCustomPackage = 1)
             OR
           (OI.IDSeq = @IPVC_OrderItemIDSeq and @IPB_IsCustomPackage = 0)
          )   
   and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
   and    OI.RenewalCount    = @IPVC_RenewalCount
   inner join
         PRODUCTS.dbo.Charge    CHG with (nolock)
   on    PROD.Code          = CHG.ProductCode
   and   PROD.PriceVersion  = CHG.PriceVersion
   and   OI.ProductCode     = CHG.ProductCode
   and   OI.PriceVersion    = CHG.PriceVersion
   and   OI.ChargeTypecode  = CHG.ChargeTypecode
   and   OI.Measurecode     = CHG.Measurecode
   and   OI.FrequencyCode   = CHG.FrequencyCode
   left outer join
         SECURITY.dbo.[User] UM with (nolock)
   on    OI.ModifiedByUserIDSeq = UM.IDSEQ
   left outer join
         SECURITY.dbo.[User] UF with (nolock)
   on    OI.FulfilledByIDSeq = UF.IDSEQ
   left outer join
         SECURITY.dbo.[User] UC with (nolock)
   on    OI.CancelByIDSeq = UC.IDSEQ
   left outer join
         SECURITY.dbo.[User] URB with (nolock)
   on    OI.RollbackByIDSeq = URB.IDSEQ
   left outer Join
         Orders.dbo.Reason R with (nolock)
  on     OI.RollbackReasonCode = R.Code
  )
  select @LVC_AccountIDSeq                                                as AccountIDSeq,
         @LVC_CompanyIDSeq                                                as CompanyIDSeq,
         @LVC_PropertyIDSeq                                               as PropertyIDSeq,
         @LVC_SiteMasterID                                                as SiteMasterID,
         @LVC_QuoteIDSeq                                                  as QuoteIDSeq,
         @LVC_QuoteTypeCode                                               as QuoteTypeCode,
         @LVC_QuoteTypeName                                               as QuoteTypeName,
         @LVC_OrderApprovalDate                                           as OrderApprovalDate,
         @LVC_OrderApprovalDate                                           as QuoteApprovedDate, 
         @LVC_ProductCustomerSinceDate                                    as ProductCustomerSinceDate,
         @LI_OrderSynchStartMonth                                         as OrderSynchStartMonth,
         CTE.OrderIDSeq                                                   as OrderIDSeq,
         CTE.OrderGroupIDSeq                                              as OrderGroupIDSeq,
         CTE.PlatformCode                                                 as PlatformCode,
         CTE.FamilyCode                                                   as FamilyCode,
         CTE.ProductCode                                                  as ProductCode,
         CTE.ProductName                                                  as ProductName,
         CTE.[Description]                                                as [Description],
         CTE.PriceVersion                                                 as PriceVersion,
         CTE.Status                                                       as Status,
         CTE.FrequencyCode                                                as FrequencyCode,
         CTE.MeasureCode                                                  as MeasureCode,
         CTE.ReportingTypeCode                                            as ReportingTypeCode,
         CTE.StartDate                                                    as StartDate,
         CTE.EndDate                                                      as EndDate,
         CTE.ActivationStartDate                                          as ActivationStartDate,
         CTE.ActivationEndDate                                            as ActivationEndDate,
         CTE.CancelDate                                                   as CancelDate,
         CTE.ILFStartDate                                                 as ILFStartDate,
         CTE.ILFEndDate                                                   as ILFEndDate,
         CTE.LastBillingPeriodFromDate                                    as LastBillingPeriodFromDate,
         CTE.LastBillingPeriodToDate                                      as LastBillingPeriodToDate,
         CTE.Quantity                                                     as Quantity, 
         CTE.SHAmount                                                     as SHAmount,
         CTE.RenewalTypeCode                                              as RenewalTypeCode,
         CTE.MasterOrderItemIDSeq                                         as MasterOrderItemIDSeq,
         @LI_HigherRenewalExistsFlag                                      as RenewalExistsFlag,
         @LI_PreviousRenewalStatusFlag                                    as RenewedOrderStatus,
         CTE.PrintFlag                                                    as PrintFlag,
         CTE.CheckInvoice                                                 as CheckInvoice,
         CTE.MinUnits                                                     as MinUnits,
         CTE.MaxUnits                                                     as MinUnits,
         CTE.DollarMinimum                                                as DollarMinimum,
         CTE.DollarMaximum                                                as DollarMaximum,
         CTE.RenewalCount                                                 as RenewalCount,
         CTE.PublicationQuarter                                           as PublicationQuarter,
         CTE.PublicationYear                                              as PublicationYear,
         CTE.MPFPublicationFlag                                           as MPFPublicationFlag,
         CTE.MPFPublicationName                                           as MPFPublicationName,
         CTE.CancelReasonCode                                             as CancelReasonCode,
         CTE.CancelNotes                                                  as CancelNotes,
         CTE.AllowLongerContractFlag                                      as AllowLongerContractFlag,
         CTE.LastModifiedbyUser                                           as LastModifiedbyUser,
         CTE.LastModifiedDate                                             as LastModifiedDate,
         CTE.FulfillbyUser                                                as FulfillbyUser,
         CTE.FulfillActivityDate                                          as FulfillActivityDate,
         CTE.CancelbyUser                                                 as CancelbyUser,
         CTE.CancelActivityDate                                           as CancelActivityDate,
         CTE.RollBackReason                                               as RollBackReason,
         CTE.RollbackbyUser                                               as RollbackbyUser,
         CTE.RollbackActivityDate                                         as RollbackActivityDate,
         -----------------------------------------------------------------------------------------
         CTE.BillToAddressTypeCode                                        as BillToAddressTypeCode,
         CTE.BillToDeliveryOptionCode                                     as BillToDeliveryOptionCode,
         coalesce(@LVC_PropertyName,@LVC_CompanyName)                     as AccountName,
         Addr.AttentionName                                               as ContactName,
         Addr.AddressLine1                                                as Addressline1,
         coalesce(Addr.AddressLine2,'')                                   as AddressLine2,
         Addr.City                                                        as City,
         Addr.State                                                       as State,
         Addr.Zip                                                         as Zip,
         Addr.Countrycode                                                 as Country,
         Addr.Country				                          as CountryName,
         coalesce(Addr.Email,'')                                          as Email
         -----------------------------------------------------------------------------------------
  from     CTE
  inner join
           Customers.dbo.Address Addr with (nolock)
  on       Addr.CompanyIDSeq = @LVC_CompanyIDSeq
  and      CTE.BillToAddressTypeCode     = Addr.Addresstypecode
  and   (
          (CTE.BillToAddressTypeCode    = Addr.Addresstypecode and 
           CTE.BillToAddressTypeCode   like 'PB%'              and 
           coalesce(Addr.PropertyIDSeq,'ABCDEF') = coalesce(@LVC_PropertyIDSeq,'ABCDEF')  
         )
          OR
         (CTE.BillToAddressTypeCode    = Addr.Addresstypecode and
          CTE.BillToAddressTypeCode   not like 'PB%' 
         )
       );
  ---------------------------------------------------------------------------------------
END
GO
