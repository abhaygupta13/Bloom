/***
Class       : EmailReminderhandler
Author      : Smaartt
Description : created to handle the email reminders to sent to the broker agency admins.
TestClass   : EmailReminderhandlerTest
HelperClass: 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version_DevInitials     Date       Author          Details
1.          V1.0              02/08/24    Smaartt      Initial Version 
****************************************************************************************************************/
public class EmailReminderhandler {
    Public static Void BrokerAgencyExpiryReminder(){
        
        Id orgEmailId;
        
        Date today = Date.today();
        Date thirtyDaysFromToday = today.addDays(integer.valueof(System.label.thirtyDaysFromToday));
        Date SevenDaysFromToday = today.addDays(integer.valueof(System.label.SevenDaysFromToday));
        
        Set<id> Accountid = new Set<id>();
        Set<id> Accountidtradeexpirydateid = new Set<id>();
        
        List<String> toAddressesOfCustomereaddressList = new List<String>();
        List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress where DisplayName =: Constants.Bloom_No_Reply ];
        List<Emailtemplate> TradeemailTemplateId= [Select id,Name From Emailtemplate where Name =: Constants.Tradelicenseexpiryemailtempalte];
        List<Emailtemplate> brokeremailTemaplateId = [Select id,Name From Emailtemplate where Name =: Constants.BrokerAgreementExpiryFinalTemplate];
        
        Messaging.SingleEmailMessage[] messages =new List<Messaging.SingleEmailMessage>();
        
        for(Account Acc:[SELECT Id,Name,Broker_Registration_Expiry_Date__c,Trade_License_Expiry_Date__c 
                         FROM Account 
                         WHERE RecordTypeId=: Constants.BrokerAgencyRecTypeId 
                         AND (Broker_Registration_Expiry_Date__c!=null OR Trade_License_Expiry_Date__c!= null) ]){
                             if(Acc.Broker_Registration_Expiry_Date__c == thirtyDaysFromToday || Acc.Broker_Registration_Expiry_Date__c == SevenDaysFromToday ){
                                 Accountid.add(Acc.Id);
                             }
                             if(Acc.Trade_License_Expiry_Date__c == thirtyDaysFromToday || Acc.Trade_License_Expiry_Date__c == SevenDaysFromToday ){
                                 Accountidtradeexpirydateid.add(Acc.Id);
                             }
                         }
        if(Accountidtradeexpirydateid.size()>0){
            for(Contact con : [SELECT Id,Email,AccountId FROM Contact WHERE AccountId IN: Accountidtradeexpirydateid AND RecordTypeId =: Constants.BrokerContactRecTypeId AND BrokerType__c =: Constants.Agency_Admin]){
                toAddressesOfCustomereaddressList.add(con.Email);
                If(orgWideEmailAddresses.size()> 0){
                    orgEmailId = orgWideEmailAddresses[0].id;  
                    messages.add(
                        checkEmail(
                            TradeemailTemplateId[0].Id,
                            String.valueof(orgEmailId),
                            toAddressesOfCustomereaddressList,
                            con.AccountId,con.id
                        )
                    );
                }
            }
        }
        if(Accountid.size()>0){
            for(Contact con : [SELECT Id,Email,AccountId 
                               FROM Contact 
                               WHERE AccountId IN: Accountid 
                               AND RecordTypeId =: Constants.BrokerContactRecTypeId 
                               AND BrokerType__c =: Constants.Agency_Admin]){
                                   toAddressesOfCustomereaddressList.add(con.Email);
                                   If(orgWideEmailAddresses.size()> 0){
                                       orgEmailId = orgWideEmailAddresses[0].id;  
                                       messages.add(
                                           checkEmail(
                                               brokeremailTemaplateId[0].Id,
                                               String.valueof(orgEmailId),
                                               toAddressesOfCustomereaddressList,
                                               con.AccountId,con.id
                                           )
                                       );     
                                       
                                   }
                               }
        }
        
        if(messages.size()>0){
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
        
    }
    Private Static Messaging.SingleEmailMessage checkEmail(String Emailtemplateid,string orgIdString,List<String> toAddressesOfCustomereaddressList,ID Accountidtogiven,ID setTargetObjectId ){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(Emailtemplateid);
        mail.setOrgWideEmailAddressId(orgIdString);
        mail.setToAddresses(toAddressesOfCustomereaddressList);      
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(true);
        mail.setWhatId(Accountidtogiven);
        mail.setTargetObjectId(setTargetObjectId);
        return mail;
    }
    /* Public static Void SendEmailforlead(List<lead> Lelist){
List<Lead> Updatelist= [select id,leadsubsource__c,Email from lead where id IN:Lelist];
Messaging.SingleEmailMessage[] messages =new List<Messaging.SingleEmailMessage>();
Id orgEmailId;
string Emailtemplateid = system.label.Red_Crescent_Event_email_template_id;
List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress where DisplayName =: Constants.Bloom_No_Reply ];
List<String> toAddressesOfCustomereaddressListforlead = new List<String>();
For(Lead l :Updatelist ){
if(l.leadsubsource__c == 'Red Crescent Event'){
toAddressesOfCustomereaddressListforlead.add(l.Email);
If(orgWideEmailAddresses.size()> 0){
orgEmailId = orgWideEmailAddresses[0].id;

Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setTemplateId(Emailtemplateid);
mail.setOrgWideEmailAddressId(String.valueof(orgEmailId));
mail.setToAddresses(toAddressesOfCustomereaddressListforlead);      
mail.setSaveAsActivity(true);
mail.setTreatTargetObjectAsRecipient(true);
// mail.setWhatId(l.id);
// mail.setWhoID(l.id);

mail.setTargetObjectId(l.Id);
messages.add(mail);
}

}

}
if(messages.size()>0){

Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
}
} */
}