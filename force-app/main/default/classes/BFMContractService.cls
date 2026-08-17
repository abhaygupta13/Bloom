/*****************************************************************************************
Class       : BFMContractService
Author      : Vikas Baliyan
Description : 
test Class: 
Created Date: 17 MAR 2025
*****************************************************************************************/
public class BFMContractService {
    
    private static BFMContractService instance;
    
    public BFMContractService() {}
    
    public static BFMContractService getInstance() {
        if(instance == null) {
            instance = new BFMContractService();
        }
        return instance;
    }
    
    public List<BFMContract__c> getBFMContractWithinRange(String unitId){
        return [SELECT Id,ContractSpecification__c FROM BFMContract__c WHERE Status__c = 'Active' AND UnitNumber__c =: unitId AND ContractStartDate__c <= TODAY AND ContractEndDate__c >= TODAY];
    }
}