import { api, LightningElement, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callApprovalProcess from "@salesforce/apex/approvalProcessSubmitHandler.callApprovalProcess";
import updateSalesOrder from "@salesforce/apex/approvalProcessSubmitHandler.updateSalesOrder";
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import SO_Recieved_Amt from "@salesforce/schema/SalesOrder__c.Sales_Order_Received_Amount__c";
const fields = [SO_Recieved_Amt];

export default class SalesOrderCancellationProcess extends LightningElement {
    @api recordId;
    @track isModalOpen = true;
    @track refundApplicable = false;
    @track showLoading=false;   
    
    @wire(getRecord, { recordId: "$recordId", fields })
    soRecord;

    get SOAmount() {
        return getFieldValue(this.soRecord.data, SO_Recieved_Amt);
      }

    handleRefundApplicable(event) {
        let checkboxvalue = event.target.value;
        if (checkboxvalue == true) {
            this.refundApplicable = true;
        }
        else {
            this.refundApplicable = false;
        }
    }

    submitforCancellationApproval() {
        this.showLoading=true;
        let fields = event.detail.fields;

        var sOrder = new Object();
        sOrder.sobjectType = 'SalesOrder__c';
        sOrder.Id = this.recordId;

        sOrder.Reason_for_Cancellation__c = fields['Reason_for_Cancellation__c'];
        sOrder.Refund_Applicable__c = fields['Refund_Applicable__c'];
        sOrder.Refund_Reason__c = fields['Refund_Reason__c'];
        sOrder.Refund_Amount__c = fields['Refund_Amount__c'];
        sOrder.Forfeit_Amount__c = fields['Forfeit_Amount__c'];
        sOrder.Reallocation_Amount__c = fields['Reallocation_Amount__c'];
        sOrder.Charges_Amount__c = fields['Charges_Amount__c'];
        sOrder.Comments__c = fields['Comments__c'];

        updateSalesOrder({
            salesOrder: sOrder
        });

        callApprovalProcess({
            recid: this.recordId
        }).then(result => {

            const events = new ShowToastEvent({
                title: "Submitted",
                message: "Sales Order has been submitted for Cancellation",
                variant: 'Success'
            });
            this.dispatchEvent(events);
            this.showLoading=false;
            this.closeModal();
            this.updateRecordView(this.recordId);

        }).catch(error => {
            this.closeModal();
            const events = new ShowToastEvent({
                title: "Error",
                message: error.body.message,
                variant: 'error'
            });
            this.dispatchEvent(events);
        });




    }

    closeModal() {
        this.isModalOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
        this.updateRecordView(this.recordId);
    }

    updateRecordView(recordId) {
        updateRecord({ fields: { Id: recordId } });
    }


    /* handleOnLoad(event) {
        var record = event.detail.records;
        var fields = record[this.recordId].fields;
        console.log(JSON.stringify(fields));

    } */

}