public with sharing class RecalculatePaymentsController {
    @AuraEnabled
    public static String performRecalculation(Id caseId) {
      
         ResaleServiceRequestHandler resaleObj = ResaleServiceRequestHandler.getInstance();
         CaseService caseServiceObj = CaseService.getInstance();
         Case caseObj = caseServiceObj.getCaseById(caseId);
        
         SalesOrder__c  salesOrderObj = SalesOrderService.getInstance().getSalesOrdersById(caseObj.Sales_Order__c);
          InstallmentLineService insServiceObj = InstallmentLineService.getInstance();    
            Map<Id,Decimal> orderWiseClearedAmt = resaleObj.evaluateCustomerPaidAmount(salesOrderObj);
        
            Decimal netAmount = 0;
             if(salesOrderObj.SalesPriceExcludingADMWithDiscount__c != null 
               && salesOrderObj.SalesPriceExcludingADMWithDiscount__c>0){
               netAmount =  salesOrderObj.SalesPriceExcludingADMWithDiscount__c;
            }
            else if(salesOrderObj.Sales_Price_Excluding_ADM__c!= null 
                    && salesOrderObj.Sales_Price_Excluding_ADM__c >0
                    && (salesOrderObj.ADM_Fee_Combined__c == null ||salesOrderObj.ADM_Fee_Included__c == False)
                    ){
                        
             netAmount = salesOrderObj.Sales_Price_Excluding_ADM__c 
          + (salesOrderObj.Discount__c != null ? salesOrderObj.Discount__c : 0);
             
            }
            Decimal cleared = orderWiseClearedAmt.containsKey(salesOrderObj.Id) ? orderWiseClearedAmt.get(salesOrderObj.Id) : 0;
           
            
            Decimal percentagePaid = 0;
            Decimal resaleToCompleteAmt = 0;
            Decimal billingToCompleteAmt = 0;
            Decimal actualInstallmentDuePercent = 0;
            List<InstallmentLines__c> insDueTillDate = insServiceObj.getInstallmentLinesDueTillDateBySalesOrder(salesOrderObj.id);
          
            if(!insDueTillDate.isEmpty()){ 
                for(InstallmentLines__c line : insDueTillDate){
                    actualInstallmentDuePercent += line.InstallmentPercentage__c;
                }
            }
            Decimal resaleThreshold = salesOrderObj.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c!= null?salesOrderObj.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c:0;
            Decimal higherResaleThreshold = resaleThreshold>actualInstallmentDuePercent ? resaleThreshold : actualInstallmentDuePercent;
            System.debug('higherResaleThreshold'+higherResaleThreshold);      
            if (netAmount > 0) {
                percentagePaid = (cleared / netAmount) * 100;
                 billingToCompleteAmt =netAmount * 0.01*higherResaleThreshold;
                //billingToCompleteAmt = netAmount * 0.01*salesOrderObj.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c;
                //billingToCompleteAmt = netAmount-cleared;
           }
          
            Case caseToUpdate = new Case();
            caseToUpdate.id= caseId;
            caseToUpdate.CustomerPaidPercentage__c =percentagePaid.setScale(2); // round to 2 decimal places
            caseToUpdate.ActualInstallmentDuePercentage__c = actualInstallmentDuePercent;
            caseToUpdate.TotalCollection__c = cleared;
         
            if(percentagePaid < higherResaleThreshold){
                caseToUpdate.IsPaymentReviewRequired__c = true; 
                //Decimal resaleToCompletePercent = resaleThreshold-percentagePaid;
                Decimal resaleToCompletePercent = higherResaleThreshold-percentagePaid;
                caseToUpdate.ResaleToCompleteAmount__c = netAmount - billingToCompleteAmt;
                caseToUpdate.BillingToCompleteAmount__c = billingToCompleteAmt;
            }
            else{
                 caseToUpdate.ResaleToCompleteAmount__c = 0;
                 caseToUpdate.BillingToCompleteAmount__c = billingToCompleteAmt;
            }
             caseServiceObj.updateCase(caseToUpdate);
            return 'Payments recalculated successfully!';
         
    }
}