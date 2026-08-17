public class DocomotionToSendEmailWithAttachment {
    
    public static void sendEmail(Integer formId,Id sobjectId,Id TemplateId,string subject,Id whoId,string orgwideID){
        Map<String, Object> params = new Map<String, Object>();
        params.put('format','PDF');
        params.put('formId',formId);
        params.put('isActivatedVersion',false);
        params.put('sobjectId',sobjectId);
        params.put('TemplateId',TemplateId);
        params.put('subject',subject);
        params.put('whoId',whoId);
        params.put('orgWideAddressId',orgwideID);
       
        //Flow.Interview.docomotion_SendEmailWithAttachment flow = new Flow.Interview.docomotion_SendEmailWithAttachment(params);
        if(!Test.isRunningTest()) {
        	//flow.start();
        }
    }

}