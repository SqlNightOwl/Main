SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_PropertySelect
-- Description     : This procedure gets called for Property Modal to return only Property specific Attributes
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_PropertySelect  Passing Input Parameters
-- Revision History:
-- Author          : SRS
----------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertySelect] (@IPVC_CompanyIDSeq    varchar(50),
                                                      @IPVC_PropertyIDSeq   varchar(50)='' ---> This is blank for Brand New Property creation
                                                                                            --    so that this proc returns a blank template with some attributes of Company
                                                     )
as
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ---------------------------------------------------------------------------- 
  declare @LVC_CompanyBreakDownCode                    varchar(5)
  declare @LVC_PropertyExpandCustomBundleFlag          varchar(5)  

  declare @LI_OwnsGSAProduct                           int
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @IPVC_PropertyIDSeq  = NULLIF(@IPVC_PropertyIDSeq,'')

  select @LVC_CompanyBreakDownCode          = 'NOBR',
         @LVC_PropertyExpandCustomBundleFlag= 0,
         @LI_OwnsGSAProduct                 = 0         
  ----------------------------------------------------------------------------
  select Top 1 @LVC_CompanyBreakDownCode      = CustomBundlesProductBreakDownTypeCode
  from   Customers.dbo.Company C with (nolock)
  where  IDSeq = @IPVC_CompanyIDSeq 

  if (@IPVC_PropertyIDSeq is null)
  begin
    select @LVC_PropertyExpandCustomBundleFlag     = (case when @LVC_CompanyBreakDownCode='YEBR' then  1  -- Keep the Expand Custom Bundle check Box Checked by default in Property Modal
                                                           when @LVC_CompanyBreakDownCode='NOBR' then  3  -- Keep the Expand Custom Bundle check Box disabled in Property Modal
                                                          else 0                                          -- Keep the Expand Custom Bundle check Box Un Checked by default in Property Modal  
                                                     end)


    select ''                                       as PropertyIDSeq,
           ''                                       as PropertyName,
           ''                                       as Phase,
           ''                                       as OwnerIDSeq,
           ''                                       as OwnerName,
           ''                                       as PropertyURL,
           0                                        as Units,
           0                                        as Beds,
           100                                      as PPUPercentage,
           0                                        as QuotableUnits,
           0                                        as QuotableBeds,
           '[Unassigned]'                           as AccountID,
           ''                                       as SiteMasterID,
           '[Unassigned]'                           as SiebelID,
           '[Unassigned]'                           as EpicorCustomerCode,
           '[Unassigned]'                           as LegacyRegistrationCode,
           0                                        as SubPropertyFlag,
           'ACTIV'                                  as StatusTypeCode,
           @LVC_PropertyExpandCustomBundleFlag      as ExpandCustomBundleFlag, --> When 1 Expand Custom Bundle check Box is checked by default.0=keep it unchecked. 3 means disabled.
           (Case when @LVC_PropertyExpandCustomBundleFlag = 1  then 'YEBR'
                 else 'NOBR'
            end)                                    as CustomBundlesProductBreakDownTypeCode,
           0                                        as SeparateInvoiceByFamilyFlag,
           1                                        as ConventionalFlag,  
           0                                        as HUDFlag,
           0                                        as TaxCreditFlag,
           0                                        as StudentLivingFlag,
           0                                        as RHSFlag,
           0                                        as VendorFlag,
           0                                        as RetailFlag,
           0                                        as GSAEntityFlag,
           0                                        as OwnsGSAProduct,              --> 0 by default means User can UnCheck  GSAEntityFlag.
                                                                                    ---  1 means User Cannot uncheck as atleast one active order is present.
                                                                                    ---  In this case, throw a message "This Property Account has atleast one active GSA Qualified product 
                                                                                    ---       and that it has to be Cancelled before this Property can be taken off the GSA Qualified List"
           0                                        as MilitaryPrivatizedFlag,
           0                                        as SeniorLivingFlag 
            
  end
  else 
  begin
    if exists (select top 1 1
               from   ORDERS.dbo.[Order] O with (nolock)
               inner join
                      ORDERS.dbo.[OrderItem] OI with (nolock)
               on     O.OrderIdSeq    = OI.Orderidseq
               and    OI.FamilyCode   = 'GSA'
               and    OI.StatusCode   in ('FULF','PENR')
               and    O.CompanyIDSeq  = @IPVC_CompanyIDSeq
               and    O.PropertyIDSeq = @IPVC_PropertyIDSeq
              )
    begin
      select @LI_OwnsGSAProduct = 1
    end
    else 
    begin
      select @LI_OwnsGSAProduct = 0
    end
    --------------------------------
    select Top 1
           P.IDSeq                                           as PropertyIDSeq,
           P.Name                                            as PropertyName,
           P.Phase                                           as Phase,
           P.OwnerIDSeq                                      as OwnerIDSeq,
           Own.[Name]                                        as OwnerName,
           Coalesce(AddrProp.URL,'')                         as PropertyURL,
           P.Units                                           as Units,
           P.Beds                                            as Beds,
           P.PPUPercentage                                   as PPUPercentage,
           P.QuotableUnits                                   as QuotableUnits,
           P.QuotableBeds                                    as QuotableBeds,
           coalesce(A.IDSeq,'[Unassigned]')                  as AccountID,
           P.SiteMasterID                                    as SiteMasterID,
           coalesce(P.SiebelID,A.IDSeq,'[Unassigned]')       as SiebelID,
           coalesce(A.EpicorCustomerCode,'[Unassigned]')     as EpicorCustomerCode,
           coalesce(P.LegacyRegistrationCode,'[Unassigned]') as LegacyRegistrationCode,
           convert(int,P.SubPropertyFlag)                    as SubPropertyFlag,
           P.StatusTypeCode                                  as StatusTypeCode,
           (case when P.CustomBundlesProductBreakDownTypeCode = 'YEBR' then 1
                  else 0
            end)                                             as ExpandCustomBundleFlag, --> When 1 Expand Custom Bundle check Box is checked by default.0=keep it unchecked.
           P.CustomBundlesProductBreakDownTypeCode           as CustomBundlesProductBreakDownTypeCode,
           convert(int,P.SeparateInvoiceByFamilyFlag)        as SeparateInvoiceByFamilyFlag,
           convert(int,P.ConventionalFlag)                   as ConventionalFlag,  
           convert(int,P.HUDFlag)                            as HUDFlag,
           convert(int,P.TaxCreditFlag)                      as TaxCreditFlag,
           convert(int,P.StudentLivingFlag)                  as StudentLivingFlag,
           convert(int,P.RHSFlag)                            as RHSFlag,
           convert(int,P.VendorFlag)                     as VendorFlag,
           convert(int,P.RetailFlag)                         as RetailFlag,
           convert(int,P.GSAEntityFlag)                      as GSAEntityFlag,
           @LI_OwnsGSAProduct                                as OwnsGSAProduct,      --> 0 by default means User can UnCheck  GSAEntityFlag.
                                                                                             ---  1 means User Cannot uncheck as atleast one active order is present.
                                                                                             ---  In this case, throw a message "This Property Account has atleast one active GSA Qualified product 
                                                                                              ---       and that it has to be Cancelled before this Property can be taken off the GSA Qualified List"
           MilitaryPrivatizedFlag                            as MilitaryPrivatizedFlag,
           SeniorLivingFlag                                  as SeniorLivingFlag  
    from CUSTOMERS.dbo.Property P        with (nolock)
    inner join
         CUSTOMERS.dbo.Address  AddrProp with (nolock)
    on   P.PMCIDSeq =  AddrProp.CompanyIDSeq
    and  P.IDSeq    =  AddrProp.PropertyIDSeq
    and  P.PMCIDSeq =  @IPVC_CompanyIDSeq
    and  P.IDSeq    =  @IPVC_PropertyIDSeq
    and  AddrProp.CompanyIDSeq  =  @IPVC_CompanyIDSeq
    and  AddrProp.PropertyIDSeq =  @IPVC_PropertyIDSeq
    and  AddrProp.AddressTypeCode = 'PRO'
    and  AddrProp.PropertyIDSeq is not null
    Left Outer join
         CUSTOMERS.dbo.Account A with (nolock)
    on   P.PMCIDSeq = A.CompanyIDSeq
    and  P.IDSeq    = A.PropertyIDSeq
    and  P.PMCIDSeq =  @IPVC_CompanyIDSeq
    and  P.IDSeq    =  @IPVC_PropertyIDSeq
    and  A.CompanyIDSeq   =  @IPVC_CompanyIDSeq
    and  A.PropertyIDSeq  =  @IPVC_PropertyIDSeq
    and  A.AccountTypeCode=  'APROP'
    and  A.ActiveFlag     =  1
    Left Outer join
         CUSTOMERS.dbo.Company Own with (nolock)
    on   P.OwnerIDSeq = Own.IDSeq
    and  P.PMCIDSeq  =  @IPVC_CompanyIDSeq
    and  P.IDSeq     =  @IPVC_PropertyIDSeq 
    where P.PMCIDSeq =  @IPVC_CompanyIDSeq
    and   P.IDSeq    =  @IPVC_PropertyIDSeq  
  end
END
GO
