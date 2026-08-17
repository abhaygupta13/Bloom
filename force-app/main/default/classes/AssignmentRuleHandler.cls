/*****************************************************************************************
Class       : AssignmentRuleHandler
Author      : Biswajeet
Description : Assignment Rule Service
test Class  : AssignmentRuleHandlerTest
Created Date: 29 AUG 2024 
*****************************************************************************************/
public inherited sharing class AssignmentRuleHandler {
    
    private static final string DIGITAL_LEAD_CREATED_BY_IDS { get { return 'DigitalLeadCreatedByIds'; } }
    private static final string DIGITAL_CASE_CREATED_BY_IDS { get { return 'DigitalCaseCreatedByIds'; } }
    private static final string DIGITAL_LEAD_CREATED_BY_Profile_IDS { get { return 'DigitalLeadCreatedByProfileIds'; } }   
    private static final string COMPLAINT_CASE_CREATED_BY_Profile_IDS { get { return 'ComplaintCaseCreatedByProfileIds'; } }
    private static final string CONTACT_CENTER_PROFILE_ID { get { return 'ContactCentreProfileId'; } }
    private static final string ASSIGNMENT_RULE_RECORD_TYPE_LEAD { get { return 'Lead'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_TYPE_LEASING { get { return 'Leasing'; } }
    private static final string ASSIGNMENT_RULE_RECORD_TYPE_CASE { get { return 'Case'; } }
    private static final string ASSIGNMENT_RULE_RECORD_TYPE_HANDOVER { get { return 'Handover'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_DIGITAL_LEAD_ASSIGNMENT { get { return 'Digital Lead Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_ADHA_LEAD_ASSIGNMENT { get { return 'ADHA Lead Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_DIGITAL_LEASING_LEAD_ASSIGNMENT { get { return 'Digital Leasing Lead Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_DIGITAL_CASE_ASSIGNMENT { get { return 'Digital Case Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_ANPR_SERVICE_REQUEST_ASSIGNMENT { get { return 'ANPR Service Request Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_BFM_EMAIL_TO_CASE_ASSIGNMENT { get { return 'BFM Email To Case Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_GENERAL_COMPLAINT_CASE_ASSIGNMENT { get { return 'General Complaint Case Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_DIGITAL_QUALIFIED_LEAD_ASSIGNMENT { get { return 'Qualified Lead Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_LEASING_RESIDENTIAL_QUALIFIED_LEAD_ASSIGNMENT { get { return 'Leasing Residential Qualified Lead Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_LEASING_COMMERCIAL_QUALIFIED_LEAD_ASSIGNMENT { get { return 'Leasing Commercial Qualified Lead Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_CRM_CASE_ASSIGNMENT { get { return 'CRM Case Assignment'; } }
      private static final string ASSIGNMENT_RULE_PROCESS_CRM_COMPLAINT_CASE_ASSIGNMENT { get { return 'CRM Complaint Case Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_CRM_HANDOVER_ASSIGNMENT { get { return 'Handover CRM Agent Assignment'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_CRM_RESALE_CASE_ASSIGNMENT { get { return 'CRM Resale Case Assignment'; } }
    private static final string MTD_LEASING_LEAD_DEFAULT_QUEUE_ID { get { return 'LeasingLeadDefaultQueueId'; } }
    private static final string LEASING_LEAD_CREATED_BY_IDS { get { return 'LeasingLeadCreatedByIds'; } }
    private static final string COMMUNITY_MANAGEMENT_STR { get { return 'Community Management'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_NAME_COMMUNITY_APP_SERVICE_REQUEST_ASSIGNMENT { get { return 'Community App Service Request Assignment'; } }
    private static final string COMMUNITY_APP_SR_CREATED_IDS { get { return 'CommunityAppSRCreatedIds'; } }
    private static final string ASSIGNMENT_RULE_PROCESS_BROKER_CASE_ASSIGNMENT { get { return 'Broker Case Assignment'; } } //BAPP Broker Generic Case
    private static final string MTD_SERVICE_REQUEST_ASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestAssignmentId'; } }
    private static final string MTD_COMMUNITY_SR_ASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'CommunityAppSRAssignmentEmailTempId'; } }
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final String SUPER_APP_REGISTRATION_CASE_ASSIGNMENT { get { return 'Super App Registration Case Assignment'; } }
    private static final String SUPER_APP_OPERATION_TEAM_CASE_ASSIGNMENT { get { return 'Super App Operation Team Case Assignment'; } }
    private static final String SUPER_APP_STR = 'Super App';
    private static final string BLC_CASE_ASSIGNMENT { get { return 'BLC Common Area SR Assignment'; } }
    private static final string DLP_CASE_ASSIGNMENT { get { return 'DLP Common Area SR Assignment'; } }
    private static final string SUBMITTED_STR { get { return 'Submitted'; } }


    
    //Digital Marketing Sales Lead Auto Assignment
    public static void salesDigitalLeadAssignment(List<Id> recordIds){
        //MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        Set<Id> leadIds = new Set<Id>(recordIds);
        List<Lead> leadList = objLeadService.getLeadByIds(leadIds);
        
        // Filter out leads where IsDraftLead__c = true
        List<Lead> filteredLeads = new List<Lead>();
        for (Lead l : leadList) {
            if (l.IsDraftLead__c == false) {
                filteredLeads.add(l);
            }
        }
        if(!filteredLeads.isEmpty()){
            
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_LEAD,ASSIGNMENT_RULE_PROCESS_DIGITAL_LEAD_ASSIGNMENT,'Sales');
            
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                filteredLeads = objAssignmentRuleService.assignRecordOwner(filteredLeads, objAssignmentRule, assignmentUserList);
                for(Lead objLead : filteredLeads){
                    objLead.Status = 'In Progress';
                    objLead.ContactCenterAssignedDate__c = System.now();
                    objLead.ContactCentreLeadStatus__c = 'New';
                }
                objLeadService.updateLeadsWithoutDuplicateRule(filteredLeads); 
            }            
        }
    }
    
    //Digital Marketing Sales Qualified Lead Auto Assignment
    public static void salesDigitalQualifiedLeadAssignment(List<Id> recordIds){
        
        LeadService objLeadService = LeadService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String digitalLeadCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_LEAD_CREATED_BY_IDS);
        String qualifiedLeadCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_LEAD_CREATED_BY_Profile_IDS);
        
        List<Id> digitalLeadCreatedByUserIdList = digitalLeadCreatedByIds.split(',');
        List<Id> qualifiedLeadCreatedByProfileIdList = qualifiedLeadCreatedByIds.split(',');
        
        Set<Id> leadIds = new Set<Id>(recordIds);
        Set<Id> digitalLeadCreatedByUserIds = new Set<Id>(digitalLeadCreatedByUserIdList);
        Set<Id> qualifiedLeadCreatedByProfileIds = new Set<Id>(qualifiedLeadCreatedByProfileIdList);
        List<Lead> leadList = objLeadService.getLeadByCreatedByIds(leadIds, digitalLeadCreatedByUserIds,qualifiedLeadCreatedByProfileIds);
        
        if(!leadList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_LEAD, ASSIGNMENT_RULE_PROCESS_DIGITAL_QUALIFIED_LEAD_ASSIGNMENT,'Sales');
            Integer assignmentAgentIndex = 0;
            List<Lead> updateLeadList = new List<Lead>();
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                leadList = objAssignmentRuleService.assignRecordOwner(leadList, objAssignmentRule, assignmentUserList);
                for(Lead objLead : leadList){
                    objLead.LeadManagerStatus__c = 'New';
                    objLead.Status = 'In Progress';
                    objLead.LeadManagerAssignedDate__c = System.now();
                }
                objLeadService.updateLeadsWithoutDuplicateRule(leadList); 
            }
        }
    }
    
    //ADHA Lead Auto Assignment
    public static void adhaLeadAssignment(List<Id> recordIds){
        
        LeadService objLeadService = LeadService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Set<Id> leadIds = new Set<Id>(recordIds);
        List<Lead> leadList = objLeadService.getLeadByIds(leadIds);
        
        if(!leadList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_LEAD, ASSIGNMENT_RULE_PROCESS_ADHA_LEAD_ASSIGNMENT,'Sales');
            Integer assignmentAgentIndex = 0;
            List<Lead> updateLeadList = new List<Lead>();
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                leadList = objAssignmentRuleService.assignRecordOwner(leadList, objAssignmentRule, assignmentUserList);
                for(Lead objLead : leadList){
                    objLead.LeadManagerStatus__c = 'New';
                    objLead.Status = 'In Progress';
                    objLead.LeadManagerAssignedDate__c = System.now();
                }
                objLeadService.updateLeadsWithoutDuplicateRule(leadList); 
            }
        }
    }
    
    public static void leasingLeadAssignment(List<Id> recordIds) {
        LeadService objLeadService = LeadService.getInstance();
        Set<Id> leadIds = new Set<Id>(recordIds);
        List<Lead> leadList = objLeadService.getLeadByIds(leadIds);
        if(!leadList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_LEAD,ASSIGNMENT_RULE_PROCESS_DIGITAL_LEASING_LEAD_ASSIGNMENT,'Leasing');
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                leadList = objAssignmentRuleService.assignRecordOwner(leadList, objAssignmentRule, assignmentUserList);
                for(Lead objLead : leadList){
                    objLead.ContactCenterAssignedDate__c = System.now();
                    objLead.ContactCentreLeadStatus__c = 'New';
                    objLead.Status = 'In Progress';
                }
                objLeadService.updateLeadsWithoutDuplicateRule(leadList);
            }            
        }
    }
    
    public static void leasingQualifiedLeadAssignment(List<Id> recordIds) {
        LeadService objLeadService = LeadService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        String digitalLeadCreatedByIds = objMetadataService.getAppSettingTextValue(LEASING_LEAD_CREATED_BY_IDS);
        String qualifiedLeadCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_LEAD_CREATED_BY_Profile_IDS);
        
        List<Id> digitalLeadCreatedByUserIdList = digitalLeadCreatedByIds.split(',');
        List<Id> qualifiedLeadCreatedByProfileIdList = qualifiedLeadCreatedByIds.split(',');
        
        Set<Id> leadIds = new Set<Id>(recordIds);
        Set<Id> digitalLeadCreatedByUserIds = new Set<Id>(digitalLeadCreatedByUserIdList);
        Set<Id> qualifiedLeadCreatedByProfileIds = new Set<Id>(qualifiedLeadCreatedByProfileIdList);
        
        List<Lead> leadList = objLeadService.getLeadByCreatedByIds(leadIds, digitalLeadCreatedByUserIds, qualifiedLeadCreatedByProfileIds);
        AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
        List<AssignmentRule__c> objAssignmentRuleList = objAssignmentRuleService.getAssignmentRulesAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_LEAD, ASSIGNMENT_RULE_PROCESS_TYPE_LEASING);
        List<Lead> leadUpdateList = new List<Lead>();
        
        Id leasingLeadDefaultQueueId = objMetadataService.getAppSettingTextValue(MTD_LEASING_LEAD_DEFAULT_QUEUE_ID);
        for(Lead objLead :leadList){
            if(String.isNotBlank(objLead.Project__c)){
                Boolean hasValidAssignmentRule = false;
                for(AssignmentRule__c objAssignmentRule :objAssignmentRuleList){
                    AssignmentRule__c objEligibleAssignmentRule;
                    List<String> propertyTypes = String.isNotBlank(objAssignmentRule.PropertyType__c) ? objAssignmentRule.PropertyType__c.split(';') : new List<String>();
                    List<String> projectList = String.isNotBlank(objAssignmentRule.Project__c) ? objAssignmentRule.Project__c.split(';') : new List<String>();
                    if(projectList.contains(objLead.Project__c) && objLead.IsCommercialLeasing__c && propertyTypes.contains('Commercial')){
                        objEligibleAssignmentRule = objAssignmentRule;
                    }else if (projectList.contains(objLead.Project__c) && propertyTypes.contains('Residential') && !objLead.IsCommercialLeasing__c){
                        objEligibleAssignmentRule = objAssignmentRule;                        
                    }
                    if(objEligibleAssignmentRule != NULL){
                        hasValidAssignmentRule = true;
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                        List<Lead> assignedLeadList = objAssignmentRuleService.assignRecordOwner(new List<lead>{objLead}, objAssignmentRule, assignmentUserList);
                        leadUpdateList.addAll(assignedLeadList);
                    }
                }
                if(!hasValidAssignmentRule){
                    objLead.OwnerId = leasingLeadDefaultQueueId;
                    leadUpdateList.add(objLead);
                }
            }else{
                objLead.OwnerId = leasingLeadDefaultQueueId;
                leadUpdateList.add(objLead);
            }
        }
        for(Lead objLead :leadUpdateList){
            objLead.LeadManagerStatus__c = 'New';
            objLead.Status = 'In Progress';
            objLead.LeadManagerAssignedDate__c = System.now();
        }
        objLeadService.updateLeadsWithoutDuplicateRule(leadUpdateList);
    }
    
    public static List<Lead> salesLeadReshuffle(Set<Id> leadIds) {
        LeadService objLeadService = LeadService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String digitalLeadCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_LEAD_CREATED_BY_IDS);
        String qualifiedLeadCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_LEAD_CREATED_BY_Profile_IDS);
        List<Id> digitalLeadCreatedByUserIdList = digitalLeadCreatedByIds.split(',');
        List<Id> qualifiedLeadCreatedByProfileIdList = qualifiedLeadCreatedByIds.split(',');
        Set<Id> digitalLeadCreatedByUserIds = new Set<Id>(digitalLeadCreatedByUserIdList);
        Set<Id> qualifiedLeadCreatedByProfileIds = new Set<Id>(qualifiedLeadCreatedByProfileIdList);
        List<Lead> leadList = objLeadService.getLeadByCreatedByIds(leadIds, digitalLeadCreatedByUserIds,qualifiedLeadCreatedByProfileIds);
        List<Lead> updateLeadList = new List<Lead>();
        
        if(!leadList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_LEAD, ASSIGNMENT_RULE_PROCESS_DIGITAL_QUALIFIED_LEAD_ASSIGNMENT,'Sales');
            if(objAssignmentRule != NULL){
                Map<Id, AssignmentUser__c> assignmentUserMap = objAssignmentRuleService.getAvailableAssignmentUserMap(objAssignmentRule.AssignmentUsers__r);
                System.debug('Available Users Count = ' + assignmentUserMap.size());
                System.debug('Available User Ids = ' + assignmentUserMap.keySet());
                Integer assignmentAgentIndex = 0;
                Integer roundRobinNumber = 0;
                if (!assignmentUserMap.isEmpty()) {
                    for(Lead objLead :leadList){
                        Map<Id, AssignmentUser__c> filteredUserMap = new Map<Id, AssignmentUser__c>(assignmentUserMap);
                        if(assignmentUserMap.containsKey(objLead.OwnerId)){
                            filteredUserMap.remove(objLead.OwnerId);
                        }
                        if (!filteredUserMap.isEmpty()) {
                            Id newOwnerId = new List<Id>(filteredUserMap.keySet())[0];
                            objLead.OwnerId = newOwnerId;
                            objLead.LeadManagerAssignedDate__c = System.now();
                            updateLeadList.add(objLead);
                        }
                    }
                }
            }
        }
        return updateLeadList;
    }
    
    public static void qualifiedLeadAssignment(List<Id> recordIds){
        LeadService objLeadService = LeadService.getInstance();
        Set<Id> leadIds = new Set<Id>(recordIds);
        List<Lead> leadListToProcess = objLeadService.getLeadByIds(leadIds);
        List<Id> qualifiedSalesLeadIds = new List<Id>();
        List<Id> qualifiedLeasingLeadIds = new List<Id>();
        for(Lead l: leadListToProcess){
            if(l.LeadTeam__c == 'Sales'){
                qualifiedSalesLeadIds.add(l.Id);
            }else if(l.LeadTeam__c == 'Leasing'){
                qualifiedLeasingLeadIds.add(l.Id);
            }
        }
        if(!qualifiedLeasingLeadIds.isEmpty()){
            leasingQualifiedLeadAssignment(qualifiedLeasingLeadIds);
        }
        if(!qualifiedSalesLeadIds.isEmpty()){
            salesDigitalQualifiedLeadAssignment(qualifiedSalesLeadIds);
        }
    }
    
    //Digital Marketing Case Auto Assignment
    public static void salesDigitalCaseAssignment(List<Id> recordIds){
        
        CaseService objCaseService = CaseService.getInstance();
        
        Set<Id> caseIds = new Set<Id>(recordIds);
        
        List<Case> caseList = objCaseService.getCaseByIds(caseIds);
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_DIGITAL_CASE_ASSIGNMENT,'Sales');
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
                objCaseService.updateCasesWithoutTrigger(caseList); 
            }
        }
        objCaseService.updateCasesWithoutTrigger(caseList);
    }
    
    //Community App Service Request Assignment
    public static void communityAppServiceRequestAssignment(List<Id> recordIds) {
        CaseService objCaseService = CaseService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String communityCaseCreatedIds = objMetadataService.getAppSettingTextValue(COMMUNITY_APP_SR_CREATED_IDS);
        List<Id> communityCaseCreatedUserIdList = communityCaseCreatedIds.split(',');
        Set<Id> communityCaseCreatedUserIds = new Set<Id>(communityCaseCreatedUserIdList);
        //if running from test class
        if(Test.isRunningTest()){
            communityCaseCreatedUserIds.add(UserInfo.getUserId());
        }
        
        List<Case> caseList = objCaseService.getCaseByIdsAndCreatedByIds(new Set<Id>(recordIds), communityCaseCreatedUserIds);
        AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
        List<AssignmentRule__c> objAssignmentRuleList = objAssignmentRuleService.getAssignmentRules(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_NAME_COMMUNITY_APP_SERVICE_REQUEST_ASSIGNMENT, COMMUNITY_MANAGEMENT_STR);
        List<Case> caseUpdateList = new List<Case>();
        
        Set<Id> caseOwnerIdSet = new Set<Id>();
        for(Case objCase :caseList){
            if(String.isNotBlank(objCase.Projectname__c) && objCase.Status == SUBMITTED_STR){
                for(AssignmentRule__c objAssignmentRule :objAssignmentRuleList){
                    AssignmentRule__c objEligibleAssignmentRule;
                    List<String> projectList = String.isNotBlank(objAssignmentRule.Project__c) ? objAssignmentRule.Project__c.split(';') : new List<String>();
                    if(projectList.contains(objCase.Projectname__c)){
                        objEligibleAssignmentRule = objAssignmentRule;
                    }
                    if(objEligibleAssignmentRule != NULL){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                        List<Case> assignedCaseList = objAssignmentRuleService.assignRecordOwner(new List<Case>{objCase}, objAssignmentRule, assignmentUserList);
                        caseOwnerIdSet.add(assignedCaseList[0].OwnerId);
                        caseUpdateList.addAll(assignedCaseList);
                    }
                }
            }
        }
        objCaseService.updateCases(caseUpdateList);
        
        //Send email about case Assignment to the owner
        sendEmailToCaseOwner(caseUpdateList, caseOwnerIdSet);
    }
    
    public static void sendEmailToCaseOwner(List<Case> caseUpdateList, Set<Id> caseOwnerIdSet){
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        UserService  objUserService = UserService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<Id, User> ownerMap = objUserService.getActiveUsersByIds(caseOwnerIdSet);
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMMUNITY_SR_ASSIGNMENT_EMAIL_TEMPLATE_ID); 
        for(Case objCase :caseUpdateList){
            if(ownerMap.containsKey(objCase.OwnerId)){
                Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, objCase.Id,new List<String>{ownerMap.get(objCase.OwnerId).Email} , null, null);
                emailList.add(objMail);
            }
        }
        objEmailService.sendEmail(emailList);
    }
    
    //BFM Case Auto Assignment
    public static void bfmEmailToCaseCaseAssignment(List<Id> recordIds){
        CaseService objCaseService = CaseService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String bfmCaseCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_CASE_CREATED_BY_IDS);
        
        List<Id> bfmCaseCreatedByUserIdList = bfmCaseCreatedByIds.split(',');
        Set<Id> bfmCaseCreatedByUserIds = new Set<Id>(bfmCaseCreatedByUserIdList);
        //if running from test class
        if(Test.isRunningTest()){
            bfmCaseCreatedByUserIds.add(UserInfo.getUserId());
        }
        List<Case> caseList = objCaseService.getCaseByIdsAndCreatedByIds(new Set<Id>(recordIds), bfmCaseCreatedByUserIds);
        
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_BFM_EMAIL_TO_CASE_ASSIGNMENT);
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
                for(Case objCase : caseList){
                    objCase.Status = 'In Progress';
                }
                objCaseService.updateCasesWithoutTrigger(caseList); 
            }
        }
    }

    //BFM Common Area BLC Case Auto Assignment
    public static void bfmCommonAreaBLCCaseAssignment(List<Id> recordIds){
        commonAreaCaseAssignment(recordIds, BLC_CASE_ASSIGNMENT);
    }

    //BFM Common Area DLP Case Auto Assignment
    public static void bfmCommonAreaDLPCaseAssignment(List<Id> recordIds){
        commonAreaCaseAssignment(recordIds, DLP_CASE_ASSIGNMENT);
    }

    private static void commonAreaCaseAssignment(List<Id> recordIds, String assignmentRule){
        CaseService objCaseService = CaseService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        List<Case> caseList = objCaseService.getCaseByIds(new Set<Id>(recordIds));
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_CASE, assignmentRule);
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
                for(Case objCase : caseList){
                    objCase.PendingWith__c =  assignmentRule == BLC_CASE_ASSIGNMENT ? 'BLC Team' :'DLP Team';
                }
                objCaseService.updateCasesWithoutTrigger(caseList);
                List<Messaging.SingleEmailMessage> emailList = objCaseService.sendEmailToCaseOwner(caseList);
                if(!emailList.isEmpty()){
                    objEmailService.sendEmail(emailList);
                }
            }
        }
    }

    //ANPR Case Auto Assignment
    public static void anprCaseAssignment(List<Id> recordIds){
        CaseService objCaseService = CaseService.getInstance();
        Set<Id> caseIds = new Set<Id>(recordIds);
        List<Case> caseList = objCaseService.getCaseByIds(caseIds);
        
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            List<AssignmentRule__c> objAssignmentRules = objAssignmentRuleService.getAssignmentRules(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_ANPR_SERVICE_REQUEST_ASSIGNMENT, COMMUNITY_MANAGEMENT_STR);
            for(Case c : caseList){
                for(AssignmentRule__c assignRule : objAssignmentRules){
                    if(assignRule.Project__c != null && assignRule.Project__c.split(';').contains(c.Project__r.Name)){
                        c.OwnerId = String.isNotBlank(assignRule.DefaultQueueID__c) ? (Id)assignRule.DefaultQueueID__c : assignRule.DefaultUser__c;
                        break;
                    }
                }
            }
            objCaseService.updateCasesWithoutTrigger(caseList);
        }
    }
    
    //Complaint Case Auto Assignment
    public static void salesComplaintCaseAssignment(List<Id> recordIds){
        
        CaseService objCaseService = CaseService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String complaintCaseCreatedByProfileIds = objMetadataService.getAppSettingTextValue(COMPLAINT_CASE_CREATED_BY_Profile_IDS);
        List<Id> complaintCaseCreatedByProfileIdList = complaintCaseCreatedByProfileIds.split(',');
        
        Set<Id> caseIds = new Set<Id>(recordIds);
        List<Case> caseList = objCaseService.getCasesByCreatedByIds(caseIds,complaintCaseCreatedByProfileIdList);
        List<Case> caseListToUpdate = new List<Case>();
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            List<AssignmentRule__c> assignmentRuleList = objAssignmentRuleService.getAssignmentRuleAndUsersByProcessName(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_GENERAL_COMPLAINT_CASE_ASSIGNMENT,'Sales');
            /* if(objAssignmentRule != NULL){
List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
objCaseService.updateCasesWithoutTrigger(caseList); 
} */
            
            for(Case cseRec : caseList){
                if(cseRec.Projectname__c != NULL) {
                    for(AssignmentRule__c assignmentRuleRec : assignmentRuleList){
                        List<String> projectList = String.isNotBlank(assignmentRuleRec.Project__c) ? assignmentRuleRec.Project__c.split(';') : new List<String>();
                        if(projectList.contains(cseRec.Projectname__c)){
                            List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                            caseListToUpdate.addAll((List<Case>)objAssignmentRuleService.assignRecordOwner(new List<Case>{cseRec}, assignmentRuleRec, assignmentUserList));
                        }
                    }
                }
            }
        }
        //objCaseService.updateCasesWithoutTrigger(caseList);
        if(caseListToUpdate != NULL && caseListToUpdate.size() > 0){
            objCaseService.updateCasesWithoutTrigger(caseListToUpdate);
        }
    }
    
    //CRM Case Round Robin Assignment
    public static void crmCaseAssignment(List<Id> recordIds){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        List<Id> contactCentreProfileIdList = contactCentreProfileIds.split(',');
        
        Set<Id> caseIds = new Set<Id>(recordIds);
        CaseService objCaseService = CaseService.getInstance();
        List<Case> caseList = new List<Case>();
        
        for (Case cse : objCaseService.getCaseByIds(caseIds)) {
            String createdByProfileId =
                String.valueOf(cse.CreatedBy.ProfileId).substring(0, 15);
            
            if (contactCentreProfileIdList.contains(createdByProfileId)
                || cse.Origin == SUPER_APP_STR) {
                    caseList.add(cse);
                }
        }
        List<Case> caseListToUpdate = new List<Case>();
        
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            List<AssignmentRule__c> assignmentRuleList = objAssignmentRuleService.getAssignmentRuleAndUsersByProcessName(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_CRM_CASE_ASSIGNMENT, 'Sales');
            
            for(Case cseRec : caseList){
                for(AssignmentRule__c assignmentRuleRec : assignmentRuleList){
                    List<String> projectList = String.isNotBlank(assignmentRuleRec.Project__c) ? assignmentRuleRec.Project__c.split(';') : new List<String>();
                    if(String.isNotBlank(cseRec.Projectname__c) && projectList.contains(cseRec.Projectname__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        caseListToUpdate.addAll((List<Case>)objAssignmentRuleService.assignRecordOwner(new List<Case>{cseRec}, assignmentRuleRec, assignmentUserList));
                        break;
                    }
                    else if(String.isBlank(cseRec.Projectname__c) && String.isBlank(assignmentRuleRec.Project__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        caseListToUpdate.addAll((List<Case>)objAssignmentRuleService.assignRecordOwner(new List<Case>{cseRec}, assignmentRuleRec, assignmentUserList));
                        break;
                    }
                }
            }
        }
        if(caseListToUpdate != NULL && caseListToUpdate.size() > 0){
            objCaseService.updateCasesWithoutTrigger(caseListToUpdate);
        }
    }
    
     //CRM Handover Round Robin Assignment
    public static void crmHandoverAssignment(Set<Id> recordIds){
        
        MetadataService objMetadataService = MetadataService.getInstance();
     
        HandoverService objHandoverService = HandoverService.getInstance();
        List<Handover__c> handoverList = objHandoverService.getHandoverByIds(recordIds);
        
        List<Handover__c> handoverListToUpdate = new List<Handover__c>();
        
        if(!handoverList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            List<AssignmentRule__c> assignmentRuleList = objAssignmentRuleService.getAssignmentRuleAndUsersByProcessName(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_CRM_CASE_ASSIGNMENT, 'Sales');
            
            for(Handover__c handoverRec : handoverList){
                for(AssignmentRule__c assignmentRuleRec : assignmentRuleList){
                    List<String> projectList = String.isNotBlank(assignmentRuleRec.Project__c) ? assignmentRuleRec.Project__c.split(';') : new List<String>();
                    if(String.isNotBlank(handoverRec.Projectname__c) && projectList.contains(handoverRec.Projectname__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        handoverListToUpdate.addAll((List<Handover__c>)objAssignmentRuleService.assignRecordOwner(new List<Handover__c>{handoverRec}, assignmentRuleRec, assignmentUserList));
                        break;
                    }
                    else if(String.isBlank(handoverRec.Projectname__c) && String.isBlank(assignmentRuleRec.Project__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        handoverListToUpdate.addAll((List<Handover__c>)objAssignmentRuleService.assignRecordOwner(new List<Handover__c>{handoverRec}, assignmentRuleRec, assignmentUserList));
                        break;
                    }
                }
            }
        }
       
            objHandoverService.updateHandoverWithoutTrigger(handoverListToUpdate);
        
    }
 public static void crmComplaintCaseAssignment(List<Id> recordIds){
        
        MetadataService objMetadataService = MetadataService.getInstance();
       
        
        Set<Id> caseIds = new Set<Id>(recordIds);
        CaseService objCaseService = CaseService.getInstance();
        List<Case> caseList = new List<Case>();
        
        for (Case cse : objCaseService.getCaseByIds(caseIds)) {
                    caseList.add(cse);
                
        }
        List<Case> caseListToUpdate = new List<Case>();
        
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            List<AssignmentRule__c> assignmentRuleList = objAssignmentRuleService.getAssignmentRuleAndUsersByProcessName(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_CRM_COMPLAINT_CASE_ASSIGNMENT, 'Sales');
            
            for(Case cseRec : caseList){
                for(AssignmentRule__c assignmentRuleRec : assignmentRuleList){
                    List<String> projectList = String.isNotBlank(assignmentRuleRec.Project__c) ? assignmentRuleRec.Project__c.split(';') : new List<String>();
                    if(String.isNotBlank(cseRec.Projectname__c) && projectList.contains(cseRec.Projectname__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        caseListToUpdate.addAll((List<Case>)objAssignmentRuleService.assignRecordOwner(new List<Case>{cseRec}, assignmentRuleRec, assignmentUserList));
                        break;
                    }
                    else if(String.isBlank(cseRec.Projectname__c) && String.isBlank(assignmentRuleRec.Project__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        caseListToUpdate.addAll((List<Case>)objAssignmentRuleService.assignRecordOwner(new List<Case>{cseRec}, assignmentRuleRec, assignmentUserList));
                        break;
                    }
                }
            }
        }
        if(caseListToUpdate != NULL && caseListToUpdate.size() > 0){
            objCaseService.updateCasesWithoutTrigger(caseListToUpdate);
        }
    }
    public static void crmHandoverAssignment(List<Handover__c> recordIds){
        
        AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
        List<AssignmentRule__c> assignmentRuleList = objAssignmentRuleService.getAssignmentRuleAndUsersByProcessName(ASSIGNMENT_RULE_RECORD_TYPE_HANDOVER, ASSIGNMENT_RULE_PROCESS_CRM_HANDOVER_ASSIGNMENT, 'Handover');
        HandoverService objHandoverService =  HandoverService.getInstance();
        List<Handover__c>handoverList = objHandoverService.getHandoversByIds(recordIds);
        for(Handover__c handoverRec : handoverList){
            if(handoverRec.Projectname__c != NULL) {
                for(AssignmentRule__c assignmentRuleRec : assignmentRuleList){
                    List<String> projectList = String.isNotBlank(assignmentRuleRec.Project__c) ? assignmentRuleRec.Project__c.split(';') : new List<String>();
                    if(projectList.contains(handoverRec.Projectname__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        handoverList.addAll((List<Handover__c>)objAssignmentRuleService.assignRecordOwner(new List<Handover__c>{handoverRec}, assignmentRuleRec, assignmentUserList));
                    }
                }
            }
        }
        if(handoverList != NULL && handoverList.size() > 0){
            objHandoverService.updateHandoverWithoutTrigger(handoverList);
        }
    }
    
    //CRM Resale Case Round Robin Assignment
    public static void crmResaleCaseAssignment(List<Id> recordIds){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        List<Id> contactCentreProfileIdList = contactCentreProfileIds.split(',');
        
        Set<Id> caseIds = new Set<Id>(recordIds);
        CaseService objCaseService = CaseService.getInstance();
        List<Case> caseList = objCaseService.getCasesByCreatedByIds(caseIds, contactCentreProfileIdList); 
        List<Case> caseListToUpdate = new List<Case>();
        
        AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
        List<AssignmentRule__c> assignmentRuleList = objAssignmentRuleService.getAssignmentRuleAndUsersByProcessName(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_CRM_RESALE_CASE_ASSIGNMENT, 'Sales');
        
        
        for(Case cseRec : caseList){
            if(cseRec.Projectname__c != NULL) {
                for(AssignmentRule__c assignmentRuleRec : assignmentRuleList){
                    List<String> projectList = String.isNotBlank(assignmentRuleRec.Project__c) ? assignmentRuleRec.Project__c.split(';') : new List<String>();
                    if(projectList.contains(cseRec.Projectname__c)){
                        List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(assignmentRuleRec.AssignmentUsers__r);
                        caseListToUpdate.addAll((List<Case>)objAssignmentRuleService.assignRecordOwner(new List<Case>{cseRec}, assignmentRuleRec, assignmentUserList));
                    }
                }
            }
        }
        
        if(caseListToUpdate != NULL && caseListToUpdate.size() > 0){
            objCaseService.updateCasesWithoutTrigger(caseListToUpdate);
        }
    }
    
    //BAPP Broker Generic Case Auto Assignment - 
    public static void genericCaseAssignmentBAPP(List<Id> recordIds){
        
        CaseService objCaseService = CaseService.getInstance();
        Set<Id> caseIds = new Set<Id>(recordIds);
        List<Case> caseList = objCaseService.getCaseByIds(caseIds);
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_CASE, ASSIGNMENT_RULE_PROCESS_BROKER_CASE_ASSIGNMENT,'Broker');
            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
                objCaseService.updateCasesWithoutTrigger(caseList); 	
            }
        }
        objCaseService.updateCasesWithoutTrigger(caseList);
    }
    
    public static void superAppCaseAssignment(List<Id> recordIds){
        CaseService objCaseService = CaseService.getInstance();
        Set<Id> caseIds = new Set<Id>(recordIds);
        List<Case> caseList = objCaseService.getCaseByIds(caseIds);
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_CASE, SUPER_APP_REGISTRATION_CASE_ASSIGNMENT,'Sales');

            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
                objCaseService.updateCasesWithoutTrigger(caseList); 
            }
        }
    }

    public static Map<Id, Case> assignCasesToNextOwner(Set<Id> recordIds, String processName, String processType){
        
        if(recordIds == null || recordIds.isEmpty()){
            return new Map<Id, Case>();
        }

        CaseService objCaseService = CaseService.getInstance();
        List<Case> caseList = objCaseService.getCaseByIds(recordIds);
        if(!caseList.isEmpty()){
            AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
            AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers(ASSIGNMENT_RULE_RECORD_TYPE_CASE, processName, processType);

            if(objAssignmentRule != NULL){
                List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                caseList = objAssignmentRuleService.assignRecordOwner(caseList, objAssignmentRule, assignmentUserList);
                objCaseService.updateCasesWithoutTrigger(caseList); 
            }
        }
        return new Map<Id, Case>(caseList);
    }
}