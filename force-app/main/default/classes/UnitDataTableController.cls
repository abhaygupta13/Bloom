/*
*********************************************************
Apex Class Name    : UnitDataTableController
Created Date       : July 15, 2024
@description       : This class is handling method related to lwc component.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
2.0   28-08-2024   : Pavitra Chauhan                      Initial Version
*********************************************************
*/

public with sharing class UnitDataTableController {
    @AuraEnabled(cacheable=true)
    public static List<SalesOrder__c> getRelatedUnits(Id accountId) {
        List<SalesOrder__c> salesOrder = new List<SalesOrder__c>([Select ID,Unit__r.Id,Unit__r.Name,Unit__r.ProjectName__c,Unit__r.NOCExpiryDate__c,Unit__r.UnitType__c,Unit__r.DLP_End_Date__c,Unit__r.DLP_Start_Date__c From SalesOrder__c Where Account__c =: accountId And Status__c = 'Sold']);
        return salesOrder;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SalesOrder__c> geRelatedtAccount(Id unitId) {
        List<SalesOrder__c> salesOrder = new List<SalesOrder__c>([Select ID,Account__r.Id,Unit__r.Id,Unit__r.NOCExpiryDate__c From SalesOrder__c Where Unit__c =: unitId And Status__c = 'Sold']);
        return salesOrder;
    }
}