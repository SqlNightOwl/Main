SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_BillingTargetDateMappingRefresh]
-- Description     : This procedure Refreshes INVOICES.dbo.BillingTargetDateMapping table for all combinations
--                   of LeadDays based on current BillingCycle Date is Active Status. (ie Open Billing Cycle Date)
-- Input Parameters: None
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh

--Author           : SRS
--history          : Created 02/08/2010 Defect #7546

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BillingTargetDateMappingRefresh]
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  ------------------------------------
  begin try
    Insert into INVOICES.dbo.BillingTargetDateMapping(BillingCycleDate,LeadDays,TargetDate)
    select distinct B.BillingCycleDate,S.LeadDays,
                    (case when S.LeadDays =  90 then DATEADD(qq,DATEDIFF(qq,-1,B.BillingCycleDate),-1)                      --> Last Day of current  quarter for BillingCycleDate
                          when S.LeadDays = -90 then DATEADD(qq,DATEDIFF(qq,+1,B.BillingCycleDate),-1)                      --> Last Day of Previous quarter for BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays = -30
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate),0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate),0))))
                                         )                                                                                  --> Middle Day of Previous Month for BillingCycleDate 
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = -30
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate),0))                             --> Last Day of Previous Month for BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  30
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+2,0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+2,0))))
                                         )                                                                                  --> Middle Day of forward 1 Month from BillingCycleDate 
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = 30
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+2,0))                           --> Last Day of forward 1 Month from BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  60
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))
                                         )                                                                                  --> Middle Day of forward 2 Month from BillingCycleDate 
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = 60
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))                           --> Last Day of forward 2 Month from BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  -60
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)-1,0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)-1,0))))
                                         )                                                                                  --> Middle Day of previous 2 Month from BillingCycleDate 
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = -60
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)-1,0))                           --> Last Day of previous 2 Month from BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  45
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+2,0))                           --> Last Day of forward 1 Month from BillingCycleDate
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = 45
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))
                                         )                                                                                  --> Middle Day of forward 2 Month from BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  -45
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)-1,0))                            --> Last Day of Previous 2 Month from BillingCycleDate
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = -45
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate),0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate),0))))
                                         )                                                                                  --> Middle Day of Previous Month from BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  15
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+1,0))                           --> Last Day of Current Month of BillingCycleDate
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = 15
                             then convert(datetime,
                                          convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+2,0))))+
                                          '/15/'+
                                          convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+2,0))))
                                         )                                                                                  --> Middle Day of forward 1 Month from BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          when ((day(B.BillingCycleDate)= 15)) and S.LeadDays =  -15
                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate),0))                             --> Last Day of Previous Month for BillingCycleDate
                          when ((day(B.BillingCycleDate)<> 15)) and S.LeadDays = -15
                             then convert(datetime,
                                          convert(varchar(50),Month(B.BillingCycleDate))+
                                          '/15/'+
                                          convert(varchar(50),Year(B.BillingCycleDate))
                                         )                                                                                  --> Middle Day of Current Month of BillingCycleDate
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                          else (CONVERT(datetime,CONVERT(varchar(20),B.BillingCycleDate,(101)),(0))+ S.LeadDays)      --------> Else Straight function of BillingCycleDate + LeadDays
                          -------------------------------------------------------------------------------------------------------------------------------------------------------
                     end) as TargetDate
    from   INVOICES.dbo.InvoiceEOMServiceControl B with (nolock)
    cross join
           (select distinct C.LeadDays 
            from Products.dbo.Charge C with (nolock)
           ) S 
    where  B.BillingCycleClosedFlag = 0
    and not exists (select top 1 1 
                    from   INVOICES.dbo.BillingTargetDateMapping X with (nolock)
                    where  X.BillingCycleDate = B.BillingCycleDate
                    and    X.LeadDays         = S.LeadDays
                   )
  end try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingTargetDateMappingRefresh. BillingTargetDateMapping table Refresh Failed.'
    return
  end   Catch      
END --: Main Procedure END
GO
