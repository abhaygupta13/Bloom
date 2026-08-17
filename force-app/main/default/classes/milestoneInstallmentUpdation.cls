/***
Class       : milestoneInstallmentUpdation
Author      : Smaartt
Description : 
TestClass   : milestoneInstallmentUpdationTest
Execution   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              31/01/24           Initial Version 
****************************************************************************************************************/
public class milestoneInstallmentUpdation {
    public Static Void installmentReviseddateUpdation(List<Milestone__c> mlist){
        set<id> Mids = new set<id>();
        set<id> insids = new set<id>();
        list<ReceiptAcknowledgement__C> Raklist = new list<ReceiptAcknowledgement__C>();
        List<String> toAddressesofcustomer = new List<String>();
        List<String> phonenumberofcustomer = new List<String>();
        List<SMSTransaction__c> SmsList = new List<SMSTransaction__c>();
        Map<String,ReceiptAcknowledgement__C> racmap = new  Map<String,ReceiptAcknowledgement__C>();
        for (Milestone__c milestone : mlist) {
            if(milestone.Milestone_Status__c == 'Delayed'){
                Mids.add(milestone.Id);         
            }          
        }
        List<InstallmentLines__c> inslist = [Select id,SalesOrder__r.Account__r.Formatted_Mobile_Number__c,SalesOrder__r.Account__r.PersonMobilePhone,SalesOrder__r.Account__r.PersonEmail,PaymentInstallments__c,PaymentInstallments__r.Milestone__r.Milestone_Date__c, PaymentInstallments__r.Milestone__C from InstallmentLines__c where PaymentInstallments__r.Milestone__C =:Mids];
        
        for(InstallmentLines__c ins : inslist){
            ins.RevisedDate__c = ins.PaymentInstallments__r.Milestone__r.Milestone_Date__c;
            if (ins.SalesOrder__r.Account__r.PersonEmail != null) {
                toAddressesofcustomer.add(String.valueof(ins.SalesOrder__r.Account__r.PersonEmail));
                
            }
            if(ins.SalesOrder__r.Account__r.PersonMobilePhone != null){
                phonenumberofcustomer.add(string.valueof(ins.SalesOrder__r.Account__r.Formatted_Mobile_Number__c));
            }
            insids.add(ins.id);
            
           
                SMSTransaction__c sm = new SMSTransaction__c();
                sm.Phone_Number__c = ins.SalesOrder__r.Account__r.Formatted_Mobile_Number__c;
                sm.Account__c = ins.SalesOrder__r.Account__c;
                sm.Message__c = 'Test Message, Please Ignore';
                SmsList.add(sm);
            
        }
        if(inslist.size()>0){
            
            Update inslist;
            List<String> toAddresses = new List<String>();
            String emailTemplateLabel = System.Label.milestoneDelayedEmailTemplate;
            
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName=:emailTemplateLabel];
            
            toAddresses.addAll(Utilities.getUsersInPublicGroup(System.Label.Finance_Group));
            toAddresses.addAll(Utilities.getUsersInPublicGroup(System.Label.Operations_Team));
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemplate.Id);
            mail.setToAddresses(toAddresses);
            mail.setSaveAsActivity(true);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setTargetObjectId(userinfo.getUserId());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if (!toAddressesOfCustomer.isEmpty()) {
             
                system.debug(toAddressesOfCustomer);
                String emailTemplateCustomerLabel = System.Label.milestoneDelayedEmailTemplate;
                
                EmailTemplate emailTemplateCustomer = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName=:emailTemplateCustomerLabel];
                
                
                Messaging.SingleEmailMessage Customermail = new Messaging.SingleEmailMessage();
                Customermail.setTemplateId(emailTemplateCustomer.Id);
                Customermail.setToAddresses(toAddressesofcustomer);
                Customermail.setSaveAsActivity(true);
                Customermail.setTreatTargetObjectAsRecipient(false);
                Customermail.setTargetObjectId(userinfo.getUserId());
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { Customermail });
            }
            if(SmsList.size()>0){
            Insert SmsList;
            }
            List<ReceiptAllocation__c> Raclist = [select id,InstallmentLine__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.New_Maturity_Date__c,InstallmentLine__r.PaymentInstallments__r.Milestone__r.Milestone_Date__c
                                                  from ReceiptAllocation__c where InstallmentLine__c  =:insids ];
            
            for(ReceiptAllocation__c RAC : Raclist){
                
                if(RAC.ReceiptAcknowledgement__r.MaturityDate__c > RAC.InstallmentLine__r.PaymentInstallments__r.Milestone__r.Milestone_Date__c && RAC.ReceiptAcknowledgement__r.Status__c == 'Received'){
                    ReceiptAcknowledgement__C rak = new  ReceiptAcknowledgement__C();
                    rak.Id = RAC.ReceiptAcknowledgement__c;
                    rak.New_Maturity_Date__c = RAC.InstallmentLine__r.PaymentInstallments__r.Milestone__r.Milestone_Date__c;
                    if(!racmap.containskey(rak.id)){
                        racmap.put(rak.Id,rak);
                    }
                    
                }
                If(racmap.values().size()>0){
                    Update racmap.values();
                }
            }
        }
        
        
    }
}