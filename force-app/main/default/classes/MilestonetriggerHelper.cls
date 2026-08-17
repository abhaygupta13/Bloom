/*
* @Author : Jayprakash Bharti
* @CreatedDate : 26th AUG 2024
* @Description : Milestone object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Jayprakash   	26AUG2024        
*****************************************************************************************************/
 
public with sharing class MilestonetriggerHelper {
    public Static Void installmentReviseddateUpdation(List<Milestone__c> mlist){
        Milestoneinstallmentupdation.installmentreviseddateupdation(mlist);
    }
}