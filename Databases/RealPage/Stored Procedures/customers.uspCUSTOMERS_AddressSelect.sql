SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_AddressSelect
-- Description     : This procedure gets called from UI to get Address for Company and Property.
--                   For Customer Company Modal: Pass @IPVC_CompanyIDSeq and @IPVC_PropertyIDSeq is blank
--                     --> In this case  Company Related All Addresses (COM,CBT,CST) are fetched. CB0,CB1,CB2...For future release
--                   For Property  Modal: Pass @IPVC_CompanyIDSeq and @IPVC_PropertyIDSeq
--                     --> In this case  Propertly Related All Addresses (PRO,PBT,PST) are fetched. + PB0,PB1,PB2 etc if available for Multiple Billing Address.
--                     --> When Same as PMC is checked by user in PBT and /or PST area,
--                            Make the same proc call with only  @IPVC_CompanyIDSeq and @IPVC_PropertyIDSeq is blank
--                            which will then fetch Companys(COM,CBT,CST) address, so that CBT and CST can be bound appropriated.

                   
-- Input Parameters: As Below in Sequential order.
-- Code Example    : 
/*
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='',@IPVC_AddressType='LOCATION',@IPVC_AddressTypeApplyTo='Company'
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='',@IPVC_AddressType='SHIPPING',@IPVC_AddressTypeApplyTo='Company'
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='',@IPVC_AddressType='BILLING',@IPVC_AddressTypeApplyTo='Company'

Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='P0901032152',@IPVC_AddressType='LOCATION',@IPVC_AddressTypeApplyTo='Property'
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='P0901032152',@IPVC_AddressType='SHIPPING',@IPVC_AddressTypeApplyTo='Property'
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='P0901032152',@IPVC_AddressType='BILLING',@IPVC_AddressTypeApplyTo='Property'

Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='',@IPVC_AddressType='BILLING',@IPVC_AddressTypeApplyTo='RegionalOffice'
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='',@IPVC_AddressType='BILLING',@IPVC_AddressTypeApplyTo='RegionalOffice'
Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressSelect @IPVC_CompanyIDSeq = 'C0901000002',@IPVC_PropertyIDSeq='',@IPVC_AddressType='BILLING',@IPVC_AddressTypeApplyTo='RegionalOffice'

*/
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_AddressSelect] (@IPI_PageNumber                              int=1,                 --> This is Page number 1,2,3...
                                                     @IPI_RowsPerPage                             int=19,                --> This is rows per Page. Default is 19 rows.
                                                     @IPVC_CompanyIDSeq                           varchar(50),           --> CompanyID (Mandatory) : For Both Company and Property Addresses
                                                     @IPVC_PropertyIDSeq                          varchar(50)='',        --> For Company Addresses, PropertyID is NULL or Blank. 
                                                                                                                         -- For Property Addresses, PropertyID is Mandatory
                                                     @IPVC_AddressType                            varchar(30),           --> THIS IS Mandatory
                                                                                                                         -- This denotes the addressType as 'LOCATION' for Primary Location/Street
                                                                                                                         -- This denotes the addressType as 'BILLING'  for Billing Address Type
                                                                                                                         -- This denotes the addressType as 'SHIPPING' for Shipping Address Type   
                                                     @IPVC_AddressTypeApplyTo                     varchar(30)            --- This denotes Address Type Apply to
                                                                                                                         --  Company,         --> Only applies to Company
                                                                                                                         --  Property,        --> Only applies to Property
                                                                                                                         --  RegionalOffice   --> Only applies to RegionalOffice
                                                                                                                         --  ALL              --> Both Company and its Regional Office.
                                                    )
as 
BEGIN
  set nocount on;  
  SET CONCAT_NULL_YIELDS_NULL off;
  declare @rowstoprocess bigint  
  ----------------------------------------------------------------------------
  select @IPVC_PropertyIDSeq              =  NULLIF(@IPVC_PropertyIDSeq,'')
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------------------
  ;WITH tablefinal AS
     (select Addr.IDSeq                                    as AddressIDSeq,   --->Unique PK Identifier. UI to Pass this to back to uspCUSTOMERS_AddressUpdate Proc.
             Addr.CompanyIDSeq                             as CompanyIDSeq,
             coalesce(Addr.PropertyIDSeq,'')               as PropertyIDSeq,
             Adt.ApplyToRegionalOfficeIDSeq                as RegionalOfficeIDSeq,
             coalesce(CRO.RegionalOfficeDescription,'')    as RegionalOfficeDescription,
             -----------------------------------------------
             Adt.Code                                      as AddressTypeCode,
             Adt.Type                                      as AddressType,
             Adt.ApplyTo                                   as AddressTypeApplyTo,
             Adt.[Name]                                    as AddressTypeName,         
             -----------------------------------------------
             coalesce(Addr.AddressLine1,'')                as AddressLine1,   -- This is Line 1
             coalesce(Addr.AddressLine2,'')                as AddressLine2,   -- This is Line 2
             coalesce(Addr.City,'')                        as City,           -- This is City
             coalesce(Addr.County,'')                      as County,         -- This is County - Not shown in UI (Future)
             coalesce(Addr.State,'')                       as State,          -- This is State
             coalesce(Addr.Zip,'')                         as Zip,            -- This is Zip
             coalesce(Addr.PhoneVoice1,'')                 as PhoneVoice1,    -- This is Phone
             coalesce(Addr.PhoneVoiceExt1,'')              as PhoneVoiceExt1, -- This is EXT for Phone
             coalesce(Addr.PhoneFax,'')                    as PhoneFax,       -- This is Fax
             coalesce(Addr.PhoneVoice2,'')                 as PhoneVoice2,    -- Not shown in UI (Future)
             coalesce(Addr.PhoneVoiceExt2,'')              as PhoneVoiceExt2, -- Not shown in UI (Future)
             coalesce(Addr.PhoneVoice3,'')                 as PhoneVoice3,    -- Not shown in UI (Future)
             coalesce(Addr.PhoneVoiceExt3,'')              as PhoneVoiceExt3, -- Not shown in UI (Future)
             coalesce(Addr.PhoneVoice4,'')                 as PhoneVoice4,    -- This is CELL / Mobile Phone
             coalesce(Addr.PhoneVoiceExt4,'')              as PhoneVoiceExt4, -- Not shown in UI (Future)         
             coalesce(Addr.Email,'')                       as Email,          -- This is Email
             coalesce(Addr.URL,'')                         as URL,            -- This is URL (The value corresponding to AddressTypeCode PRO shows as Property URL on Left hand Side in Property Modal.)
                                                                              --             (The value corresponding to AddressTypeCode COM shows as Company URL on Left hand Side in Company Modal.)
             coalesce(convert(int,Addr.SameAsPMCAddressFlag),0)
                                                           as SameAsPMCAddressFlag, --SameAsPMCAddressFlag. Usually 0. 
                                                                          -- when 1 corresponding to PBT, shown same as PMC checked on Billing address in Property Modal.)
                                                                          -- when 1 corresponding to PST, shown same as PMC checked on Billing address in Property Modal.)
             coalesce(Addr.AttentionName,'')               as AttentionName,  -- This is Contact Name
             coalesce(Addr.Country,'')                     as Country,        -- This is Country Name  (drop down)
             coalesce(Addr.CountryCode,'')                 as CountryCode,    -- This is Country Code  (internal to drop down): Not shown in UI.
             (case when Adt.Code in ('COM','CST','CBT','PRO','PBT','PST')
                    then 0
                   when exists (select top 1 1 
                                from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
                                where  X.companyIDSeq = @IPVC_CompanyIDSeq
                                and    coalesce(X.BillToAddressTypeCode,
                                       (case when Addr.PropertyIDSeq is not null then 'PBT' else 'CBT' end)) 
                                          = Adt.Code
                                and    ( 
                                          (Adt.ApplyTo in ('Company','RegionalOffice')
                                                and
                                           X.companyIDSeq = @IPVC_CompanyIDSeq
                                          )
                                                OR
                                          (coalesce(X.ApplyToOMSIDSeq,coalesce(Addr.PropertyIDSeq,Addr.CompanyIDSeq))
                                                                     = coalesce(Addr.PropertyIDSeq,Addr.CompanyIDSeq)
                                          )
                                          
                                       )
                               )
                     then 0
                                       
                   else 1
             end)                                                    as DeleteableFlag,

             (case when exists (select top 1 1
                                from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
                                where  X.companyIDSeq = @IPVC_CompanyIDSeq
                                and    X.DeliveryOptionCode = 'EMAIL'
                                and    coalesce(X.BillToAddressTypeCode,
                                       (case when Addr.PropertyIDSeq is not null then 'PBT' else 'CBT' end)) 
                                          = Adt.Code
                                and    ( 
                                          (Adt.ApplyTo in ('Company','RegionalOffice')
                                                and
                                           X.companyIDSeq = @IPVC_CompanyIDSeq
                                          )
                                                OR
                                          (coalesce(X.ApplyToOMSIDSeq,coalesce(Addr.PropertyIDSeq,Addr.CompanyIDSeq))
                                                                     = coalesce(Addr.PropertyIDSeq,Addr.CompanyIDSeq)
                                          )
                                          
                                       )
                               )
                     then 1
                     else 0
             end)                                                    as EmailReferencedFlag,

             row_number() OVER(ORDER BY Adt.[DisplaySortSeq] asc,
                                        Addr.IDSeq ASC)              as  [RowNumber],
             Count(1) OVER()                                         as  TotalBatchCountForPaging
      from   CUSTOMERS.dbo.Address Addr with (nolock)
      inner join
             CUSTOMERS.dbo.AddressType  Adt with (nolock) 
      on     Addr.AddressTypecode = Adt.Code
      and    Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    coalesce(Addr.PropertyIDSeq,'ABCDEF') =  Coalesce(@IPVC_PropertyIDSeq,'ABCDEF')
      and    Adt.Type             = @IPVC_AddressType
      and    ((Adt.ApplyTo        = @IPVC_AddressTypeApplyTo)
                OR
              (Adt.ApplyTo in ('Company','RegionalOffice') and @IPVC_AddressTypeApplyTo= 'ALL')
             )
      left outer join
             CUSTOMERS.dbo.[CompanyRegionalOffice] CRO with (nolock)
      on     Adt.ApplyToRegionalOfficeIDSeq = CRO.RegionalOfficeIDSeq
      and    Addr.CompanyIDSeq              = CRO.CompanyIDSeq
      and    Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    CRO.CompanyIDSeq     = @IPVC_CompanyIDSeq
      where  Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    coalesce(Addr.PropertyIDSeq,'ABCDEF') =  Coalesce(@IPVC_PropertyIDSeq,'ABCDEF')
      and    Adt.Type             = @IPVC_AddressType
      and    ((Adt.ApplyTo        = @IPVC_AddressTypeApplyTo)
                OR
              (Adt.ApplyTo in ('Company','RegionalOffice') and @IPVC_AddressTypeApplyTo= 'ALL')
             )
     )
  select tablefinal.AddressIDSeq,
         tablefinal.CompanyIDSeq,
         tablefinal.PropertyIDSeq,
         tablefinal.RegionalOfficeIDSeq,
         tablefinal.RegionalOfficeDescription,
         tablefinal.AddressTypeCode,
         tablefinal.AddressType,
         tablefinal.AddressTypeApplyTo,
         tablefinal.AddressTypeName,
         tablefinal.AddressLine1,
         tablefinal.AddressLine2,
         tablefinal.City,
         tablefinal.County,
         tablefinal.State,
         tablefinal.Zip,
         tablefinal.PhoneVoice1,
         tablefinal.PhoneVoiceExt1,
         tablefinal.PhoneFax,
         tablefinal.PhoneVoice2,
         tablefinal.PhoneVoiceExt2,
         tablefinal.PhoneVoice3,
         tablefinal.PhoneVoiceExt3,
         tablefinal.PhoneVoice4,
         tablefinal.PhoneVoiceExt4,
         tablefinal.Email,
         tablefinal.URL,
         tablefinal.SameAsPMCAddressFlag,
         tablefinal.AttentionName,
         tablefinal.Country,
         tablefinal.CountryCode,
         tablefinal.DeleteableFlag,
         tablefinal.EmailReferencedFlag,
         tablefinal.TotalBatchCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  ----------------------------------------------------------------------------  
END
GO
