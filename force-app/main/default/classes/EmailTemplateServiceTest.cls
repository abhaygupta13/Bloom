@istest

public class EmailTemplateServiceTest {
  @IsTest
    static void testgetcreateCustomerDocument() {
        EmailTemplateService.getEmailTemplateByDeveloperName('Reject_Moveout_request_to_Applicant');
        EmailTemplateService.getEmailTemplateByName('Notify Line Manager On Termination Start');
        String templateName = 'Reject_Moveout_request_to_Applicant';
        Set<String> setEmailTemplateDevName = new Set<String>();
        setEmailTemplateDevName.add(templateName);
        EmailTemplateService.getInstance().getEmailTemplateByDeveloperNames(setEmailTemplateDevName);
        EmailTemplateService.getInstance().getByDeveloperName('Reject_Moveout_request_to_Applicant');
        
    }
    
      
}