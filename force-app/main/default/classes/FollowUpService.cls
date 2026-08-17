/***
Class       : FollowUpService
Author      : Aman Bharti
Description : 
TestClass   : FollowUpServiceTest
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
Sr.No.  version    ¯          Date                Details
1.       V1.0              19/11/25           Initial Version 
****************************************************************************************************************/
public inherited sharing class FollowUpService {
    private static FollowUpService instance;
    
    private FollowUpService() {
        
    }
    
    public static FollowUpService getInstance() { 
        if(instance == null) {
            instance = new FollowUpService();
        }
        return instance;
    }

    public FollowUp__c createFollowUpObj(Id caseId, String comments){
        FollowUp__c objFollowUp = new FollowUp__c();
        objFollowUp.Case__c = caseId;
        objFollowUp.Comments__c = comments;
        return objFollowUp;
    }

    public void createFollowUp(FollowUp__c objFollowUp){
        if(objFollowUp != NULL ){
            insert objFollowUp;
        }
    }
}