/*****************************************************************************************
Class       : CaseService
Author      : Sonali
Description : Case service class
test Class: CaseServiceTest
Created Date: 26 Feb 2025
*****************************************************************************************/
public inherited sharing  class CaseInstallmentService { 
    
    private static CaseInstallmentService instance;
    
    private CaseInstallmentService() {
        
    }
    
    public static CaseInstallmentService getInstance() { 
        if(instance == null) {
            instance = new CaseInstallmentService();
        }
        return instance;
    }
    public List<CaseInstallment__c> getCaseInstallments(Id caseId) { 
        return [SELECT Id, NewInstallmentDate__c,InstallmentDate__c 
                FROM CaseInstallment__c 
                WHERE Case__c = :caseId 
                AND NewInstallmentDate__c != NULL];
    }
    public List<CaseInstallment__c> updateCaseInstallments(List<CaseInstallment__c> caseInsList){ 
        if(caseInsList != NULL && !caseInsList.isEmpty()){
            update caseInsList;
        }
        return caseInsList; 
    }   
     public List<CaseInstallment__c> insertCaseInstallments(List<CaseInstallment__c> caseInsList){
        if(caseInsList != NULL && !caseInsList.isEmpty()){
            insert caseInsList;
        }
        return caseInsList;
    }
    
}