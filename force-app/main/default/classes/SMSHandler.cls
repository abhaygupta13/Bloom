/***
Class       : SMSHandler
Author      : Biswajeet
Description : 
TestClass   : SMSHandler
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/07/23           Initial Version 
2.          v2.0              19/01/24           updated null check and added Number in English Words. 
3.			v3.0			  22/01/24			 Added SMS Logic
****************************************************************************************************************/
public class SMSHandler implements Queueable, Database.AllowsCallouts {
    
    private static final String MTD_OTP_PROCESS_TYPE_BLOOM_APP_REGISTRATION { get { return 'SMSAPI'; } }
    
    private SMS sms;
    
    public SMSHandler(SMS sms) {
        this.sms = sms;
    }
    
    public void execute(QueueableContext context) {
        sendSMS(this.sms);
    }
    
    public static void sendSMS(SMS sms) {
        APISetting__mdt objAPISetting = MetadataService.getInstance().getAPISettingDetails(MTD_OTP_PROCESS_TYPE_BLOOM_APP_REGISTRATION);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(objAPISetting.Endpoint__c);
        System.debug('setEndpoint >>'+objAPISetting.Endpoint__c);
        request.setHeader('Content-Type','application/json');
        request.setHeader('client_id', objAPISetting.Client_Id__c);
        request.setHeader('client_secret', objAPISetting.Client_Secret__c);
        request.setBody(JSON.serialize(sms));
        request.setTimeout(120000);
        request.setMethod('POST');
        Http http = new Http();            
        try {
            HttpResponse response = http.send(request);
            System.debug('SMS API Response--->>> ' + response.getBody());
            System.debug('Status--->>>> ' + response.getStatusCode());
        } catch (Exception exp) {
            System.debug('SMS Error----->>>>> ' + exp.getMessage());
        }
    }
    
    public static SMS getSuperAppOTPSMS(List<OTP__c> otpList) {
        SMS objSMS = new SMS();
        List<Message> messageList = new List<Message>();
        for(OTP__c objOTP :otpList){
            Message objMessage = new Message();
            objMessage.channel = 'SMS';
            objMessage.sender = 'Bloom Cares';
            Destination objDestination = new Destination();
            Content objContent = new Content();
            Body objBody = new Body();
            objDestination.to = objOTP.PhoneNumber__c;
            objMessage.destinations = new List<Destination>{objDestination};
                objBody.text = 'Hi, Your OTP for Bloom App is '+ objOTP.OTPCode__c +'. It is valid for 2 miniutes. Do not share it with anyone.';
            objBody.type = 'TEXT';
            objContent.body = objBody;
            objMessage.content = objContent;
            messageList.add(objMessage);
        }
        objSMS.messages = messageList;
        return objSMS;
    }
    
    public static SMS getBrokerAppOTPSMS(List<OTP__c> otpList) {
        SMS objSMS = new SMS();
        List<Message> messageList = new List<Message>();
        for(OTP__c objOTP :otpList){
            Message objMessage = new Message();
            objMessage.channel = 'SMS';
            objMessage.sender = 'Bloom Cares';
            Destination objDestination = new Destination();
            Content objContent = new Content();
            Body objBody = new Body();
            objDestination.to = objOTP.PhoneNumber__c;
            objMessage.destinations = new List<Destination>{objDestination};
                objBody.text = 'Hi, Your OTP for Bloom App is '+ objOTP.OTPCode__c +'. It is valid for 2 miniutes. Do not share it with anyone.';
            objBody.type = 'TEXT';
            objContent.body = objBody;
            objMessage.content = objContent;
            messageList.add(objMessage);
        }
        objSMS.messages = messageList;
        return objSMS;
    }
    
    // =========================================================
    //  BAPP AGREEMENT REMINDER SMS (AGENCY + PARTNER / OWNER)
    // =========================================================
    
    public static SMS getAgreementReminderSMS(List<BrokerApplication__c> apps,Map<Id, List<BrokerApplicant__c>> applicantsByApp) {
        SMS objSMS = new SMS();
        List<Message> messageList = new List<Message>();
    	System.debug('apps 99 >> '+ apps);
        System.debug('applicantsByApp 99 >> '+ applicantsByApp);
        MetadataService metadataService = MetadataService.getInstance();
		BAPPSMSTemplate__mdt template =
            metadataService.getActiveSMSTemplateByName('Agreement Pending Signature');
        System.debug('template 104 >> '+ template);
        if (template == null || String.isBlank(template.Message_Body__c)) {
            System.debug('return objSMS 106 >> ');
            return objSMS; // or handle gracefully
        }
        for (BrokerApplication__c app : apps) {
    
            // ---------------- Merge fields
            Map<String, String> mergeMap = new Map<String, String>{
                'Application_Number' => app.ApplicationNumber__c,
                'Initiation_Date' =>
                    app.AgreementInitiationDate__c != null
                        ? String.valueOf(app.AgreementInitiationDate__c)
                        : '',
                'Days_Remaining' =>
                    app.AgreementInitiationDate__c != null
                        ? String.valueOf(
                            30 - app.AgreementInitiationDate__c.daysBetween(Date.today())
                          )
                        : ''
            };
    		System.debug('mergeMap 125 >> '+ mergeMap);
            String smsText = template.Message_Body__c;
            for (String key : mergeMap.keySet()) {
                String value = mergeMap.get(key);
                smsText = smsText.replace(
                    '{{' + key + '}}',
                    value != null ? value : ''
                );
            }
    
            // =========================
            // Agency SMS
            // =========================
            if (String.isNotBlank(app.CompanyPhone_Number__c)
                && String.isNotBlank(app.CountryCode__c)) {
    
                Message msg = new Message();
                msg.channel = 'SMS';
                msg.sender = 'Bloom Cares';
    
                Destination dest = new Destination();
                dest.to = '+' + app.CountryCode__c + app.CompanyPhone_Number__c;
                System.debug('dest.to 147 >> '+dest.to);
                Body body = new Body();
                body.type = 'TEXT';
                body.text = smsText;
    
                Content content = new Content();
                content.body = body;
    
                msg.destinations = new List<Destination>{ dest };
                msg.content = content;
    
                messageList.add(msg);
            }
    		System.debug('messageList 160 >> '+ messageList);
            // =========================
            // Partner / Owner SMS
            // =========================
            if (applicantsByApp != null &&
                applicantsByApp.containsKey(app.Id)) {
    
                for (BrokerApplicant__c ba :
                     applicantsByApp.get(app.Id)) {
    				System.debug('ba 169 >> '+ba);
                    Message msg = new Message();
                    msg.channel = 'SMS';
                    msg.sender = 'Bloom Cares';
    
                    Destination dest = new Destination();
                    dest.to = '+' + ba.CountryCode__c + ba.PhoneNumber__c;
                    System.debug('dest.to 176 >> '+dest.to);
                    Body body = new Body();
                    body.type = 'TEXT';
                    body.text = smsText;
    
                    Content content = new Content();
                    content.body = body;
    
                    msg.destinations = new List<Destination>{ dest };
                    msg.content = content;
    
                    messageList.add(msg);
                }
                    System.debug('messageList 189 >> '+ messageList);
            }
        }
    
        objSMS.messages = messageList;
        System.debug('objSMS 194 >> '+ objSMS);
        return objSMS;
    }
    // =========================================================
    // BAPP RFI REMINDER SMS
    // =========================================================
    public static SMS getRFIReminderSMS(List<RFI__c> rfiList,Map<Id, List<BrokerApplicant__c>> applicantsByApp) {
        SMS objSMS = new SMS();
        System.debug('rfiList 202 >> '+ rfiList);
        System.debug('applicantsByApp 203 >> '+ applicantsByApp);
        List<Message> messageList = new List<Message>();
        if (rfiList == null || rfiList.isEmpty()) {
            objSMS.messages = messageList;
            System.debug('Inside If rfiList 207 >> '+ objSMS);
            return objSMS;
        }
    
        //  DEDUP SET 
        Set<String> sentNumbers = new Set<String>();
    
        MetadataService metadataService = MetadataService.getInstance();
		BAPPSMSTemplate__mdt template =
            metadataService.getActiveSMSTemplateByName('RFI Raised');
        System.debug('template 217 >> '+ template);
        if (template == null || String.isBlank(template.Message_Body__c)) {
            System.debug('inside if template return objSMS 219 >> '+ objSMS);
            return objSMS; // or handle gracefully
        }
    
        for (RFI__c rfi : rfiList) {
            System.debug('rfi 224 >> '+ rfi);
            BrokerApplication__c app = rfi.BrokerApplication__r;
            System.debug('app 225 >> '+ app);
            if (app == null) continue;
    
            String smsText = template.Message_Body__c
                .replace('{{Application_Number}}', app.ApplicationNumber__c)
                .replace('{{RFI_Date}}', String.valueOf(rfi.CreatedDate.date()))
                .replace('{{View_RFI_Request}}', Label.BAPP_BloomConnectLoginPageLink);
    		System.debug('smsText 233 >> '+ smsText);
            // =========================
            // Agency SMS (DEDUPED)
            // =========================
            if (String.isNotBlank(app.CompanyPhone_Number__c)
                && String.isNotBlank(app.CountryCode__c)) {
    			System.debug('inside if 239 >> ');
                String agencyNumber = '+' + app.CountryCode__c + app.CompanyPhone_Number__c;
    			System.debug('agencyNumber 241 >> '+agencyNumber);
                if (!sentNumbers.contains(agencyNumber)) {
                    sentNumbers.add(agencyNumber);
                    System.debug('sentNumbers 244 >> '+sentNumbers);
                    messageList.add(buildSMS(agencyNumber, smsText));
                    System.debug('messageList 246 >> '+messageList);
                }
            }
    
            // =========================
            // Partner / Owner SMS (DEDUPED)
            // =========================
            if (applicantsByApp != null && applicantsByApp.containsKey(app.Id)) {
    			System.debug('Inside If applicantsByApp  254 >> '+ applicantsByApp);
                for (BrokerApplicant__c ba : applicantsByApp.get(app.Id)) {
				System.debug('ba 256 >> '+ ba);    
                    String applicantNumber =
                        '+' + ba.CountryCode__c + ba.PhoneNumber__c;
    			System.debug('applicantNumber  259 >> '+ applicantNumber);
                    if (sentNumbers.contains(applicantNumber)) {
                        System.debug('Inside If sentNumbers  261 >> '+ sentNumbers);
                        continue; // prevent duplicate SMS
                    }
    
                    sentNumbers.add(applicantNumber);
                    System.debug('sentNumbers 266 >> '+ sentNumbers);
                    messageList.add(buildSMS(applicantNumber, smsText));
                    System.debug('messageList 268 >> '+ messageList);
                }
            }
        }
    
        objSMS.messages = messageList;
        System.debug('objSMS 274 >> '+ objSMS);
        return objSMS;
    }
    private static Message buildSMS(String phoneNumber, String text) {
        Message msg = new Message();
        msg.channel = 'SMS';
        msg.sender = 'Bloom Cares';
    
        Destination dest = new Destination();
        
        dest.to = phoneNumber;
        System.debug('dest.to 285 >> '+ dest.to);
    
        Body body = new Body();
        body.type = 'TEXT';
        body.text = text;
    
        Content content = new Content();
        content.body = body;
    
        msg.destinations = new List<Destination>{ dest };
        msg.content = content;
    	System.debug('msg 296 >> '+ msg);
        return msg;
    }
    
    public class SMS {
        public Message[] messages;
    }
    
    public class Message {
        public String channel;	//SMS
        public String sender;	//Bloom Cares
        public Destination[] destinations;
        public Content content;
    }
    
    public class Destination {
        public String to;	//971528970361
    }
    
    public class Content {
        public Body body;
    }
    
    public class Body {
        public String text;	//May the Force be with you.
        public String type;	//TEXT
    }
}