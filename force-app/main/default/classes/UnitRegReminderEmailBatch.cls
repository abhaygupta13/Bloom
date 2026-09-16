/*****************************************************************************************
Class       : UnitRegReminderEmailBatch
Author      : Jayesh
Description : Batch class to send email to internal teams (Operation, CRM and SalesFinance Team).
Test Class  : UnitRegReminderEmailBatchTest
Created Date: 28 Nov 2024
*****************************************************************************************/
public class UnitRegReminderEmailBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'NoReplySalesIT'; } }
    private static final string MTD_UPLOADING_DOC_EMAIL_TEMPLATE_ID { get { return 'UploadingDocumentEmailTemplateId'; } } 
    private static final string MTD_UNREG_EMAIL_TEMPLATE_ID { get { return 'UnregisteredUnitsEmailTemplateID'; } } 
    private static final string MTD_FUNDNOTMOVE_EMAIL_TEMPLATE_ID { get { return 'FundNotMovedEmailTemplateId'; } } 
    private static final string MTD_FUNDS_MOVED_EMAIL_TEMPLATE_ID { get { return 'FundsMovedEmailTemplateId'; } }
    private static final string MTD_FUNDS_MOVED_GR_EMAIL_TEMPLATE_ID { get { return 'FundsMovedGREmailTemplateId'; } }
    private static final string MTD_OPT_TEAM_EMAIL_ADDSS { get { return 'OperationTeamEmailAddresses'; } }
    private static final string MTD_CRM_TEAM_EMAIL_ADDSS { get { return 'CRMTeamEmailAddresses'; } }
    private static final string MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS { get { return 'SalesFinanceTeamEmailAddresses'; } }
    private static final string MTD_GR_TEAM_EMAIL_ADDSS { get { return 'GRTeamEmailAddresses'; } }
    private static final string REMINDER_DAYS { get { return 'ProjectUnitRegEmailReminderDays'; } }
    private static final string YESTERDAY_DAY { get { return 'Yesterday'; } }
    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();
    private static final Map<Id, Project__c> mapOfIdAndProject = new Map<Id, Project__c>();
    
    // Query to fetch records
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            Select Id, Name
            FROM Project__c
            WHERE ProjectRegistrationDate__c != null
        ]);
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UnitRegReminderEmailBatch());
    }
    
    // Processing each batch
    public void execute(Database.BatchableContext bc, List<Project__c> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Integer threeDays = objMetadataService.getAppSettingNumberValue(REMINDER_DAYS);
        Integer oldDay = objMetadataService.getAppSettingNumberValue(YESTERDAY_DAY);
        Map<Id, List<Unit__c>> projectWithNotRegisteredUnits = new Map<Id, List<Unit__c>>();
        Map<Id, List<Unit__c>> projectWithFundNotMovedUnits = new Map<Id, List<Unit__c>>();
        Map<Id, List<Unit__c>> projectWithDocumentUploadedUnits = new Map<Id, List<Unit__c>>();
        Map<Id, List<Unit__c>> projectWithFundMovedDate = new Map<Id, List<Unit__c>>();
        Date threeDaysAgo = System.today().addDays(-threeDays);
        Date yesterday_OldDay = System.today().addDays(oldDay);
        Date yesterdayDateValue = System.today().addDays(-1);
        
        for(Unit__c unit : [SELECT Id, Name, RegistrationDate__c, ADMPlotNumber__c, Active_Sales_Order__r.DocumentUploadedDate__c, Active_Sales_Order__c, Active_Sales_Order__r.Name,
                            Project__r.Name,Project__r.ProjectRegistrationDate__c, Project__c, ProjectName__c, Active_Sales_Order__r.Account__r.Name,Active_Sales_Order__r.FundReleaseRequested__c,
                            Project__r.LastProjectRegEmailReminder__c, Active_Sales_Order__r.FundMovedToGRDate__c, Active_Sales_Order__r.FundMovedtoGR__c
                            FROM Unit__c 
                            WHERE Project__c IN :scope AND Active_Sales_Order__c != null
                           ]){
                               if (unit.RegistrationDate__c == null && unit.Project__r.LastProjectRegEmailReminder__c == threeDaysAgo) {   
                                   if (!projectWithNotRegisteredUnits.containsKey(unit.Project__c)) {
                                       projectWithNotRegisteredUnits.put(unit.Project__c, new List<Unit__c>());
                                   }
                                   projectWithNotRegisteredUnits.get(unit.Project__c).add(unit);  
                               }  
                               if (unit.Active_Sales_Order__r.FundReleaseRequested__c == true && unit.Active_Sales_Order__r.FundMovedToGRDate__c == null && unit.Active_Sales_Order__r.FundMovedtoGR__c != 'Completed') {   
                                   if (!projectWithFundNotMovedUnits.containsKey(unit.Project__c)) {
                                       projectWithFundNotMovedUnits.put(unit.Project__c, new List<Unit__c>());
                                   }
                                   projectWithFundNotMovedUnits.get(unit.Project__c).add(unit);  
                               }
                               if (unit.Active_Sales_Order__r.DocumentUploadedDate__c == yesterday_OldDay) {   
                                   if (!projectWithDocumentUploadedUnits.containsKey(unit.Project__c)) {
                                       projectWithDocumentUploadedUnits.put(unit.Project__c, new List<Unit__c>());
                                   }
                                   projectWithDocumentUploadedUnits.get(unit.Project__c).add(unit);  
                               }  
                               if(unit.Active_Sales_Order__r.FundReleaseRequested__c == true && unit.Active_Sales_Order__r.FundMovedToGRDate__c != null && unit.Active_Sales_Order__r.FundMovedToGRDate__c == yesterdayDateValue && unit.Active_Sales_Order__r.FundMovedtoGR__c == 'Completed'){
                                   if (!projectWithFundMovedDate.containsKey(unit.Project__c)) {
                                       projectWithFundMovedDate.put(unit.Project__c, new List<Unit__c>());
                                   }
                                   projectWithFundMovedDate.get(unit.Project__c).add(unit);  
                               }
                           }
        if(projectWithDocumentUploadedUnits != null && !projectWithDocumentUploadedUnits.isEmpty()) sendDocumentUploadedConfirmationEmail(projectWithDocumentUploadedUnits);
        if(projectWithNotRegisteredUnits != null && !projectWithNotRegisteredUnits.isEmpty()) sendEmailForUnregisteredUnits(projectWithNotRegisteredUnits);
        if(projectWithFundNotMovedUnits != null && !projectWithFundNotMovedUnits.isEmpty()) sendFundNotMovedUnitEmail(projectWithFundNotMovedUnits);
        if(projectWithFundMovedDate != null && !projectWithFundMovedDate.isEmpty()){
            sendProjectWithFundMovedDateEmail(projectWithFundMovedDate);
            sendGRNotificationEmail(projectWithFundMovedDate);
        }
    }
    
    // Post-batch processing
    public void finish(Database.BatchableContext bc) {
        if(!mapOfIdAndProject.isEmpty()){
            ProjectService ps = ProjectService.getInstance();
            ps.updateProjects(mapOfIdAndProject.Values());
        }
    }
    
    private static void sendDocumentUploadedConfirmationEmail(Map<Id, List<Unit__c>> projectToUnitsMap){
        List<String> toAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();    
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String optTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_OPT_TEAM_EMAIL_ADDSS);
        String crmTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_EMAIL_ADDSS);
        String salesFinanceTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS);
        EmailTemplate documentUploadET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_UPLOADING_DOC_EMAIL_TEMPLATE_ID));
        
        toAddress.addAll(optTeamEmailAddress.split(','));
        toAddress.addAll(crmTeamEmailAddress.split(','));
        toAddress.addAll(salesFinanceTeamEmailAddress.split(','));
        //Send email as a unit registration table
        for(Id pId : projectToUnitsMap.KeySet()){
            if(projectToUnitsMap.get(pId) != null || !projectToUnitsMap.get(pId).isEmpty()){
                String projectName;
                String projectLink;
                String emailSub = documentUploadET.Subject;
                String emailBody = documentUploadET.HtmlValue;
                List<Unit__c> units = projectToUnitsMap.get(pId); 
                String registrationTable = tableHeaderDocumentUploadedUnits();
                for(Unit__c unit : units){
                    projectName = unit.ProjectName__c;
                    registrationTable += tableBodyDocumentUploadedUnits(unit);
                }
                registrationTable += '</table>';
                projectLink = '<a href="'+BASE_URL+ '/' + pId + '">'+projectName+'</a>';
                emailSub = emailSub.replace('[Project_Name]', projectName);
                emailBody = emailBody.replace('{{UNITS_TABLE}}', registrationTable);
                emailBody = emailBody.replace('[Project_Name]', projectName);
                emailBody = emailBody.replace('[Project_Link]', projectLink);
                emailList.add(objEmailService.getSingleEmailMessage(toAddress, emailSub, emailBody, noReplyOWDId)); 
            }
        }
        objEmailService.sendEmail(emailList);
    }
    
    //Send email after 3 days of project registration for Unregistered Units 
    private static void sendEmailForUnregisteredUnits(Map<Id, List<Unit__c>> projectUnitsMap){
        List<String> toAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();    
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String optTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_OPT_TEAM_EMAIL_ADDSS);
        String crmTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_EMAIL_ADDSS);
        String salesFinanceTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS);
        Id EmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_UNREG_EMAIL_TEMPLATE_ID);
        EmailTemplate documentUploadET = objEmailService.getEmailTemplateById(EmailTemplateId);
        toAddress.addAll(optTeamEmailAddress.split(','));
        toAddress.addAll(crmTeamEmailAddress.split(','));
        toAddress.addAll(salesFinanceTeamEmailAddress.split(','));
        
        //Send email as a unit registration table
        for(Id pId : projectUnitsMap.KeySet()){
            if(projectUnitsMap.get(pId) != null || !projectUnitsMap.get(pId).isEmpty()){
                String projectName;
                String projectLink;
                String emailSub = documentUploadET.Subject;
                String emailBody = documentUploadET.HtmlValue;
                List<Unit__c> units = projectUnitsMap.get(pId); 
                String registrationTable = tableHeaderForUnregisteredAndFundNotMovedUnits();
                for(Unit__c unit : units){
                    projectName = unit.ProjectName__c;
                    registrationTable += tableBodyForUnregisteredAndFundNotMovedUnits(unit);
                }
                registrationTable += '</table>';
                projectLink = '<a href="'+BASE_URL+ '/' + pId + '">'+projectName+'</a>';
                emailSub = emailSub.replace('[Project_Name]', projectName);
                emailBody = emailBody.replace('{{UNITS_TABLE}}', registrationTable);
                //emailBody = emailBody.replace('[Project_Name]', projectName);
                emailBody = emailBody.replace('[Project_Link]', projectLink);
                emailList.add(objEmailService.getSingleEmailMessage(toAddress, emailSub, emailBody, noReplyOWDId)); 
            }
            Project__c project = new Project__c(Id = pId,LastProjectRegEmailReminder__c = System.today());
            mapOfIdAndProject.put(pId, project);
        }
        objEmailService.sendEmail(emailList);
        
    }
    
    
    private static void sendFundNotMovedUnitEmail(Map<Id, List<Unit__c>> projectToUnitsMap){
        List<String> toAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();    
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String salesFinanceTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS);
        EmailTemplate documentUploadET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_FUNDNOTMOVE_EMAIL_TEMPLATE_ID));
        toAddress.addAll(salesFinanceTeamEmailAddress.split(','));
        //Send email as a unit registration table
        for(Id pId : projectToUnitsMap.KeySet()){
            if(projectToUnitsMap.get(pId) != null || !projectToUnitsMap.get(pId).isEmpty()){
                String projectName;
                String projectLink;
                String emailSub = documentUploadET.Subject;
                String emailBody = documentUploadET.HtmlValue;
                List<Unit__c> units = projectToUnitsMap.get(pId); 
                String registrationTable = tableHeaderForUnregisteredAndFundNotMovedUnits();
                for(Unit__c unit : units){
                    projectName = unit.ProjectName__c;
                    registrationTable += tableBodyForUnregisteredAndFundNotMovedUnits(unit);
                }
                registrationTable += '</table>';
                projectLink = '<a href="'+BASE_URL+ '/' + pId + '">'+projectName+'</a>';
                emailSub = emailSub.replace('[Project_Name]', projectName);
                emailBody = emailBody.replace('{{UNITS_TABLE}}', registrationTable);
                emailBody = emailBody.replace('[Project_Link]', projectLink);
                emailList.add(objEmailService.getSingleEmailMessage(toAddress, emailSub, emailBody, noReplyOWDId)); 
            }
        }
        objEmailService.sendEmail(emailList);
    }
    
    private static void sendProjectWithFundMovedDateEmail(Map<Id, List<Unit__c>> projectToUnitsMap){
        List<String> toAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();    
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String optTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_OPT_TEAM_EMAIL_ADDSS);
        EmailTemplate documentUploadET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_FUNDS_MOVED_EMAIL_TEMPLATE_ID));
        toAddress.addAll(optTeamEmailAddress.split(','));
        //Send email as a unit registration table
        for(Id pId : projectToUnitsMap.KeySet()){
            if(projectToUnitsMap.get(pId) != null || !projectToUnitsMap.get(pId).isEmpty()){
                String projectName;
                String projectLink;
                String emailSub = documentUploadET.Subject;
                String emailBody = documentUploadET.HtmlValue;
                List<Unit__c> units = projectToUnitsMap.get(pId); 
                String registrationTable = tableHeaderForUnregisteredAndFundNotMovedUnits();
                for(Unit__c unit : units){
                    projectName = unit.ProjectName__c;
                    registrationTable += tableBodyForUnregisteredAndFundNotMovedUnits(unit);
                }
                registrationTable += '</table>';
                projectLink = '<a href="'+BASE_URL+ '/' + pId + '">'+projectName+'</a>';
                emailSub = emailSub.replace('[Project_Name]', projectName);
                emailBody = emailBody.replace('{{UNITS_TABLE}}', registrationTable);
                emailBody = emailBody.replace('[Project_Link]', projectLink);
                emailList.add(objEmailService.getSingleEmailMessage(toAddress, emailSub, emailBody, noReplyOWDId)); 
            }
        }
        objEmailService.sendEmail(emailList);
    }
    
    private static void sendGRNotificationEmail(Map<Id, List<Unit__c>> projectToUnitsMap){
        List<String> toAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String grTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_GR_TEAM_EMAIL_ADDSS);
        toAddress.addAll(grTeamEmailAddress.split(','));
        EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_FUNDS_MOVED_GR_EMAIL_TEMPLATE_ID));
        for(Id pId : projectToUnitsMap.keySet()){
            List<Unit__c> units = projectToUnitsMap.get(pId);
            String projectName;
            String projectLink;
            String emailSub = emailTemplate.Subject;
            String emailBody = emailTemplate.HtmlValue;
            String registrationTable = tableHeaderForUnregisteredAndFundNotMovedUnits();
            for(Unit__c unit : units){
                projectName = unit.ProjectName__c;
                registrationTable += tableBodyForUnregisteredAndFundNotMovedUnits(unit);
            }
            registrationTable += '</table>';
            projectLink = '<a href="'+ BASE_URL + '/' + pId + '">' + projectName + '</a>';
            emailSub = emailSub.replace('[Project_Name]', projectName);
            emailBody = emailBody.replace('{{UNITS_TABLE}}',registrationTable);
            emailList.add(objEmailService.getSingleEmailMessage(toAddress,emailSub,emailBody,noReplyOWDId));
        }
        objEmailService.sendEmail(emailList);
    }
    
    private static String tableHeaderForUnregisteredAndFundNotMovedUnits(){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        emailBody += '<tr>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Sales Order Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Unit Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Plot Number</th>';
        emailBody += '</tr>';
        return emailBody;
    }
    
    private static String tableBodyForUnregisteredAndFundNotMovedUnits(Unit__c unit){
        String unitLink = '<a href="'+BASE_URL+ '/' + unit.Id + '">' + unit.Name + '</a>';
        String soLink = '<a href="'+BASE_URL+ '/' + unit.Active_Sales_Order__c + '">' + unit.Active_Sales_Order__r.Name + '</a>';
        String htmlBody = '<tr>';
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + soLink+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unitLink+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unit.ADMPlotNumber__c+ '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
    
    private static String tableHeaderDocumentUploadedUnits(){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        emailBody += '<tr>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Sales Order Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Unit Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Customer Name</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Document Uploaded Date</th>';
        emailBody += '</tr>';
        return emailBody;
    }
    
    private static String tableBodyDocumentUploadedUnits(Unit__c unit){
        String unitLink = '<a href="'+BASE_URL+ '/' + unit.Id + '">' + unit.Name + '</a>';
        String soLink = '<a href="'+BASE_URL+ '/' + unit.Active_Sales_Order__c + '">' + unit.Active_Sales_Order__r.Name + '</a>';
        String docUploadedDate='';
        if(unit.Active_Sales_Order__r.DocumentUploadedDate__c!=null){
            docUploadedDate= unit.Active_Sales_Order__r.DocumentUploadedDate__c.format();
        }
        String htmlBody = '<tr>';
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + soLink+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unitLink+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unit.Active_Sales_Order__r.Account__r.Name+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + docUploadedDate+ '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
}