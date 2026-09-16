/*************************************************************************************************
Class       : TaskBusinessDaysBatch
Author      : prashant sahu 29/06/2026
Description : Scheduled batch to calculate Business Days for open Tasks.
*************************************************************************************************/
global class TaskBusinessDaysBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final String MTD_BUSINESS_HOURS_PER_WORKING_DAY = 'BusinessHoursPerWorkingDay';
    
    global Database.QueryLocator start(Database.BatchableContext bc) { 
        
         return Database.getQueryLocator([SELECT Id, Status, BusinessHours__c, SLAHours__c, WorkingDaysSpent__c, AssignedDateTime__c FROM Task 
			WHERE Status != 'Completed' AND BusinessHours__c != NULL AND SLAHours__c != NULL AND AssignedDateTime__c != NULL  AND (WhoId != NULL OR WhatId != NULL)]);
    }
    
    global void execute(Database.BatchableContext bc, List<Task> updateTasks) {
        
        ActivityService objActivityService = ActivityService.getInstance();
        BusinessHoursService businessHoursService = BusinessHoursService.getInstance();
        
        MetadataService objMetadataService = MetadataService.getInstance();
        Integer workingHoursInDay = Integer.valueOf(objMetadataService.getAppSettingTextValue(MTD_BUSINESS_HOURS_PER_WORKING_DAY));
        
        for (Task task : updateTasks) {
        
             task.WorkingDaysSpent__c = businessHoursService.calculateWorkingDaysSpent( task.BusinessHours__c, task.AssignedDateTime__c, System.now(), workingHoursInDay);
        }
        objActivityService.updateTasksWithoutTrigger(updateTasks);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
    global void execute(SchedulableContext sc){
        Database.executeBatch(new TaskBusinessDaysBatch(),2000);
    }
    
}