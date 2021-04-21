SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_CheckEmailDeliveryRule]
-- Description     : This is the Main SP called to check EmailDeliveryRule exists for a specific customer
-- Input Parameters: @IPVC_CompanyIDSeq
-- Syntax          : Exec CUSTOMERS.dbo.uspCUSTOMERS_CheckEmailDeliveryRule @IPVC_CompanyIDSeq='C0901000002'
-- Author          : Mahaboob
-- 11/10/2011      : Stored Procedure Created. (TFS #1579) 
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CheckEmailDeliveryRule] (@IPVC_CompanyIDSeq          varchar(50)     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                             )                  
AS
BEGIN 
     select count(IDSeq) 
     from  CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
     where IDER.CompanyIDSeq = @IPVC_CompanyIDSeq and IDER.DeliveryOptionCode = 'EMAIL'
END
GO
