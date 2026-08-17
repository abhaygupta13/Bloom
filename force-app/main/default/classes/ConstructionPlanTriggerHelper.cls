/***
Class       : ConstructionPlanTriggerHelper
Author      : Smaartt
Description : 
TestClass   : ConstructionPlanTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0            23/08/24           Initial Version 
2.          V1.1            26/08/24           added method  sendEmailOnConstructPlanUpdate
3.			V1.2			7/08/25			   modified sendProjectUpdateEmail()
****************************************************************************************************************/
public class ConstructionPlanTriggerHelper {
    
    private static final string MTD_NO_REPLY_SALESIT_OWEID_SETTING { get { return 'NoReplySalesIT'; } }
    private static final string MTD_Construction_Plan_Email_Template_Id { get { return 'ConstructionPlanETId'; } }
    private static final string MTD_Finance_Group_Id { get { return 'Finance_Group_Id'; } }
    private static final string MTD_Operation_Group_Id { get { return 'Operation_Group_Id'; } }
    private static final string MTD_CRM_Operation_Group_Id { get { return 'CRM_Operation_Group_Id'; } }
    private static final string MTD_ProjectTeam_Group_Id { get { return 'Project_Update_Group_Id'; } }
    
    public static void sendProjectUpdateEmail(List<Construction_Plan__c> constructionPlanList) {
        if (!constructionPlanList.isEmpty()) {
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            Id orgWideEmailAddressId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_SALESIT_OWEID_SETTING);
            Id financeGrpId = objMetadataService.getAppSettingTextValue(MTD_Finance_Group_Id);
            Id operationGrpId = objMetadataService.getAppSettingTextValue(MTD_Operation_Group_Id);
            Id crmOperationGrpId = objMetadataService.getAppSettingTextValue(MTD_CRM_Operation_Group_Id);
            Id projectTeamGrpid = objMetadataService.getAppSettingTextValue(MTD_ProjectTeam_Group_Id);
            
            String constructionPlanEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_Construction_Plan_Email_Template_Id);
            
            List<String> toAddresses = new List<String>();
            
            EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(constructionPlanEmailTemplateId);
            
            toAddresses = Utility.getUserEmailsFromPublicGroupIds(new Set<Id>{FinanceGrpId,OperationGrpId,CrmOperationGrpId,ProjectTeamGrpid});
            
            // Initialize placeholders
            String emailSubject = emailTemplate.Subject;
            String emailBody = emailTemplate.HtmlValue;
            DateTime dt = DateTime.now();
            Set<String> projectNamesSet = new Set<String>();
            String constructionPlansText = '';
            String recordLinks = '';
            String projectUrl = '';
            
            for (Construction_Plan__c cp : constructionPlanList) {
                if (String.isNotBlank(cp.Project__c) && !projectNamesSet.contains(cp.Project_Name__c)) {
                    projectNamesSet.add(cp.Project_Name__c);
                    constructionPlansText += ('- ' + cp.Project_Name__c + '\n');
                    projectUrl = System.URL.getOrgDomainUrl().toExternalForm() + '/' + cp.Id;
                }     
            }
            // Replace placeholders in the email body
            emailSubject = emailSubject.replace('{Project}', constructionPlansText);
            emailBody = emailBody.replace('{Project}', constructionPlansText);
            emailBody = emailBody.replace('{Project_Url}', projectUrl);
            
            if (!toAddresses.isEmpty()) {
                objEmailService.sendMailWithHtmlBody(toAddresses, emailSubject, emailBody, null, null, orgWideEmailAddressId);
            }
        }
    }
    
    public static void sendEmailOnConstructPlanUpdate(List<Construction_Plan__c> newList, Map<Id, Construction_Plan__c> oldMap) {
        List<Construction_Plan__c> constructionPlanList = new List<Construction_Plan__c>();
        List<Schema.FieldSetMember> fieldsToCheck = Schema.SObjectType.Construction_Plan__c.fieldSets.getMap().get('CP_Update_Fields').getFields();
        for (Construction_Plan__c record : newList) {
            for (FieldSetMember member : fieldsToCheck){
                String field = member.getFieldPath();
                if (record.get(field) != oldMap.get(record.Id).get(field)){
                    constructionPlanList.add(record);
                }
            }
        }
        
        if (!constructionPlanList.isEmpty()) {
            ConstructionPlanTriggerHelper.sendProjectUpdateEmail(constructionPlanList);
        }
    }
}