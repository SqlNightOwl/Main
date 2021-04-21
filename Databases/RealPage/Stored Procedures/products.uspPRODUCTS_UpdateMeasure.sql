SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_UpdateMeasure
-- Description     : This proc is called by Product Administration Measure Management to Update Existing Measures
-- Input Parameters: @IPVC_MeasureCode,@IPVC_MeasureName,@IPI_DisplayFlag
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_UpdateMeasure 
                       @IPVC_MeasureCode = 'RACK'  --> This is the existing Measurecode 
                      ,@IPVC_MeasureName = 'Rack1' --> This is the new updated MeasureName
                      ,@IPBI_UserIDSeq    = 76
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Measure Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_UpdateMeasure]  (@IPVC_MeasureCode           varchar(6),      ---->MANDATORY : This is the upto 6 character Unique Measure Code of existing Measure
                                                     @IPVC_MeasureName           varchar(20),     ---->MANDATORY : This is new Measure Name for the existing measure                                                      
                                                     @IPBI_UserIDSeq             bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                   )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_MeasureCode = UPPER(NullIf(ltrim(rtrim(@IPVC_MeasureCode)),'')),
          @IPVC_MeasureName = NullIf(ltrim(rtrim(@IPVC_MeasureName)),''),
          @LDT_SystemDate   = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_MeasureCode or @IPVC_MeasureName cannot be blank or null
  If (@IPVC_MeasureCode is null)
  begin
    select @LVC_CodeSection = 'Error: Measure Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  If (@IPVC_MeasureName is null)
  begin
    select @LVC_CodeSection = 'Error: Measure Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 2: @IPVC_MeasureName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Measure M with (nolock)
             where   (M.Name =  @IPVC_MeasureName)
             and     (M.Code <> @IPVC_MeasureCode)   
            )
  begin
    select @LVC_CodeSection = 'Error: Measure Name already exists for a different Measure Code in the system. Measure Name should be unique.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Measure M with (nolock)
             where   (M.Code =  @IPVC_MeasureCode) 
             and     (M.Name <> @IPVC_MeasureName)
            )
  begin
    Update M
    set    M.Name            = @IPVC_MeasureName
          ,M.ModifiedByIdSeq = @IPBI_UserIDSeq
          ,M.ModifiedDate    = @LDT_SystemDate 
          ,M.SystemLogDate   = @LDT_SystemDate
    from  PRODUCTS.dbo.Measure M with (nolock)
    where (M.Code =  @IPVC_MeasureCode) 
    and   (M.Name <> @IPVC_MeasureName)
  end
  ------------------------------------------
END--> Main End
GO
