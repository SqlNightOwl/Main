SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_ValidateSitemasterID
-- Description     : Validate For SitemasterID for Order Item Fulfilment.
-- Input Parameters: 
-- Code Example    : 
-- Revision History:
-- Author          : Naval Kishore
-- 19/06/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_ValidateSitemasterID] (@IPVC_OrderIDSeq        varchar(50),
                                                         @IPVC_OrderItemIDSeq    bigint,
                                                         @IPVC_OrderGroupIDSeq   bigint,
                                                         @IPVC_ChargeTypeCode    varchar(4),
                                                         @IPB_IsCustomPackage    bit
                                                        )
AS
BEGIN
  set nocount on;  
  -----------------------------------------------------------------------------------------
  --Local Variables
  Declare @LVC_BundleType            varchar(25),
          @LVC_CompSiteMasterID      varchar(30),
          @LVC_PropSiteMasterID      varchar(30),
          @LVC_ProductValidationFlag varchar(10);

  select @LVC_BundleType = 'PropertyBundle',@LVC_ProductValidationFlag='NO'
  -----------------------------------------------------------------------------------------
  --Get Company SitemasterId and BundleType 
  select Top 1 @LVC_CompSiteMasterID = isnull(C.SiteMasterID,''),
               @LVC_BundleType       = (Case when (O.propertyIDseq is null or O.propertyIDseq = '') 
                                               then 'CompanyBundle' 
                                               else 'PropertyBundle'
                                        end) 
  FROM   Orders.dbo.[order]    O    with (nolock) 
  inner  join 
         Customers.dbo.Company C    with (nolock)
  on     O.companyIDseq = C.IDSeq
  and    O.OrderidSeq = @IPVC_OrderIDSeq
  where  O.OrderidSeq = @IPVC_OrderIDSeq
  -----------------------------------------------------------------------------------------
  --Get Property SitemasterID
  select Top 1 @LVC_PropSiteMasterID = isnull(P.SiteMasterID,'') 
  FROM   Orders.dbo.[order]     O    with (nolock)  
  inner  join 
         Customers.dbo.Property P  with (nolock)
  on     O.propertyidseq = P.IDSeq
  and    O.OrderidSeq = @IPVC_OrderIDSeq
  where  O.OrderidSeq = @IPVC_OrderIDSeq
  -----------------------------------------------------------------------------------------
  ---Step 1 : if @IPVC_ChargeTypeCode is ILF, then per BL there is no validation for SitemasterID.
  If (@IPVC_ChargeTypeCode = 'ILF')
  begin
    select 'NO' as ValidationAlertRequired,@LVC_BundleType as BundleType
  end
  -----------------------------------------------------------------------------------------
  --Determine if Product master requires SitemasterID to be validated or Not.
  if exists (select Top 1 S.Flag
             from   (select (case when (C.ValidateSiteMasterIDFlag=0)  then 'NO'                                  
                                  else 'YES'
                             end) as Flag
                     from orders.dbo.[orderItem] OI With (nolock)
                     inner join
                          products.dbo.product   P  with (nolock)
                     on   OI.productcode = P.Code
                     and  OI.Priceversion= P.Priceversion
                     and  OI.ChargeTypeCode   = 'ACS'
                     and  OI.orderidseq       = @IPVC_OrderIDSeq
                     and  OI.[ordergroupidseq]= @IPVC_OrderGroupIDSeq
                     and  (
                           (OI.IDSeq =  @IPVC_OrderItemIDSeq and @IPB_IsCustomPackage = 0)
                              OR
                           (@IPB_IsCustomPackage = 1)
                          )
                     inner join
                          Products.dbo.Charge C with (nolock)
                     on   OI.ProductCode      = C.ProductCode
                     and  OI.Priceversion     = C.PriceVersion
                     and  OI.Chargetypecode   = C.ChargetypeCode
                     and  OI.Measurecode      = C.Measurecode
                     and  OI.FrequencyCode    = C.FrequencyCode
                     and  C.ChargeTypeCode    = 'ACS'
                     and  OI.orderidseq       = @IPVC_OrderIDSeq
                     and  OI.[ordergroupidseq]= @IPVC_OrderGroupIDSeq
                     and  (
                           (OI.IDSeq =  @IPVC_OrderItemIDSeq and @IPB_IsCustomPackage = 0)
                              OR
                           (@IPB_IsCustomPackage = 1)
                          )
                     where OI.orderidseq      = @IPVC_OrderIDSeq
                     and  OI.[ordergroupidseq]= @IPVC_OrderGroupIDSeq
                     and  (
                           (OI.IDSeq =  @IPVC_OrderItemIDSeq and @IPB_IsCustomPackage = 0)
                              OR
                           (@IPB_IsCustomPackage = 1)
                          )
                    ) S
             where S.Flag = 'YES'
             )
  begin
    select @LVC_ProductValidationFlag = 'YES'
  end
  else
  begin
    select @LVC_ProductValidationFlag = 'NO'
  end
  -----------------------------------------------------------------------------------------
  if (@LVC_BundleType = 'CompanyBundle')
  begin
    if ((@LVC_ProductValidationFlag='NO') OR ((@LVC_ProductValidationFlag='YES') 
                                                  AND 
                                             (@LVC_CompSiteMasterID is not null and @LVC_CompSiteMasterID <> '')--> Company SitemasterID should not be null for Company bundle
                                            )
        )                                   
    begin
      select 'NO' as ValidationAlertRequired,@LVC_BundleType as BundleType
      return
    end
    else
    begin
      select 'Yes' as ValidationAlertRequired,@LVC_BundleType as BundleType
      return
    end
  end
  else if (@LVC_BundleType = 'PropertyBundle')
  begin
    if ((@LVC_ProductValidationFlag='NO') OR ((@LVC_ProductValidationFlag='YES') 
                                                  AND 
                                              ((@LVC_CompSiteMasterID is not null and @LVC_CompSiteMasterID <> '')  --> Company SitemasterID should not be null for Property bundle and
                                                  AND 
                                               (@LVC_PropSiteMasterID is not null and @LVC_PropSiteMasterID <> '')  --> Property SitemasterID should not be null for Property bundle
                                              )
                                             )
        )                                   
    begin
      select 'NO' as ValidationAlertRequired,@LVC_BundleType as BundleType
      return
    end
    else
    begin
      select 'Yes' as ValidationAlertRequired,@LVC_BundleType as BundleType
      return
    end
  end
  -----------------------------------------------------------------------------------------
END
GO
