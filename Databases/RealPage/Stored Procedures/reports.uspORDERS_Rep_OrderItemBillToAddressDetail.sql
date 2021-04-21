SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : [uspORDERS_Rep_OrderItemBillToAddressDetail]      
-- Description     : This procedure gets Billing Details based on Customer. And this is based on the Excel File NewOrdersPendingActivationsDetailbyCustomer.xls     
-- Input Parameters: Optional except @IPD_StartDate and @IPD_EndDate
-- Code Example    : 
--Exec [dbo].[uspORDERS_Rep_OrderItemBillToAddressDetail] @IPVC_CompanyID= 'C0901010086'
--Exec [dbo].[uspORDERS_Rep_OrderItemBillToAddressDetail] @IPVC_CompanyID= 'C0901000061'

-- Revision History:      
-- Author          : Naval Kishore      
-- 04-June-2010    : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_OrderItemBillToAddressDetail]       (@IPVC_CompanyID     varchar(50)  = '',
                                                                           @IPVC_CustomerName  varchar(100) = '',
                                                                           @IPC_PropertyID     varchar(50)  = '',
                                                                           @IPVC_AccountID     varchar(50)  = '',
                                                                           @IPVC_AccountName   varchar(100) = '',
                                                                           @IPVC_FamilyCode    varchar(3)   = ''																		  
                                                                          )      
As      
BEGIN -->Main BEGIN         
  Set nocount on;   
  --------------------------------------------------------------------------
  set @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  set @IPVC_CustomerName  = ltrim(rtrim(@IPVC_CustomerName))
  set @IPC_PropertyID     = nullif(@IPC_PropertyID,'')
  set @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
  set @IPVC_AccountID     = nullif(@IPVC_AccountID,'')
  set @IPVC_AccountName   = ltrim(rtrim(@IPVC_AccountName))
 ------------------------------------------------------------------------------------------------------------------------------------------------
  select  O.AccountIDSeq                         As [Account ID],
          O.CompanyIDSeq                         As [Customer ID],
          C.Name                                 As [Customer Name],
          O.PropertyIDSeq                        As [Property ID],
          PRP.Name                               As [Property Name],       
          F.Name                                 As [Family Name],
          P.DisplayName                          As [Product Name],
          OI.OrderIDSeq                          As [Order ID],
          OI.Chargetypecode                      As [Charge Type],
          OI.MeasureCode                         As [Measure],
          OI.FrequencyCode                       As [Frequency],
          OI.Netchargeamount                     As [Net Charge ($)],
          OI.NetExtYear1Chargeamount             As [Annualized Net ($)],
          (case when OG.CustomBundleNameEnabledFlag = 1 then 'CustomBundle'
                 else 'Alacarte'
          end)                                   As [Bundle Type],
          (case when OG.CustomBundleNameEnabledFlag = 1 then OG.Name
                 else ''
          end)                                    As [Bundle Name],
          (Case when OI.BilltoAddressTypeCode = 'CBT'    then 'Company Billing Address'
                when OI.BilltoAddressTypeCode = 'PBT'    then 'Property Billing Address'
                when OI.BilltoAddressTypeCode like 'PB%' then 'Additional Property Billing Address'
                when OI.BilltoAddressTypeCode like 'B0%' then 'Additional Company Billing Address'
                else 'Unknown'
          end)                                    As [Billing Type],
       Addr.AddressLine1                          As [Billing Address 1],
       coalesce(Addr.AddressLine2,'')             As [Billing Address 2],
       Addr.City				  As [Billing City],
       Addr.State				  As [Billing State],
       Addr.Zip                                   As [Billing Zip],
       Addr.Country                               As [Billing Country],
       coalesce(Addr.Email,'')                    as [Billing Email],
       DP.Name                                    as [Deliver By]
  ----------------------------------------------
  from  Orders.dbo.[Order] O with (nolock)
  inner Join
        CUSTOMERS.dbo.Company  C with (nolock)
  on    O.CompanyIdSeq = C.IDSeq 
  and   C.IDSeq        = coalesce(@IPVC_CompanyID,C.IDSeq)
  and   O.CompanyIDSeq = coalesce(@IPVC_CompanyID,O.CompanyIDSeq)
  and   O.AccountIDSeq = coalesce(@IPVC_AccountID,O.AccountIDSeq)
  and   C.Name         like '%' + @IPVC_CustomerName + '%'
  and    coalesce(O.PropertyIDSeq,'0') = coalesce(@IPC_PropertyID,coalesce(O.PropertyIDSeq,'0'))
  inner Join
        Orders.dbo.[Orderitem] OI with (nolock)
  on    O.CompanyIDSeq = C.IDSeq 
  and   O.OrderIDSeq   = OI.OrderIDSeq
  and   OI.StatusCode  = 'FULF'
  inner join
        Orders.dbo.[OrderGroup] OG with (nolock)
  on    OG.IDSeq      = OI.OrderGroupIDSeq
  and   O.Orderidseq  = OG.Orderidseq
  and   OI.Orderidseq = OG.Orderidseq
  inner Join
      Products.dbo.Product P with (nolock)
  on    OI.ProductCode = P.Code
  and   OI.PriceVersion= P.PriceVersion
  and   P.FamilyCode   = coalesce(@IPVC_FamilyCode,P.FamilyCode)
  inner join
        Products.dbo.Family F with (nolock)
  on    P.FamilyCode = F.Code
  inner join
        Customers.dbo.Address Addr with (nolock)
  on    O.CompanyIDSeq   = Addr.CompanyIDSeq
  and   C.IDSeq          = Addr.CompanyIDSeq 
  and   OI.BilltoAddressTypeCode = Addr.AddressTypeCode
  and   (
           (OI.BilltoAddressTypeCode = Addr.AddressTypeCode and 
            OI.BillToAddressTypeCode like 'PB%'             and 
            coalesce(O.PropertyIDSeq,'') = coalesce(Addr.PropertyIDSeq,'') 
           )
            OR
           (OI.BilltoAddressTypeCode = Addr.AddressTypeCode and 
            OI.BilltoAddressTypeCode NOT like 'PB%'  
           )
         )
  left outer Join Customers.dbo.DeliveryOption DP WITH (NOLOCK)   
  on    OI.BillToDeliveryOptionCode = DP.Code 
  left outer Join
        Customers.dbo.Property PRP with (nolock)
  on    O.CompanyIDSeq   = PRP.PMCIDSeq
  and   C.IDSeq          = PRP.PMCIDSeq
  and   O.PropertyIDSeq  = PRP.IDSeq
  Where (PRP.name like '%'+ @IPVC_AccountName +'%' or C.[name] like '%'+ @IPVC_AccountName +'%')
  Order by [Customer Name] ASC,[Property Name] ASC,[Family Name] ASC,[Bundle Type] ASC,
           [Product Name] ASC,[Order ID] ASC,[Charge Type] desc,[Billing Type] ASC

END -->Main END
GO
