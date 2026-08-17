//============================ BCAPP_MoveoutUserDeactivationBatch =============================
/*
* @Author : Eagles  
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_MoveoutUserDeactivationBatch
* @Description : This APEX class used deactivate the user after Move out 
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               28 OCT 2024        Initial draft 
*****************************************************************************************************/

global class BCAPP_MoveoutUserDeactivationBatch implements database.batchable<sobject>, Database.AllowsCallouts{ 

    global Database.QueryLocator start(database.batchablecontext bc){
        String cases = 'SELECT ID,AccountId,Unit__c,Account.User__c,Account.User__r.Email__c,Account.User__r.Azure_UserId__c FROM Case where Recordtype.name=\'Move Out\' AND Move_Out_Date__c=TODAY AND Account.User__r.isActive__c=true';
        return Database.getQueryLocator(cases);
    }
    global void execute(database.batchablecontext bc,List<Case> lstCases){

        Set<Id> setInventoryId = new Set<Id>();
        List<Unit__c> lstUnits = new List<Unit__c>();
        Set<Id> setUserID = new Set<Id>();
        List<User__c> lstusers = new List<User__c>();
        for(Case eachCase:lstCases){
            setInventoryId.add(eachCase.Unit__c);
            setUserID.add(eachCase.Account.User__c);
            if(!test.isrunningtest()){
                MicrosoftAzureB2CUtility.deactivateUser(eachCase.Id,eachCase.Account.User__r.Azure_UserId__c);
            }
        }   

        for(User__c eachuser:[SELECT isActive__c FROM User__c where ID IN:setUserID]){
            eachuser.isActive__c = false;
            lstusers.add(eachuser);
        }
        for(Unit__c eachUnit:[SELECT ID,Occupancy_Type__c FROM Unit__c where ID IN:setInventoryId]){
            eachUnit.Occupancy_Type__c = 'Available';
            lstUnits.add(eachUnit);
            
        }
        if(lstUnits.size() >0){
            update lstUnits;
        }

        if(lstusers.size()>0){
            update lstusers;
        }
    }
    global void finish(database.batchablecontext bc){

    }
}