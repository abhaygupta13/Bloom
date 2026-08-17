/**
* @Class Name      : ADHALeadAPI
* @Description     : REST API endpoint for ADHA (Abu Dhabi Housing Authority)
*                    integration to create or update Lead records in Salesforce.
*
*                    This API accepts applicant and project information in JSON
*                    format, validates the incoming request, and performs the
*                    following operations:
*
* @URL Mapping     : /services/apexrest/ADHALeadAPI
* @HTTP Method     : POST
*
* @Request Format  : JSON
* @Response Format : JSON
*
* @Author          : Prashant Sahu
* @Version         : 1.1
*
* Modification History
* ------------------------------------------------------------------------------------
* Version    Date          Author            Description
* ------------------------------------------------------------------------------------
* 1.0        Aug 2026       Prashant Sahu      Initial implementation.
************************************************************************************************************/
@RestResource(urlMapping='/ADHALeadAPI/*')
global without sharing class ADHALeadAPI {
    
    @HttpPost
    global static Response createLead(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Blob body = req.requestBody;
        Response objResponse = new Response();
        LeadService objLeadService = LeadService.getInstance();
        ProjectService projectService = ProjectService.getInstance();
        
        try {
            String requestString = body.toString();
            Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(requestString);
            // Extract nested data
            Map<String, Object> applicant = (Map<String, Object>) inputMap.get('Applicant');
            Map<String, Object> project = (Map<String, Object>) inputMap.get('Project');
            Map<String, Object> notes = (Map<String, Object>) inputMap.get('Notes');
            
            String applicationNumber = (String)inputMap.get('ApplicationNumber');
            
            if(String.isBlank(applicationNumber)){
                objResponse.code = 500;
                objResponse.message = 'Please share the Application number';
                return objResponse;
            }
            OpportunityService oppServiceInstance= OpportunityService.getInstance();
            List<Opportunity> oppsToUpdate = oppServiceInstance.getOpportunitiesByADHAApplicationNumber(applicationNumber);
            for(Opportunity opp : oppsToUpdate){
                opp.ADHAStatus__c = (String) inputMap.get('Status');
            }
            oppServiceInstance.updateOpportunities(oppsToUpdate);
            if(oppsToUpdate != null && !oppsToUpdate.isEmpty()){
                objResponse.code = 200;
                objResponse.DeveloperReferenceNumber = oppsToUpdate[0].Lead__c ;
                objResponse.message = 'Application status has been updated successfully';
                return objResponse;
            }else{
                List<Lead> existingLeadList = objLeadService.getLeadsByADHAApplicationNumber(applicationNumber);
                
                // Create Lead object and set fields
                Lead newLead = new Lead();
                if(!existingLeadList.isEmpty() && existingLeadList != NULL){
                    newLead.Id = existingLeadList[0].Id;
                }
                // Mapping basic details
                newLead.ADHAStatus__c = (String)inputMap.get('Status');
                newLead.Status = 'In Progress'; 
                newLead.LeadSource = 'Government Entity';
                newLead.leadsubsource__c = 'ADHA';
                newLead.Lead_Channel__c = 'API Integration';
                newLead.ApplicationNumber__c = applicationNumber;
                newLead.LeadTeam__c = 'Sales';
                if (applicant != null) {
                    newLead.FirstName = (String) applicant.get('Name');
                    newLead.LastName = (String) applicant.get('FamilyName');
                    newLead.Emirates_Id__c = (String) applicant.get('EID');
                    newLead.MobilePhone = (String) applicant.get('PhoneNumber');
                    newLead.Email = (String) applicant.get('Email');
                    newLead.Tribe__c = (String) applicant.get('Tribe');
                    newLead.GenderIdentity = (String) applicant.get('Gender');
                    if (applicant.containsKey('DOB') && String.isNotBlank((String) applicant.get('DOB'))) {
                        newLead.Birthdate__c = Date.valueOf((String) applicant.get('DOB'));
                    }
                    newLead.MaritalStatus__c = (String) applicant.get('MaritalStatus');
                    newLead.NumberOfWives__c = (Integer) applicant.get('NumberOfWives');
                    newLead.NumberOfChildren__c = (Integer) applicant.get('NumberOfChildren');
                    newLead.AnnualRevenue = Decimal.valueOf(String.valueOf(applicant.get('Salary')));
                    newLead.City = (String) applicant.get('TownName');
                    Map<String, Object> passport = (Map<String, Object>) applicant.get('Passport');
                    if (passport != null) {
                        newLead.Passport_Number__c =(String) passport.get('Number');
                        newLead.PassportIssueDate__c =Date.valueOf(String.valueOf(passport.get('IssueDate')));
                        newLead.PassportExpiryDate__c = Date.valueOf(String.valueOf(passport.get('ExpiryDate')));
                    }
                }
                if(inputMap != null && inputMap.containsKey('LoanValue')){
                    newLead.LoanAmount__c = inputMap.get('LoanValue') != null ? Decimal.valueOf(String.valueOf(inputMap.get('LoanValue')))  : null;
                }
                if (project != null) {
                    String adhaProjectId = (String) project.get('ProjectID');
                    if (String.isNotBlank(adhaProjectId)) {
                        Project__c projectRecord = projectService.getADHAProjectById(adhaProjectId);
                        if (projectRecord != null) {
                            newLead.Project__c = projectRecord.Name;
                            newLead.ProjectLookup__c= projectRecord.Id;
                        }
                    }
                    newLead.Municipality__c = (String) project.get('Municipality');
                    newLead.Region__c = (String) project.get('Region');
                    newLead.District__c = (String) project.get('District');
                }
                
                Database.SaveResult result;
                if(!existingLeadList.isEmpty()){
                    result = objLeadService.updateLeadWithoutDuplicateRule(newLead);
                }else{
                    result = objLeadService.insertLeadWithoutDuplicateRule(newLead);
                }
                if(result != NULL){
                    if (result.isSuccess()) {
                        objResponse.code = 200;
                        objResponse.message = 'success';
                        objResponse.DeveloperReferenceNumber = result.getId() ;
                    } else {
                        objResponse.message = result.getErrors()[0].getMessage();
                        objResponse.code = 500;
                    }
                }else{
                    objResponse.message = 'Data process failed';
                    objResponse.code = 500;
                }
            } 
        }
        catch (System.Exception ex) {
            objResponse.code = 500;
            objResponse.message = ex.getMessage();
        }
        return objResponse;
    }
    
    global class Response{
        global string message {get;set;}
        global integer code {get;set;}
        global string DeveloperReferenceNumber {get;set;}
    }
}