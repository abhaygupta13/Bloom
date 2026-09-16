/***
Class       : CaseAsyncTriggerHelper
Author      : Samiksha Mahajan
Description : 
TestClass   : CaseAsyncTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/
public without sharing class CaseAsyncTriggerHelper {
    
    public static void processApprovedCustomerTypeUpdateCases(Set<Id> caseIds) {
        
        List<Case> caseList = CaseService.getInstance().getCaseByIds(caseIds);
        List<Case> caseToUpdateList = new List<Case>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Case> customerTypeUpdateCases = new List<Case>();
        
        for (Case cs : caseList) {     
            if (cs.SubType__c == 'Customer Type Update') {                    
                cs.Status = 'Closed';
                caseToUpdateList.add(cs);
            }
            
            if (cs.AccountId != null && cs.SubType__c == 'Customer Type Update') {
                accountsToUpdate.add(new Account(Id = cs.AccountId,
                                                 CustomerType__c = cs.Customer_Type__c,
                                                 CustomerSubType__c = cs.Customer_Sub_Type__c,
                                                 CorporateWealthName__c = cs.NameofCorporate__c
                                                )
                                    );
                
                if (cs.Customer_Sub_Type__c == 'Suqur Al Watan') {
                    customerTypeUpdateCases.add(cs);
                }
            }
        }
        
        if (!caseToUpdateList.isEmpty()) {   
            CaseService.getInstance().updateCases(caseToUpdateList);    
            ServiceRequestTaskHandler.getInstance().closeAllOpenTasksOnCancel(new Set<Id>(new Map<Id, Case>(caseToUpdateList).keySet()));
        }
        
        AccountService.getInstance().updateAccounts(accountsToUpdate);
        
        if (!customerTypeUpdateCases.isEmpty()) {
            GeneralEnquirySRHandler.getInstance().syncCaseDocumentsToAccount(customerTypeUpdateCases);
        }
    }
}