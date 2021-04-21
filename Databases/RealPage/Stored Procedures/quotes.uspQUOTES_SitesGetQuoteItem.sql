SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_SitesGetGroupProperties
-- Description     : This procedure returns a recordset of the Group Properties details pertaining to 
--                   the QuoteIDSeq and GroupIDSeq passed
-- Revision History:
-- Author          : KRK, SRA Systems Limited.
-- 05/23/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_SitesGetQuoteItem](
	                                                            @IPVC_PropertyIDSeq  varchar(12),
	                                                            @IPI_GroupIDSeq      int
                                                     ) 
AS
BEGIN   

        SELECT 
        * 
        FROM        
                    QUOTES.DBO.QUOTEITEM        Q_ITEM

        INNER JOIN  
                    QUOTES.DBO.GROUPPROPERTIES  Q_GPRO

        ON 
                    Q_ITEM.QUOTEIDSEQ = Q_GPRO.QUOTEIDSEQ 

        WHERE   
                    Q_GPRO.PROPERTYIDSEQ = @IPVC_PropertyIDSeq
        AND
                    Q_GPRO.GROUPIDSEQ = @IPI_GroupIDSeq

END

GO
