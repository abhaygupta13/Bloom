/*****************************************************************************************
Class       : VerificationController
Author      : Biswajeet 
Description : 
testClass   : VerificationControllerTest
Created Date: 15 Oct 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             15Oct2024           Initial Version 
*****************************************************************************************/
public class VerificationController {
    
    @AuraEnabled
    public static void verifyRecord(Id recordId){
        try{
            if(String.isNotBlank(recordId)){
                if(recordId.getSObjectType() == ReceiptAcknowledgement__c.getSObjectType()){
                    ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
                    ReceiptAcknowledgement__c objReceiptAcknowledgement = new ReceiptAcknowledgement__c(Id = recordId, Finance_Verified__c = true, VerifyBy__c = UserInfo.getUserId(), VerifyDate__c = System.Today());
                    objReceiptAcknowledgementService.updateReceiptAcknowledgement(objReceiptAcknowledgement);
                }
                else if(recordId.getSObjectType() == BrokerCommission__c.getSObjectType()){
                    BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
                    BrokerCommission__c broker = new BrokerCommission__c(Id = recordId, InvoiceVerified__c = true, VerifiedBy__c = UserInfo.getUserId(), VerifiedDate__c = Datetime.now());
                    objBrokerCommissionServ.updateBrokerCommissions(new List<BrokerCommission__c>{broker});
                }

            }
        }catch(System.exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
}