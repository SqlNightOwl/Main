SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [oms].[uspCUSTOMERS_GetPMCAddress] (@IPCCompanyIDSeq char(11))
AS
BEGIN
   select top 1 AddressLine1,AddressLine2,City,State,Zip,Country,CountryCode from Address where CompanyIDSeq = @IPCCompanyIDSeq
END


GO
