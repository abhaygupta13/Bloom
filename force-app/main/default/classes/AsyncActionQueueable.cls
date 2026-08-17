/***
Class       : AsyncActionQueueable
Author      : Biswajeet
Description : 
TestClass   : AsyncActionQueueableTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/
public class AsyncActionQueueable implements Queueable {
    
    private String processName;
    private List<sObject> objectList;
    
    public AsyncActionQueueable(String processName, List<sObject> objectList) {
        this.processName = processName;
        this.objectList = objectList;
    }
    
    public void execute(QueueableContext context) {
        if(this.processName == 'UPDATE_PAYMENT_INSTALLMENT_WITHOUT_TRIGGER'){
            List<PaymentInstallments__c> installments = new List<PaymentInstallments__c>();
            for (SObject sob : objectList) {
                installments.add((PaymentInstallments__c)sob);
            }
            PaymentInstallmentService.getInstance().updatePaymentInstallmentWithoutTrigger(installments);
        }
    }
}