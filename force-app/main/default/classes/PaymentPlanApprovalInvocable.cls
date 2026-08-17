global class PaymentPlanApprovalInvocable {

    @InvocableMethod(label='Reset Revised Date Updated Flag')
    public static void resetCheckbox(List<Id> paymentPlanIds){

        if(paymentPlanIds == null || paymentPlanIds.isEmpty()){
            return;
        }

        List<PaymentInstallments__c> installmentsToUpdate = [
            SELECT Id,
                   RevisedDateUpdated__c
            FROM PaymentInstallments__c
            WHERE PaymentPlan__c IN :paymentPlanIds
            AND RevisedDateUpdated__c = true
        ];

        if(installmentsToUpdate.isEmpty()){
            return;
        }

        for(PaymentInstallments__c installment : installmentsToUpdate){

            installment.RevisedDateUpdated__c = false;
        }

        update installmentsToUpdate;
    }
}