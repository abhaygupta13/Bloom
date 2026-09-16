/***
Class       : DuplicateRecordSetTriggerHelper
Author      : Biswajeet
Description : Duplicate Record Set object trigger helper
****************************************************************************************************************/
public class DuplicateRecordSetTriggerHelper {
    
    private static final string MD_LEAD_DUPLICATE_RULE_ID { get { return 'LeadDuplicateRuleId'; } }
    private static final string MD_LEAD_DUPLICATE_EMAIL_TEMPLATE_ID { get { return 'DuplicateLeadEmailTemplateId'; } }
    private static final string MD_OWE_NO_REPLY_SALES_IT_ID { get { return 'NoReplySalesIT'; } }
    private static final string MD_DUPLICATE_LEAD_NOTIFICATION_EMAIL_ADDRESS { get { return 'DuplicateLeadNotificationEmailAddress'; } }
    private static final string MD_DUPLICATE_LEASING_LEAD_NOTIFICATION_EMAIL { get { return 'DuplicateLeasingLeadNotificationEmail'; } }
    
    public static void sendDuplicateLeadEmail(List<DuplicateRecordSet> newList){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        Id leadDuplicateRuleId = objMetadataService.getAppSettingTextValue(MD_LEAD_DUPLICATE_RULE_ID);
        Set<Id> duplicateRecordSetIds = new Set<Id>();
        for(DuplicateRecordSet objDuplicateRecordSet :newList){
            if(objDuplicateRecordSet.DuplicateRuleId == leadDuplicateRuleId){
                duplicateRecordSetIds.add(objDuplicateRecordSet.Id);
            }
        }
        
        if(!duplicateRecordSetIds.isEmpty()){
            Map<Id, Set<Id>> duplicateLeadIdMap = new Map<Id, Set<Id>>();
            Set<Id> leadIds = new Set<Id>();
            DuplicateRecordSetService objDuplicateRecordSetService = DuplicateRecordSetService.getInstance();
            
            List<DuplicateRecordItem> duplicateRecordItemList = objDuplicateRecordSetService.getDuplicatItemsByDuplicateRecordSetIds(duplicateRecordSetIds);
            for(DuplicateRecordItem objDuplicateRecordItem :duplicateRecordItemList){
                Set<Id> duplicateLeadIds = new Set<Id>();
                if(duplicateLeadIdMap.containsKey(objDuplicateRecordItem.DuplicateRecordSetId)){
                    duplicateLeadIds = duplicateLeadIdMap.get(objDuplicateRecordItem.DuplicateRecordSetId);
                }
                duplicateLeadIds.add(objDuplicateRecordItem.RecordId);
                duplicateLeadIdMap.put(objDuplicateRecordItem.DuplicateRecordSetId, duplicateLeadIds);
                leadIds.add(objDuplicateRecordItem.RecordId);
            }
            
            if(!duplicateLeadIdMap.isEmpty()){
                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                EmailService objEmailService = EmailService.getInstance();
                LeadService objLeadService = LeadService.getInstance();
                Map<Id, Lead> leadMap = new Map<Id, Lead>(objLeadService.getLeadByIds(leadIds));
                
                EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MD_LEAD_DUPLICATE_EMAIL_TEMPLATE_ID));
                Id noreplySalesITOWDEmailId = objMetadataService.getAppSettingTextValue(MD_OWE_NO_REPLY_SALES_IT_ID);
                String duplicateLeadNotificationEmailAddress = objMetadataService.getAppSettingTextValue(MD_DUPLICATE_LEAD_NOTIFICATION_EMAIL_ADDRESS);
                String duplicateLeasingLeadNotificationEmailAddress = objMetadataService.getAppSettingTextValue(MD_DUPLICATE_LEASING_LEAD_NOTIFICATION_EMAIL);
                
                for(Id duplicateSetId :duplicateLeadIdMap.keySet()){
                    Boolean isLeasing = false;
                    String emailBody = emailTemplate.HtmlValue;
                    List<Id> duplicateLeadIds = new List<Id>(duplicateLeadIdMap.get(duplicateSetId));
                    if(duplicateLeadIds != NULL && !duplicateLeadIds.isEmpty()){
                        Lead objLead = leadMap.get(duplicateLeadIds[0]);
                        String htmlBody = ('<table style="border-collapse: collapse" Border="1" ><thead><tr><th>Name</th><th>Lead Number</th> <th>Mobile</th><th>Email</th><th>Emirates ID</th><th>Passport Number</th><th>Nationality</th><th>Owner</th><th>Status</th><th>Created By</th><th>Created Date</th></tr></thead><tbody>');
                        htmlBody += getDuplicateLeadEmailContent(objLead);
                        htmlBody += ('</tbody></table>');
                        emailBody = emailBody.replace('{{NEWLEADTABLE}}', htmlBody);
                    }
                    if(duplicateLeadIds != NULL && duplicateLeadIds.size() > 1){
                        String htmlBody = '<table  style="border-collapse: collapse" Border="1"  ><thead><tr><th>Lead Name</th><th>Lead Number</th> <th>Mobile</th><th>Email</th><th>Emirates ID</th><th>Passport Number</th><th>Nationality</th><th>Owner</th><th>Status</th><th>Created By</th><th>Created Date</th></tr></thead><tbody>';
                        String firstLeadTeam = leadMap.get(duplicateLeadIds[0]).LeadTeam__c;
						Boolean isMixedTeam = false;
                        for(Integer i = 1; i < duplicateLeadIds.size(); i++){
                            Lead objLead = leadMap.get(duplicateLeadIds[i]);
                            if(objLead.LeadTeam__c != firstLeadTeam){
                                isMixedTeam = true;
                                break;
                            }
                            
                            htmlBody += getDuplicateLeadEmailContent(objLead);
                        }
                        if(isMixedTeam){
                            continue; // don't send the email
                        }
                        String emailRecipient = (firstLeadTeam == 'Leasing') ? duplicateLeasingLeadNotificationEmailAddress : duplicateLeadNotificationEmailAddress;
                        htmlBody += '</tbody></table>';
                        emailBody = emailBody.replace('{{EXISTINGLEADTABLE}}', htmlBody);
                        emails.add(objEmailService.getSingleEmailMessage(emailRecipient.split(','), emailTemplate.Subject,emailBody, noreplySalesITOWDEmailId));
                    }
                }
                objEmailService.sendEmail(emails);
            }
        }
    }
    
    private static String getDuplicateLeadEmailContent(Lead objLead){
        String htmlBody = '<tr><td>' + (objLead.Name != null ? objLead.Name : '') + '</td>';
        htmlBody += ('<td>' + (objLead.LeadNumber__c!=null ? objLead.LeadNumber__c:'') + '</td>');
        htmlBody += ('<td>' + (objLead.MobilePhone!=null ? objLead.MobilePhone:'') + '</td>');
        htmlBody += ('<td>' + (objLead.Email!=null ? objLead.Email:'') + '</td>');
        htmlBody += ('<td>' + (objLead.Emirates_Id__c!=null ? objLead.Emirates_Id__c:'') + '</td>');
        htmlBody += ('<td>' + (objLead.Passport_Number__c!=null ? objLead.Passport_Number__c:'') + '</td>');
        htmlBody += ('<td>' + (objLead.nationality__c!=null ? objLead.nationality__c:'') + '</td>');
        htmlBody += ('<td>' + (objLead.Owner.Name!=null ? objLead.Owner.Name:'') + '</td>');
        htmlBody += ('<td>' + (objLead.Status !=null ? objLead.Status: '') + '</td>');
        htmlBody += ('<td>' + (objLead.CreatedBy.Name!=null ? objLead.CreatedBy.Name:'') + '</td>');
        htmlBody += ('<td>' + (objLead.CreatedDate!=null ? objLead.CreatedDate.format('dd/MM/yyyy'):'') + '</td></tr>');
        return htmlBody;
    }
}