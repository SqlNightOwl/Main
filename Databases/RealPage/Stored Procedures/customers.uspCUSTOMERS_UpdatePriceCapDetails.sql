SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspCUSTOMERS_UpdatePriceCapDetails
-- Description     :  This procedure updates the Price Cap Details fetched from UI
--                    and also inserts into the Price Cap History
-- Input Parameters: 	1. @PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_UpdatePriceCapDetails  
--                        @IPI_PriceCapIDSeq      = 1,
--                        @IPC_CompanyIDSeq       = 'C0000000001',
--                        @IPVC_FamilyCode        = 'ADM',
--                        @IPVC_PriceCapBasisCode = '', 
--                        @IPD_PriceCapPercent    = 15.5, 
--                        @IPI_PriceCapTerm       = 1, 
--                        @IPDT_PriceCapStartDate = '02/15/2007', 
--                        @IPDT_PriceCapEndDate   = '02/15/2007'
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 02/15/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_UpdatePriceCapDetails] 
                  @IPI_PriceCapIDSeq          bigint,
                  @IPC_CompanyIDSeq           char(11),
                  @IPVC_PriceCapBasisCode     varchar(4), 
                  @IPD_PriceCapPercent        numeric(30,5), 
                  @IPI_PriceCapTerm           int, 
                  @IPDT_PriceCapStartDate     datetime, 
                  @IPDT_PriceCapEndDate       datetime

AS
BEGIN

  -----------------------------------------------------
  --          Update values in Price Cap
  -----------------------------------------------------
  UPDATE  PriceCap 
  SET
          CompanyIDSeq      = @IPC_CompanyIDSeq, 
          PriceCapBasisCode = @IPVC_PriceCapBasisCode, 
          PriceCapPercent   = @IPD_PriceCapPercent, 
          PriceCapTerm      = @IPI_PriceCapTerm, 
          PriceCapStartDate = @IPDT_PriceCapStartDate, 
          PriceCapEndDate   = @IPDT_PriceCapEndDate
  WHERE   
          IDSeq             = @IPI_PriceCapIDSeq
  -----------------------------------------------------

  -----------------------------------------------------
  --          Insert Into Price Cap History
  -----------------------------------------------------
  INSERT INTO PriceCapHistory
                      (
                          CompanyIDSeq, 
                          PriceCapBasisCode, 
                          PriceCapPercent, 
                          PriceCapTerm, 
                          PriceCapStartDate, 
                          PriceCapEndDate
                      )
  VALUES              (
                          @IPC_CompanyIDSeq, 
                          @IPVC_PriceCapBasisCode, 
                          @IPD_PriceCapPercent, 
                          @IPI_PriceCapTerm, 
                          @IPDT_PriceCapStartDate, 
                          @IPDT_PriceCapEndDate
                      )
  -----------------------------------------------------
	
END

GO
