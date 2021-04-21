SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_SitesInsertGroupProperties
-- Description     : This procedure inserts the groupProperties to Quotes.dbo.GroupProperties during site transfer
-- Revision History:
-- Author          : KRK, SRA Systems Limited.
-- 05/23/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_SitesInsertGroupProperties](
	                                                  
	                                                                @IPVC_QuoteIDSeq             varchar(22),
	                                                                @IPBI_GroupIDSeq             bigint,
	                                                                @IPC_PropertyIDSeq           char(22) ,
	                                                                @IPC_CustomerIDSeq           char(11) ,
	                                                                @IPVC_PriceTypeCode          varchar(20),
	                                                                @IPI_ThresholdOverrideFlag   int,
	                                                                @IPM_AnnualizedILFAmount     money,
	                                                                @IPM_AnnualizedAccessAmount  money,
	                                                                @IPI_Units                   int,
	                                                                @IPI_Beds                    int,
	                                                                @IPI_PPUPercentage           int
                                                              )
AS
BEGIN   

                    INSERT INTO QUOTES.DBO.GROUPPROPERTIES
                    (
                           QuoteIDSeq
                          ,GroupIDSeq
                          ,PropertyIDSeq
                          ,CustomerIDSeq
                          ,PriceTypeCode
                          ,ThresholdOverrideFlag
                          ,AnnualizedILFAmount
                          ,AnnualizedAccessAmount
                          ,Units
                          ,Beds
                          ,PPUPercentage
                    )
                    VALUES
                    (
                          @IPVC_QuoteIDSeq,
                          @IPBI_GroupIDSeq,
                          @IPC_PropertyIDSeq,
                          @IPC_CustomerIDSeq,
                          @IPVC_PriceTypeCode,
                          @IPI_ThresholdOverrideFlag,
                          @IPM_AnnualizedILFAmount,
                          @IPM_AnnualizedAccessAmount,
                          @IPI_Units,
                          @IPI_Beds,
                          @IPI_PPUPercentage
                    )

END

GO
