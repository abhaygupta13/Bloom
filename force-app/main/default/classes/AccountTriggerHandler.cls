/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : AccountTriggerHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public class AccountTriggerHandler  implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;

	private static final string ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT { get { return 'Broker_Agency'; } }    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        AccountTriggerHelper.handleBeforeInsertFieldUpdates((List<Account>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        AccountTriggerHelper.createDocuments((List<Account>)newList);
        AccountTriggerHelper.handleAfterInsertFieldUpdates((List<Account>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        AccountTriggerHelper.handleBeforeUpdateFieldUpdates((List<Account>)newList,(Map<Id,Account>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        AccountTriggerHelper.handleAfterUpdateFieldUpdates((List<Account>)newList,(Map<Id,Account>)oldMap);        
        //Added By Ranjan        
        AccountTriggerHelper.handleSuqurAlWatanDocumentOnUpdate((List<Account>)newList,(Map<Id,Account>)oldMap);
        
      	Id brokerAgencyAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT);
        List<Account> eligibleAccounts = new List<Account>();
        List<Account> accounts = (List<Account>)newList;
        for (Account acc : accounts) {
            if (String.isNotBlank(acc.TypeofEstablishment__c) && acc.RecordTypeId == brokerAgencyAccountRecordTypeId ) {
                eligibleAccounts.add(acc);
            }
        }
         if (!eligibleAccounts.isEmpty()) {
             AccountTriggerHelper.BrokerAgencyAfterUpdate((List<Account>)newList,(Map<Id,Account>)oldMap);
         }
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}