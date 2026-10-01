/*****************************************************************************************
Class       : ActivityController
Author      : Dhanraj Poojary
Description : ActivityController class
Created Date: 26 MAR 2025
*****************************************************************************************/
public class ActivityController {
    private static final string DEFAULT_BUSINESS_HOURS_ID { get { return 'DefaultBusinessHoursId'; } }
    private static final string TASK_SUBJECT_DAY_1_CALL_1 { get { return 'Day 1 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_2_CALL_1 { get { return 'Day 2 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_3_CALL_1 { get { return 'Day 3 Call 1 - Follow Up'; } }
    private static final string TASK_COMPLETED_DESCRIPTION { get { return 'Not Contactable'; } }
    private static final string TASK_OPEN_STATUS { get { return 'Open'; } }
    private static final string TASK_QUALIFIED_STATUS { get { return 'Qualified'; } }
    private static final string TASK_COMPLETED_STATUS { get { return 'Completed'; } }
    private static final string TASK_NOT_CONTACTABLE_STATUS { get { return 'Not Contactable'; } }
    private static final string TASK_TYPE { get { return 'Call'; } }
    private static final string TASK_PRIORITY { get { return 'Normal'; } }
    private static final string SALES_TASK_SUBJECT { get { return 'SM'; } }
    private static final string LEASING_TASK_SUBJECT { get { return 'LO'; } }
    private static final string CONTACT_CENTRE_TASK_SUBJECT { get { return 'CC'; } }
    private static final string RECORD_SUCCESS_MESSAGE { get { return 'Record Has Been Updated Successfully.'; } }
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }

    @AuraEnabled
    public static String markTaskComplete(Id recordId) {
        LeadService objLeadService = LeadService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        String result;
        List<Task> taskList = new List<task>();
        Task objTask = objActivityService.getTasksById(recordId);
        if(objTask != null && objTask.Status == TASK_OPEN_STATUS){
            objTask.Description = TASK_COMPLETED_DESCRIPTION;
            objTask.Status = TASK_COMPLETED_STATUS;
            taskList.add(objTask);
            if(objTask.Subject.contains(TASK_SUBJECT_DAY_1_CALL_1) || objTask.Subject.contains(TASK_SUBJECT_DAY_2_CALL_1)){
                lead objLead = objLeadService.getLeadById(objTask.WhoId);
                taskList.add(createNewFollowupTask(objTask,objLead));
            }
            
            result = RECORD_SUCCESS_MESSAGE;
        }
        else if(objTask != null && (objTask.Status == TASK_COMPLETED_STATUS)){
            result = objTask.Status;
        }
        
        objActivityService.upsertTasks(taskList);           
        return result;
    }
    
    public static Task createNewFollowupTask(Task objTask, Lead objLead){
        ActivityService objActivityService = ActivityService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        Id defaultBHId = objMetadataService.getAppSettingTextValue(DEFAULT_BUSINESS_HOURS_ID);
        Date nextBusinessDate = objBHService.getNextBusinessDate(defaultBHId,System.now());
        Date nextDate = Date.today().addDays(1);
        String subject = '';
        Date dueDate; 
        Boolean isADHALead = objLead.Lead_Channel__c == 'API Integration' && objLead.LeadSource == 'Government Entity' && objLead.leadsubsource__c == 'ADHA' && objLead.ApplicationNumber__c != null;
        Map<String, String> followUpMapping = new Map<String, String>{TASK_SUBJECT_DAY_1_CALL_1 => TASK_SUBJECT_DAY_2_CALL_1,
            TASK_SUBJECT_DAY_2_CALL_1 => TASK_SUBJECT_DAY_3_CALL_1
            };
                
                for (String key : followUpMapping.keySet()) {
                    if (objTask.Subject.contains(key)) {
                       if (objLead.ContactCentreLeadStatus__c == TASK_QUALIFIED_STATUS && !isADHALead) {
                            subject = objTask.Subject.startsWith(SALES_TASK_SUBJECT) ? SALES_TASK_SUBJECT + ' - ' + followUpMapping.get(key) : LEASING_TASK_SUBJECT + + ' - ' + followUpMapping.get(key);
                            dueDate = nextBusinessDate;
                        }
                        if(objLead.ContactCentreLeadStatus__c != TASK_QUALIFIED_STATUS  && !isADHALead){
                            subject = objTask.Subject.startsWith(CONTACT_CENTRE_TASK_SUBJECT) ? CONTACT_CENTRE_TASK_SUBJECT + ' - ' + followUpMapping.get(key) : '';
                            dueDate = nextDate; 
                        }
                        System.debug('subject'+subject);
                    }
                }
        Task objNewTask = objActivityService.getActivity(subject, dueDate, dueDate, '', 
                                                         TASK_OPEN_STATUS, TASK_TYPE, TASK_PRIORITY, 1, objTask.OwnerId, objTask.WhoId); 
        return objNewTask;
    }
}