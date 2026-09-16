/*
*********************************************************
Apex Class Name    : SlaProcessService
Created Date       : Dec 26, 2024
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   10-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class SlaProcessService {
    private SlaProcessService() {}
    
    public static SlaProcessService getInstance() {
        return new SlaProcessService();
    }
    
    public SlaProcess getSlaProcessByName(String slaName) {
        return [SELECT Id, description, Name FROM SlaProcess WHERE Name = :slaName LIMIT 1];          
    }
}