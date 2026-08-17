/**
* SAP_PaymentStatusPoster
* Layer: Integration (Async @future callout)
* Purpose: Post successful online payment data to SAP in either Service ('S') or Misc ('M') format.
*
* Key Behavior:
*  - Entry: postPaymentStatus(paymentId, 'Service'|'Misc') via @future(callout=true).
*  - Builds payload(s) from OnlinePayment + line items and sends to SAP.
*  - Reads token and API endpoints from APISetting__mdt (no hard-coded URLs).
*
* Sharing Model: without sharing (no row-level security needed for integration payload build).
* Dependencies: OnlinePaymentService, OnlinePaymentLineItemService, APISetting__mdt, Http/HttpRequest.
* SOQL/DML Location: None in this class; all queries are delegated to services.
* Error Handling: Quietly returns on configuration/auth/send failures (no System.debug logs per project standards).
* Last Reviewed: 2025-09-01
*/
public without sharing class BCAPP_SAPPaymentStatusPoster {
    
    private static final String BANK_NAME = 'ABU DHABI COMMERCIAL BANK';
    
    /** Entry point: posts payment status to SAP for Service or Misc types. */
    @Future(callout=true)
    public static void postPaymentStatus(Id paymentId, String type) {
        if (type == 'Service') {
            postServicePayment(paymentId);
        } else if (type == 'Misc') {
            postMiscPayment(paymentId);
        } 
        else if (type == 'QuickPay') {
            postQuickPayment(paymentId);
        } else {
            // Unsupported type -> no-op (quiet per logging policy)
            return;
        }
    }
    
    /** Build & send payload for invoice-based Service payments (ReqType 'S'). */
    private static void postServicePayment(Id paymentId) {
        OnlinePayment__c payment =
            OnlinePaymentService.getInstance().getForPaymentPosting(paymentId);
        
        if (payment == null) return;
        Decimal totalAmount = payment.PaidAmount__c+(payment.TechnologyFee__c!=null?payment.TechnologyFee__c:0);
        List<OnlinePaymentLineItem__c> lines =
            OnlinePaymentLineItemService.getInstance().getLinesForServicePayment(paymentId);
        if (lines.isEmpty()) return;
        
        List<Map<String, Object>> invoiceList = new List<Map<String, Object>>();
        for (OnlinePaymentLineItem__c line : lines) {
            invoiceList.add(new Map<String, Object>{
                'SFId'         => payment.Id,
                    'SFrono'       => line.Invoice__r.SAPInvoiceNumber__c,
                    'Bukrs'        => line.Invoice__r.CompanyCode__c,
                    'Contract'     => line.Invoice__r.SAPContractNumber__c,
                    'Invoice'      => line.Invoice__r.SAPInvoiceNumber__c,
                    'Name'         => payment.Account__r.Name,
                    'VerifiedDate' => String.valueOf(payment.CreatedDate.date()),
                    'Amount'       => String.valueOf(totalAmount),
                    'Bnkname'      => BANK_NAME,
                    'Buyer'        => line.Invoice__r.CustomerNumber__c,
                    'ReqType'      => 'S',
                    'TransType'    => 'CARD',
                    'FiscalYear'   => line.Invoice__r.InvoiceYear__c
                    });
        }
        
        ApiCallResult result = sendToSAP(invoiceList);
        updateAllocationDocRefs(result.responseBody);
        // Parse SAP clearing items (focus: InvoiceDetails)
        // List<BCAPP_SapInvoiceClearingItem> sapItems = BCAPP_SapInvoiceClearingItem.parseFromResponse(result.responseBody);
        //BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(payment, lines, sapItems); 
    }
    
    
    private static void postQuickPayment(Id paymentId) {
        OnlinePayment__c payment =
            OnlinePaymentService.getInstance().getForPaymentPosting(paymentId);
        
        if (payment == null) return;
        
        Decimal totalAmount = payment.PaidAmount__c+(payment.TechnologyFee__c!=null?payment.TechnologyFee__c:0);
        List<Map<String, Object>> invoiceList = new List<Map<String, Object>>();
        invoiceList.add(new Map<String, Object>{
            'SFId'         => payment.Id,
                'SFrono'       => payment.Id,
                'Bukrs'        => payment.Unit__r.CommunityCompanyCode__c,
                'Contract'     => payment.Unit__r.CommunityContractNumber__c,
                'Invoice'      => '',
                'Name'         => payment.Account__r.Name,
                'VerifiedDate' => String.valueOf(payment.CreatedDate.date()),
                'Amount'       => String.valueOf(totalAmount),
                'Bnkname'      => BANK_NAME,
                'Buyer'        => payment.Account__r.SAP_BP_No__c,
                'ReqType'      => 'S',
                'TransType'    => 'CARD',
                'FiscalYear'   => ''
                });
        
        
        ApiCallResult result = sendToSAP(invoiceList);
        updateReceiptRefs(result.responseBody,payment.Id);
        
        // Parse SAP clearing items (focus: InvoiceDetails)
        // List<BCAPP_SapInvoiceClearingItem> sapItems = BCAPP_SapInvoiceClearingItem.parseFromResponse(result.responseBody);
        //BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(payment, lines, sapItems); 
    }
    
    /** Build & send payload for miscellaneous payments (ReqType 'M'). */
    private static void postMiscPayment(Id paymentId) {
        OnlinePayment__c payment =
            OnlinePaymentService.getInstance().getForPaymentPosting(paymentId);
        
        if (payment == null) return;
        
        List<OnlinePaymentLineItem__c> lines =
            OnlinePaymentLineItemService.getInstance().getLinesForMiscPayment(paymentId);
        if (lines.isEmpty()) return;
        System.debug('payment' + payment);
        Address pa = payment.Account__r != null ? payment.Account__r.PersonMailingAddress : null;

        List<String> parts = new List<String>();
        if (pa != null) {
            // Normalize street to one line
            String street = pa.street != null ? pa.street.replaceAll('[\\r\\n]+', ' ').trim() : null;
            if (!String.isBlank(street)) parts.add(street);
            if (!String.isBlank(pa.city)) parts.add(pa.city.trim());
            if (!String.isBlank(pa.state)) parts.add(pa.state.trim());
            if (!String.isBlank(pa.postalCode)) parts.add(pa.postalCode.trim());
            if (!String.isBlank(pa.country)) parts.add(pa.country.trim());
        }
        
        String billingAddr = String.join(parts, ', ');
        
        // Trim to 250 characters
        if (!String.isBlank(billingAddr) && billingAddr.length() > 250) {
            billingAddr = billingAddr.substring(0, 250);
        }
        List<Map<String, Object>> invoiceList = new List<Map<String, Object>>();
        for (OnlinePaymentLineItem__c line : lines) {
            invoiceList.add(new Map<String, Object>{
                'SFId'         => payment.Id,
                    'SFrono'       => payment.Id,
                    'Bukrs'        => payment.Unit__r.CommunityCompanyCode__c,
                    'Contract'     => payment.Unit__r.CommunityContractNumber__c,
                    'Name'         => payment.Account__r.Name,
                    'VerifiedDate' => String.valueOf(payment.CreatedDate.date()),
                    'Amount'       => String.valueOf(payment.PaidAmount__c),
                    'Bnkname'      => BANK_NAME,
                    'Buyer'        => payment.Account__r.SAP_BP_No__c,
                    'TransType'    => 'CARD', // preserving original behavior
                    'ReqType'      => 'M',
                    'Address'      => billingAddr,
                    'MobileNo'     => payment.Account__r.PersonMobilePhone,
                    'Email'        => payment.Account__r.PersonEmail,
                    'TRN'          => '',
                    'Status'       => 'Paid'
                    });
        }
        
        ApiCallResult result = sendToSAP(invoiceList);
        // Parse SAP clearing items (focus: InvoiceDetails)
        List<BCAPP_SapInvoiceClearingItem> sapItems = BCAPP_SapInvoiceClearingItem.parseFromResponse(result.responseBody);
        BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(payment, lines, sapItems);
    }
    
    /**
* Gets an Azure B2C token (ROPC) and posts the InvoiceDetails payload to Bloom SAP API.
* Reads endpoints/credentials from APISetting__mdt entries:
*  - Bloom_SAP_Invoice_Token
*  - Bloom_SAP_Invoice_API
*/
    private static ApiCallResult sendToSAP(List<Map<String, Object>> invoiceDetails) {
        ApiCallResult out = new ApiCallResult();
        out.success = false;
        APISetting__mdt tokenCfg = APISetting__mdt.getInstance('Bloom_SAP_Invoice_Token');
        APISetting__mdt apiCfg   = APISetting__mdt.getInstance('Bloom_SAP_Invoice_API');
        if (tokenCfg == null || apiCfg == null) return out;
        
        // 1) Get access token
        String accessToken;
        try {
            HttpRequest tkReq = new HttpRequest();
            tkReq.setEndpoint(tokenCfg.URL__c);
            tkReq.setMethod(String.isBlank(tokenCfg.httpMethod__c) ? 'POST' : tokenCfg.httpMethod__c);
            tkReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            tkReq.setHeader('accept', 'application/json');
            tkReq.setTimeout(15000);
            
            List<String> kv = new List<String>();
            kv.add('grant_type=' + EncodingUtil.urlEncode('password', 'UTF-8'));
            if (String.isNotBlank(tokenCfg.Client_Id__c))
                kv.add('client_id=' + EncodingUtil.urlEncode(tokenCfg.Client_Id__c, 'UTF-8'));
            if (String.isNotBlank(tokenCfg.Client_Secret__c))
                kv.add('client_secret=' + EncodingUtil.urlEncode(tokenCfg.Client_Secret__c, 'UTF-8'));
            if (String.isNotBlank(tokenCfg.Scope__c))
                kv.add('scope=' + EncodingUtil.urlEncode(tokenCfg.Scope__c, 'UTF-8'));
            if (String.isNotBlank(tokenCfg.Authorization__c))
                kv.add('username=' + EncodingUtil.urlEncode(tokenCfg.Authorization__c, 'UTF-8'));
            if (String.isNotBlank(tokenCfg.Password__c))
                kv.add('password=' + EncodingUtil.urlEncode(tokenCfg.Password__c, 'UTF-8'));
            
            tkReq.setBody(String.join(kv, '&'));
            
            HttpResponse tkRes = new Http().send(tkReq);
            if (tkRes.getStatusCode() >= 200 && tkRes.getStatusCode() < 300) {
                Map<String, Object> tokenJson = (Map<String, Object>) JSON.deserializeUntyped(tkRes.getBody());
                accessToken = (String) tokenJson.get('access_token');
            }
        } catch (Exception e) {
            out.error = e.getMessage();
        }
        if (String.isBlank(accessToken)) return out;
        try {
            Map<String, Object> payload = new Map<String, Object>{ 'InvoiceDetails' => invoiceDetails };
                System.debug('payload' + JSON.serialize(payload));
            HttpRequest apiReq = new HttpRequest();
            apiReq.setEndpoint(apiCfg.URL__c);
            apiReq.setMethod(String.isBlank(apiCfg.httpMethod__c) ? 'POST' : apiCfg.httpMethod__c);
            apiReq.setHeader('Authorization', 'Bearer ' + accessToken);
            apiReq.setHeader('Content-Type', 'application/json');
            apiReq.setTimeout(15000);
            apiReq.setBody(JSON.serialize(payload));
            
            HttpResponse apiRes = new Http().send(apiReq);
            if (apiRes != null) {
                out.statusCode   = apiRes.getStatusCode();
                out.responseBody = apiRes.getBody();
                System.debug(apiRes.getBody());
                out.success      = (out.statusCode != null && out.statusCode >= 200 && out.statusCode < 300);
            }
        } catch (Exception ex) {
            out.error = ex.getMessage();
        }
        return out;
    }
    /**
* Updates Document Reference (RefDoc) on all invoices parsed from SAP response.
* Matching is based on (SAPInvoiceNumber__c + CustomerNumber__c) composite key.
*/
    /**
* Update SAP document reference on the latest InvoiceAllocation__c
* for each cleared invoice item (per SAP response), where the doc-ref is null.
*
* Match key: (Invoice + Buyer + Amount)
* - Normalizes Buyer: strips leading '00' if present
* - Normalizes Invoice: strips leading '00' if present (if needed)
* - Amount: string → Decimal with safe parse
*
* Writes to: InvoiceAllocation__c.SAPAssignment__c   <-- change if your field differs
*/
    
    // Now the corrected method ----------------------------------------------------
    private static void updateAllocationDocRefs(String responseBody) {
        if (String.isBlank(responseBody)) return;
        
        // 1) Parse SAP items via DTO
        List<BCAPP_SapInvoiceClearingItem> sapItems =
            BCAPP_SapInvoiceClearingItem.parseFromResponse(responseBody);
        if (sapItems.isEmpty()) return;
        
        // 2) Build rows (Invoice + Buyer + Amount)
        List<AllocRow> rows = new List<AllocRow>();
        Set<String> invoiceNos = new Set<String>();
        Set<String> buyers     = new Set<String>();
        
        for (BCAPP_SapInvoiceClearingItem s : sapItems) {
            if (s == null) continue;
            if (String.isBlank(s.Invoice) || String.isBlank(s.Buyer) || String.isBlank(s.RefDoc)) continue;
            
            // normalize buyer (strip leading '00')
            String buyerNorm = s.Buyer;
            if (buyerNorm != null && buyerNorm.startsWith('00')) buyerNorm = buyerNorm.substring(2);
            
            // normalize invoice (strip leading '00' if present)
            String invNorm = s.Invoice;
            if (invNorm != null && invNorm.startsWith('00')) invNorm = invNorm.substring(2);
            
            Decimal amt = tryParseDec(s.Amount);
            if (amt == null) continue;
            
            AllocRow r = new AllocRow();
            r.inv   = invNorm;
            r.buyer = buyerNorm;
            r.amt   = amt.setScale(2);
            r.ref   = s.RefDoc;
            rows.add(r);
            
            invoiceNos.add(invNorm);
            buyers.add(buyerNorm);
        }
        if (rows.isEmpty()) return;
        
        // 3) Find Invoice__c records (composite: InvoiceNo + Buyer)
        Map<String, Id> keyToInvoiceId = new Map<String, Id>(); // key = inv|buyer
        for (Invoice__c inv : [
            SELECT Id, SAPInvoiceNumber__c, CustomerNumber__c
            FROM Invoice__c
            WHERE SAPInvoiceNumber__c IN :invoiceNos
            AND CustomerNumber__c    IN :buyers
        ]) {
            String key = inv.SAPInvoiceNumber__c + '|' + inv.CustomerNumber__c;
            keyToInvoiceId.put(key, inv.Id);
        }
        if (keyToInvoiceId.isEmpty()) return;
        
        // 4) Query allocations with null doc-ref, newest first
        List<InvoiceAllocation__c> allocs = [
            SELECT Id, Invoice__c, AllocatedAmount__c , Notes__c, CreatedDate
            FROM InvoiceAllocation__c
            WHERE Invoice__c IN :keyToInvoiceId.values()
            AND (Notes__c = NULL OR Notes__c = '')
            ORDER BY CreatedDate DESC
        ];
        
        // group by invoice
        Map<Id, List<InvoiceAllocation__c>> invIdToAllocs = new Map<Id, List<InvoiceAllocation__c>>();
        for (InvoiceAllocation__c a : allocs) {
            List<InvoiceAllocation__c> listA = invIdToAllocs.get(a.Invoice__c);
            if (listA == null) {
                listA = new List<InvoiceAllocation__c>();
                invIdToAllocs.put(a.Invoice__c, listA);
            }
            listA.add(a);
        }
        
        // 5) Match and prepare updates
        Decimal tol = 0.01;
        List<InvoiceAllocation__c> updates = new List<InvoiceAllocation__c>();
        
        for (AllocRow r : rows) {
            String key = r.inv + '|' + r.buyer;
            Id invId = keyToInvoiceId.get(key);
            if (invId == null) continue;
            
            List<InvoiceAllocation__c> cand = invIdToAllocs.get(invId);
            if (cand == null || cand.isEmpty()) continue;
            
            InvoiceAllocation__c target = null;
            Integer removeIdx = -1;
            
            // First: latest match by amount (we queried DESC)
            for (Integer i = 0; i < cand.size(); i++) {
                InvoiceAllocation__c a = cand[i];
                Decimal aAmt = (a.AllocatedAmount__c  == null) ? null : a.AllocatedAmount__c .setScale(2);
                if (withinTol(aAmt, r.amt, tol)) {
                    target = a;
                    removeIdx = i;
                    break;
                }
            }
            // Fallback: take latest null-doc allocation
            if (target == null) {
                target = cand[0];
                removeIdx = 0;
            }
            
            if (target != null) {
                updates.add(new InvoiceAllocation__c(
                    Id = target.Id,
                    Notes__c = r.ref // <-- change field API name if different
                ));
                // remove by index so we don't reuse the same allocation
                if (removeIdx >= 0 && removeIdx < cand.size()) {
                    cand.remove(removeIdx);
                }
            }
        }
        
        // 6) Save (partial success)
        if (!updates.isEmpty()) {
          update updates;
        }
    }
    
    private static void updateReceiptRefs(String responseBody, String paymentId) {
        if (String.isBlank(responseBody)) return;
        
        // 1) Parse SAP items via DTO
        List<BCAPP_SapInvoiceClearingItem> sapItems =
            BCAPP_SapInvoiceClearingItem.parseFromResponse(responseBody);
        if (sapItems.isEmpty()) return;
        
        // 2) Build rows (Invoice + Buyer + Amount)
        List<AllocRow> rows = new List<AllocRow>();
        Set<String> invoiceNos = new Set<String>();
        Set<String> buyers     = new Set<String>();
        
        for (BCAPP_SapInvoiceClearingItem s : sapItems) {
            if (s == null) continue;
            if (String.isBlank(s.Invoice) || String.isBlank(s.Buyer) || String.isBlank(s.RefDoc)) continue;
            
            // normalize buyer (strip leading '00')
            String buyerNorm = s.Buyer;
            if (buyerNorm != null && buyerNorm.startsWith('00')) buyerNorm = buyerNorm.substring(2);
            
            // normalize invoice (strip leading '00' if present)
            String invNorm = s.Invoice;
            if (invNorm != null && invNorm.startsWith('00')) invNorm = invNorm.substring(2);
            
            Decimal amt = tryParseDec(s.Amount);
            if (amt == null) continue;
            
            AllocRow r = new AllocRow();
            r.inv   = invNorm;
            r.buyer = buyerNorm;
            r.amt   = amt.setScale(2);
            r.ref   = s.RefDoc;
            rows.add(r);
            
            invoiceNos.add(invNorm);
            buyers.add(buyerNorm);
        }
        Receipt__c r = [Select Id, SAPDocumentNo__c  FROM Receipt__c where OnlinePayment__c =:paymentId];
        r.SAPDocumentNo__c = sapItems[0].RefDoc;
        update r;
    }
    // Put these inside the class (but OUTSIDE any method) -------------------------
    
    /** simple carrier for SAP item we care about */
    private class AllocRow {
        String inv;
        String buyer;
        Decimal amt;
        String ref;
    }
    
    private static Decimal tryParseDec(String s) {
        try { return String.isBlank(s) ? null : Decimal.valueOf(s); } catch (Exception e) { return null; }
    }
    
    private static Boolean withinTol(Decimal a, Decimal b, Decimal tol) {
        if (a == null || b == null || tol == null) return false;
        Decimal diff = a - b;
        if (diff < 0) diff = -diff;
        return diff <= tol;
    }
    
    
    private class ApiCallResult {
        Boolean success;
        Integer statusCode;
        String  responseBody;
        String  error;
    }
    
}