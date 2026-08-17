/*Class       : installmentMilestoneUpdationCtlr
Author      : Smaartt
Description : 
TestClass   : installmentMilestoneUpdationCtlrTest
Execution   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              29/01/24           Initial Version 
****************************************************************************************************************/

public class installmentMilestoneUpdationCtlr {
 @AuraEnabled
    Public Static void Installments(string MilestoneId){
        system.debug('Milestone id'+ MilestoneId);
        set<id> insids = new set<id>();
        Map<String,ReceiptAcknowledgement__C> racmap = new  Map<String,ReceiptAcknowledgement__C>();
        List<InstallmentLines__c> InsListToBeUpdated = new List<InstallmentLines__c>();
        List<InstallmentLines__c> InsList = [Select id,PaymentInstallments__c,SalesOrder__r.Status__c,PaymentInstallments__r.Milestone__r.Milestone_Date__c, PaymentInstallments__r.Milestone__C from InstallmentLines__c
                                             where PaymentInstallments__r.Milestone__C =: MilestoneId AND SalesOrder__r.Status__c ='Sold'];
        for(InstallmentLines__c Ins : InsList){
           Ins.Milestone__c = id.valueof(MilestoneId);
            InsListToBeUpdated.add(Ins);
            insids.add(ins.id);
        }
        try
        {
            If(InsListToBeUpdated.size() > 0){
              update InsListToBeUpdated;   
            }
           
        }
        catch(DmlException e){
            throw new AuraHandledException(e.getMessage());
        }
                 List<ReceiptAllocation__c> Raclist = [select id,InstallmentLine__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.New_Maturity_Date__c,InstallmentLine__r.PaymentInstallments__r.Milestone__r.Milestone_Date__c
                                                  from ReceiptAllocation__c where InstallmentLine__c  =:insids ];
            
            for(ReceiptAllocation__c RAC : Raclist){
                
                
                    ReceiptAcknowledgement__C rak = new  ReceiptAcknowledgement__C();
                    rak.Id = RAC.ReceiptAcknowledgement__c;
                    rak.Milestone__c = RAC.InstallmentLine__r.PaymentInstallments__r.Milestone__C;
                    if(!racmap.containskey(rak.id)){
                        racmap.put(rak.Id,rak);
                    
                                    }               
            }
         If(racmap.values().size()>0){
                    Update racmap.values();
                }
        
    }
    
}