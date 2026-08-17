/*****************************************************************************************
Class       : DashboardController
Author      :  Antriksh jain
Description : 
test Class  : DashboardControllerTest 
Created Date: 07/01/2026 
*****************************************************************************************/ 
public with sharing class DashboardController {
    @AuraEnabled(cacheable=true)
    public static String getDashboardIdByName(String dashboardName) {
        List<Dashboard> dashList = [SELECT Id FROM Dashboard WHERE Title = :dashboardName LIMIT 1];
        if(!dashList.isEmpty()){
            return dashList[0].Id;
        }
        return null;
    }
}