/*****************************************************************************************
Class       : CaseAssignmentHistoryService
Author      : Sonali
Description : Case assignment history service class
test Class: CaseAssignmentHistoryServiceTest
Created Date: 19 March 2025
*****************************************************************************************/
public inherited sharing  class CaseAssignmentHistoryService {   
    
    private static CaseAssignmentHistoryService instance;
    
    private CaseAssignmentHistoryService() {
        
    }
    
    public static CaseAssignmentHistoryService getInstance() { 
        if(instance == null) {
            instance = new CaseAssignmentHistoryService();
        }
        return instance;
    }
    public List<CaseAssignmentHistory__c> updateCaseAssignmentHistory(List<CaseAssignmentHistory__c> historyList){ 
        if(historyList != NULL && !historyList.isEmpty()){
            update historyList;
        }
        return historyList; 
    }
    public List<CaseAssignmentHistory__c> insertCaseAssignmentHistory(List<CaseAssignmentHistory__c> historyList){
        if(historyList != NULL && !historyList.isEmpty()){
            insert historyList;
        }
        return historyList;
    }
    
}