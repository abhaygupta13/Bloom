/*****************************************************************************************
Class       : EmailActionController
Author      : Vikas Baliyan
Description : EmailAction Controller
Test Class  : EmailActionControllerTest
Created Date: 23 JAN 2025 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0             	 02/03/2025          HOC Changes  
****************************************************************************************************************/ 
public class EmailActionController {
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string HOC_CC_EMAIL_ADDRESS { get { return 'HOC_CC_Email_Address'; } }
    private static final string HOC_BCC_EMAIL_ADDRESS { get { return 'HOC_BCC_Email_Address'; } }
    private static final string HOC_DATE_NO_OF_DAYS { get { return 'HOCDateDays'; } }
        
    @AuraEnabled
    public static String sendEmail(Id recordId,  List<Map<String,String>> fileList){
        try{
            ContactService objContactService = ContactService.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            SalesOrderService objSalesOrder = SalesOrderService.getInstance();
            SalesOrder__c salesOrder = objSalesOrder.getSalesOrdersWithJointOwner(new Set<Id>{recordId})[0];
            String customerEmailId;
            Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
            String hocCCEmailAddress = objMetadataService.getAppSettingTextValue(HOC_CC_EMAIL_ADDRESS);
            List<String> hocCCEmailAddressList = hocCCEmailAddress != null ? hocCCEmailAddress.split(',') : null;
            String hocBCCEmailAddress = objMetadataService.getAppSettingTextValue(HOC_BCC_EMAIL_ADDRESS);
            List<String> hocBCCEmailAddressList = hocBCCEmailAddress != null ? hocBCCEmailAddress.split(',') : null;
            // fetch the customer id for email send
            if(String.isNotBlank(recordId) && salesOrder.Account__c != null){
                if(salesOrder.Account__r.RecordType.DeveloperName == 'PersonAccount'){
                    customerEmailId = salesOrder.Account__r.PersonEmail;
                }
                else{
                    List<Contact> conList = objContactService.getPrimaryContactByAccountId(salesOrder.Account__c, true);
                    if(conList.isEmpty()) {
                        return 'Primary contact not found';
                    }
                    customerEmailId = conList.isEmpty() ? '': conList[0].Email;
                }
            }
            Integer intNoOfDays = objMetadataService.getAppSettingNumberValue(HOC_DATE_NO_OF_DAYS);
            // fetch email template id
            Id emailTemplateId = (salesOrder.Sales_Order_Installment_Total__c == salesOrder.Sales_Order_Cleared_Amount__c ? salesOrder.Unit__r.Project__r.HOCEmailTemplateFullyPaid__c : salesOrder.Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c);
            EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(emailTemplateId);
            Messaging.SingleEmailMessage result = Messaging.renderStoredEmailTemplate(emailTemplateId, null, recordId);
            String emailBody = result.getHtmlBody();
            //fetch the email html body
            emailBody = getBody(salesOrder, emailBody, salesOrder.Unit__r.Project__c,customerEmailId,intNoOfDays);
            // send email if customer id is not blank
            if(String.isNotBlank(customerEmailId)){
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(new List<String>{customerEmailId}, recordId, null, result.Subject, emailBody, noReplyBloomSalesOWDId,hocCCEmailAddressList,hocBCCEmailAddressList);
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                for(Map<String,String> file : fileList){
                    Messaging.EmailFileAttachment emailFileAttachment = objEmailService.getEmailAttachment(file.get('filename'), EncodingUtil.base64Decode(file.get('base64')), file.get('filetype'));
                    attachments.add(emailFileAttachment);
                }
                email.setFileAttachments(attachments);
                Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                if (results != null && results.size() > 0 && results[0].isSuccess()){
                    List<SalesOrder__c> lstSO = new List<SalesOrder__c>();
                    SalesOrder__c objSO = new SalesOrder__c();
                    objSO.Id = recordId;
                    objSO.HOCNoticeSentDate__c = Date.today();
                    objSO.HOCDate__c = Date.today().addDays(intNoOfDays);
                    lstSO.add(objSO);
                    objSalesOrder.updateSalesOrders(lstSO);
                    return 'true';
                    
                }else{
                    return 'false';
                }
            }
            else{
                return 'Customer email not found';
            }

        }catch(Exception ex){
            System.debug('ex-->>'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        } 
    }

    @AuraEnabled(cacheable=true)
    public static String fetchEmailTemplate(Id recordId){
        try{
            ContactService objContactService = ContactService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            SalesOrderService objSalesOrder = SalesOrderService.getInstance();
            SalesOrder__c salesOrder = objSalesOrder.getSalesOrdersWithJointOwner(new Set<Id>{recordId})[0];
            MetadataService objMetadataService = MetadataService.getInstance();
            String customerEmailId;
            
            Integer intNoOfDays = objMetadataService.getAppSettingNumberValue(HOC_DATE_NO_OF_DAYS);
            if(salesOrder.Unit__c == null && salesOrder.Unit__r.Project__c == null){
                return 'Unit or Project not found for current Sales Order';
            }
            
            Id emailTemplateId = ((salesOrder.Sales_Order_Installment_Total__c - salesOrder.Sales_Order_Cleared_Amount__c) <= 1 ? salesOrder.Unit__r.Project__r.HOCEmailTemplateFullyPaid__c : salesOrder.Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c);
            if(emailTemplateId == null){
                return 'Email Template Id not found for current Project';
            }
            EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(emailTemplateId);
            if(emailTemplate == null){
                return 'Email template not found for current Project';
            }
            String emailBody = emailTemplate.HtmlValue;
            if(String.isNotBlank(recordId) && salesOrder.Account__c != null){
                if(salesOrder.Account__r.RecordType.DeveloperName == 'PersonAccount'){
                    if(salesOrder.Account__r.PersonEmail != null){
                        customerEmailId = salesOrder.Account__r.PersonEmail;
                    }
                    else{
                        return 'Customer Email not found';
                    }
                }
                else{
                    List<Contact> conList = objContactService.getPrimaryContactByAccountId(salesOrder.Account__c, true);
                    if(conList.isEmpty()) {
                        return 'Primary contact not found';
                    }
                    customerEmailId = conList.isEmpty() ? '': conList[0].Email;
                }
            }
            
            Messaging.SingleEmailMessage results = Messaging.renderStoredEmailTemplate(emailTemplateId, null, recordId);
            emailBody = results.getHtmlBody();
            //fetch the email html body
            return getBody(salesOrder, emailBody, salesOrder.Unit__r.Project__c,customerEmailId,intNoOfDays); 
        }catch(System.exception ex){
            System.debug('ex-->>'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        } 
    }

    private static String getBody(SalesOrder__c objSalesOrder, String emailBody, Id projectId, String emailName, Integer noOfDays){
        /*BankAccountService objBankAccountService = BankAccountService.getInstance();
        BankAccount__c bankAccount = objBankAccountService.getBankAccountByProjectIds('Handover', projectId);
        System.debug('bankAccount'+bankAccount);
        if(bankAccount != null){
            emailBody = emailBody.replace('{BankName}', (bankAccount.BankNameCorporate__c != null ? bankAccount.BankNameCorporate__c :''));
            emailBody = emailBody.replace('{BankAccountName}', (bankAccount.Name != null ? bankAccount.Name :''));
            emailBody = emailBody.replace('{BankAccountNumber}', (bankAccount.AccountNumberCorporate__c != null ? bankAccount.AccountNumberCorporate__c :''));
            emailBody = emailBody.replace('{BankAccountIBAN}', (bankAccount.IBANNoCorporate__c != null ? bankAccount.IBANNoCorporate__c :''));
            emailBody = emailBody.replace('{BankSwiftCode}', (bankAccount.SwiftCodeCorporate__c != null ? bankAccount.SwiftCodeCorporate__c :''));
        }*/
        Date d = Date.today(); 
        String jointownerNamesEnglish = '<span>';
        String jointownerNamesArabic = '<span>';
        String formattedDate = DateTime.newInstance(d.year(),d.month(),d.day()).format('dd/MM/YYYY');
        List<JointOwner__c> jointOwnerList = (objSalesOrder.Joint_OwnersSalesOrder__r != null ? objSalesOrder.Joint_OwnersSalesOrder__r : null);
        if(jointOwnerList != null && jointOwnerList.size() > 0){
            String accountName = getAccountName(objSalesOrder,null,false);
            String accountNameString = 'Name: '+ accountName;
            String accountNameArabic = getAccountName(objSalesOrder,null,true);
            String accountNameStringArabic = 'الاسم: '+ accountNameArabic;
            
            for(JointOwner__c objJO : jointOwnerList){
                String jointAccountName = getAccountName(null,objJO,false);
                accountNameString += '<br/> Joint Owner: '+ jointAccountName;
                String jointAccountNameArabic = getAccountName(null,objJO,true);
                accountNameStringArabic += '<br/> المالك المشترك: '+ jointAccountNameArabic;

                jointownerNamesEnglish += jointAccountName +', ';
                jointownerNamesArabic += jointAccountNameArabic +', ';
                System.debug('jointownerNamesEnglish ::::: '+ jointownerNamesEnglish);
                
            }
            /* jointownerNamesEnglish += '</span>';
            jointownerNamesArabic += '</span>';
            emailBody = emailBody.replace('{JointOwnerNamesEnglish}', jointownerNamesEnglish);
            emailBody = emailBody.replace('{JointOwnerNamesArabic}', jointownerNamesArabic); */
            emailBody = emailBody.replace('{AccountName}', accountNameString); 
            emailBody = emailBody.replace('{AccountNameArabic}', accountNameStringArabic); 
        }
        else{
            String accountName = getAccountName(objSalesOrder,null,false);
            String accountNameString = 'Name: '+ accountName;
            String accountNameArabic = getAccountName(objSalesOrder,null,true);
            String accountNameStringArabic = 'الاسم: '+ accountNameArabic;
            
            emailBody = emailBody.replace('{AccountName}', accountNameString); 
            emailBody = emailBody.replace('{AccountNameArabic}', accountNameStringArabic); 
        }
        
        jointownerNamesEnglish += '</span>';
        jointownerNamesArabic += '</span>';
        emailBody = emailBody.replace('{JointOwnerNamesEnglish}', jointownerNamesEnglish);
        emailBody = emailBody.replace('{JointOwnerNamesArabic}', jointownerNamesArabic);
        emailBody = emailBody.replace('{TodayDate}', formattedDate);
        emailBody = emailBody.replace('{CustomerEmail}', emailName);
        return emailBody;
    }
    
    private static String getAccountName(SalesOrder__c objSalesOrder, JointOwner__c objJO, Boolean isArabic){
        String accountName = '';
        if(isArabic){
            if(objSalesOrder != null){
                if(objSalesOrder.Account__r.RecordType.DeveloperName == 'PersonAccount'){
                    accountName += (objSalesOrder.Account__r.Title_Arabic__c != null ? objSalesOrder.Account__r.Title_Arabic__c : '');
                    accountName += (objSalesOrder.Account__r.NameinArabic__c != null ? objSalesOrder.Account__r.NameinArabic__c : '');
                } 
                else{
                    accountName += (objSalesOrder.Account__r.NameinArabic__c != null ? objSalesOrder.Account__r.NameinArabic__c : ''); 
                }
            }
            else if(objJO != null){
                if(objJO.Account__r.RecordType.DeveloperName == 'PersonAccount'){
                    accountName += (objJO.Account__r.Title_Arabic__c != null ? objJO.Account__r.Title_Arabic__c : ' ');
                    accountName += (objJO.Account__r.NameinArabic__c != null ? objJO.Account__r.NameinArabic__c : ' ');
                } 
                else{
                    accountName += (objJO.Account__r.NameinArabic__c != null ? objJO.Account__r.NameinArabic__c : ' '); 
                }
            }
        }
        else{
            if(objSalesOrder != null){
                if(objSalesOrder.Account__r.RecordType.DeveloperName == 'PersonAccount'){
                    accountName += (objSalesOrder.Account__r.Salutation != null ? objSalesOrder.Account__r.Salutation : ' ');
                    accountName += (objSalesOrder.Account__r.FirstName != null ? objSalesOrder.Account__r.FirstName : ' ');
                    accountName += (objSalesOrder.Account__r.MiddleName != null ? objSalesOrder.Account__r.MiddleName : ' ');
                    accountName += (objSalesOrder.Account__r.LastName != null ? objSalesOrder.Account__r.LastName : ' ');
                }
                else{
                    accountName = (objSalesOrder.Account__r.Name != null ? objSalesOrder.Account__r.Name : ' ');
                }
            }
            else if(objJO != null){
                if(objJO.Account__r.RecordType.DeveloperName == 'PersonAccount'){
                    accountName += (objJO.Account__r.Salutation != null ? objJO.Account__r.Salutation : ' ');
                    accountName += (objJO.Account__r.FirstName != null ? objJO.Account__r.FirstName : ' ');
                    accountName += (objJO.Account__r.MiddleName != null ? objJO.Account__r.MiddleName : ' ');
                    accountName += (objJO.Account__r.LastName != null ? objJO.Account__r.LastName : ' ');
                }
                else{
                    accountName = (objJO.Account__r.Name != null ? objJO.Account__r.Name : ' ');
                }
            } 
        }
        return accountName;
    }
}