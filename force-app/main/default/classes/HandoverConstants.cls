/***
@Author : Rajat Rastogi
@Description : HandoverConstants Class

----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 02/09/2024           Initial Version  
****************************************************************************************************************/ 
public class HandoverConstants {
       /************************************** START - HANDOVER CONSTANTS ***********************************************/
    public static String SNAGGING = 'snagging';
    public static String DESNAGGING = 'desnagging';
    public static STRING TEAM_OPERATION = 'Operation';
    public static String TEAM_CRM = 'CRM';
    public static String BCC = 'BCC';
    public static String NOC = 'NOC';
    public static String Orientation = 'Orientation';
    public static String HANDOVER_SOBJECT = 'Handover__c';
    public static String HandoverPHPPRecordType = 'Handover_PHPP';
    public static String HandoverSObject = 'Handover__c';
    public static String NO = 'No';
    public static String YES = 'Yes';
    /*********** HANDOVER STATUS *******************/
    public static String Handover_Customer_Delegate_to_BLoom = 'Customer Delegate to BLoom';
    public static String Handover_Payment_Type_PHPP = 'PHPP';
    public static String Handover_Payment_Type_Cash = 'Cash';
    public static String Early_Settlement_Settlement = 'Settlement';
    public static String Early_Settlement_Resale = 'Resale';
    public static String Leasing_type_Owner_Occupied = 'Owner Occupied';
    public static String Mortgage_Release_Initiated = 'Mortgage Release Initiated';
    public static String Mortgage_Release_Document_Uploaded = 'Mortgage Release Document Uploaded';
    public static String Escrow_Letter_Generated = 'Escrow Letter Generated';
    public static String Mortgage_Release_Completed = 'Mortgage Release Completed';
    public static String PHPP_Completion_Pending = 'PHPP Completion Pending';
    public static String PHPP_Finance_Clearance = 'PHPP Finance Clearance';
    public static String Handover_Payment_Type_Mortgage = 'Mortgage';
    
    public static String Customer_Available = 'Customer Available';
    public static String Customer_Not_Available = 'Customer Not available';
    public static String Customer_Deligate_To_Bloom	 = 'Customer Delegate To Bloom';
    public static String Orientation_Appointment_Status_Cancelled = 'Cancelled';
    public static String Orientation_Appointment_Status_Scheduled = 'Scheduled';
    public static String Orientation_Appointment_Status_ReScheduled = 'ReScheduled';
    public static String SO_STATUS_CANCELLED = 'Cancelled';
    public static String SO_STATUS_SOLD = 'Sold';

    public static String Handover_Sub_Status_QA_Snagging = 'QA Snagging';
    public static String Handover_Sub_Status_QA_DeSnagging = 'QA De-Snagging';
    public static String Handover_Sub_Status_Upload_SOA = 'Upload SOA';
    public static String Handover_Sub_Status_Upload_SPA = 'Upload SPA';
    public static String Handover_Sub_Status_Handover_Keys_to_BAM = 'Handover Keys to BAM';
    public static String Handover_Sub_Status_Send_CHO_and_NOC = 'Send Handover Notice';
    public static String Handover_Sub_Status_Book_Appointment_with_Customer = 'Book Appointment with Customer';
    public static String Handover_Sub_Status_Pre_CHO_Check = 'Pre CHO Check';
    public static String Handover_Sub_Status_CHO_Snagging = 'CHO Snagging';
    public static String Handover_Sub_Status_CHO_DeSnagging = 'CHO De-Snagging';
    public static String Handover_Sub_Status_Settlement_Follow_up = 'Settlement Follow up';
    public static String Handover_Sub_Status_Generate_Bank_NOC = 'Generate Bank NOC';
    public static String Handover_Sub_Status_Settlement_Confirmation = 'Settlement Confirmation';
    public static String Handover_Sub_Status_HO_Undertaking_Letter = 'HO Undertaking Letter';
    public static String Handover_Sub_Status_Upload_Signed_Tawtheeq_Agreement = 'Tawtheeq Enrollment';
    public static String Handover_Sub_Status_Lease_Agreement = 'Lease Agreement';
    public static String Handover_Sub_Status_Handover_Signing_Document_Appointment = 'Handover Signing Document (KHO) Appointment';
    public static String Handover_Sub_Status_PHPP_Handover_Keys = 'PHPP Handover Keys';
    public static String Handover_Sub_Status_Await_PHPP_Completion = 'Await PHPP Completion';
    public static String Handover_Sub_Status_Clear_PHPP_Finances = 'Clear PHPP Finances';
    public static String Handover_Sub_Status_Initiate_Mortgage_Release = 'Initiate Mortgage Release';
    public static String Handover_Sub_Status_Upload_Mortgage_Release_Documents = 'Upload Mortgage Release Documents';
    public static String Handover_Sub_Status_ADREC_Approval_and_Mortgage_Release = 'ADREC Approval and Mortgage Release';
    public static String Handover_Sub_Status_Generate_Escrow_Letter = 'Generate Escrow Letter';
    public static String Handover_Sub_Status_Generate_Developer_NOC = 'Generate Developer NOC';
    public static String Handover_Sub_Status_Developer_NOC_Internal_Follow_Up = 'Developer NOC Internal Follow Up';
    public static String Handover_Sub_Status_Register_Title_Deed = 'Register Title Deed';
    public static String Handover_Sub_Status_Transfer_Utilities = 'Transfer Utilities';
    public static String Handover_Sub_Status_Mortgage_Cheque_Clearance = 'Mortgage Cheque Clearance';
    public static String Handover_Sub_Status_Handover_Completed = 'Handover Completed';
    public static String Handover_Sub_Status_Potential_Defaulter = 'Potential Defaulter';
    public static String Handover_Sub_Status_Default_Under_Discussion = 'Default -Under Discussion';
    public static String Handover_Sub_Status_Cancelled = 'Cancelled';
    public static String Handover_Sub_Status_Initiate_Cancellation = 'Initiate Cancellation';
    public static String Handover_Sub_Status_Under_Resale = 'Under Resale';
    
    /*********** Profiles Names *******************/

    public static String Profile_CRM_Team = 'CRM Team';
    public static String Profile_Service_Charge_Community = 'Community Team';
    public static String Profile_HO_Agent = 'HO Agent';
    public static String Profile_System_Administrator = 'System Administrator';
    public static String Profile_Finance_Team = 'Finance Team';
    public static String Profile_Government_relations_Team = 'Government relations';
    public static String Profile_Operations_Team = 'Operations Team';
    public static String Profile_Treasury = 'Treasury';


    /*********** HANDOVER ONSITE MESSAGE *******************/
    public static String HANDOVER_CREATED_SUCCESSFULLY_FOR_THIS_UNIT = '{"message": "Handover created successfully for this unit.", "statusCode": 200, "statusType": "Success", "HandoverName": ';
    public static String REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER = '{"message": "Report uploaded successfully on Handover", "statusCode": 200, "statusType": "Success", "HandoverName": ';
    public static String Please_Select_Snagging_Report = 'Please select report type snagging and Status is QA';
    public static String FILE_DATA_NOT_FOUND = '{"message": "File Data not found", "statusCode": "401", "statusType": "Error"}';
    public static String HANDOVER_ALREADY_CREATED = '{"message": "Handover already created for this unit. ", "statusCode": "401", "statusType": "Error"}';
    public static String INSPECTOR_NOT_FOUND = '{"message": "Inspector not found in the system", "statusCode": "401", "statusType": "Error"}';
    public static String UNABLE_TO_FIND_UNIT = '{"message": "Unable to find Unit in the system", "statusCode": "401", "statusType": "Error"}';
    public static String UNIT_CANNOT_BE_BLANK = '{"message": "Unit cannot be blank", "statusCode": "401", "statusType": "Error"}';
    public static String DOCUMENT_PLACEHOLDER_NOT_FOUND = '{"message": "No Document placeholder found on Handover", "statusCode": "401", "statusType": "Error"}';
    
    /************ HANDOVER DOCUMENT  ************************/
    public static String HO_QA_Snagging_Report = 'QA Snagging Report';
    public static String HO_QA_DeSnagging_Report = 'QA Desnagging Report';
    public static String HO_CHO_Snagging_Report = 'CHO Snagging Report';
    public static String HO_CHO_DeSnagging_Report = 'CHO Desnagging Report';
    public static String HO_SOA = 'SOA';
    public static String Title_Deed = 'Title Deed';
    public static String ADDC_NOC = 'ADDC NOC';
    public static String BCC_DOCUMENT = 'BCC Document';
    public static String PAYMENT_RECEIPT = 'Payment Receipt';
    public static String Full_Guideline_Document = 'Full Guideline Document';
    public static String Home_Orientation_Journey = 'Home Orientation Journey';
    public static String Guideline_1_Arabic = 'Guideline 1 Arabic';
    public static String Guideline_2_Arabic = 'Guideline 2 Arabic';
    public static String Guideline_3_Arabic = 'Guideline 3 Arabic';
    public static String Guideline_1 = 'Guideline 1';
    public static String Guideline_2 = 'Guideline 2';
    public static String Guideline_3 = 'Guideline 3';
    
    public static String Application_Modification_Fitout_Works_Eng = 'Application for Modification and Fitout Works English';
    public static String Application_Modification_Fitout_Works_Arb = 'Application for Modification and Fitout Works Arabic';
    public static String Community_Entry_Permit_English_Eng = 'Community Entry Permit English';
    public static String Community_Entry_Permit_English_Arb = 'Community Entry Permit Arabic';

    public static String Emirates_Id = 'Emirates Id';
    public static String Passport = 'Passport';
    public static String SPA = 'SPA';
    public static String MortgageValue = 'Mortgage Value';
    public static String Mortgage_Cheque_Copy = 'Mortgage Cheque Copy';
    public static String Mortgage_Contract = 'Mortgage Contract';
    public static String BloomTitleDeed = 'Bloom Title Deed';
    public static String BankNOC = 'Bank NOC';
    public static String DeveloperNOC = 'Developer NOC';
    public static String Leasing_ADDC_NOC = 'Leasing ADDC NOC';
    public static String TawtheeqRegistrationConfirmation = 'Tawtheeq Registration Confirmation';
    public static String HandoverPaymentAttachment = 'Handover Payment Attachment';
    public static String HandoverServiceChargeClerance = 'Service Charge Clearance Letter';
    
    /************ HANDOVER VALIDATION ERROR MESSAGE  ************************/
    public static String You_do_not_Appointment_Booked_with_Customer_yet  = 'You have not booked an appointment with Customer yet';
    public static String NOC_send_to_customer_successfully  = 'NOC send to customer successfully';
    
    public static String Title_Deed_Registration_Completed  = 'Title Deed Registration Completed';   // need to check
    public static String BCC_ALREADY_SENT = 'BCC Document already sent. Please proceed for Home Orientation.';
    public static String CHOSnagNeededError = 'This status can be set only in case of CHO Snagging needed. ';
    public static String Select_Customer_Availability = 'Please select Customer Availability for CHO on the related Handover';
    public static String Cannot_Book_Appointment = 'You cannot book an appointment if customer is not available. Please update Customer Availability for CHO if customer is available.';
    public static String Delete_Existing_Appointment = 'To reschedule new orientation appointment, please set orientation appointment status as Cancelled';
    public static String Please_fill_the_required_details_in_the_attach_KHO_document = 'Please fill the required details in the attach KHO document';
    public static String Failed_to_send_email_Errors =  'Failed to send email. Errors: ';
    public static String Email_address_is_null = 'Email address is null';
    public static String RecordId_is_null = 'RecordId is null.';
    public static String Mail_has_already_been_sent = 'Mail has already been sent';
    
    /************************************ HANDOVER TEMPLATE  ************************/
    public static String Handover_Congratulation_Email_Template = 'Handover Congratulation Email Template'; 
    public static String Key_Handover_Template = 'Key Handover Template'; 
    public static String Orientation_Template = 'Orientation Letter Template';
    public static String Title_Deed_Registration  = 'Title Deed Registration';
    public static String Appointment_Booked_Template = 'Appointment Booked Template'; 
    public static String Notice_of_Completion_Template = 'Notice of Completion Template'; 
    public static String PAYMENT_Confirmation_Template = 'Handover Payment Confirmation';
    public static String KHO_Appointment_Scheduled_Template = 'KHO Appointment Scheduled';
    public static String Home_Orientation_By_Bloom = 'Home Orientation By Bloom'; 
    public static String CHO_Desnagging_Communication_Email_Template = 'CHO Desnagging Communication Email Template'; 
    public static String Handover_Completion_Customer_Attended = 'Handover Completion Customer Attended'; 
    public static String Handover_Completion_Customer_Not_Attended = 'Handover Completion Customer Not Attended'; 
    public static String BCCAnnouncementEmailTemplate = 'BCCAnnouncementEmailTemplate'; 
    public static String DE_SNAGGING_REPORT = 'deSnaggingReport';
    public static String Appointment_Booked_Reminder_After_Five_Days = 'Appointment Booked Reminder After Five Days';
    public static String Appointment_Booked_Reminder_After_Ten_Days = 'Appointment Booked Reminder After Ten Days';
    public static String Appointment_Booked_Reminder_after_15_days = 'Appointment Booked Reminder after 15 days';
    public static String Home_Orientation_Appointment_Rescheduling = 'Home Orientation Appointment Rescheduling';
    public static String PaymentReminderAfter30Days = 'PaymentReminderAfter30Days';
    public static String PaymentReminderAfter20Days = 'PaymentReminderAfter20Days';
    public static String PaymentReminderAfter10Days = 'PaymentReminderAfter10Days';
    public static String KHO_Document = 'KHO Document';
    public static String ADDC_Registration_Email = 'ADDC Registration Email';
    
    
    /************************************ HANDOVER Queue  ************************/
    public static String FINANCE_QUEUE = 'Handover_Finance_Queue';
    public static String HO_COLLECTION_QUEUE = 'Handover_Collection_Team_Queue';
    public static String HO_OPERATION_QUEUE = 'Handover_Operation_Team_Queue';
    public static String Handover_Leasing_Team_Queue = 'Handover_Leasing_Team_Queue';
    public static String Handover_Government_Relations_Queue = 'Handover_Government_Relations_Queue';
    public static String Handover_Treasury_Queue = 'Handover_Treasury_Queue';
    public static String Handover_Service_Charge_Confirm_Community_Queue = 'Service_Charge_Confirm_Community_Queue';

    
    public static String KHO_Document_pdf = 'KHO_Document.pdf';
    public static String KHO_document_is_successfully_send_to_Customer = 'KHO document is successfully send to Customer';
    public static String Appointment_Booked_Successfully = 'Appointment Booked Successfully'; 
    public static String KHO_Appointment_Scheduled = 'KHO Appointment Scheduled';
    public static String Appointment_Booked_Reminder = 'Appointment Booked Reminder'; 
    public static String BCC_Announcement = 'BCC Announcement'; 
    public static String Is_Notice_of_Completion_Sent = 'Is_Notice_of_Completion_Sent__c'; 
    public static String Please_Select_Status = 'Please Select Status';
    public static String Status_CHO = 'CHO';
    public static String Status_QA = 'QA';
    public static String Handover = 'Handover';
    
    public static String Handover_HOAgent_Profiles = 'Handover_HOAgent_Profiles';
    public static String profilesToSkipValidations = 'profilesToSkipValidations';
    public static String NoReplyEmailAddress = 'NoReplyEmailAddress';
    public static String OrgWideEmailAddress = 'OrgWideEmailAddress';
    public static String HandoverBloomEmail = 'HandoverBloomEmail';
    public static String HandoverBloomPhone = 'HandoverBloomPhone';
    public static String DLP_Expiy_Information_Email_Tempate = 'DLP Expiy Information Email Tempate';
    public static String HandoverAccountManagerEmail = 'HandoverAccountManagerEmail';
    public static String LocationName = 'LocationName';
    public static String Orientation_Appointment = 'Home Orientation Appointment';
    public static String KHO_Appointment = 'KHO Appointment';

    
    /************************************** END - HANDOVER CONSTANTS ***********************************************/

}