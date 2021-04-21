SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetRelatedOtherAccounts]
-- Description     : This procedure Selects CustomBundlesProductBreakDownTypeCode in Customer and Property Table
--Input Parameter  : @IPVC_CustomerIDSEQ           bigint, 
--                  
--
-- Code Example    : [CUSTOMERS].dbo.[uspCUSTOMERS_GetRelatedOtherAccounts] @IPVC_CompanyIDSeq='C0912000001',@IPVC_PropertyIDSeq=''
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 07/24/2007      : Stored Procedure Created.
-- 12/01/2009      : Naval Kishore Modifed to add new parameters @IPVC_SelectedOption
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetRelatedOtherAccounts] (@IPVC_CompanyIDSeq   varchar(30),
							       @IPVC_PropertyIDSeq  varchar(30)=''                                                              
                                                               )     
AS
BEGIN 
  set nocount on;
  select @IPVC_PropertyIDSeq = nullif(@IPVC_PropertyIDSeq,'')
  ---------------------------------------------------------------------------------
  ---- For Display on Company Modal from the UI link for a given Company
  if (@IPVC_PropertyIDSeq is NULL)
  BEGIN
    select C.Name                 as [Name],
           ISys.Name              as InterfaceSystemName,
	   IST.Name               as IDType,
	   ISD.InterfacedSystemID as SystemID,
           ISD.IDSeq              as IDSeq
    from   Customers.dbo.Company C with (nolock)
    left outer join
           InterfacedSystemIdentifier ISD with (nolock)
    on    C.IDSeq = ISD.CompanyIDSeq
    and   ISD.RecordType = 'AHOFF'
    and   ISD.PropertyIDSeq is null
    and   C.IDSeq = @IPVC_CompanyIDSeq
    inner Join
          InterfacedSystem ISys with (nolock)
    on    ISD.InterfacedSystemCode = ISys.Code
    inner Join
          InterfacedSystemIDType IST with (nolock)
    on    ISD.InterfacedSystemIDTypeCode = IST.Code
    where C.IDSeq = @IPVC_CompanyIDSeq
    order by InterfaceSystemName ASC,IDType ASC
  END
  ELSE
  BEGIN
    ---------------------------------------------------------------------------------
    ---- For Display on Property Modal from the UI link for a given Property
    select P.Name                 as [Name],
           ISys.Name              as InterfaceSystemName,
           IST.Name               as IDType,
           ISD.InterfacedSystemID as SystemID,
           ISD.IDSeq              as IDSeq
    from   Customers.dbo.Property P with (nolock)    
    left outer join
           InterfacedSystemIdentifier ISD with (nolock)
    on     P.IDSeq    = ISD.PropertyIDSeq
    and    P.PMCIDSeq = ISD.CompanyIDSeq
    and   ISD.RecordType = 'APROP'
    and   ISD.PropertyIDSeq is not null
    and   P.IDSeq    = @IPVC_PropertyIDSeq
    and   P.PMCIDSeq = @IPVC_CompanyIDSeq
    inner Join
	  InterfacedSystem ISys with (nolock)
    on    ISD.InterfacedSystemCode = ISys.Code
    inner Join
          InterfacedSystemIDType IST with (nolock)
    on    ISD.InterfacedSystemIDTypeCode = IST.Code
    where P.IDSeq    = @IPVC_PropertyIDSeq
    and   P.PMCIDSeq = @IPVC_CompanyIDSeq
    order by InterfaceSystemName ASC,IDType ASC
  END
---------------------------------------------------------------------------------
END
GO
