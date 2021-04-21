SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspOMS_SW_MaintenanceInserts] 
AS
BEGIN 

--INSERT Into ORDDB.dbo.SW_Maintenance(
  INSERT Into CUSTOMERS.dbo.SW_Maintenance(
    AcctNo,History_Ind,ItemCdFrequency,ItemCd_Category,ItemCd_Supp_Cd,
    ItemCd_System,ItemCd_Media,ItemCd_Sale_Typ,ItemCd_License,ItemCd_Package,
    ItemCd_State,ItemCd_Lan_User,Next_Support_Cd,Version_Number,Serial_Number,
    SW_Order_Key,Units,Net_Amount,Chrg_Ovrd_Ind,Bus_Tax_Disc,
    Filler,Load_Period,Invoice_Pd_Ind,No_Cancel_Ind,No_Credit_Ind,
    No_Release_Ind,Cancel_Code,Update_Reason,Update_User,
    Init_Begin_DtTm,Init_End_Dt_Tm,Contract_Beg_Dt,Contract_End_Dt,
    Concurrent_User,PAR_AGREE_ID
  ) 
  Select 
    '????',' ','X','MA','X',
    'XX','PC','NW','L','??????',
    'TX','LN','X','XXXXXXXX',0,
    3,1,10.00,'N',1.00,
    'X','Load  ','Y','Y','Y',
    'X','XX','XX','XX',
    GetDate(),GetDate(),GetDate(),GetDate(),
    0,'???????'


END

--SELECT * From CUSTOMERS.dbo.SW_Maintenance

GO
