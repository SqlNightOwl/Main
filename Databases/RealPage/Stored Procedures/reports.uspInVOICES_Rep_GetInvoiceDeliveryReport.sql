SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspInVOICES_Rep_GetInvoiceDeliveryReport
-- Description     : Gets Invoice Delivery Report
-- Input Parameters: @IPDT_BillingCycleDate 
--                   
-- OUTPUT          : Result set for Report
-- Code Example    : 
/*
-------------------------------------------------------------------
---SCENARIO 1 : For Lanvera OutBound
--Step 1 :To construct the main Gigantic XML for all Invoices.
          BM Calls EXEC INVOICES.dbo.uspINVOICES_GetInvoiceXMLResults  
                                                               @IPVC_DeliveryOptionCode = 'Lanvera'
                                                              ,@IPVC_BusinessUnit               = '' 

--Step 2: For constructing the final XML section for <BatchTotals></BatchTotals> , BM will call the proc below like this passing Billingcycle date
Exec INVOICES.dbo.[uspInVOICES_Rep_GetInvoiceDeliveryReport]   @IPDT_BillingCycleDate            = '06/15/2011' --> This is Billing CycleDate. BM knows this.
                                                               ,@IPVC_ResultSetReturnType        = 'XML' --> When called from billing Manager program
                                                               ,@IPVC_OutBoundDeliveryOptionCode = 'Lanvera'
                                                               ,@IPVC_BusinessUnit               = ''
-------------------------------------------------------------------
--SCENARIO 2 :For SSRS or UI report, the UI or SSRS will call the same proc below like this passing Billingcycle date as parameter
Exec INVOICES.dbo.[uspInVOICES_Rep_GetInvoiceDeliveryReport]   @IPDT_BillingCycleDate    = '06/15/2011'  --> This is Billing CycleDate. BM knows this.
                                                               ,@IPVC_ResultSetReturnType = 'RECORDSET' --> When called from SSRS report 
                                                               ,@IPVC_OutBoundDeliveryOptionCode = 'ALL'
                                                               ,@IPVC_BusinessUnit               = ''
-------------------------------------------------------------------
--SCENARIO 3 : For OPSEI OutBound
BM Already maintains a distinct collection of BusinessUnits and uses that to build Business Unit Specific XMLs.

--Step 1 :To construct the main Gigantic XML for OPSEI qualified Invoices for each BusinessUnit
          BM Calls EXEC INVOICES.dbo.uspINVOICES_GetInvoiceXMLResults  @IPVC_DeliveryOptionCode = 'OPSEI'
                                                                       ,@IPVC_BusinessUnit       = {BusinessUnit}
--Step 2 : BM will call uspInVOICES_Rep_GetInvoiceDeliveryReport proc (Eg below) for the BusinessUnit

BM Already maintains a distinct collection of BusinessUnits and uses that to build Business Unit Specific XMLs.
such as Velocity_datetimestamp.xml,RealPage_datetimestamp.xml,OpsTech_datetimestamp.xml,eREI_datetimestamp.xml etc
Invoices that has OPSEI delivery option Invoices and markasprintflag=0 for the billingcycle will qualify for OPSEI BusinessUnit XML
--For each distinct BusinessUnit when BM builds the  Business Unit Specific XML for constructing final XML section for <BatchTotals></BatchTotals>, BM will then call the same proc below like this eg
Exec INVOICES.dbo.[uspInVOICES_Rep_GetInvoiceDeliveryReport]   @IPDT_BillingCycleDate            = '06/15/2011'  --> This is Billing CycleDate. BM knows this.
                                                               ,@IPVC_ResultSetReturnType        = 'XML'         --> When called from billing Manager program
                                                               ,@IPVC_OutBoundDeliveryOptionCode = 'OPSEI'       --This is for OPSEI OutBound
                                                               ,@IPVC_BusinessUnit               = 'Realpage'    --If business unit is Realpage

Exec INVOICES.dbo.[uspInVOICES_Rep_GetInvoiceDeliveryReport]   @IPDT_BillingCycleDate            = '06/15/2011' --> This is Billing CycleDate. BM knows this.
                                                               ,@IPVC_ResultSetReturnType        = 'XML'        --> When called from billing Manager program
                                                               ,@IPVC_OutBoundDeliveryOptionCode = 'OPSEI'      --This is for OPSEI OutBound
                                                               ,@IPVC_BusinessUnit               = 'eREI'       --If business unit is eREI

Exec INVOICES.dbo.[uspInVOICES_Rep_GetInvoiceDeliveryReport]   @IPDT_BillingCycleDate            = '06/15/2011' --> This is Billing CycleDate. BM knows this.
                                                               ,@IPVC_ResultSetReturnType        = 'XML'        --> When called from billing Manager program
                                                               ,@IPVC_OutBoundDeliveryOptionCode = 'OPSEI'      --This is for OPSEI OutBound
                                                               ,@IPVC_BusinessUnit               = 'OpsTech'    --If business unit is OpsTech

Exec INVOICES.dbo.[uspInVOICES_Rep_GetInvoiceDeliveryReport]   @IPDT_BillingCycleDate            = '06/15/2011' --> This is Billing CycleDate. BM knows this.
                                                               ,@IPVC_ResultSetReturnType        = 'XML'        --> When called from billing Manager program
                                                               ,@IPVC_OutBoundDeliveryOptionCode = 'OPSEI'      --This is for OPSEI OutBound
                                                               ,@IPVC_BusinessUnit               = 'Velocity'   --If business unit is Velocity
etc etc for other businessunits.

-------------------------------------------------------------------
*/
---Return values : 
/*
--Scenario 1: when Input parameter from BM is @IPVC_ResultSetReturnType = 'XML'
<BatchTotals>
  <row>
    <BusinessUnit>Grand Total</BusinessUnit>
    <MethodOfDelivery></MethodOfDelivery>
    <LanveraMethodOfDelivery></LanveraMethodOfDelivery>
    <InvoiceCount>30836</InvoiceCount>
    <InvoiceTotal>12217043.2900</InvoiceTotal>
    <Comments></Comments>
  </row>
  <row>
    <BusinessUnit>ALWizard</BusinessUnit>
    <MethodOfDelivery>Email</MethodOfDelivery>
    <LanveraMethodOfDelivery>Email</LanveraMethodOfDelivery>
    <InvoiceCount>26</InvoiceCount>
    <InvoiceTotal>9396.2000</InvoiceTotal>
    <Comments>Lanvera will Email these invoices to client and also revert back with PDF to be available in OMS and DockLink.</Comments>
  </row>
  ....
<BatchTotals>

--Scenario 2: when Input parameter from SSRS is @IPVC_ResultSetReturnType = 'RECORDSET'
Resultset with below columns 
BusinessUnit,MethodOfDelivery,LanveraMethodOfDelivery,InvoiceCount,InvoiceTotal,Comments
*/
--                                                             
-- Revision History:
-- Author          : srs
-- 07/08/2011      : Stored Procedure Created.
-- 09/20/2011      : TFS 321 Enhancement
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspInVOICES_Rep_GetInvoiceDeliveryReport](@IPDT_BillingCycleDate            datetime,                ----> Mandatory: This is Billingcycle Date.
                                                                                                                             ----  Billing Manager knows what Billing Cycle Date it is processing. Hence BM will pass this.
                                                                  @IPVC_ResultSetReturnType         varchar(100) = 'XML',    ----> Mandatory: This is the Resultset return type.
                                                                                                                             ----   For Billing Manager, this @IPVC_ResultSetReturnType passed in as XML so that this proc will return an XML
                                                                                                                             ----   For SSRS Reports, this @IPVC_ResultSetReturnType passed in as RECORDSET, so that proc will return an resultset
                                                                  @IPVC_OutBoundDeliveryOptionCode  varchar(50)  ='Lanvera', ----> Mandatory : This is the Intended Delivery to which Billing Manager delivers.
                                                                                                                             ---->  Currently the 2 possible values are LANVERA for which Lanvera_Datetimestamp.xml is generated as Outbound.
                                                                                                                             ----   OPSEI  for which XML for each BusinessUnit that has only OPSEI delivery option Invoices XML is generated as outbound.
                                                                                                                             ----    Eg: Velocity_datetimestamp.xml,RealPage_datetimestamp.xml,OpsTech_datetimestamp.xml,eREI_datetimestamp.xml
                                                                  @IPVC_BusinessUnit                varchar(255) =''         ----> This is BusinessUnit. 
                                                                                                                             -----  For Lanvera DeliveryOption, this is defaulted to blank. 
                                                                                                                             -----  For OPSEI  DeliveryOption, BM will pass BusinessUnit such as Realpage or Velocity or OpsTech or eREI
                                                                                                                             ----   ie. For each distinct Business unit outbound xml operation of BM
                
                                                                  )
AS
BEGIN 
  set nocount on;  
  ---------------------------------------------------
  ---Variable intitialization
  select @IPVC_BusinessUnit               = nullif(ltrim(rtrim(@IPVC_BusinessUnit)),'');
  select @IPVC_OutBoundDeliveryOptionCode = coalesce(nullif(ltrim(rtrim(@IPVC_OutBoundDeliveryOptionCode)),''),'');

  if (@IPVC_OutBoundDeliveryOptionCode ='LANVERA' or 
      @IPVC_OutBoundDeliveryOptionCode = 'ALL'    or 
      @IPVC_OutBoundDeliveryOptionCode = ''
     )
  begin
    --BM will pass LANVERA when Outbound is for Lanvera.
    --UI or SSRS will pass as ALL 
    select @IPVC_OutBoundDeliveryOptionCode = 'LANVERA';
    select @IPVC_BusinessUnit = NULL;    
  end
  else
  begin
    --BM will pass OPSEI when OutBound Delivery is Not for Lanvera
    select @IPVC_OutBoundDeliveryOptionCode = nullif(ltrim(rtrim(@IPVC_OutBoundDeliveryOptionCode)),'');
    select @IPVC_BusinessUnit               = nullif(ltrim(rtrim(@IPVC_BusinessUnit)),'');
  end;
  ---------------------------------------------------
  if (@IPVC_ResultSetReturnType = 'XML')
  begin
    ;with IXML_CTE(InvoiceIDSeq,BusinessUnit,InvoiceTotalAmount,BillToDeliveryOptionCode,MethodOfDelivery,LanveraMethodOfDelivery,Comments,PrePaidFlag,MarkAsPrintedFlag)
    as (Select I.InvoiceIDSeq                                               as InvoiceIDSeq
               ,IXML.BusinessUnit                                           as BusinessUnit
               ,IXML.InvoiceTotal                                           as InvoiceTotalAmount
               ,I.BillToDeliveryOptionCode                                  as BillToDeliveryOptionCode
               ,(Case when I.PrePaidFlag      = 1 
                       then 'NO Delivery.' 
                      when I.MarkAsPrintedFlag = 1 
                       then 'NO Delivery.'
                      else DO.Name
                end)                                                       as MethodOfDelivery
               ,(Case when I.PrePaidFlag      = 1 
                       then 'PDFOnly' 
                      when I.MarkAsPrintedFlag = 1 
                       then 'PDFOnly'
                      when DO.Code = 'EMAIL' 
                       then DO.Name
                      when DO.Code = 'SMAIL' 
                       then DO.Name
                      else 'PDFOnly'
                end)                                                       as LanveraMethodOfDelivery
               ,(Case when I.PrePaidFlag      = 1 
                       then 'Lanvera to NOT DELIVER these Sub Total: invoices to client but revert back with PDF to be available in OMS and DockLink. PrePaid Instant Invoice.' 
                      when I.MarkAsPrintedFlag = 1 
                       then 'Lanvera to NOT DELIVER these Sub Total: invoices to client but revert back with PDF to be available in OMS and DockLink. Payment Transaction(s) Invoice.'
                      when DO.Code = 'EMAIL' 
                       then 'Lanvera to EMAIL these Sub Total: invoices to client and also revert back with PDF to be available in OMS and DockLink.'
                      when DO.Code = 'SMAIL' 
                       then 'Lanvera to SNAIL MAIL these Sub Total: invoices to client and also revert back with PDF to be available in OMS and DockLink.'
                       else
                            'Lanvera to NOT DELIVER these Sub Total: invoices to client but revert back with PDF to be available in OMS and DockLink.' +
                            ' Realpage will internally post to ' + DO.Name +'.'
                end)                                                        as Comments             
               ,I.PrePaidFlag                                               as PrePaidFlag
               ,I.MarkAsPrintedFlag                                         as MarkAsPrintedFlag           
        from  Invoices.dbo.Invoice    I    with (nolock)
        inner join
              Invoices.dbo.InvoiceXML IXML with (nolock)
        on    I.InvoiceIDSeq        = IXML.InvoiceIDSeq        
        and   I.BillingCycleDate    = IXML.BillingCycleDate
        and   I.BillingCycleDate    = @IPDT_BillingCycleDate
        and   IXML.BillingCycleDate = @IPDT_BillingCycleDate
        and   I.Printflag           = 1
        inner join
              CUSTOMERS.dbo.DeliveryOption DO with (nolock)
        on    I.BillToDeliveryOptionCode = DO.Code
        where I.BillingCycleDate    = @IPDT_BillingCycleDate
        and   IXML.BillingCycleDate = @IPDT_BillingCycleDate
        and   I.Printflag           = 1
        and   (
                 (@IPVC_OutBoundDeliveryOptionCode='Lanvera')
                    OR
                 (@IPVC_OutBoundDeliveryOptionCode = 'OPSEI' 
                    AND
                  I.MarkAsPrintedFlag        = 0
                    AND 
                  I.BillToDeliveryOptionCode = @IPVC_OutBoundDeliveryOptionCode
                 )
              )
        )
    select  
            (case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then 'Grand Total'
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then 'Sub Total'
                  else IXML_CTE.BusinessUnit
             end)                                     as BusinessUnit
           ,(case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then ''
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then ''
                  else IXML_CTE.MethodOfDelivery
             end)                                     as MethodOfDelivery
           ,(case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then ''
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then IXML_CTE.LanveraMethodOfDelivery
                  else IXML_CTE.LanveraMethodOfDelivery
             end)                                     as LanveraMethodOfDelivery             
           ,count(1)                                  as InvoiceCount
           ,sum(IXML_CTE.InvoiceTotalAmount)          as InvoiceTotal
           ,(case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then 'Lanvera to process Grand Total:'+ convert(varchar(255),count(1))+ ' Invoice(s) for Billing Cycle ' + convert(varchar(50),@IPDT_BillingCycleDate,101) + '.'
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then replace(Max(IXML_CTE.Comments),'Sub Total:','Sub Total:' + convert(varchar(255),count(1)))
                  else replace(Max(IXML_CTE.Comments),'Sub Total:',convert(varchar(255),count(1))+ ' '+ IXML_CTE.BusinessUnit)
             end)                                     as Comments
    from   IXML_CTE IXML_CTE
    group by IXML_CTE.BusinessUnit,IXML_CTE.MethodOfDelivery,IXML_CTE.LanveraMethodOfDelivery
    WITH CUBE
    having (
            (GROUPING(IXML_CTE.BusinessUnit) = 0 and GROUPING(IXML_CTE.MethodOfDelivery) = 0 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0 )
               OR
            (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
               OR  
            (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
           )
    order by IXML_CTE.BusinessUnit asc,IXML_CTE.MethodOfDelivery,IXML_CTE.LanveraMethodOfDelivery
    FOR XML PATH('row'), ROOT('BatchTotals');
    return;
  end
  ---------------------------------------------------
  else
  begin
    ;with IXML_CTE(InvoiceIDSeq,BusinessUnit,InvoiceTotalAmount,BillToDeliveryOptionCode,MethodOfDelivery,LanveraMethodOfDelivery,Comments,PrePaidFlag,MarkAsPrintedFlag)
    as (Select I.InvoiceIDSeq                                               as InvoiceIDSeq
               ,IXML.BusinessUnit                                           as BusinessUnit
               ,IXML.InvoiceTotal                                           as InvoiceTotalAmount
               ,I.BillToDeliveryOptionCode                                  as BillToDeliveryOptionCode
               ,(Case when I.PrePaidFlag      = 1 
                       then 'NO Delivery.' 
                      when I.MarkAsPrintedFlag = 1 
                       then 'NO Delivery.'
                      else DO.Name
                end)                                                       as MethodOfDelivery
               ,(Case when I.PrePaidFlag      = 1 
                       then 'PDFOnly' 
                      when I.MarkAsPrintedFlag = 1 
                       then 'PDFOnly'
                      when DO.Code = 'EMAIL' 
                       then DO.Name
                      when DO.Code = 'SMAIL' 
                       then DO.Name
                      else 'PDFOnly'
                end)                                                       as LanveraMethodOfDelivery
               ,(Case when I.PrePaidFlag      = 1 
                       then 'Lanvera to NOT DELIVER these Sub Total: invoices to client but revert back with PDF to be available in OMS and DockLink. PrePaid Instant Invoice.' 
                      when I.MarkAsPrintedFlag = 1 
                       then 'Lanvera to NOT DELIVER these Sub Total: invoices to client but revert back with PDF to be available in OMS and DockLink. Payment Transaction(s) Invoice.'
                      when DO.Code = 'EMAIL' 
                       then 'Lanvera to EMAIL these Sub Total: invoices to client and also revert back with PDF to be available in OMS and DockLink.'
                      when DO.Code = 'SMAIL' 
                       then 'Lanvera to SNAIL MAIL these Sub Total: invoices to client and also revert back with PDF to be available in OMS and DockLink.'
                       else
                            'Lanvera to NOT DELIVER these Sub Total: invoices to client but revert back with PDF to be available in OMS and DockLink.' +
                            ' Realpage will internally post to ' + DO.Name +'.'
                end)                                                        as Comments             
               ,I.PrePaidFlag                                               as PrePaidFlag
               ,I.MarkAsPrintedFlag                                         as MarkAsPrintedFlag           
        from  Invoices.dbo.Invoice    I    with (nolock)
        inner join
              Invoices.dbo.InvoiceXML IXML with (nolock)
        on    I.InvoiceIDSeq        = IXML.InvoiceIDSeq        
        and   I.BillingCycleDate    = IXML.BillingCycleDate
        and   I.BillingCycleDate    = @IPDT_BillingCycleDate
        and   IXML.BillingCycleDate = @IPDT_BillingCycleDate
        and   I.Printflag           = 1
        inner join
              CUSTOMERS.dbo.DeliveryOption DO with (nolock)
        on    I.BillToDeliveryOptionCode = DO.Code
        where I.BillingCycleDate    = @IPDT_BillingCycleDate
        and   IXML.BillingCycleDate = @IPDT_BillingCycleDate
        and   I.Printflag           = 1
        and   (
                 (@IPVC_OutBoundDeliveryOptionCode='Lanvera')
                    OR
                 (@IPVC_OutBoundDeliveryOptionCode = 'OPSEI' 
                    AND
                  I.MarkAsPrintedFlag        = 0
                    AND 
                  I.BillToDeliveryOptionCode = @IPVC_OutBoundDeliveryOptionCode
                 )
              )
        )
    select  
            (case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then 'Grand Total'
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then 'Sub Total'
                  else IXML_CTE.BusinessUnit
             end)                                     as BusinessUnit
           ,(case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then ''
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then ''
                  else IXML_CTE.MethodOfDelivery
             end)                                     as MethodOfDelivery
           ,(case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then ''
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then IXML_CTE.LanveraMethodOfDelivery
                  else IXML_CTE.LanveraMethodOfDelivery
             end)                                     as LanveraMethodOfDelivery             
           ,count(1)                                  as InvoiceCount
           ,sum(IXML_CTE.InvoiceTotalAmount)          as InvoiceTotal
           ,(case when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
                    then 'Lanvera to process Grand Total:'+ convert(varchar(255),count(1))+ ' Invoice(s) for Billing Cycle ' + convert(varchar(50),@IPDT_BillingCycleDate,101) + '.'
                  when (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
                    then replace(Max(IXML_CTE.Comments),'Sub Total:','Sub Total:' + convert(varchar(255),count(1)))
                  else replace(Max(IXML_CTE.Comments),'Sub Total:',convert(varchar(255),count(1))+ ' '+ IXML_CTE.BusinessUnit)
             end)                                     as Comments
    from   IXML_CTE IXML_CTE
    group by IXML_CTE.BusinessUnit,IXML_CTE.MethodOfDelivery,IXML_CTE.LanveraMethodOfDelivery
    WITH CUBE
    having (
            (GROUPING(IXML_CTE.BusinessUnit) = 0 and GROUPING(IXML_CTE.MethodOfDelivery) = 0 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0 )
               OR
            (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=0)
               OR  
            (GROUPING(IXML_CTE.BusinessUnit) = 1 and GROUPING(IXML_CTE.MethodOfDelivery) = 1 and GROUPING(IXML_CTE.LanveraMethodOfDelivery)=1)
           )
    order by IXML_CTE.BusinessUnit asc,IXML_CTE.MethodOfDelivery,IXML_CTE.LanveraMethodOfDelivery    
    return;
  end
END
GO
