/*****************************************************************************************
Class       : DeletedOwnerService
Author      : Biswajeet
Description : Deleted Owner service class
test Class: JointOwnerServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public inherited sharing class DeletedOwnerService {
    
    private static DeletedOwnerService instance;
    
    private DeletedOwnerService() {
        
    }
    
    public static DeletedOwnerService getInstance() { 
        if(instance == null) {
            instance = new DeletedOwnerService();
        }
        return instance;
    }
    

     public List<DeletedOwner__c> fetchDeletedOwners(Id caseId){
        List<DeletedOwner__c> deletedOwnerList = new List<DeletedOwner__c>();
        deletedOwnerList = [Select id,Account__c,Case__c from DeletedOwner__c where Case__c = :caseId];
        return deletedOwnerList;  
    }
}