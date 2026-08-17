/***
Class       : Constants
Author      : Smaartt
Description : 
TestClass   : ConstantsTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/

public class Constants{/************************************** START - HANDOVER CONSTANTS ***********************************************/
    public static String SNAGGING = 'snagging';
    public static String DESNAGGING = 'desnagging';
    public static STRING TEAM_OPERATION = 'Operation';
    public static String TEAM_CRM = 'CRM';
    public static String HANDOVER_SOBJECT = 'Handover__c';
    public static String NO = 'No';
    public static String YES = 'Yes';
    /*********** HANDOVER STATUS *******************/
    public static String HANDOVER_STATUS_QA_Snagging_Completed = 'QA Snagging Completed';
    public static String HANDOVER_STATUS_QA_DESnagging_Completed = 'QA De-Snagging Completed';
    public static string Handover_Sub_Status_Bcc_Sent_To_Customer = 'Bcc Sent To Customer';
    public static string Handover_Sub_Status_Home_Orientation_Sent = 'Home Orientation Sent'; 
    public static String Handover_Sub_Status_Appointment_Booked = 'Appointment Booked with Customer';
    public static String Handover_Sub_Status_Pre_Checklist_Completed = 'Pre-Checklist Completed';  
    public static String Handover_Sub_Status_Pending_for_CHO_Snagging = 'Pending for CHO Snagging';
    public static String Handover_Sub_Status_CHO_SNAGGING_COMPLETED = 'CHO Snagging Completed';
    public static String Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED = 'CHO De-Snagging';
    public static String Handover_Sub_Status_Payment_Settled = 'Payment Settled';
    public static String Handover_Sub_Status_Finance_Verified = 'Finance Verified';
    public static String Handover_Sub_Status_Title_Deed_Registration_Completed = 'Title Deed Registration Completed';
    public static String Handover_Customer_Delegate_to_BLoom = 'Customer Delegate to BLoom';
    public static String Handover_Status_Handover_Completed = 'Handover Completed';
    public static String Handover_Status_Utilities_Transfer_Completed = 'Utilities Transfer Completed';
    public static String Handover_Potentail_Defaulter = 'Potential Defaulter';
    public static String Handover_Sub_Status_Cancelled = 'Cancelled';
    public static String Handover_Status_Default = 'Default';

    
    /*********** HANDOVER ONSITE MESSAGE *******************/
    public static String HANDOVER_CREATED_SUCCESSFULLY_FOR_THIS_UNIT = '{"message": "Handover created successfully for this unit", "statusCode": 200, "statusType": "Success", "HandoverName": ';
    public static String REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER = '{"message": "Report uploaded successfully on Handover", "statusCode": 200, statusType: "Success", "HandoverName": ';
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
    
    /************ HANDOVER VALIDATION ERROR MESSAGE  ************************/
    public static String HANDOVER_ALREADY_THERE = 'Handover already exist for this SalesOrder';
   	public static String UPLOAD_QA_SNAG_REPORT = 'Please upload QA Snagging Report';
    public static String UPLOAD_QA_DESNAG_REPORT = 'Please upload QA Desnagging Report';
    public static String UPLOAD_CHO_SNAG_REPORT = 'Please upload CHO Snagging Report';
    public static String UPLOAD_CHO_DESNAG_REPORT = 'Please upload CHO Desnagging Report';
    public static String UPLOAD_PAYMENT_RECEIPT = 'Please upload Payment Reciept before Payment Settled.';
    public static String You_havenot_sent_the_BCC_to_the_customer_yet  = 'You have not sent the BCC to the customer yet';
    public static String You_havenot_sent_the_Home_Orientation  = 'You have not sent the Home Orientation yet. Please check the unit Ready first';
    public static String You_do_not_Appointment_Booked_with_Customer_yet  = 'You have not booked an appointment with Customer yet';
    public static String CannotChangeStatustToAppointmentBooked = 'You cannot change the status if Meeting is not created and Customer Availablity is not selected';
    public static String Please_Upload_Desnagging_Report  = 'Please Upload Desnagging Report';
    public static String Please_Upload_SOA_Report  = 'Please Upload SOA Report';
    public static String NOC_send_to_customer_successfully  = 'NOC send to customer successfully';
    public static String Please_send_the_BCC_Announcement = 'Please send the BCC Announcement first before the NOC send to customer';
    public static String Please_Book_KHO_Appointment = 'Please booked an appointment before first the KHO Appointment Scheduled';
    
    public static String Title_Deed_Registration_Completed  = 'Title Deed Registration Completed';   // need to check
    public static String You_havenot_Complete_the_Title_Deed_Registration_yet  = 'Please upload the Title Deed document first';
    public static String You_havenot_Utilities_Transfer_Completed  = 'Please upload the ADDC NOC document first';
	public static String BCC_ALREADY_SENT = 'BCC Document already sent. Please proceed for Home Orientation.';
    public static String CHOSnagNeededError = 'This status can be set only in case of CHO Snagging needed. ';
    public static String NOCNotSentYet = 'Please send NOC first before Payment Settlement.';
    public static String Select_Customer_Availability = 'Please select Customer Availability for CHO on the related Handover';
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
    public static String  Notice_of_Completion_Template = 'Notice of Completion Template'; 
    public static String PAYMENT_Confirmation_Template = 'Handover Payment Confirmation';
    public static String KHO_Appointment_Scheduled_Template = 'KHO Appointment Scheduled';
    public static String  Home_Orientation_By_Bloom = 'Home Orientation By Bloom'; 
    public static String  Handover_Completion_Customer_Attended = 'Handover Completion Customer Attended'; 
    public static String  Handover_Completion_Customer_Not_Attended = 'Handover Completion Customer Not Attended'; 
    public static String  BCCAnnouncementEmailTemplate = 'BCCAnnouncementEmailTemplate'; 
    public static String DE_SNAGGING_REPORT = 'deSnaggingReport';
    public static String Appointment_Booked_Reminder_After_Five_Days = 'Appointment Booked Reminder After Five Days';
    public static String Appointment_Booked_Reminder_After_Ten_Days = 'Appointment Booked Reminder After Ten Days';
    public static String Appointment_Booked_Reminder_after_15_days = 'Appointment Booked Reminder after 15 days';
    public static String Home_Orientation_Appointment_Rescheduling = 'Home Orientation Appointment Rescheduling';

    public static String KHO_Document = 'KHO Document';
    
    public static String Customer_Available = 'Customer Available';
    public static String Customer_Not_Available = 'Customer Not available';
    public static String Customer_Deligate_To_Bloom	 = 'Customer Delegate To Bloom';
    public static String Orientation_Appointment_Status_Cancelled = 'Cancelled';
    public static String Orientation_Appointment_Status_Scheduled = 'Scheduled';
    public static String Orientation_Appointment_Status_ReScheduled = 'ReScheduled';

    public static String FINANCE_QUEUE = 'Handover Finance Queue';
    public static String HO_COLLECTION_QUEUE = 'Handover Collection Team Queue';
    public static String HO_OPERATION_QUEUE = 'Handover Operation Team Queue';
    
    
    public static String KHO_Document_pdf = 'KHO_Document.pdf';
    public static String KHO_document_is_successfully_send_to_Customer = 'KHO document is successfully send to Customer';
     
    public static String  Appointment_Booked_Successfully = 'Appointment Booked Successfully'; 
    public static String  KHO_Appointment_Scheduled = 'KHO Appointment Scheduled';
    public static String  Appointment_Booked_Reminder = 'Appointment Booked Reminder'; 
    public static String  BCC_Announcement = 'BCC Announcement'; 
    public static String  Is_Notice_of_Completion_Sent = 'Is_Notice_of_Completion_Sent__c'; 
    
    public static String Please_Select_Status = 'Please Select Status';
    public static String Status_CHO = 'CHO';
    public static String Status_QA = 'QA';
    public static String Handover = 'Handover';
    
    /************************************** END - HANDOVER CONSTANTS ***********************************************/
    

    
    public static String STATUS = 'Status';
    public static String INVALID = 'Invalid';
    public static String ERROR_CODE = 'ErrorCode';
    public static String COMPLETED = 'Completed';
    public static String NORMAL = 'Normal';
    public static String HOURS = 'Hours';
    public static String VAT = 'VAT';

  
  //----- Profiles
 
  public static String SALES_MANAGER = 'Sales Manager';  
  public static string FINANCE_PROFILE = 'Finance Team';

  //----- APISetting__mdt
  public static String EMAIL = 'Email';
  public static String PHONE = 'Phone';
  public static String SMS = 'SMS';
  public static String SMSBULK = 'SMSBulk';
  
  public static String PAYMENT = 'Payment';
  //----- Lead Fields
  public static String RENT = 'Rent';

 // public static final String RESTRICT_SPECIAL_CONDITION_UPDATION = 'RESTRICT_SPECIAL_CONDITION_UPDATION' ;
  public static String RECEIPT_ALLOCATION_RESTRICTION = 'RECEIPT_ALLOCATION_RESTRICTION';
  public static String ALLOCATION_AMOUNT_RESTRICTION = 'ALLOCATION_AMOUNT_RESTRICTION';
  //---- Task Subject
  public static String SALES_OFFER = 'Sales Offer';
  public static String MEETING = 'Meeting';
  public static String CLOSEDWON = 'closedWon';

  //---- Opportunity stage
  public static String STAGE_PROPOSAL = 'Proposal';
  public static String STAGE_CLOSEDWON = 'Closed Won';
  public static String STAGE_NEW = 'New';
  public static String STAGE_IN_PROGRESS = 'Discussion In Progress';

  //----- Unit Status
  public static String UNIT_STATUS_AVAILABLE = 'Available';
  public static String UNIT_STATUS_BLOCKED = 'Blocked';
  public static String UNIT_STATUS_BOOKING_INPROGRESS = 'In-Progress';
  public static String UNIT_STATUS_BOOKED = 'Booked';
  public static String UNIT_STATUS_SOLD = 'Sold';
  
  //Email TEmplates
  public static string OFFER_LETTER = 'Offer_Letter';
  public static string OFFER_LETTER_LEAD = 'Offer_Letter';
  //Org wide email address
  public static string PROPERTIES_ORGWIDEEMAIL = 'Development';
  //Offer and Discount Types
  public static string  DISCOUNT_TYPE_BULK_DISCOUNT = 'Bulk Discount';
  public static string  OFFER_TYPE_VOUCHER ='Voucher';

  //RoundRobinAssignmentMatrix
  public static string STATUS_AVAILABLE = 'Available';

  //--- Generic Web-Service Messages
  public static final String SUCCESS_MESSAGE = 'Success';  
  public static final String INCORRECT_RECORD_ID = 'Please provide a valid record id.';
  public static final String GENERIC_MOBILE_LOG_VIEW = 'Mobile View';
    //----- Opportunity Unit
  public static string OPPO_UNIT_SUBSTATUS_PENDING_SM = 'Pending with Sales Manager';
    
  //----- BrokerRegistrationExpiryDateClass
   public static Id BrokerAgencyRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
   public static Id BrokerContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
   public static String Agency_Admin ='Agency Admin';
   public static string Bloom_No_Reply='Bloom No Reply';
   public static string Tradelicenseexpiryemailtempalte = 'Tradelicenseexpiryemailtempalte';
   public static string BrokerAgreementExpiryFinalTemplate = 'BrokerAgreementExpiryFinalTemplate';

  //--- Sales Order Statuses
  public static String SO_STATUS_CANCELLED = 'Cancelled';
  public static String SO_STATUS_CANCELLED_BY_USER = 'Cancelled by User';
  public static String SO_BOOK_STATUS_CANCELLED = 'Book Cancelled';
    
  public static string STATUS_RESERVED = 'Reserved';
  public static string OPPO_UNIT_STATUS_PENDING = 'Booked';
    //Timmer Names
  public static string RESERVATION_TIMMERNAME = 'ReservationUnit';
  //Payment
  public static string ONLINE = 'Online';
  public static string RECEIPT_STATUS_CLEARED = 'Cleared';
  public static string RECEIPT_STATUS_Received = 'Received';
  public static string RECEIPT_STATUS_Reversed = 'Reversed'; 
  
  //Broker Agency Portal
  @AuraEnabled
  public final String SUBMITTED = 'Submitted';

    //----- Aramex Integration
  public static String ARAMEX_TRACk_SHIPMENTS_INTEGRATION = 'AramexTrackShipments';

  //----- Broker Account Status
  public static String ACTIVE = 'Active';
  //------SalesOrder Sub Status
  public static String SALES_STATUS_CANCELLED = 'Cancelled';
    //-------Opportunity Status
  public static String OPPORTUINTY_REFERRAL_STAFF= 'Internal Staff Referral';
  //-------Project Budget Lines Name
  public static String BUDGET_LINE_DISCOUNT = 'Discounts';
  public static String BUDGET_LINE_ADMFEE = 'ADM Fee';
  public static String BUDGET_LINE_ADMADMINFEE = 'ADM Admin Fee';
  public static String BUDGET_LINE_OTHER = 'Other Sales Support';
  //-------Commission Line Item
  public static String COMMISSION_LINE_INTERNAL_COMMISSION = 'Sales Manager';
  public static String COMMISSION_LINE_EXTERNAL_COMMISSION = 'External';
 
  //payment Plan
  public static String PAYMENT_PLAN_TYPE_STANDARD='Standard';
 // public static Boolean IS_ACTIVE='Supplemenatry Documents'; 
public static String INVOICE_TYPE_INSTALLMENT = 'Installment';
  public static String INVOICE_TYPE_ADM = 'ADM';
  //Invoice line status
  public static string CLEARED = 'Cleared';
 //---- AML Result
  public static String AML_SCREENING_RESULT = 'No Risk Identified - Proceed';
  //----- Resident Status
  public static String RESIDENTSTATUS_RESIDENT = 'Resident';
  //External Comission Basis
  public static String COMISSIONBASIS_PERCENT ='Percent';
  public static String COMISSIONBASIS_AMOUNT ='Amount';
  //---- For Logging Purpose
  public static String LOG_TYPE_APEX_EXCEPTION = 'Apex Exception';
    
    /************************************************************ START - DLP CONSTANTS *********************************************************************/
    //WorkOrderTriggerHandler
    public static String DEFECT_LIABILITY_COMPLAINT = 'Defect_liability'; //'Defect liability Complaint';
    public static String WORKORDER_CREATION_NOTIFICATION_FOR_DLP_AGENT = 'WorkOrder Creation Notification for DLP Agent';
    public static String NEW_WORKORDER_ASSIGNED = 'New Work Order is assigned to you.';
    public static String WORKORDER_NUMBER_BLANK = 'Work Order Number: Blank.';
    public static String WORK_ORDER_NUMBER = 'Work Order Number: ';
    public static String DLP_LABEL = 'DLP';
    
    //Commission For
    public static String COMMISSION_FOR_BROKER = 'Broker';
    public static String COMMISSION_FOR_INTERNAL = 'Internal';
    //ProcessType__c
    public static String PROCESS_TYPE_SALES = 'Sales';
    
    //Approval Status
    public static String APPROVAL_STATUS_NOTAPPROVED = 'Not Approved';
    
    //Sales Order Status
    public static String SALES_ORDER_STATUS_SOLD = 'Sold';
    
    //Commission Invoice Status
    public static String COMMISSION_INVOICE_STATUS_DRAFT = 'Draft';
    public static String COMMISSION_INVOICE_STATUS_POSTED = 'Posted';
    public static String COMMISSION_INVOICE_STATUS_SHARED = 'Shared';
    
    // Document Types
    public static String GENERATED_INVOICE = 'Generated Invoice';
    public static String BROKER_SHARED_INVOICE = 'Broker Shared Invoice';
    public static String BROKER_FORM = 'Broker Form';
    
    
    //ServiceAppointmentTriggerHandler
    
    public static String Case_LABEL = 'Case';
    public static String WARRANTY_POST_DLP = 'Warranty post DLP';
    public static String OUT_OF_SCOPE = 'Out of Scope';
    public static String UNDER_SCOPE = 'Under Scope';
    public static String CHECK_IN = 'Check-In';
     public static String Schedule_Appointment = 'Schedule Appointment';
     public static String After_Rectification = 'After Rectification';
     public static String Check_Out = 'Check-Out';
    
    public static String PHONE_LABEL = 'Phone';
    public static String EMERGENCY = 'Emergency';
    public static String WITHIN_5_DAYS = 'Within 5 Days';
    public static String WITHIN_1_DAY = '1 Day';
    public static String REPLACE = 'Replace';
    public static String REPAIR = 'Repair';
    public static String PRIORITY_1 = 'Priority 1';
    public static String WITHIN_7_DAYS = 'Within 7 Days';
    public static String WITHIN_2_DAYS = '2 Days';
    public static String PRIORITY_2 = 'Priority 2';
    public static String WITHIN_14_DAYS = 'Within 14 Days';
    public static String WITHIN_5_DAY = '5 Day';
    public static String PRIORITY_3 = 'Priority 3';
    public static String WITHIN_2_DAY = 'Within 2 Day';
    public static String WITHIN_2_HOURS = 'Within 2 hours';
    public static String P1 = 'P1';
    public static String P2 = 'P2';
    public static String P3 = 'P3';
    public static String CLOSED = 'Closed';
    public static String RESOLVED = 'Resolved';
    public static String COMPLETED_LABEL = 'Completed';
    public static String NONE = 'None';
    public static String CUSTOMER_NOT_AVAILABLE_LABEL = 'Customer not available';
    public static String CUSTOMER_NOT_AVAILABLE_WHEN_AGENT_VISITED = 'Customer not available when agent visited';
    public static String NOT_AVAILABLE = 'Not Available';
    public static String OUT_OF_DLP_SCOPE = 'Out of DLP Scope';
    public static String OUTSIDE_SCOPE = 'Outside Scope';
    public static String CASE_RESOLVED = 'Case Resolved';
    public static String WORK_COMPLETED = 'Work Completed';
    public static String WORKORDER_CREATE_NOTIFICATION = 'WorkOrder Create Notification';
    public static String SCHEDULED = 'Scheduled';    
    public static String CONTRACTOR = 'Contractor';
    public static String SELF = 'Self';    
    public static String IN_PROGRESS = 'In Progress';
    public static String SUCCESS = 'Success';
    public static String PENDING = 'Pending';
    public static String BLOOM_NO_REPLY_LABEL = 'Bloom No Reply';
    public static String DISPATCHED  = 'Dispatched';
    public static String Not_Checked_In  = 'Not Checked-In';
    
    /************************************************************ END - DLP CONSTANTS *********************************************************************/
}