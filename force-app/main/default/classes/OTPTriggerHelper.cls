/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : OTPTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public class OTPTriggerHelper {
    
    private static final String MTD_OTP_PROCESS_TYPE_BLOOM_APP_REGISTRATION { get { return 'Bloom App Registration'; } }
    private static final String MTD_OTP_PROCESS_TYPE_BLOOM_APP_FORGOT_PASSWORD { get { return 'Bloom App Forgot Password'; } }
    private static final String MTD_OTP_PROCESS_TYPE_ADHA_LOGIN_VERIFICATION { get { return 'ADHA Login Verification'; } }

    public static void sendSuperAppOTP(List<OTP__c> newList){
        
        OTPService objOTPService = OTPService.getInstance();
        List<OTP__c> superAppEmailOTPList = new List<OTP__c>();
        List<OTP__c> superAppSMSOTPList = new List<OTP__c>();
        
        for(OTP__c objOTP :newList){
            if(objOTP.ProcessType__c == MTD_OTP_PROCESS_TYPE_BLOOM_APP_REGISTRATION
              || objOTP.ProcessType__c == MTD_OTP_PROCESS_TYPE_BLOOM_APP_FORGOT_PASSWORD
              || objOTP.ProcessType__c == MTD_OTP_PROCESS_TYPE_ADHA_LOGIN_VERIFICATION){
                if(objOTP.CommunicationType__c != NULL && objOTP.CommunicationType__c.contains('Email')){
                    superAppEmailOTPList.add(objOTP);
                }
                if(objOTP.CommunicationType__c != NULL && objOTP.CommunicationType__c.contains('SMS')){
                    superAppSMSOTPList.add(objOTP);
                }
            }
        }
        objOTPService.sendSuperAppOTPEmail(superAppEmailOTPList);
        objOTPService.sendSuperAppOTPSMS(superAppSMSOTPList);
    }
}