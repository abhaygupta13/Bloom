//============================ BCAPP_SendNotificationAction =============================
/*
* @Author : Eagles  
* @CreatedDate : 02 Jul 2025
* @Name : BCAPP_SendNotificationAction
* @Description : This APEX class handles the Send Email and Push Notification process which configured on Action Items
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               02 Jul 2025     Initial draft 
*****************************************************************************************************/
public without sharing class BCAPP_SendNotificationAction {
    List<Case> requests = new List<Case>();
    Map<Id,sObject> oldMap = new Map<Id,sObject>();
    public BCAPP_SendNotificationAction(List<Case> requests,Map<Id,sObject> oldMap){
        this.requests = requests;
        this.oldMap = oldMap;
    }
    
    public void handleSendEmailActionItems() {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();  
        CaseService cService = CaseService.getInstance();
        ActionItemsService aiService = ActionItemsService.getInstance();
        EmailTemplateService etService = EmailTemplateService.getInstance();
        EmailService emailService = EmailService.getInstance();
        UserService uService = UserService.getInstance();
        Set<Id> catalogIds = new Set<Id>();
        Map<Id,String> caseEmails = new Map<Id,String>();
        for (Case c : requests) {
            if (c.Service_Catalog__c != null) {
                catalogIds.add(c.Service_Catalog__c);
            }
        }
        for(Case cEmail:cService.getCasesByCaseIds(requests)){
            String caseEmail = '';
            if(cEmail.user__c!=null){
                caseEmail = cEmail.user__r.Email__c;
            }
            else{
                caseEmail = cEmail.Account.PersonEmail!=null?cEmail.Account.PersonEmail:cEmail.Account_Email__c;
            }
             
            if(caseEmail!=null){
                caseEmails.put(cEmail.Id,caseEmail);
            }
        }
        Map<Id, List<Task_Action__c>> catalogToActions = new Map<Id, List<Task_Action__c>>();
        if (!catalogIds.isEmpty()) {
            List<Action_Items__c> actionItems = aiService.getActionItemsRelatedToServiceCatalog(catalogIds,'Send Email');
            
            for (Action_Items__c item : actionItems) {
                for (Task_Action__c ra : item.Task_Action__r) {
                    if (!catalogToActions.containsKey(item.Service_Catalog__c)) {
                        catalogToActions.put(item.Service_Catalog__c, new List<Task_Action__c>());
                    }
                    catalogToActions.get(item.Service_Catalog__c).add(ra);
                }
            }
        }
        
        Set<String> allTemplateNames = new Set<String>();
        for (List<Task_Action__c> ras : catalogToActions.values()) {
            for (Task_Action__c ra : ras) {
                if (!String.isBlank(ra.EmailTemplateName__c)) {
                    allTemplateNames.add(ra.EmailTemplateName__c.trim());
                }
            }
        }
        
        Map<String, Id> templateMap = new Map<String, Id>();
        if (!allTemplateNames.isEmpty()) {
            for (EmailTemplate et : etService.getEmailTemplateByDeveloperNames(allTemplateNames)) {
                templateMap.put(et.DeveloperName, et.Id);
            }
        }
        
        // Collect all group names
        Set<String> allGroupNames = new Set<String>();
        GroupService gService = GroupService.getInstance(); 
        for (List<Task_Action__c> ras : catalogToActions.values()) {
            for (Task_Action__c ra : ras) {
                if (!String.isBlank(ra.EmailRecipients__c)) {
                    for (String g : ra.EmailRecipients__c.split(',')) {
                        if (!String.isBlank(g)) {
                            allGroupNames.add(g.trim());
                        }
                    }
                }
            }
        }
        
        // Fetch groups and their user members
        Map<String, Set<String>> groupToEmails = new Map<String, Set<String>>();
        if (!allGroupNames.isEmpty()) {
            Map<String, Id> groupNameToId = new Map<String, Id>();
            for (Group g : gService.getGroupByNames(allGroupNames)) {
                groupNameToId.put(g.Name, g.Id);
            }
            
            Set<Id> groupIds = new Set<Id>(groupNameToId.values());
            
            Map<Id, Set<Id>> groupIdToUserIds = new Map<Id, Set<Id>>();
            for (GroupMember gm : GroupService.getGroupMembersByGroupIds(groupIds)) {
                if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                    if (!groupIdToUserIds.containsKey(gm.GroupId)) {
                        groupIdToUserIds.put(gm.GroupId, new Set<Id>());
                    }
                    groupIdToUserIds.get(gm.GroupId).add(gm.UserOrGroupId);
                }
            }
            
            Set<Id> allUserIds = new Set<Id>();
            for (Set<Id> ids : groupIdToUserIds.values()) {
                allUserIds.addAll(ids);
            }
            
            Map<Id, String> userIdToEmail = new Map<Id, String>();
            for (User u : uService.getUsersByIds(allUserIds)) {
                if (!String.isBlank(u.Email)) {
                    userIdToEmail.put(u.Id, u.Email);
                }
            }
            
            for (String groupName : groupNameToId.keySet()) {
                Id groupId = groupNameToId.get(groupName);
                Set<String> emails = new Set<String>();
                if (groupIdToUserIds.containsKey(groupId)) {
                    for (Id userId : groupIdToUserIds.get(groupId)) {
                        if (userIdToEmail.containsKey(userId)) {
                            emails.add(userIdToEmail.get(userId));
                        }
                    }
                }
                groupToEmails.put(groupName, emails);
            }
        }
        // Send emails per case, Bulkified
        for (Case c : requests) {
            if (!catalogToActions.containsKey(c.Service_Catalog__c)){
                continue;
            } 
           
            for (Task_Action__c ra : catalogToActions.get(c.Service_Catalog__c)) {
                if (ra.Project__c!=null && ra.Project__c != c.Project__c || (ra.Task_Rule_Criteria__c!=null &&
                    ra.Task_Rule_Criteria__r.Rule_Criteria__c!=null && 
                    !evaluateExpression(ra.Task_Rule_Criteria__r.Rule_Criteria__c,c))) {
                         continue;                                                          
                    }
                
                Id templateId = templateMap.get(ra.EmailTemplateName__c?.trim());
                if (templateId == null) continue;
                
                Set<String> emailAddresses = new Set<String>();
                List<String> emailCCAddresses = new List<String>();
                if(ra.Send_Customer__c && caseEmails.containsKey(c.Id)){
                    emailAddresses.add(caseEmails.get(c.Id));
                }
                else{
                    // Collect emails from public groups
                    
                    if (!String.isBlank(ra.EmailRecipients__c)) {
                        for (String g : ra.EmailRecipients__c.split(',')) {
                            if (!String.isBlank(g)) {
                                String trimmed = g.trim();
                                if (groupToEmails.containsKey(trimmed)) {
                                    emailAddresses.addAll(groupToEmails.get(trimmed));
                                }
                                else if (trimmed.contains('@')) {
                                    emailAddresses.add(trimmed);
                                }
                            }
                        }
                    }
                }
                if (!String.isBlank(ra.emailCCAddresses__c)) {
                        for (String g : ra.emailCCAddresses__c.split(',')) {
                            if (!String.isBlank(g)) {
                                String trimmed = g.trim();
                                emailCCAddresses.add(trimmed);
                            }
                        }
                }
                if (!emailAddresses.isEmpty()) {
                    
                    Messaging.SingleEmailMessage   email =
                        Messaging.renderStoredEmailTemplate(templateId, null, c.Id);
                    
                    email.setToAddresses(new List<String>(emailAddresses));
                    email.setCcAddresses(emailCCAddresses);
                    email.setSaveAsActivity(true);
                    email.setWhatId(c.Id);
                    emailsToSend.add(email);
                }
            }
        }
        
        if (!emailsToSend.isEmpty()) {
            emailService.sendEmail(emailsToSend);
        }
    }
    
    public void handlePushNotificationActionItems() {
        
        Set<Id> catalogIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,String> accountDeviceToken = new Map<Id,String>();
        String  deviceToken = '';
        List<BCAPP_PushNotificationAPI.PushNotificationParams> notifyParams = new List<BCAPP_PushNotificationAPI.PushNotificationParams>();
        ActionItemsService aiService = ActionItemsService.getInstance();
        User_Service uService = User_Service.getInstance();
        for (Case c : requests) {
            if (c.Service_Catalog__c != null) {
                catalogIds.add(c.Service_Catalog__c);
                
            }
            if( c.AccountId != null){
                accountIds.add(c.AccountId);
            }
           
        }
        
        Map<Id, List<Task_Action__c>> catalogToActions = new Map<Id, List<Task_Action__c>>();
        if (!catalogIds.isEmpty()) {
            List<Action_Items__c> actionItems =  aiService.getActionItemsRelatedToServiceCatalog(catalogIds,'Push Notification'); 
            for (Action_Items__c item : actionItems) {
                for (Task_Action__c ra : item.Task_Action__r) {
                    if (!catalogToActions.containsKey(item.Service_Catalog__c)) {
                        catalogToActions.put(item.Service_Catalog__c, new List<Task_Action__c>());
                    }
                    catalogToActions.get(item.Service_Catalog__c).add(ra);
                }
            }
        }
        if(!accountIds.isEmpty()){
             for(User__c aUser:uService.getUsersByAccountId(accountIds)){
                if(aUser.deviceRegistrationId__c!=null){
                    accountDeviceToken.put(aUser.User_Account__c,aUser.deviceRegistrationId__c);
                }
            
        	}
        }
       
         for (Case c : requests) {
            if (!catalogToActions.containsKey(c.Service_Catalog__c)){
                continue;
            } 
            for (Task_Action__c ra : catalogToActions.get(c.Service_Catalog__c)) {
                if (ra.Template__c==null || (ra.Task_Rule_Criteria__c!=null &&
                    ra.Task_Rule_Criteria__r.Rule_Criteria__c!=null && 
                                             !evaluateExpression(ra.Task_Rule_Criteria__r.Rule_Criteria__c,c))){
                                                 continue;
                                             } 
                if(!accountDeviceToken.isEmpty() &&  accountDeviceToken.get(c.AccountId)!=null){
                    deviceToken =  accountDeviceToken.get(c.AccountId);
                }
                else{
                    deviceToken = c.deviceRegistrationId__c;
                }
                if(!String.isEmpty(deviceToken)){
                    String messageBody = replaceCaseMergeFields(ra.Template__c,c);
                    BCAPP_PushNotificationAPI.PushNotificationParams nParams = new BCAPP_PushNotificationAPI.PushNotificationParams(deviceToken,ra.Title__c,messageBody,c.CaseNumber,c.Status);
                    nParams.accountId = c.AccountId;
                    notifyParams.add(nParams);
                }
               
            }
             if(!notifyParams.isEmpty()){
                  System.enqueueJob(new BCAPP_PushNotificationAPI(notifyParams));
             } 
         }
    }
    
    public static String replaceCaseMergeFields(String template, Case caseRecord) {
        if (String.isBlank(template) || caseRecord == null) return template;

        // Find all merge fields in format {fieldName}
        Pattern pattern = Pattern.compile('\\{(.*?)\\}');
        Matcher matcher = pattern.matcher(template);

        Set<String> fieldNames = new Set<String>();
        while (matcher.find()) {
            fieldNames.add(matcher.group(1));
        }

        for (String fieldName : fieldNames) {
            try {
                Object fieldValue = caseRecord.get(fieldName);
                String valueStr = fieldValue != null ? String.valueOf(fieldValue) : '';
                template = template.replace('{' + fieldName + '}', valueStr);
            } catch (Exception e) {
                // Field not found or inaccessible - skip it
                System.debug('Field not found: ' + fieldName);
            }
        }

        return template;
    }
    


    public Boolean evaluateExpression(String expression, SObject record) {
    expression = expression.replaceAll('(?i)\\bOR\\b', ' OR ');
    expression = expression.replaceAll('(?i)\\bAND\\b', ' AND ');

    // Replace field comparisons with true/false
    Pattern p = Pattern.compile('(\\w+)\\s*=\\s*\'([^\']*)\'');
    Matcher m = p.matcher(expression);
    while (m.find()) {
        String fullMatch = m.group(0);        
        String fieldName = m.group(1);        
        String expectedVal = m.group(2);      

        Object actualValObj;
        try {
            actualValObj = record.get(fieldName);
            if(oldMap!=null && oldMap.containsKey((String)record.get('Id'))){
                if(actualValObj==oldMap.get((String)record.get('Id')).get(fieldName)){
                    return false;
                }
            }
        } catch (Exception e) {
            actualValObj = null;
        }

        String actualVal = actualValObj != null ? String.valueOf(actualValObj) : '';
        Boolean comparisonResult = actualVal.toLowerCase() == expectedVal.toLowerCase();

        expression = expression.replace(fullMatch, String.valueOf(comparisonResult));
    }

    return evaluateBooleanLogic(expression);
}

	private static Boolean evaluateBooleanLogic(String logicExpr) {
    logicExpr = logicExpr.replaceAll('\\s+', ''); // remove all spaces

    List<String> tokens = new List<String>();
    Integer i = 0;
    while (i < logicExpr.length()) {
        String sub = logicExpr.substring(i).toLowerCase();
        if (sub.startsWith('true')) {
            tokens.add('true');
            i += 4;
        } else if (sub.startsWith('false')) {
            tokens.add('false');
            i += 5;
        } else if (sub.startsWith('and')) {
            tokens.add('AND');
            i += 3;
        } else if (sub.startsWith('or')) {
            tokens.add('OR');
            i += 2;
        } else {
            i++;
        }
    }

    // Evaluate AND first
    for (Integer j = 0; j < tokens.size(); j++) {
        if (tokens[j] == 'AND') {
            Boolean left = tokens[j - 1] == 'true';
            Boolean right = tokens[j + 1] == 'true';
            Boolean result = left && right;
            tokens[j - 1] = String.valueOf(result);
            tokens.remove(j); 
            tokens.remove(j); 
            j -= 1;
        }
    }

    // Evaluate OR next
    Boolean finalResult = tokens[0] == 'true';
    for (Integer j = 1; j < tokens.size(); j += 2) {
        String op = tokens[j];
        Boolean nextVal = tokens[j + 1] == 'true';
        if (op == 'OR') {
            finalResult = finalResult || nextVal;
        }
    }

    return finalResult;
}
    
    

}