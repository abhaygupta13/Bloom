/***
Class       : BrokerRegistrationExpiryDateClass
Author      : Smaartt
Description : created to run schedule everyday to check the trade license expiry date and broker registration expiry 
              date and send emails with EmailReminderhandler Class.
TestClass   : BrokerRegistrationExpiryDateClassTest
HelperClass: 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version_DevInitials     Date       Author          Details
1.          V1.0              02/08/24    Smaartt      Initial Version 
****************************************************************************************************************/
public class BrokerRegistrationExpiryDateClass implements Schedulable{
    public void execute(SchedulableContext sc){
      EmailReminderhandler.BrokerAgencyExpiryReminder();
        
    }
}