SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Function Nam e  : fnGetNextAvailableAddressTypeCode
-- Description     : This Function gets next available NextAvailableAddressTypeCode to use for corresponding Billing Address Type.
--                   if 'N/A' then nothing is available and all are exhausted.
--                   if NextAvailableAddressTypeCode is valid Address Type Code, then that is 
                   
-- Input Parameters: As Below in Sequential order.
-- Code Example    : select fnGetNextAvailableAddressTypeCode  Passing Input Parameters
--                   Select CUSTOMERS.dbo.fnGetNextAvailableAddressTypeCode('C0901000002','','BILLING','Company','',-1)
--                   Select CUSTOMERS.dbo.fnGetNextAvailableAddressTypeCode('C0901000002','P0901032152','BILLING','Property',-1)
--                   Select CUSTOMERS.dbo.fnGetNextAvailableAddressTypeCode('C0901000002','','BILLING','RegionalOffice',1)
--                   Select CUSTOMERS.dbo.fnGetNextAvailableAddressTypeCode('C0901000002','','BILLING','RegionalOffice',2)
-- Revision History:
-- Author          : SRS
-------------------------------------------------------------------------------------------------------------------------------------
create function [customers].[fnGetNextAvailableAddressTypeCode](@IPVC_CompanyIDSeq                varchar(50),           --> CompanyID (Mandatory) : For Both Company and Property Addresses
                                                          @IPVC_PropertyIDSeq               varchar(50),           --> For Company Addresses, PropertyID must be NULL or Blank. 
                                                                                                                   -- For Property Addresses, PropertyID is Mandatory
                                                          @IPVC_AddressType                 varchar(30),           --> THIS IS Mandatory PARAMETER. 
                                                                                                                    -- This denotes the addressType  as 'LOCATION' for Primary Location/Street
                                                                                                                    -- This denotes the addressType  as 'BILLING'  for Billing Address Type
                                                                                                                    -- This denotes the addressType as 'SHIPPING' for Shipping Address Type 
                                                          @IPVC_AddressTypeApplyTo          varchar(30),           --- This denotes Address Type Apply to
                                                                                                                    --   Company, Property,RegionalOffice
                                                          @IPVC_ApplyToRegionalOfficeIDSeq  bigint                 --- This applies only to Regional Office. Pass -1 when not applicable.
                                                         )
returns varchar(10)
as
begin
  ----------------------------------------------------------------------------
  declare @LVC_NextAvailableAddressTypeCode    varchar(20)

  select @IPVC_PropertyIDSeq              = NULLIF(@IPVC_PropertyIDSeq,'')
  ----------------------------------------------------------------------------
  select @LVC_NextAvailableAddressTypeCode = (select S.AddressTypecode
                                              from   (select XAdt.Code as AddressTypecode
                                                             ,DENSE_RANK() over (Partition by XAdt.Type order by XAdt.DisplaySortSeq asc) as DenseRank
                                                      from   CUSTOMERS.dbo.AddressType  XAdt with (nolock)
                                                      Left outer join
                                                      CUSTOMERS.dbo.Address XAddr with (nolock) 
                                                      on     XAdt.Code             = XAddr.AddressTypecode 
                                                      and    XAddr.CompanyIDSeq    = @IPVC_CompanyIDSeq 
                                                      and    coalesce(XAddr.PropertyIDSeq,'ABCDEF') =  Coalesce(@IPVC_PropertyIDSeq,'ABCDEF')          
                                                      and    XAdt.Type             = @IPVC_AddressType
                                                      and    XAdt.ApplyTo          = @IPVC_AddressTypeApplyTo
                                                      and    coalesce(XAdt.ApplyToRegionalOfficeIDSeq,'-1')= coalesce(@IPVC_ApplyToRegionalOfficeIDSeq,'-1')
                                                      where  XAdt.Type             = @IPVC_AddressType
                                                      and    XAdt.ApplyTo          = @IPVC_AddressTypeApplyTo
                                                      and    coalesce(XAdt.ApplyToRegionalOfficeIDSeq,'-1')= coalesce(@IPVC_ApplyToRegionalOfficeIDSeq,'-1')
                                                      and    XAddr.IDSeq is null
                                                     ) S
                                               where S.DenseRank = 1
                                              )
  return @LVC_NextAvailableAddressTypeCode
end
GO
