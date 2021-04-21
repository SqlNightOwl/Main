SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteMeasure
-- Description     : This proc is called by Product Administration Measure Management to an Existing Measure
-- Input Parameters: @IPVC_MeasureCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteMeasure 
                          @IPVC_MeasureCode = 'RACK'
                         ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Measure Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteMeasure]  (@IPVC_MeasureCode           varchar(6),      ---->MANDATORY : This is the upto 6 character Unique Measure Code of existing Measure                                                                                                                                           
                                                     @IPBI_UserIDSeq             bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                    )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_MeasureCode = UPPER(NullIf(ltrim(rtrim(@IPVC_MeasureCode)),'')),
          @LDT_SystemDate   = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_MeasureCode cannot be blank or null
  If (@IPVC_MeasureCode is null)
  begin
    select @LVC_CodeSection = 'Error: Measure Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_MeasureCode should not be referenced by any Product Charge irrespective of Version
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Charge C with (nolock)
             where   C.MeasureCode = @IPVC_MeasureCode
            )
  begin
    select @LVC_CodeSection = 'Error: Measure is actively referenced by atleast one product charge record. Measure cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 3: @IPVC_MeasureCode should not be referenced by any Diverse Measure for Account
  --              BL to be filled in when that piece is done down the road. 
  ------------------------------------------
  Delete M
  from   PRODUCTS.dbo.Measure M with (nolock)
  where  (M.Code =  @IPVC_MeasureCode);  
  ------------------------------------------
END--> Main End
GO
