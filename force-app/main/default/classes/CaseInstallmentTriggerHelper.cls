/*
* @Author : Sonali Sengar
* @CreatedDate : 15th April 2025
* @Description : Case Installment trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment
* 1.0           Sonali    	   15APR2025
*****************************************************************************************************/

public class CaseInstallmentTriggerHelper {
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    
public static void handleAfterUpdate(List<CaseInstallment__c> newList, Map<Id, CaseInstallment__c> oldMap) {
    if (newList.isEmpty()) return;

    // Collect all related Case IDs
    Set<Id> caseIds = new Set<Id>();
    for (CaseInstallment__c ci : newList) {
        if (ci.Case__c != null) {
            caseIds.add(ci.Case__c);
        }
    }

    if (caseIds.isEmpty()) return;

    // Get the RecordTypeId for Post-Sale Payment Deferral
    Id postSalePaymentDeferralRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, POST_SALE_PAYMENT_DEFERRAL_RT);

    // Retrieve related Cases
    CaseService caseService = CaseService.getInstance();
    Map<Id, Case> caseMap = new Map<Id, Case>(caseService.getCaseByIds(caseIds));

    List<Case> casesToUpdate = new List<Case>();

    for (CaseInstallment__c newCI : newList) {
        CaseInstallment__c oldCI = oldMap.get(newCI.Id);
        if (oldCI == null) continue;

        Case relatedCase = caseMap.get(newCI.Case__c);
        if (relatedCase == null || relatedCase.RecordTypeId != postSalePaymentDeferralRTId) continue;

        // Check if NewInstallmentDate changed
        if (oldCI.NewInstallmentDate__c == newCI.NewInstallmentDate__c) continue;

        String deferralStatus = '';

        if (newCI.NewInstallmentDate__c != null && newCI.InstallmentDate__c != null) {
            Integer deferralDays = newCI.InstallmentDate__c.daysBetween(newCI.NewInstallmentDate__c);
            deferralStatus = (deferralDays > 31) ? 'No' : 'Yes';
        }

        casesToUpdate.add(new Case(
            Id = newCI.Case__c,
            Deferral_Within_1_Month__c = deferralStatus
        ));
    }

    if (!casesToUpdate.isEmpty()) {
        caseService.updateCaseWithoutTrigger(casesToUpdate);
    }
}


}