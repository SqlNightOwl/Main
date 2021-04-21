SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetProperties](@IPDT_ReportMonthEndDate datetime)
AS
------------------------------------------------------------------- 
-- procedure  : uspCUSTOMERS_GetProperties
-- Database   : ScreeningTransactions

-- purpose    : 
--
-- returns    : n/a

-- Example of how to call this stored procedure:
-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2008-11-17 	Bhavesh Shah  	Initial creation
-- 2009-01-07   Bhavesh Shah		Added Code to make sure PMCID and SiteID are 7 chars.

-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
-----------------------------------------------------------------

BEGIN

SET NOCOUNT ON;

WITH TMP_SELECT AS 
(
  SELECT 
    C1.IDSeq as CompanyIDSeq,
    CAST(C.SiteMasterID AS NUMERIC(10,0)) AS PMCID, 
    P.IDSeq as PropertyIDSeq,
    CAST(P.SiteMasterID AS NUMERIC(10,0)) AS SiteID,
    @IPDT_ReportMonthEndDate AS LogDate
  FROM
      CUSTOMERS.dbo.[Property] P WITH (NOLOCK)
      INNER JOIN (SELECT 
                    C.IDSeq AS CompanyIDSeq, C.SiteMasterID
                  FROM
                    CUSTOMERS.dbo.[Company] C WITH (NOLOCK)
                  Where
                    NULLIF(C.SiteMasterID, '') IS NOT NULL
                  UNION
                  SELECT 
                    CH.CompanyIDSeq, CH.SiteMasterID
                  FROM
                    CUSTOMERS.dbo.[CompanyHistory] CH WITH (NOLOCK)   
                  WHERE
                    NULLIF(CH.SiteMasterID, '') IS NOT NULL
                  ) C
        ON P.PMCIDSeq = C.CompanyIDSeq
      INNER JOIN CUSTOMERS.dbo.Company C1 WITH (NOLOCK)
        ON C1.IDSeq = C.CompanyIDSeq
  Where
    P.SiteMasterID IS NOT NULL
    AND LEN(P.SiteMasterID) = 7
    AND LEN(C.SiteMasterID) = 7
UNION
  SELECT 
    C1.IDSeq as CompanyIDSeq,
    CAST(C.SiteMasterID AS NUMERIC(10,0)) AS PMCID, 
    P.IDSeq as PropertyIDSeq,
    CAST(PH.SiteMasterID AS NUMERIC(10,0)) AS SiteID,
    PH.SystemLogDate
  FROM
    CUSTOMERS.dbo.[PropertyHistory] PH WITH (NOLOCK)   
      INNER JOIN (SELECT 
                    C.IDSeq AS CompanyIDSeq, C.SiteMasterID
                  FROM
                    CUSTOMERS.dbo.[Company] C WITH (NOLOCK)
                  Where
                    NULLIF(C.SiteMasterID, '') IS NOT NULL
                  UNION
                  SELECT 
                    CH.CompanyIDSeq, CH.SiteMasterID
                  FROM
                    CUSTOMERS.dbo.[CompanyHistory] CH WITH (NOLOCK)   
                  WHERE
                    NULLIF(CH.SiteMasterID, '') IS NOT NULL
                  ) C
        ON PH.PMCIDSeq = C.CompanyIDSeq
      INNER JOIN CUSTOMERS.dbo.Company C1 WITH (NOLOCK)
        ON C1.IDSeq = C.CompanyIDSeq
      INNER JOIN CUSTOMERS.dbo.Property P WITH (NOLOCK)
        ON P.IDSeq = PH.PropertyIDSeq
  WHERE
    PH.SiteMasterID IS NOT NULL
    AND LEN(PH.SiteMasterID) = 7
    AND LEN(C.SiteMasterID) = 7
)

SELECT
  C.IDSeq AS CompanyIDSeq
  , C.Name AS CompanyName
  , C.StatusTypecode AS CompanyStatusCode
  , TS.PMCID
  , P.IDSeq as PropertyIDSeq
  , P.Name AS SiteName
  , P.StatusTypeCode AS SiteStatusCode
  , TS.SiteID
  , TS.LogDate
FROM 
  TMP_SELECT TS
    INNER JOIN Company C WITH (NOLOCK)
      ON TS.CompanyIDSeq = C.IDSeq
    INNER JOIN [Property] P WITH (NOLOCK)
      ON TS.CompanyIDSeq = P.PMCIDSeq AND TS.PropertyIDSeq = P.IDSeq
  
SET NOCOUNT OFF

END
GO
