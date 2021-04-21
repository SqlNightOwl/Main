SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_GetOrderItemsForAutoFulfilment
-- Description     : This procedure gets information on OrderItems For Auto Fulfilment process
--                   Step 1: UI Will call this proc first for @IPVC_ChargeTypeCode = 'ACS', which also autofulfill corresponding pending ILF.
--                   Step 2: UI will then call this proc again for @IPVC_ChargeTypeCode = 'ILF' to get only Not delayed PEND ILF.
-- Note            : Quote Approval sets DelayILFBillingFlag and DelayACSBillingFlag,ApprovalDate and Status as APR on the Quote header
--                   after calling its final validation proc uspQUOTES_ValidateQuote.SQL (if no critical error results set returned)
--                   then it calls uspQUOTES_ExplodeQuoteToOrders.SQL which creates all NON TRAN Orderitems in a PENDING State.
--                   This ORDERS.DBO.uspORDERS_GetOrderItemsForAutoFulfilment Proc is always called which returns a resultset of orderitems to be fulfilled
--                   or an Empty Resultset (based on input criteria). If empty resultset, UI stops processing.
--                   If Non Empty resultset, then UI calls Orderfulfilment Validation component (for validating Sitemaster and also 
--                                           other critiera uspORDERS_ValidateOrderItemFulfillment.SQL)
--                                           then it runs through UI Enddate calculator component to arrive at Enddate and then calls uspORDERS_UpdateProductDetails.SQL
--                                           for Fulfilling the Orderitem and also calling the Online Invoiceing component, Taxware.

/*
DelayILFBillingFlag	DelayACSBillingFlag	Scenario Explanation	                                                                          Auto Fullfill Process
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1	                      1	                 Possible  (When Delay ILF is checked, UI will auto check Delay ANC,ACS)	                Empty Resultset; No Orderitems will be fulfilled.
1	                      0	                 Not possible (When Delay ILF is checked, UI WILL NOT allow Delay ANC,ACS to be Unchecked)	Will validate and return a Error which UI will trap.  UI will prevent this scenario at Quote approval.    
0	                      0	                 Possible  (UI will allow Both ILF and ACS/ANC  to be NOT Delayed ie Auto Fulfilled.)	        Valid Resultsets of ILF and ACS, ANC will be returned for  Validation and Fulfillment.
0	                      1	                 Possible  (UI will allow ILF to be fulfilled and Delay only ACS/ANC)	                        Valid Resultsets of Only ILF  will be returned for  Validation and Fulfillment.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
-- Input Parameters: @IPVC_QuoteIDSeq            varchar(50)
--                   @IPI_DelayILFBillingFlag    int
--                   @IPI_DelayILFBillingFlag    int
--                   @IPVC_ChargeTypeCode        varchar(10)
--                   
--
-- Code Example    : Exec ORDERS.DBO.uspORDERS_GetOrderItemsForAutoFulfilment @IPVC_QuoteIDSeq = 'Q1002000233',
--                                                                            @IPVC_ChargeTypeCode     = 'ACS'
-- 
-- 
-- Revision History:
-- Author          : Shashi Bhushan
-- 08/12/2010      : Defect #8030 Stored Procedure Created.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrderItemsForAutoFulfilment](@IPVC_QuoteIDSeq         varchar(50),          ---> QuoteID  that is getting approved.
                                                                  @IPVC_ChargeTypeCode     varchar(10) = 'ACS'   ---> UI will call with 'ACS' as first pass; then UI will call with 'ILF' as second pass.
                                                                 )
as
BEGIN
  set nocount on;  
  --------------------------------------------------------------------------------------
  --Step 1: For all other Scenarios Return either an empty resulset or valid Pending Orderitems Resultset.
  --        The resultset columns will correspond to Input parameters for Fulfilment proc uspORDERS_UpdateProductDetails
  --        Other extra columns are returned for UI to run through EndDate Calculator Component based on StartDate as Quote Approval Date (UI already has this)
  --        and then run through validation component and when no critical errors then pass it 
  --        as input parameters to uspORDERS_UpdateProductDetails
  --------------------------------------------------------------------------------------
  set @IPVC_ChargeTypeCode = nullif(@IPVC_ChargeTypeCode,'');


  Select  OI.OrderIDSeq                                   as  OrderIDSeq,           ----> This coresponds to @IPVC_Orderidseq
          OI.IDSeq                                        as  OrderItemIDSeq,       ----> This coresponds to @IPVC_OrderItemIDSeq       
          OI.OrderGroupIDSeq                              as  OrderGroupIDSeq,      ----> This coresponds to @IPVC_OrderGroupIDSeq
          OI.ChargeTypeCode                               as  ChargeTypeCode,       ----> This coresponds to @IPVC_ChargeTypeCode
          CONVERT(VARCHAR(20),
                     coalesce(OG.AutoFulfillStartDate,O.ApprovedDate),101) 
                                                          as  FulFillStartDate,     ----> This is the Fulfillment Start date. This coresponds to @IPVC_StartDate
          ''                                              as  FulFillEndDate,       ----> UI will run FulFillStartDate ie Quote Approval Date as start date 
                                                                                     ----    through FULFILMENT ENDDATE CALCULATOR COMPONENT
                                                                                     ----    and replace this NULL with that enddate. This coresponds to @IPVC_EndDate          
          OI.StatusCode                                   as  StatusCode,           ----> UI will replace this as 'FULF'. This corresponds to @IPVC_Status
          OG.CustomBundleNameEnabledFlag                  as  IsCustomPackage,      ---->  This corresponds to @IPB_IsCustomPackage
          OI.RenewalTypeCode                              as  RenewalTypeCode,      ---->  This correponds to @IPVC_Renewal          
          0.00                                            as  SHCharge,             ---->  This corresponds to @IPVC_SHCharge
          OI.BillToAddressTypeCode                        as  BillToAddressTypeCode,---->  This corresponds to @IPVC_BillToAddressCode
          OI.RenewalCount                                 as  RenewalCount,         ---->  This corresponds to @IPI_RenewalCount
          ---------------------------------------------------
          --Extra attributes for UI
          OI.MeasureCode                                  as MeasureCode,
          OI.FrequencyCode                                as FrequencyCode,
          P.PlatformCode                                  as PlatformCode,
          P.FamilyCode                                    as FamilyCode,
          ltrim(rtrim(P.Code))                            as ProductCode,
          OI.PublicationYear                              as PublicationYear,
          OI.PublicationQuarter                           as PublicationQuarter,
          OI.ReportingtypeCode                            as ReportingtypeCode,
          C.OrderSynchStartMonth                          as OrderSynchStartMonth,
          0                                               as AutoFulfillErrorFlag,
          ''                                              as AutoFulfillErrorMessage,
          P.DisplayName                                   as ProductName,
          P.MPFPublicationFlag                            as MPFPublicationFlag,
          CHG.MPFPublicationName                          as MPFPublicationName,
          Q.QuoteTypeCode                                 as QuoteTypeCode,
		  O.[CompanyIDSeq]								as CompanyIDSeq,
		  O.[PropertyIDSeq]								as PropertyIDSeq,
 		  O.[AccountIDSeq]								as AccountIDSeq
          ---------------------------------------------------
  from    ORDERS.dbo.[Order]      O  with (nolock)
  inner Join
          Orders.dbo.[OrderGroup] OG with (nolock)
  on      OG.OrderIDSeq = O.OrderIDSeq
  and     O.QuoteIDSeq  = @IPVC_QuoteIDSeq
  inner join
          Orders.dbo.OrderItem    OI with (nolock)
  on      OI.Orderidseq      = O.OrderIDSeq
  and     OI.OrderGroupIDSeq = OG.IDSeq
  and     OI.StatusCode  =  'PEND'
  and     OI.MeasureCode <> 'TRAN'
  inner join
          Products.dbo.Product    P with (nolock)
  on      OI.ProductCode = P.Code
  and     OI.Priceversion= P.PriceVersion
  inner join
          Quotes.dbo.Quote    Q with (nolock)
  on      O.QuoteIDSeq = Q.QuoteIDSeq
  and     Q.QuoteIDSeq = @IPVC_QuoteIDSeq
  INNER JOIN
          PRODUCTS.dbo.Charge CHG with (nolock)
  on          P.Code             = CHG.ProductCode
  and         P.PriceVersion     = CHG.PriceVersion
  and         OI.ProductCode     = CHG.ProductCode
  and         OI.PriceVersion    = CHG.PriceVersion
  and         OI.ChargeTypecode  = CHG.ChargeTypecode
  and         OI.Measurecode     = CHG.Measurecode
  and         OI.FrequencyCode   = CHG.FrequencyCode
  -------------Criteria for AutoFulfilment------------
  and     OI.StatusCode  =  'PEND'
  and     OI.MeasureCode <> 'TRAN'
  and     OI.ChargeTypeCode = coalesce(@IPVC_ChargeTypeCode,OI.ChargeTypeCode) 
  and     (
           (OI.Chargetypecode = 'ACS' and P.AutoFulfillFlag = 1 and OG.AutoFulfillACSANCFlag = 1)
              OR
           (OI.Chargetypecode = 'ACS' and OG.AutoFulfillACSANCFlag = 1)
              OR
           (OI.Chargetypecode = 'ILF' and OG.AutoFulfillILFFlag = 1)
          )
  ----------------------------------------------------
  inner join
          Customers.dbo.Company C WITH (NOLOCK)
  on      O.CompanyIDSeq = C.IDSeq
  and     O.QuoteIDSeq  = @IPVC_QuoteIDSeq
  order by OI.ChargeTypeCode ASC,OI.OrderIDSeq ASC,OI.IDSeq ASC;
  --------------------------------------------------------------------------------------
END
GO
