SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CompanySelect
-- Description     : This procedure gets called for Company Modal to return only Company specific Attributes in EDIT Mode
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyGeneralInfoSelect  Passing Input Parameters
-- Revision History:
-- Author          : SRS
-- 2011-07-28      : Mahaboob ( Defect #909 ) --  Modified procedure to get "ExecutiveIDSeq" from the "Company" table.
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
----------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CompanyGeneralInfoSelect] (@IPVC_CompanyIDSeq    varchar(50)
                                                               )
as
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ---------------------------------------------------------------------------- 
  declare @LI_ExpandCustomBundleSetting               int
  declare @LVC_CustomBundlesProductBreakDownTypeCode  varchar(10)
  

  declare @LI_SeparateInvoiceByFamilyFlagSetting      int
  declare @LI_SeparateInvoiceByFamilyFlag             int  
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LI_ExpandCustomBundleSetting = 3

  select @LVC_CustomBundlesProductBreakDownTypeCode = C.CustomBundlesProductBreakDownTypeCode,
         @LI_SeparateInvoiceByFamilyFlag       = convert(int,C.SeparateInvoiceByFamilyFlag)
  from   CUSTOMERS.dbo.Company C with (nolock)
  where  C.IDSeq = @IPVC_CompanyIDSeq
        
  ----------------------------------------------------------------------------
  ---Step 1: BL for @LI_ExpandCustomBundleSetting
  --- If Company CustomBundlesProductBreakDownTypeCode is YEBR and all its properties is YEBR then 1 ie All Radio Button.
  --- If Company CustomBundlesProductBreakDownTypeCode is NOBR and all its properties is NOBR then 3 ie Radio Button at the end for Disable
  --- If Company has  a setting and atleast one of its property has a different setting then 2 ie Select Radio Button.
  select @LI_ExpandCustomBundleSetting = (Case  when  ((@LVC_CustomBundlesProductBreakDownTypeCode = 'YEBR')
                                                          and  
                                                       not exists (select top 1 1 
                                                                   from   Customers.dbo.Property P with (nolock)
                                                                   where  P.PMCIDSeq = @IPVC_CompanyIDSeq
                                                                   and    P.CustomBundlesProductBreakDownTypeCode <> @LVC_CustomBundlesProductBreakDownTypeCode
                                                                  )
                                                     ) 
                                                  then 1
                                               when  ((@LVC_CustomBundlesProductBreakDownTypeCode = 'NOBR')
                                                          and  
                                                      not exists (select top 1 1 
                                                                  from   Customers.dbo.Property P with (nolock)
                                                                  where  P.PMCIDSeq = @IPVC_CompanyIDSeq
                                                                  and    P.CustomBundlesProductBreakDownTypeCode <> @LVC_CustomBundlesProductBreakDownTypeCode
                                                                 )
                                                     ) 
                                                  then 3
                                               else 2 
                                            end)
  ----------------------------------------------------------------------------
  ---Step 2: BL for @LI_SeparateInvoiceByFamilyFlag
  --- If Company @LI_SeparateInvoiceByFamilyFlag is 1 and all its properties is 1 then 1 ie All Radio Button.
  --- If Company @LI_SeparateInvoiceByFamilyFlag is 0 and all its properties is 0 then 3 ie Radio Button at the end for Disable
  --- If Company has  a setting and atleast one of its property has a different setting then 2 ie Select Radio Button.
  select @LI_SeparateInvoiceByFamilyFlagSetting = (Case  when  ((@LI_SeparateInvoiceByFamilyFlag = 1)
                                                                    and  
                                                                 not exists (select top 1 1 
                                                                             from   Customers.dbo.Property P with (nolock)
                                                                             where  P.PMCIDSeq = @IPVC_CompanyIDSeq
                                                                             and    P.SeparateInvoiceByFamilyFlag <> @LI_SeparateInvoiceByFamilyFlag
                                                                             )
                                                               ) 
                                                          then 1
                                                          when  ((@LI_SeparateInvoiceByFamilyFlag = 0)
                                                                    and  
                                                                   not exists (select top 1 1 
                                                                               from   Customers.dbo.Property P with (nolock)
                                                                               where  P.PMCIDSeq = @IPVC_CompanyIDSeq
                                                                               and    P.SeparateInvoiceByFamilyFlag <> @LI_SeparateInvoiceByFamilyFlag
                                                                              )
                                                                ) 
                                                          then 3
                                                          else 2 
                                                   end)
  ----------------------------------------------------------------------------  
  Declare @IsExecutiveCustomer bit, @ExecutiveIDSeq varchar(11)
  select @IsExecutiveCustomer = 0, @ExecutiveIDSeq = ''
  select @ExecutiveIDSeq = E.ExecutiveCompanyIDSeq 
  from Customers.dbo.ExecutiveCompany E 
  inner join
  Customers.dbo.Company C with (nolock)
  on C.IDSeq = E.CompanyIDSeq  and C.StatusTypeCode = 'ACTIV'
  where E.CompanyIDSeq = @IPVC_CompanyIDSeq and E.ActiveFlag = 1
  if(len(@ExecutiveIDSeq)=11)
  begin
		set @IsExecutiveCustomer = 1
  end

  select  C.IDSeq                                           as CompanyIDSeq,     ---> Company ID Shown in UI
          C.Name                                            as CompanyName,      ---> Company Name Shown in UI
          coalesce(C.SignatureText,'')                      as SignatureText,    ---> SignatureText Shown in UI
          C.StatusTypecode                                  as StatusTypecode,   ---> StatusTypecode Shown in UI in drop down
          convert(int,PMCFlag)                              as PMCFlag,          ---> Not Shown in UI (Future). In OMS By default all companies are considered PMC
          convert(int,OwnerFlag)                            as OwnerFlag,        ---> OwnerFlag shown in UI in Customer Type
          convert(int,MultiFamilyFlag)                      as MultiFamilyFlag,  ---> MultiFamilyFlag shown in UI in Customer Type
          convert(int,VendorFlag)                           as VendorFlag,       ---> VendorFlag shown in UI in Customer Type
          convert(int,GSAEntityFlag)                        as GSAEntityFlag,    ---> GSAEntityFlag shown in UI in Customer Type 
          Coalesce(AddrCom.URL,'')                          as CompanyURL,       ---> CompanyURL shown in UI 
          coalesce(C.SiteMasterID,'')                       as SiteMasterID,     ---> SiteMasterID shown in UI 
          coalesce(A.IDSeq,'[Unassigned]')                  as AccountID,        ---> AccountID shown in UI 
          coalesce(C.SiebelID,A.IDSeq,'[Unassigned]')       as SiebelID,         ---> SiebelID shown in UI 
          coalesce(C.LegacyRegistrationCode,'[Unassigned]') as LegacyRegistrationCode, ---> LegacyRegistrationCode shown in UI  as Reg Code
          C.OrderSynchStartMonth                            as OrderSynchStartMonth,   ---> Interger values for drop down for Sync Start Month.
          @LI_ExpandCustomBundleSetting                     as ExpandCustomBundleSetting, ---> Expand Custom Bundle : 1 Means "All Radio Button", 2 means "Select Radio Button", 3 Means "Disable Radio Button"
          C.CustomBundlesProductBreakDownTypeCode           as CustomBundlesProductBreakDownTypeCode, ---Not Shown in UI as current Company CustomBundlesProductBreakDownType (Future)
          @LI_SeparateInvoiceByFamilyFlagSetting            as SeparateInvoiceByFamilyFlagSetting,     --->Print Separte Invoice By Family Setting : 1 Means "All Radio Button", 2 means "Select Radio Button", 3 Means "Disable Radio Button"      
--         (case 
--               when @IsExecutiveCustomer = 1 then @ExecutiveIDSeq
--               else E.IDSeq	
--           end)												as ExecutiveIDSeq,				-->Executive Company ID shown in UI
--          (case 
--               when @IsExecutiveCustomer = 1 then C.Name
--               else E.CompanyName		
--           end)		        								as ExecutiveCompanyName,		-->Executive Company Name shown in UI
          
		  E.ExecutiveCompanyIDSeq							as ExecutiveIDSeq,
		  E.CompanyName									    as ExecutiveCompanyName,
          E.CompanyIDSeq									as ExecutiveCustomerID,
          @IsExecutiveCustomer								as IsExecutiveCustomer          ---> Check for ExecutiveCustomer
  from    CUSTOMERS.dbo.Company C with (nolock)
  inner join
         CUSTOMERS.dbo.Address  AddrCom with (nolock)
  on   C.IDSeq    =  AddrCom.CompanyIDSeq 
  and  C.IDSeq    =  @IPVC_CompanyIDSeq  
  and  AddrCom.CompanyIDSeq  =  @IPVC_CompanyIDSeq 
  and  AddrCom.AddressTypeCode = 'COM'
  and  AddrCom.PropertyIDSeq is  null
  Left Outer join
       CUSTOMERS.dbo.Account A with (nolock)
  on   C.IDSeq    = A.CompanyIDSeq
  and  C.IDSeq    =  @IPVC_CompanyIDSeq
  and  A.CompanyIDSeq   =  @IPVC_CompanyIDSeq  
  and  A.AccountTypeCode=  'AHOFF'
  and  A.ActiveFlag     =  1
  left outer join
         CUSTOMERS.dbo.ExecutiveCompany E with (nolock)
  on E.ExecutiveCompanyIDSeq = C.ExecutiveCompanyIDSeq and C.StatusTypeCode = 'ACTIV' and E.ActiveFlag = 1
  ----------------------------------------------------------------------------
END
GO
