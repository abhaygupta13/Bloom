/**
 * Class: BCAPP_InvoiceHandler
 * Purpose: Orchestrates invoice-related operations exposed via REST controllers:
 *          - Fetch invoices / invoice by Id / summary
 *          - Submit payment intent and update payment status
 *          - Retrieve payment status/history and receipt details
 *          - Generate / email Statement of Account (SOA)
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - No inline SOQL or DML: all data access and persistence are delegated to Service classes.
 * - This class focuses on request validation, orchestration, and response shaping only.
 */
public without sharing class BCAPP_InvoiceHandler {

    /**
     * Fetch all unpaid/partially paid invoices for a given Account + Unit.
     * @param data { accountId: Id, unitId: Id }
     */
    public static void getInvoices(Map<String, Object> data) {
        try {
            String accountId = (String) data.get('accountId');
            String unitId    = (String) data.get('unitId');

            List<Invoice__c> invoiceRecords =
                InvoiceService.getInstance().getUnpaidOrPartialByAccountUnit((Id)accountId, (Id)unitId);

            Map<Id, Decimal> allocationMap =
                InvoiceAllocationService.getInstance().sumAllocatedByInvoices(invoiceRecords);

            List<Map<String, Object>> invoices = new List<Map<String, Object>>();
            for (Invoice__c inv : invoiceRecords) {
                Decimal allocated = allocationMap.containsKey(inv.Id) ? allocationMap.get(inv.Id) : 0;
                Decimal dueAmount = (inv.TotalAmount__c != null ? inv.TotalAmount__c : 0);
                String invDesc = '';
                if(inv.PeriodStartDate__c != null && inv.PeriodEndDate__c != null){
                    invDesc = 'Service charge from ' + inv.PeriodStartDate__c.format()+ ' to ' + inv.PeriodEndDate__c.format();
                }else{
                    invDesc = inv.InvoiceDescription__c;
                }
				
                invoices.add(new Map<String, Object>{
                    'id'                 => inv.Id,
                    'name'               => inv.Name,
                    'sapInvoiceNumber'   => inv.SapInvoiceNumber__c,
                    'totalAmount'        => inv.TotalAmount__c,
                    'status'             => inv.Status__c,
                    'invoiceDate'        => inv.InvoiceDate__c,
                    'invoiceDescription' => invDesc,
                    'dueAmount'          => dueAmount
                });
            }

            BCAPP_WebServiceHelper.makeSuccessResponse(new Map<String, Object>{ 'records' => invoices });

        } catch (Exception ex) {
            BCAPP_WebServiceHelper.makeServerErrorResponse(new Map<String, Object>{
                'errorMessage' => 'Error in getInvoices: ' + ex.getMessage()
            });
        }
    }

    /**
     * Fetch one invoice by Id.
     * @param data { invoiceId: Id }
     */
    public static void getInvoiceById(Map<String, Object> data) {
        try {
            String invoiceId = (String) data.get('invoiceId');

            Invoice__c inv = InvoiceService.getInstance().getById((Id)invoiceId);
			String invDesc = '';
                if(inv.PeriodStartDate__c != null && inv.PeriodEndDate__c != null){
                    invDesc = 'Service charge from ' + inv.PeriodStartDate__c.format()+ ' to ' + inv.PeriodEndDate__c.format();
                }else{
                    invDesc = inv.InvoiceDescription__c;
                }
            Map<String, Object> invoice = new Map<String, Object>{
                'id'                 => inv.Id,
                'name'               => inv.Name,
                'sapInvoiceNumber'   => inv.SapInvoiceNumber__c,
                'totalAmount'        => inv.TotalAmount__c,
                'status'             => inv.Status__c,
                'invoiceDate'        => inv.InvoiceDate__c,
                'invoiceDescription' => invDesc
            };

            BCAPP_WebServiceHelper.makeSuccessResponse(new Map<String, Object>{ 'invoice' => invoice });

        } catch (Exception ex) {
            BCAPP_WebServiceHelper.makeServerErrorResponse(new Map<String, Object>{
                'errorMessage' => 'Error in getInvoiceById: ' + ex.getMessage()
            });
        }
    }

    /**
     * Get summary of total due for a given Account + Unit.
     * @param data { accountId: Id, unitId: Id }
     */
    public static void getSummary(Map<String, Object> data) {
        try {
            String accountId = (String) data.get('accountId');
            String unitId    = (String) data.get('unitId');

            AggregateResult summary =
                InvoiceService.getInstance().sumTotalDueByAccountUnit((Id)accountId, (Id)unitId);

            Map<String, Object> response = new Map<String, Object>{
                'totalDue' => summary != null ? summary.get('totalDue') : null
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in getSummary: ' + ex.getMessage()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Log intent to pay (creates OnlinePayment__c with Status=Pending and related Line Items).
     * @param data { invoices: [{invoiceId, amount}], source, customerId, unitId, paymentMethod }
     */
    public static void submitPayment(Map<String, Object> data) {
        try {
            List<Object> invoiceObjs = (List<Object>) data.get('invoices');
            String source            = (String) data.get('source');
            String accountId         = (String) data.get('accountId');
            String unitId            = (String) data.get('unitId');
            String paymentMethod     = (String) data.get('paymentMethod');

            Decimal totalAmount = 0;
            List<OnlinePaymentLineItem__c> lineItems = new List<OnlinePaymentLineItem__c>();

            for (Object obj : invoiceObjs) {
                Map<String, Object> invData = (Map<String, Object>) obj;
                String invoiceId = (String) invData.get('invoiceId');
                Decimal amount   = (Decimal) invData.get('amount');

                totalAmount += (amount == null ? 0 : amount);

                lineItems.add(new OnlinePaymentLineItem__c(
                    Invoice__c       = invoiceId,
                    PlannedAmount__c = amount
                ));
            }
			Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
            BankAccount__c ba = fetchBankDetailsByCompanyCode(unit.Project__r.BankAccount__c);
            Decimal technologyFee = totalAmount * 0.0125;
			Decimal netAmount = totalAmount - technologyfee;
            
            // DML moved to services
            OnlinePayment__c payment = new OnlinePayment__c(
                PaidAmount__c    = netAmount,
                Status__c        = 'Pending',
                RequestSource__c = source,
                PaymentMethod__c = paymentMethod,
                Unit__c          = unitId,
                Account__c       = accountId,
                TechnologyFee__c = technologyFee
            );
            payment = OnlinePaymentService.getInstance().insertPayment(payment);

            for (OnlinePaymentLineItem__c item : lineItems) {
                item.OnlinePayment__c = payment.Id;
            }
            OnlinePaymentLineItemService.getInstance().insertLineItems(lineItems);

            Map<String, Object> response = new Map<String, Object>{ 'paymentId' => BCAPP_Utility.encryptId(payment.Id), 'mmid' =>ba.MMID__c};
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in submitPayment: ' + ex.getMessage() + ' | Line: ' + ex.getLineNumber() + ' | Stack: ' + ex.getStackTraceString()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Update payment activity after gateway result (Success/Failed). Creates Receipt & Allocations on Success.
     * @param data { paymentId, status, message, paymentMethod }
     */
    public static void updatePaymentStatus(Map<String, Object> data) {
        try {
            String paymentId     = (String) data.get('paymentId');
            String status        = (String) data.get('status'); // Success / Failed
            String message       = (String) data.get('message');
            String paymentMethod = (String) data.get('paymentMethod');

            OnlinePayment__c payment =
                OnlinePaymentService.getInstance().getPaymentById((Id)paymentId);

            payment.Status__c          = status;
            payment.ResponseMessage__c = message;
            payment.PaymentMethod__c   = paymentMethod;

            // DML moved to service
            OnlinePaymentService.getInstance().updatePayment(payment);

            Receipt__c receipt;

            if (status == 'Success') {
                List<OnlinePaymentLineItem__c> lines =
                    OnlinePaymentService.getInstance().getLineItemsByPayment(payment.Id);

                // DML moved to service
                receipt = new Receipt__c(
                    AmountReceived__c = payment.PaidAmount__c,
                    PaymentDate__c    = System.today(),
                    PaymentMode__c    = 'Online',
                    Status__c         = 'Posted',
                    Account__c        = payment.Account__c,
                    Unit__c = payment.unit__c,
                    OnlinePayment__c  = payment.Id,
                    TechnologyFee__c  = payment.TechnologyFee__c
                );
                receipt = ReceiptService.getInstance().insertReceipt(receipt);

                List<InvoiceAllocation__c> allocations = new List<InvoiceAllocation__c>();
                for (OnlinePaymentLineItem__c line : lines) {
                    allocations.add(new InvoiceAllocation__c(
                        Invoice__c         = line.Invoice__c,
                        Receipt__c         = receipt.Id,
                        AllocatedAmount__c = line.PlannedAmount__c,
                        AllocationDate__c  = System.today()
                    ));
                }
                InvoiceAllocationService.getInstance().insertAllocations(allocations);
            }

            if (payment.Status__c == 'Success') {
                // External system call, not DML
                BCAPP_SAPPaymentStatusPoster.postPaymentStatus(payment.Id, 'Service');
            }

            Map<String, Object> response = new Map<String, Object>{
                'status'    => payment.Status__c,
                'message'   => payment.ResponseMessage__c,
                'receiptId' => (receipt == null ? null : receipt.Id)
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in updatePaymentStatus: ' + ex.getMessage() + ' | Line: ' + ex.getLineNumber() + ' | Stack: ' + ex.getStackTraceString()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Optional polling API to check payment status.
     * @param data { paymentId }
     */
    public static void getPaymentStatus(Map<String, Object> data) {
        try {
            String paymentId = (String) data.get('paymentId');

            OnlinePayment__c payment =
                OnlinePaymentService.getInstance().getPaymentById((Id)paymentId);

            List<OnlinePaymentLineItem__c> items =
                OnlinePaymentService.getInstance().getLineItemsByPayment(payment.Id);

            List<Map<String, Object>> invoiceDetails = new List<Map<String, Object>>();
            for (OnlinePaymentLineItem__c item : items) {
                invoiceDetails.add(new Map<String, Object>{
                    'invoiceId'     => item.Invoice__c,
                    'invoiceName'   => item.Invoice__r != null ? item.Invoice__r.Name : null,
                    'plannedAmount' => item.PlannedAmount__c
                });
            }

            Map<String, Object> response = new Map<String, Object>{
                'status'      => payment.Status__c,
                'message'     => payment.ResponseMessage__c,
                'totalPaid'   => payment.PaidAmount__c,
                'createdDate' => payment.CreatedDate,
                'invoices'    => invoiceDetails
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in getPaymentStatus: ' + ex.getMessage()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Get payment history (successful payments) for an Account.
     * @param data { accountId }
     */
    public static void getPaymentHistory(Map<String, Object> data) {
        try {
            String accountId = (String) data.get('accountId');

            List<OnlinePayment__c> payments =
                OnlinePaymentService.getInstance().getSuccessfulPaymentsByAccount((Id)accountId, 100);

            Map<Id, Receipt__c> receiptsMap =
                ReceiptService.getInstance().getReceiptsByPaymentIds(payments);

            List<Map<String, Object>> paymentHistory = new List<Map<String, Object>>();
            for (OnlinePayment__c payment : payments) {
                Map<String, Object> entry = new Map<String, Object>{
                    'paymentId'        => payment.Id,
                    'paidAmount'       => (payment.PaidAmount__c+(payment.TechnologyFee__c!=null?payment.TechnologyFee__c:0)),
                    'status'           => payment.Status__c,
                    'gatewayReference' => payment.GatewayReference__c,
                    'message'          => payment.ResponseMessage__c,
                    'createdDate'      => payment.CreatedDate
                };
                if (receiptsMap.containsKey(payment.Id)) {
                    Receipt__c receipt = receiptsMap.get(payment.Id);
                    entry.put('receiptId', receipt.Id);
                    entry.put('receiptNo', receipt.Name);
                }
                paymentHistory.add(entry);
            }

            Map<String, Object> response = new Map<String, Object>{
                'paymentHistory' => paymentHistory
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in getPaymentHistory: ' + ex.getMessage()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Get receipt and its allocations OR generate/email SOA PDF for a date range.
     * @param data
     *   For getReceipt:            { receiptId }
     *   For getStatementOfAccount: { accountId, unitId, mode('view'|'email'), startDate('YYYY-MM-DD'), endDate('YYYY-MM-DD') }
     */
    public static void getReceipt(Map<String, Object> data) {
        try {
            String receiptId = (String) data.get('receiptId');

            Receipt__c receipt = ReceiptService.getInstance().getById((Id)receiptId);

            List<InvoiceAllocation__c> allocations =
                InvoiceAllocationService.getInstance().getByReceipt(receipt.Id);

            List<Map<String, Object>> invoiceList = new List<Map<String, Object>>();
            for (InvoiceAllocation__c alloc : allocations) {
                invoiceList.add(new Map<String, Object>{
                    'invoiceId'       => alloc.Invoice__c,
                    'invoiceNumber'   => alloc.Invoice__r.SAPInvoiceNumber__c,
                    'allocatedAmount' => alloc.AllocatedAmount__c,
                    'allocationDate'  => alloc.AllocationDate__c,
                    'notes'           => alloc.Notes__c
                });
            }

            // PDF generation (not DML)
            PageReference pdfPage = Page.Receipt_PDF;
            pdfPage.getParameters().put('receiptId', receipt.Id);
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                // Assign a dummy Blob value during test execution
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                // In a non-test context, generate the actual PDF
                pdfBlob = pdfPage.getContentAsPDF();
            }
            String encoded = EncodingUtil.base64Encode(pdfBlob);

            Map<String, Object> response = new Map<String, Object>{
                'receipt' => new Map<String, Object>{
                    'id'             => receipt.Id,
                    'name'           => receipt.Name,
                    'amountReceived' => receipt.AmountReceived__c,
                    'paymentDate'    => receipt.PaymentDate__c,
                    'paymentMode'    => receipt.PaymentMode__c,
                    'sapDocumentNo'  => receipt.SAPDocumentNo__c,
                    'status'         => receipt.Status__c,
                    'accountId'      => receipt.Account__c,
                    'unitId'         => receipt.Unit__c,
                    'paymentId'      => receipt.OnlinePayment__c,
                    'receiptPdf'     => encoded
                },
                'allocations' => invoiceList
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in getReceipt: ' + ex.getMessage()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Generate (view/email) Statement of Account (SOA) for Account + Unit within date range.
     * @param data { accountId, unitId, mode('view'|'email'), startDate('YYYY-MM-DD'), endDate('YYYY-MM-DD') }
     */
    public static void getStatementOfAccount(Map<String, Object> data) {
        try {
            String accountId = (String) data.get('accountId');
            String unitId    = (String) data.get('unitId');
            String mode      = (String) data.get('mode'); // "view" or "email"
            Date startDate   = Date.valueOf((String) data.get('startDate'));
            Date endDate     = Date.valueOf((String) data.get('endDate'));

            Account acc = AccountService.getInstance().getLightweightById((Id)accountId);
            Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];

            List<Invoice__c> invoiceRecs =
                InvoiceService.getInstance().getByAccountUnitInRange((Id)accountId, (Id)unitId, startDate, endDate);

            List<Map<String, Object>> invoices = new List<Map<String, Object>>();
            for (Invoice__c inv : invoiceRecs) {
                invoices.add(new Map<String, Object>{
                    'id'          => inv.Id,
                    'name'        => inv.Name,
                    'invoiceDate' => inv.InvoiceDate__c,
                    'totalAmount' => inv.TotalAmount__c,
                    'status'      => inv.Status__c
                });
            }

            List<InvoiceAllocation__c> allocationRecs =
                InvoiceAllocationService.getInstance().getByAccountUnitInRange((Id)accountId, (Id)unitId, startDate, endDate);

            List<Map<String, Object>> allocations = new List<Map<String, Object>>();
            for (InvoiceAllocation__c alloc : allocationRecs) {
                allocations.add(new Map<String, Object>{
                    'invoiceId'       => alloc.Invoice__c,
                    'invoiceName'     => alloc.Invoice__r.Name,
                    'paymentDate'     => alloc.Receipt__r.PaymentDate__c,
                    'paymentMode'     => alloc.Receipt__r.PaymentMode__c,
                    'amountReceived'  => alloc.Receipt__r.AmountReceived__c,
                    'allocatedAmount' => alloc.AllocatedAmount__c
                });
            }

            if (mode == 'view') {
                PageReference pdfPage = Page.SOA_PDF;
                pdfPage.getParameters().put('accountId', accountId);
                pdfPage.getParameters().put('unitId', unitId);
                pdfPage.getParameters().put('startDate', String.valueOf(startDate));
                pdfPage.getParameters().put('endDate', String.valueOf(endDate));

                Blob pdfBlob;
                if (Test.isRunningTest()) {
                // Assign a dummy Blob value during test execution
                    pdfBlob = Blob.valueOf('Test PDF Content');
                } else {
                    // In a non-test context, generate the actual PDF
                    pdfBlob = pdfPage.getContentAsPDF();
                }
                String encoded = EncodingUtil.base64Encode(pdfBlob);

                Map<String, Object> soa = new Map<String, Object>{
                    'accountName' => acc.Name,
                    'unitName'    => unit.Name,
                    'startDate'   => startDate,
                    'endDate'     => endDate,
                    'invoices'    => invoices,
                    'allocations' => allocations,
                    'soaPdf'      => encoded
                };
                BCAPP_WebServiceHelper.makeSuccessResponse(new Map<String, Object>{ 'soa' => soa });

            } else if (mode == 'email') {
                PageReference pdfPage = Page.SOA_PDF;
                pdfPage.getParameters().put('accountId', accountId);
                pdfPage.getParameters().put('unitId', unitId);
                pdfPage.getParameters().put('startDate', String.valueOf(startDate));
                pdfPage.getParameters().put('endDate', String.valueOf(endDate));

                Blob pdfBlob = pdfPage.getContentAsPDF();

                // DML moved to services
                ContentVersion cv = new ContentVersion();
                cv.Title              = 'StatementOfAccount.pdf';
                cv.PathOnClient       = 'StatementOfAccount.pdf';
                cv.VersionData        = pdfBlob;
                cv.FirstPublishLocationId = acc.Id;
                cv.IsMajorVersion     = true;

                cv = ContentService.getInstance().insertContentVersion(cv);

                EmailTemplate et = EmailTemplateService.getInstance().getByDeveloperName('SOAStatementEmail');

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(et.Id);

                if (acc.PersonContactId != null) {
                    email.setTargetObjectId(acc.PersonContactId);
                    email.setTreatTargetObjectAsRecipient(true);
                } else {
                    email.setToAddresses(new String[] { acc.PersonEmail });
                }

                email.setWhatId(acc.Id);
                email.setSubject('Bloom Gardens Unit ' + unit.Name + ' – Statement of Account');
                email.setHtmlBody(et.HtmlValue);
                email.setSaveAsActivity(true);
                email.setEntityAttachments(new String[] { cv.Id });

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

                BCAPP_WebServiceHelper.makeSuccessResponse(new Map<String, Object>{
                    'message' => 'SOA sent to email.'
                });

            } else {
                Map<String, Object> response = new Map<String, Object>{
                    'errorMessage' => 'Invalid mode provided: ' + mode
                };
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            }

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Error in getStatementOfAccount: ' + ex.getMessage()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }
    private static BankAccount__c fetchBankDetailsByCompanyCode(String companyCode) {
        if (String.isBlank(companyCode)) return null;
        // SOQL is supported on Custom Metadata Types
        List<BankAccount__c> rows = [
            SELECT Name,CompanyCode__c, AccountNumberCorporate__c, IBANNoCorporate__c, SwiftCodeCorporate__c, BankNameCorporate__c,MMID__c 
            FROM BankAccount__c
            WHERE Id = :companyCode
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }
}