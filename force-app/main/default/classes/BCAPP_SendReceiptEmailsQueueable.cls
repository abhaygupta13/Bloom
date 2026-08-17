/**
 * SendReceiptEmailsQueueable
 * --------------------------
 * Queued job to send receipt emails (with PDF attachment) for a list of Receipt__c records.
 * - All SOQL is delegated to selector services.
 * - No System.debug logs.
 * - Behavior preserved: if email template not found, exit silently.
 */
public without sharing class BCAPP_SendReceiptEmailsQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> receiptIds;

    /** @param receiptIds list of Receipt__c Ids to email */
    public BCAPP_SendReceiptEmailsQueueable(List<Id> receiptIds) {
        this.receiptIds = receiptIds;
    }

    /** Queueable entry point */
    public void execute(QueueableContext qc) {
        // --- Query Receipts
        Map<Id, Receipt__c> rMap = ReceiptService.getInstance().getByIds(receiptIds);
        if (rMap.isEmpty()) return;

        // --- Collect OnlinePayment Ids
        Set<Id> paymentIds = new Set<Id>();
        for (Receipt__c r : rMap.values()) {
            if (r.OnlinePayment__c != null) paymentIds.add(r.OnlinePayment__c);
        }
        if (paymentIds.isEmpty()) return;

        // --- Query OnlinePayments (with related Account/Unit/Invoice fields)
        Map<Id, OnlinePayment__c> pMap =
            OnlinePaymentService.getInstance().getByIdsForEmail(paymentIds);
        if (pMap.isEmpty()) return;

        // --- Get template by developer name
        EmailTemplate et;
        try {
            et = EmailTemplateService.getInstance().getByDeveloperName('SendReceiptEmailTemplate');
        } catch (Exception e) {
            // Preserve behavior: silently exit if template is missing
            return;
        }
        if (et == null) return;

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Receipt__c r : rMap.values()) {
            OnlinePayment__c p = pMap.get(r.OnlinePayment__c);
            if (p == null) continue;
            if (String.isBlank(p.Account__r.PersonEmail)) continue;

            // ---- Subject
            String subject;
            if (p.Invoice__c != null && p.Unit__r != null) {
                subject = 'Bloom Gardens Unit ' + p.Unit__r.Name + ' – Payment Confirmation';
            } else {
                subject = 'Bloom Gardens – Payment Confirmation';
            }

            // ---- Generate PDF
            PageReference pdfPage = Page.Receipt_PDF;
            pdfPage.getParameters().put('receiptId', r.Id);
            Blob pdfBlob;
            if (!Test.isRunningTest()) {
                pdfBlob = pdfPage.getContentAsPDF();
            } else {
                // Stub a non-null Blob during test execution to avoid exceptions
                pdfBlob = Blob.valueOf('Test PDF content');
            }

            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setContentType('application/pdf');
            att.setFileName('Receipt_' + r.Name + '.pdf');
            att.setBody(pdfBlob);

            // ---- Build templated email
            Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();
            em.setTemplateId(et.Id);

            // Person Account path (prefer template merge)
            if (p.Account__r.PersonContactId != null) {
                em.setTargetObjectId(p.Account__r.PersonContactId);
                em.setTreatTargetObjectAsRecipient(true);
                em.setSubject(subject);
                em.setHtmlBody(et.HtmlValue); // keep original behavior
            } else {
                // Fallback by email address (template merge limited)
                em.setToAddresses(new String[] { p.Account__r.PersonEmail });
            }

            em.setWhatId(r.Id);          // merge context: Receipt__c
            em.setSubject(subject);      // override subject
            em.setSaveAsActivity(false); // don't create activity
            em.setFileAttachments(new Messaging.EmailFileAttachment[] { att });

            emails.add(em);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}