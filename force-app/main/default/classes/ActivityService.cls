/*****************************************************************************************
Class       : ActivityService
Author      : Rajat Rastogi
Description : Activity service class
Created Date: 02 SEP 2024
*****************************************************************************************/
public inherited sharing class ActivityService {
    
    private static ActivityService instance;
    
    private ActivityService() {
        
    }
    
    public static ActivityService getInstance() {  
        if(instance == null) {
            instance = new ActivityService();
        }
        return instance;
    }
    
    public List<Task> getOpenTaskForCaseByOrder(Case caseObj,Integer ordr){
        return [SELECT Id,FinalTask__c,WhatId,OwnerId FROM Task 
                WHERE WhatId =:caseObj.id 
                AND Status = 'Open' 
                And Order__c =:ordr 
                AND OwnerId =:caseObj.OwnerId
                Limit 1];
        
    }

    public List<Task> getOpenTaskForHandoverTeam(Handover__c handoverObj){
        return [SELECT Id,FinalTask__c,WhatId,SubType__c,OwnerId,CompletedDateTime__c FROM Task 
                WHERE WhatId =:handoverObj.id 
                AND Status = 'Open' 
                //AND OwnerId = :handoverObj.HO_Agent_Assigned_User__c
                AND SubType__c LIKE 'Handover Team Task 2.%' LIMIT 1];
        
    }
    
    public List<Task> getTasksByWhoIds(Set<Id> whoIds){
        return  [SELECT Id,Status,Subject,WhoId FROM Task WHERE WhoId IN :whoIds];
    }
    
    public List<Task> getTasksByIds(Set<Id> recordIds){ 
        return[SELECT Id,Type__c,SubType__c,WhatId FROM Task WHERE Id IN :recordIds ];
    }
    
    public List<Task> getOpenTasksBywhatIds(Set<Id> whatIds){
        return [SELECT Id,FinalTask__c,WhatId,OwnerId,Subject,CompletedDateTime__c FROM Task WHERE WhatId IN :whatIds AND Status = 'Open' Order By CreatedDate DESC];
    }
    
    public Task createTaskFromServiceAction(ServiceAction__c sa){
        Task tsk = new Task(); 
        tsk.Subject = sa.TaskSubject__c;
        tsk.Order__c = sa.Order__c;
        tsk.FinalTask__c = sa.FinalTask__c;
        tsk.Type__c = sa.TaskType__c;
        tsk.SubType__c = sa.TaskSubType__c;
        return tsk;
    }
    
    public Task fetchTaskFromServiceAction(ServiceAction__c sa,String WhatId){
       
        return [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Subject,Department__c 
                FROM Task 
                WHERE WhatId =:WhatId 
                AND Status = 'Completed'
                AND SubType__c = :sa.TaskSubType__c
                order by lastmodifieddate desc LIMIT 1];
    }

    public List<Task> fetchCompletedTaskFromServiceAction(ServiceAction__c sa,String WhatId){
       
        return [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Subject,Department__c, BusinessHours__c
                FROM Task 
                WHERE WhatId =:WhatId 
                AND Status = 'Completed'
                AND SubType__c = :sa.TaskSubType__c
                order by lastmodifieddate desc LIMIT 1];
    }

    public List<Task> fetchClosedTaskByDept(String Dept, String WhatId){
          return [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Subject,Department__c 
                FROM Task 
                WHERE WhatId =:WhatId 
                AND Status = 'Completed'
                AND Department__c = :Dept
                order by lastmodifieddate asc LIMIT 1];
    }
 
    public List<Task> fetchLatestOpenTaskOnCase(String recordId){
        return  [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Department__c 
                 FROM Task 
                 WHERE WhatId =: recordId 
                 AND Status != 'Completed' Order By CreatedDate DESC LIMIT 1];
    }

    public List<Task> fetchOpenTaskForCase(Case caseObj){
        return [SELECT Id,FinalTask__c,WhatId,OwnerId FROM Task 
                WHERE WhatId =:caseObj.id 
                AND Status = 'Open' 
                Limit 2];
        
    }

    public List<Task> fetchOpenTaskFromServiceAction(ServiceAction__c sa,String WhatId){
        return  [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Department__c,SLAHours__c,CompletedDateTime__c
                 FROM Task 
                 WHERE WhatId =:WhatId 
                 AND Status = 'Open'
                 AND SubType__c = :sa.TaskSubType__c];
    }

    public List<Task> fetchTasksFromServiceAction(ServiceAction__c sa,String WhatId){
       
        return [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Subject,Department__c, BusinessHours__c
                FROM Task 
                WHERE WhatId =:WhatId 
                AND SubType__c = :sa.TaskSubType__c
                order by lastmodifieddate desc LIMIT 1];
    }
    
    public List<Task> updateTasks(List<Task> taskList){ 
        if(taskList != NULL && !taskList.isEmpty()){
            update taskList;
        }
        return taskList; 
    }
    public List<Task> updateTasksWithoutTrigger(List<Task> taskList){ 
        if(taskList != NULL && !taskList.isEmpty()){
            TaskTriggerHandler.isTriggerDisabled = false;
            update taskList;
            TaskTriggerHandler.isTriggerDisabled = true;
            
        }
        return taskList; 
    }
    
    public List<Event> getEventByWhatId(Set<Id> whatId){
        return [SELECT Id, WhatId, Subject, StartDateTime,EndDateTime,Type FROM Event WHERE WhatId IN :whatId];
    }

    public List<Event> getEventByWhatIdAndType(Set<Id> whatId, Set<String> typeList){
        return [SELECT Id, WhatId, Subject, StartDateTime,EndDateTime,Type FROM Event WHERE WhatId IN :whatId AND Type IN :typeList];
    }
    
    public Task getActivity(String subject, Date ActivityDate, Datetime dueDateTime, String description, 
                            String status, String type, String priority, Integer count, Id ownerId, Id whoId){ 
                                Task objTask = new Task();
                                objTask.Subject = String.isNotBlank(subject) ? subject : null;
                                objTask.ActivityDate = ActivityDate != null ? ActivityDate : null;
                                objTask.Due_Date_Time__c = dueDateTime != null ? dueDateTime : null;
                                objTask.Description = String.isNotBlank(description) ? description : null;
                                objTask.Status = String.isNotBlank(status) ? status : null;
                                objTask.Type = String.isNotBlank(type) ? type : null;
                                objTask.Priority = String.isNotBlank(priority) ? priority : null;
                                objTask.Count__c = count != null ? count : null;
                                objTask.OwnerId = ownerId != null ? ownerId : null;
                                objTask.WhoId = whoId != null ? whoId : null;
                                return objTask;
                            }
    
    public Task getActivityWithSLA(String subject, Date ActivityDate, Datetime dueDateTime, String description, 
                            String status, String type, String priority, Integer count, Id ownerId, Id whoId, Datetime slaDateTime, Id BusinessHourId, Decimal slaHours){ 
                                Task objTask = new Task();
                                objTask.Subject = String.isNotBlank(subject) ? subject : null;
                                objTask.ActivityDate = ActivityDate != null ? ActivityDate : null;
                                objTask.Due_Date_Time__c = dueDateTime != null ? dueDateTime : null;
                                objTask.Description = String.isNotBlank(description) ? description : null;
                                objTask.Status = String.isNotBlank(status) ? status : null;
                                objTask.Type = String.isNotBlank(type) ? type : null;
                                objTask.Priority = String.isNotBlank(priority) ? priority : null;
                                objTask.Count__c = count != null ? count : null;
                                objTask.OwnerId = ownerId != null ? ownerId : null;
                                objTask.WhoId = whoId != null ? whoId : null;
                                objTask.SLADateTime__c   = slaDateTime != null ? slaDateTime : null;
                                objTask.SLAHours__c = slaHours != null ? slaHours : slaDateTime != null ? (slaDateTime.getTime() - Datetime.now().getTime()) / (1000.0 * 60 * 60) : null;
                                objTask.BusinessHours__c = BusinessHourId != null ? BusinessHourId : null;
                                
                                return objTask;
                            }
    
    public Task getTasksById(Id taskId){
        Task objTask = [SELECT Id, Subject, Status ,WhatId, Description, Priority, WhoId, OwnerId FROM Task WHERE Id =: taskId LIMIT 1];
        return objTask;
    }
    
    public List<Task> getCRMTasksByCaseIds(Set<Id> caseIds){
        List<Task> taskList = [SELECT Id, WhatId, OwnerId FROM Task WHERE WhatId IN :caseIds AND Subject LIKE '%CRM%'];
        return taskList;
    }

    public void deleteEvents(List<Event> events){
        if(events != NULL && !events.isEmpty()){
            delete events;
        }
    }
    
    public Event insertEvent(Event event){
        if(event != NULL ){
            event = insertEvents(new List<Event>{event})[0];
        }
        return event;
    }
    
    public List<Event> insertEvents(List<Event> eventList){
        if(eventList != NULL && !eventList.isEmpty()){
            insert eventList;
        }
        return eventList;
    }
    
    public List<Task> insertTasks(List<Task> taskList){
        if(taskList != NULL && !taskList.isEmpty()){
            insert taskList;
        }
        return taskList;
    }
    public List<Task> getOpenTasksByOwner(Id whatId){
         
    List<Task> openTasks = [
        SELECT Id
        FROM Task
        WHERE WhatId = :whatId
        AND OwnerId = :UserInfo.getUserId()
        AND Status != 'Completed'
        LIMIT 1
    ];
        return openTasks;
        
        
    }
    
    public  Map<Id,List<Task>> fetchOpenTaskByCaseList(List<Case> listOfCases){
        Map<Id,List<Task>> caseVsOpenTask = new Map<Id,List<Task>>();
        Set<Id> caseIds = new  Set<Id>();
        for(Case caseObj : listOfCases){
            caseIds.add(caseObj.id); 
        }
        
        ActivityService objActivityService = ActivityService.getInstance();
        List<Task> taskList = objActivityService.getOpenTasksBywhatIds(caseIds);
        
        List<Task> tasksToUpdate = new List<Task>();
        for (Task tskObj : taskList) {
            tskObj.Status = 'Completed';  // Update status directly
            tasksToUpdate.add(tskObj);    // Add to the update list
        }
        
        for(Task tsk : tasksToUpdate){
            if(!caseVsOpenTask.containsKey(tsk.WhatId)){
                caseVsOpenTask.put(tsk.WhatId,new List<Task>());
            }
            caseVsOpenTask.get(tsk.WhatId).add(tsk);
            
        }
        return caseVsOpenTask;
        
    }
    
    public List<Task> closeTasks(List<Task> taskList){ 
        if(taskList != NULL && !taskList.isEmpty()){
            for(Task tsk : taskList){
                tsk.Status = 'Completed';
            }
        }
        
        return updateTasks(taskList); 
    }
    
    public Map<Id, Task> getTasksBySubjectAndWhoId(Set<Id> whoIds, String subject){
        Map<Id, Task> taskMap = new Map<Id, Task>();
        for(Task objTask :[SELECT Id, WhoId FROM Task WHERE Subject = :subject AND WhoId IN :whoIds]){
            taskMap.put(objTask.WhoId, objTask);
        }
        return taskMap;
    }
    
    public List<Task> insertTasksWithoutTrigger(List<Task> taskList){
        if(taskList != NULL && !taskList.isEmpty()){
            TaskTriggerHandler.isTriggerDisabled = false;
            insert taskList;
            TaskTriggerHandler.isTriggerDisabled = true;
        }
        return taskList;
    }
    
    public List<Task> upsertTasksWithoutTrigger(List<Task> taskList){
        if(taskList != NULL && !taskList.isEmpty()){
            TaskTriggerHandler.isTriggerDisabled = false;
            upsert taskList;
            TaskTriggerHandler.isTriggerDisabled = true;
        }
        return taskList;
    }
    
    public List<Task> upsertTasks(List<Task> taskList){ 
        if(taskList != NULL && !taskList.isEmpty()){
            upsert taskList;
        }
        return taskList; 
    }
    
    public Task updateTask(Task tsk){
        return updateTasks(new List<Task>{tsk})[0];
    }
    
    public Event createEventObj(Id whoId, Id appointmentSlotId, String status, DateTime startDateTime, DateTime endDateTime, String subject, String type, String mode){
        Event objEvent = new Event();
        objEvent.WhoId = whoId;
        objEvent.AppointmentSlot__c = appointmentSlotId;
        objEvent.AppointmentStatus__c = status;
        objEvent.StartDateTime = startDateTime;
        objEvent.EndDateTime = endDateTime;
        objEvent.Subject = subject;
        objEvent.Type = type;
        objEvent.AppointmentMode__c = String.isNotBlank(mode) ? mode : 'Offline';
        if(whoId != null && whoId.getSObjectType() == Lead.SObjectType){
            Lead objLead = LeadService.getInstance().getLeadById(whoId);
            objEvent.OwnerId = objLead.OwnerId;
        }
        return objEvent;
    }

    public List<Event> updateEvents(List<Event> eventList){ 
        if(eventList != NULL && !eventList.isEmpty()){
            update eventList;
        }
        return eventList; 
    }
    
/**
 * Creates an appointment notification email using the provided email template
 * and replaces the template placeholders with customer, appointment, and
 * account manager details.
 *
 * @param emailTemplate      Email template used to generate the email subject and body.
 * @param objEvent           Event record containing the appointment date, time, location, owner, and recipient.
 * @param customerName       Customer name used to replace the customer name placeholder.
 * @param customerNameArabic Customer name in Arabic used to replace the Arabic customer name placeholder.
 * @param noReplyBloomOWDId  ID of the no-reply email address used as the sender.
 * @return                   Configured Messaging.SingleEmailMessage for the appointment notification.
 */
    public Messaging.SingleEmailMessage createAppointmentNotificationEmail(EmailTemplate emailTemplate, Event objEvent, String customerName, 
    String customerNameArabic, Id noReplyBloomOWDId, User accountManager){
        Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, objEvent.WhoId, null);
        String emailBody = renderedEmail.getHtmlBody();
        String emailSubject = renderedEmail.getSubject();
        String appointmentDate = objEvent.StartDateTime != null ? objEvent.StartDateTime.format('yyyy MMMM dd') : '';
        String appointmentTime = (objEvent.StartDateTime != null && objEvent.EndDateTime != null) ? objEvent.StartDateTime.format('h:mm a') + ' - ' + objEvent.EndDateTime.format('h:mm a') : '';
        
        String body = emailBody.replace('[Customer_Name]', customerName)
            .replace('[Customer_Name_Arabic]', customerNameArabic)
            .replace('[Date]', appointmentDate)
            .replace('[Slot_Time]', appointmentTime)
            .replace('[Location]', String.isBlank(objEvent.Location) ? '' : objEvent.Location)
            .replace('[Manager_Name]', String.isBlank(accountManager?.Name) ? '' : accountManager.Name)
            .replace('[Manager_Number]', String.isBlank(accountManager?.Phone) ? '' : accountManager.Phone)
            .replace('[Type]', String.isNotBlank(objEvent.AppointmentMode__c) ? objEvent.AppointmentMode__c : '')
			.replace('[Link]', String.isNotBlank(objEvent.MeetingLink__c) ? '<a href="' + objEvent.MeetingLink__c + '">Click here</a>' : '');
        return EmailService.getInstance().getSingleEmailMessage(null, null, objEvent.WhoId, emailSubject, body, noReplyBloomOWDId);
    }    
    
    public Boolean hasExistingAppointment(Id whoId) {
        if (whoId != null) {
            return [ SELECT COUNT() FROM Event WHERE WhoId = :whoId AND StartDateTime >= :System.now() AND Type = 'Appointment' AND AppointmentStatus__c IN ('Scheduled')] > 0;
        } 
        return false;
    }

    public Set<Id> getExistingAppointmentWhoIds(Set<Id> whoIds) {
        Set<Id> existingWhoIds = new Set<Id>();
        if(whoIds != null && !whoIds.isEmpty()) {

            for(Event objEvent : [SELECT WhoId FROM Event WHERE WhoId IN :whoIds AND StartDateTime >= :System.now() AND Type = 'Appointment' AND AppointmentStatus__c = 'Scheduled']) 
            { 
                existingWhoIds.add(objEvent.WhoId); 
            }
        }
        return existingWhoIds;
    }

/**
 * @description Creates an IntegrationRecord__c for Microsoft Teams appointment integration based on the Event appointment status. The method prepares the required integration parameters, 
 * including ADHA lead email, timezone, appointment start and end date/time, subject, meeting ID, description, and attendee email, and delegates record creation to IntegrationRecordService.
 *
 * @param objEvent The Event record containing appointment and Microsoft Teams meeting details.
 * @param adhaLeadEmailId The email address of the ADHA lead/account manager used for the Teams integration.
 * @param adhaLeadTimeZone The timezone associated with the ADHA lead/account manager.
 *
 * @return IntegrationRecord__c The prepared integration record for Microsoft Teams meeting scheduling or cancellation.
 */
    public IntegrationRecord__c getEventIntegrationRecord(Event objEvent, String adhaLeadEmailId, String adhaLeadTimeZone) {
        Map<String, String> paramMap = new Map<String, String>();
        String actionType;
        String objectApiName = 'Event';
        String recordId = objEvent.Id;
        
        if(objEvent.AppointmentStatus__c == 'Scheduled') {
            actionType = 'SCHEDULE';
        }else if(objEvent.AppointmentStatus__c == 'Cancelled') {
            actionType = 'CANCEL';
        }
        paramMap.put('Param1', adhaLeadEmailId);
        paramMap.put('Param2', adhaLeadTimeZone);
        paramMap.put('Param3', objEvent.StartDateTime.format('yyyy MM dd, HH:mm'));
        paramMap.put('Param4', objEvent.EndDateTime.format('yyyy MM dd, HH:mm'));
        paramMap.put('Param5', objEvent.Subject);
        paramMap.put('Param6', objEvent.MeetingId__c);
        paramMap.put('LongTextParam1', objEvent.Description);
        paramMap.put('LongTextParam2', objEvent.AttendeeEmail__c);
    
        return IntegrationRecordService.getInstance().getIntegrationRecord('MICROSOFT_TEAMS_MEETING', actionType, objectApiName, recordId, paramMap);
    }
}