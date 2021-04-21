SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetPMCAddressDetails
-- Description     : This procedure gets Company Address to passed Company ID
--
-- Input Parameters: 
--                   @IPVC_CompanyIDSeq        as    varchar
-- 
-- OUTPUT          : RecordSet of AddressLine1, AddressLine2, City, State, Zip, PhoneVoice1, Email, Country
--                                
-- Revision History:
-- Author          : Satya B 
-- 08/10/2011      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [customers].[uspCUSTOMERS_GetPMCAddressDetails] (@IPVC_CompanyIDSeq VARCHAR(11))
AS
BEGIN

   SELECT AddressLine1, AddressLine2, City, State, Zip, PhoneVoice1, Email, Country
   FROM CUSTOMERS.dbo.[Address] 
   WHERE AddressTypeCode = 'COM' 
   AND CompanyIDSeq = @IPVC_CompanyIDSeq

END
GO
