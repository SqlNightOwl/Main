SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetCountryCodeForPMC]
-- Description     : This procedure gets Country Code for specific PMC
                 
-- Input Parameters: @IPVC_PMCIDSeq
-- OUTPUT          : RecordSet of CountryCode
-- Code Example    : exec [CUSTOMERS].[dbo].[uspCUSTOMERS_GetCountryCodeForPMC] 'C0901001035'
-- Author          : DNETHUNURI
-- 05/11/2011      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [customers].[uspCUSTOMERS_GetCountryCodeForPMC] ( @IPVC_PMCIDSeq   VARCHAR(50) ) 
AS  
BEGIN 

SELECT A.CountryCode AS CountryCode
FROM [CUSTOMERS].[dbo].[Company] C with (nolock)
JOIN [CUSTOMERS].[dbo].[Address] A with (nolock) ON C.IDSeq = A.CompanyIDSeq AND A.AddressTypeCode = 'COM' 
WHERE C.IDSeq = @IPVC_PMCIDSeq 
 
END  
GO
