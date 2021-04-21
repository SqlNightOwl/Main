SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Function Nam e  : fnGetNextAvailableRegionalOfficeID
-- Description     : This Function gets next available Regional Office to use for adding New Regions
--                   if 'N/A' then nothing is available and all are exhausted.
                   
-- Input Parameters: As Below in Sequential order.
-- Code Example    : select fnGetNextAvailableRegionalOfficeID  Passing Input Parameters
--                   Select CUSTOMERS.dbo.fnGetNextAvailableRegionalOfficeID('C0901000002')
-- Revision History:
-- Author          : SRS
-------------------------------------------------------------------------------------------------------------------------------------
create function [customers].[fnGetNextAvailableRegionalOfficeID] (@IPVC_CompanyIDSeq                varchar(50) --> CompanyID (Mandatory)
                                                           )
returns bigint
as
begin
  ----------------------------------------------------------------------------
  declare @LVC_NextAvailableRegionalOfficeID    bigint 
  ----------------------------------------------------------------------------
  select @LVC_NextAvailableRegionalOfficeID = S.RegionalOfficeIDSeq
  from   (select min(RO.RegionalOfficeIDSeq) as RegionalOfficeIDSeq
          from   CUSTOMERS.dbo.RegionalOffice RO with (nolock)
          where  not exists (select top 1 1
                             from   CUSTOMERS.dbo.CompanyRegionalOffice CRO with (nolock)
                             where  CRO.CompanyIDSeq = @IPVC_CompanyIDSeq
                             and    CRO.RegionalOfficeIDSeq = RO.RegionalOfficeIDSeq
                            )
         ) S
  return @LVC_NextAvailableRegionalOfficeID
end
GO
