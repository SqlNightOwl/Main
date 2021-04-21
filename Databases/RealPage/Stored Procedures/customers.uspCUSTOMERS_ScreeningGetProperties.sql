SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ScreeningGetProperties]
(
	@IPDT_ReportMonthEndDate datetime
	, @IPDT_RunDate datetime = NULL 
) 
AS
------------------------------------------------------------------- 
-- procedure  : uspCUSTOMERS_ScreeningGetProperties
-- Database   : ScreeningTransactions

-- purpose    : @IPDT_ReportMonthEndDate
--
-- returns    : Returns property records.

-- Example of how to call this stored procedure:
--              Exec CUSTOMERS.dbo.uspCUSTOMERS_ScreeningGetProperties @IPDT_ReportMonthEndDate = '01/31/2009'


-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2008-11-17 	Bhavesh Shah  	Initial creation
-- 2009-01-07   Bhavesh Shah		Added Code to make sure PMCID and SiteID are 7 chars.
-- 2009-03-30   Bhavesh Shah		Added group by to eliminate duplicate by only getting SitemasterID changes.
--                              Also added code not get change after month end date.

-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
-----------------------------------------------------------------

BEGIN

SET NOCOUNT ON;

WITH TMP_SELECT AS 
(
  SELECT 
    C.IDSeq as CustomerIDSeq,
    CAST(C.SiteMasterID AS int) AS PMCID, 
    P.IDSeq as PropertyIDSeq,
    CAST(P.SiteMasterID AS int) AS SiteID,
    CAST(CONVERT(varchar(10), Coalesce(@IPDT_RunDate, getdate()), 101) as datetime) AS LogDate
  FROM
      CUSTOMERS.dbo.[Property] P WITH (NOLOCK)
      INNER JOIN CUSTOMERS.dbo.[Company] C WITH (NOLOCK)
        ON P.PMCIDSeq = C.IDSeq
  Where
    P.SiteMasterID IS NOT NULL
    AND LEN(P.SiteMasterID) = 7
UNION
  SELECT 
    C.CompanyIDSeq,
    CAST(C.SiteMasterID AS NUMERIC(10,0)) AS PMCID, 
    P.IDSeq as PropertyIDSeq,
    CAST(PH.SiteMasterID AS NUMERIC(10,0)) AS SiteID,
    PH.SystemLogDate
  FROM
    CUSTOMERS.dbo.[PropertyHistory] PH WITH (NOLOCK)   
      INNER JOIN (SELECT 
                    C.IDSeq AS CompanyIDSeq, C.SiteMasterID, @IPDT_ReportMonthEndDate AS LogDate
                  FROM
                    CUSTOMERS.dbo.[Company] C WITH (NOLOCK)
                  UNION
                  SELECT 
                    CH.CompanyIDSeq, CH.SiteMasterID, CH.SystemLogDate
                  FROM
                    CUSTOMERS.dbo.[CompanyHistory] CH WITH (NOLOCK)   
                  ) C
        ON PH.PMCIDSeq = C.CompanyIDSeq AND CAST (CONVERT(varchar(10), C.LogDate, 101) as datetime) <= CAST (CONVERT(varchar(10), PH.SystemLogDate, 101) as datetime)
      INNER JOIN CUSTOMERS.dbo.Property P WITH (NOLOCK)
        ON P.IDSeq = PH.PropertyIDSeq
  WHERE
    PH.SiteMasterID IS NOT NULL
		-- Added to not get any changes after ReportMonthEndDate
		AND PH.SystemLogDate < @IPDT_ReportMonthEndDate
    AND LEN(PH.SiteMasterID) = 7
)

SELECT
  C.IDSeq AS CustomerIDSeq
  , C.Name AS CompanyName
  , C.StatusTypecode AS CompanyStatusCode
  , TS.PMCID
  , P.IDSeq as PropertyIDSeq
  , P.Name AS SiteName
  , P.StatusTypeCode AS SiteStatusCode
  , TS.SiteID
  , MAX(TS.LogDate) AS LogDate
	, @IPDT_ReportMonthEndDate AS ReportMonthEndDate
FROM 
  TMP_SELECT TS
    INNER JOIN Company C WITH (NOLOCK)
      ON TS.CustomerIDSeq = C.IDSeq
    INNER JOIN [Property] P WITH (NOLOCK)
      ON TS.CustomerIDSeq = P.PMCIDSeq AND TS.PropertyIDSeq = P.IDSeq
GROUP BY -- Added Group by to get only SiteMasterID changes.
	C.IDSeq
	, C.Name
	, C.StatusTypecode
	, TS.PMCID
  , P.IDSeq
  , P.Name
  , P.StatusTypeCode
  , TS.SiteID  
--	, TS.LogDate
ORDER BY 
	C.IDSeq
	, TS.PMCID
  , P.IDSeq
  , TS.SiteID  

END
GO
