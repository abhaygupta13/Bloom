/**
* @File Name : BulkEmailBatch.cls
* @Description : Batch class for handling bulk email operations.
* @Author : Kumar
* @Last Modified By : Kumar
* @Last Modified On : January 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date             | Author     | Modification
*==============================================================================
* 1.0 | December 26, 2024 |     Kumar       | Initial Version
*/
public class BulkEmailBatch implements Database.Batchable<String> {
    private List<String> emailAddresses;
    private String emailBody;
    private String emailSubject;
    private String fromEmailAddress;
    private Map<String, String> contactEmailMap;
    private List<String> attachmentNames;
    private List<String> attachmentContents;
    private String orgEmailId;

    public BulkEmailBatch(
        List<String> emailAddresses, String emailBody, String emailSubject,
        String fromEmailAddress, Map<String, String> contactEmailMap,
        List<String> attachmentNames, List<String> attachmentContents, String orgEmailId
    ) {
        this.emailAddresses = emailAddresses;
        this.emailBody = emailBody;
        this.emailSubject = emailSubject;
        this.fromEmailAddress = fromEmailAddress;
        this.contactEmailMap = contactEmailMap;
        this.attachmentNames = attachmentNames;
        this.attachmentContents = attachmentContents;
        this.orgEmailId = orgEmailId;
    }

    // Start method returns email addresses to process in batches
    public Iterable<String> start(Database.BatchableContext bc) {
        return emailAddresses;
    }

    // Execute method processes each batch of email addresses
    public void execute(Database.BatchableContext bc, List<String> scope) {
        

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        for (String email : scope) {
            if (isValidEmail(email)) { // Validate email before sending
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                emailMessage.setToAddresses(new String[]{email});
                emailMessage.setSubject(emailSubject);
                emailMessage.setHtmlBody(emailBody);
                // Attach files if provided
                if (!attachmentNames.isEmpty() && !attachmentContents.isEmpty()) {
                    List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                    for (Integer i = 0; i < attachmentNames.size(); i++) {
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        attachment.setFileName(attachmentNames[i]);
                        attachment.setBody(EncodingUtil.base64Decode(attachmentContents[i]));
                        emailAttachments.add(attachment);
                    }
                    emailMessage.setFileAttachments(emailAttachments);
                }
                // Assign OrgWideEmailAddress if available
                if (!String.isBlank(orgEmailId)) {
                    emailMessage.setOrgWideEmailAddressId(orgEmailId);
                }
                // Set TargetObjectId if available
                if (contactEmailMap.containsKey(email)) {
                    emailMessage.setTargetObjectId(contactEmailMap.get(email));
                    emailMessage.setSaveAsActivity(true);
                }

                emailMessages.add(emailMessage);
            }
        }

        // Send emails
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    }

    // Finish method for post-processing
    public void finish(Database.BatchableContext bc) {
        // Log or notify when the batch is complete
        System.debug('Bulk email batch processing completed.');
    }

    // Helper method to validate email addresses
    private static Boolean isValidEmail(String email) {
        Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
        return emailPattern.matcher(email).matches();
    }
}