SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_InterfaceDelete]
(
	@IPVC_CompanyIDSeq               varchar(50),   --> CompanyID (Mandatory) : For Both Company and Property Addresses
    @IPVC_PropertyIDSeq              varchar(50)='',--> For Company Records, PropertyID is NULL or Blank. 
    @IPVC_InterfacedSystemID         varchar(50),    --> InterfacedSystemID to exact and actual Unique ID of External System for a given InterfacedSystemIDTypeCode. eg External System AccountID, Billing ID etc  
    @IPVC_InterfacedSystemCode       varchar(5)   
)
AS
BEGIN

  delete  from InterfacedSystemIdentifier   
  where                 InterfacedSystemCode       = @IPVC_InterfacedSystemCode 
                 and    CompanyIDSeq               = @IPVC_CompanyIDSeq 
                 and    InterfacedSystemID         = @IPVC_InterfacedSystemID
                 and    coalesce(PropertyIDSeq,'') = @IPVC_PropertyIDSeq
 

END
GO
